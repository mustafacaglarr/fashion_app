import * as admin from "firebase-admin";
import { Transaction } from "firebase-admin/firestore";
import { onCall, HttpsError } from "firebase-functions/v2/https";

admin.initializeApp();
const db = admin.firestore();

const REQUEST_COST = 0.075;

// FAL queue endpointleri
const FAL_QUEUE_URL = "https://queue.fal.run/fal-ai/fashn/tryon/v1.6";

type KeyDoc = { key?: string; creditsRemaining?: number; enabled?: boolean };

async function reserveKeyTx(
  tx: Transaction
): Promise<{ id: string; key: string } | null> {
  const q = db
    .collection("apiKeys")
    .where("enabled", "==", true)
    .where("creditsRemaining", ">=", REQUEST_COST)
    .orderBy("creditsRemaining", "desc")
    .limit(1);

  const snap = await tx.get(q);
  if (snap.empty) return null;

  const doc = snap.docs[0];
  const data = doc.data() as KeyDoc;

  if (!data.key || typeof data.creditsRemaining !== "number") return null;

  tx.update(doc.ref, {
    creditsRemaining: data.creditsRemaining - REQUEST_COST,
    usageCount: admin.firestore.FieldValue.increment(1),
    lastUsedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { id: doc.id, key: String(data.key).trim() };
}

async function refund(keyId: string): Promise<void> {
  await db.runTransaction(async (tx: Transaction) => {
    const ref = db.collection("apiKeys").doc(keyId);
    const s = await tx.get(ref);
    if (!s.exists) return;
    const current = (s.data()?.creditsRemaining as number) ?? 0;
    tx.update(ref, { creditsRemaining: current + REQUEST_COST });
  });
}

async function queueRequest(
  key: string,
  payload: Record<string, unknown>
): Promise<{ status_url: string }> {
  const resp = await fetch(FAL_QUEUE_URL, {
    method: "POST",
    headers: {
      Authorization: `Key ${key}`,
      "Content-Type": "application/json",
      Accept: "application/json",
    },
    body: JSON.stringify({
      model_image: payload["model"],
      garment_image: payload["garment"],
      category: payload["category"],
      mode: payload["mode"],
      garment_photo_type: payload["garmentPhotoType"],
      moderation_level: "permissive",
      num_samples: 1,
      segmentation_free: true,
      output_format: "png",
    }),
  });

  if (!resp.ok) {
    const text = await resp.text().catch(() => "");
    console.error("FAL queue POST failed", resp.status, text);
    throw new Error(`FAL queue POST failed: ${resp.status} ${text}`);
  }

  const j = (await resp.json()) as any;
  if (!j?.status_url) {
    console.error("FAL queue response unexpected", j);
    throw new Error("FAL queue response unexpected");
  }
  return { status_url: j.status_url };
}

function normalizeFalOutput(out: any): { images: { url: string }[] } {
  const candidates =
    out?.images ??
    out?.response?.images ??
    out?.output?.images ??
    out?.result?.images;

  let images: any[] = Array.isArray(candidates) ? candidates : [];

  if (!images.length) {
    const singleUrl =
      out?.url ??
      out?.image ??
      out?.image_url ??
      out?.response?.url ??
      out?.output?.url;
    if (typeof singleUrl === "string" && singleUrl.startsWith("http")) {
      images = [{ url: singleUrl }];
    }
  }

  const normalized = images
    .map((e) => {
      if (!e) return null;
      if (typeof e === "string") return { url: e };
      const u = e.url || e.image || e.image_url || e.secure_url;
      if (typeof u === "string") return { url: u };
      return null;
    })
    .filter(Boolean) as { url: string }[];

  console.log("FAL images normalized:", normalized.length);
  if (!normalized.length) {
    console.log("FAL raw keys:", out ? Object.keys(out) : "no-out");
  }
  return { images: normalized };
}

/**
 * status_url’u poll eder:
 * - 202 ise bekler
 * - 200 geldiğinde JSON içinde response_url varsa onu da GET eder
 * - en sonunda response JSON’u (asıl çıktı) döndürür
 */
async function waitForFinalResponse(
  key: string,
  statusUrl: string
): Promise<any> {
  let waited = 0;
  let backoff = 800;
  const total = 90_000;
  const max = 4_000;

  while (waited <= total) {
    const resp = await fetch(statusUrl, {
      headers: { Authorization: `Key ${key}`, Accept: "application/json" },
    });

    // 202 → hâlâ işleniyor
    if (resp.status === 202) {
      await new Promise((r) => setTimeout(r, backoff));
      waited += backoff;
      backoff = Math.min(max, Math.floor(backoff * 1.5));
      continue;
    }

    // 200 → iş tamam. Bu JSON’DA çoğunlukla response_url olur.
    const text = await resp.text().catch(() => "");
    if (!resp.ok) {
      console.error("FAL status error", resp.status, text);
      throw new Error(`FAL status error: ${resp.status} ${text}`);
    }

    const statusJson = JSON.parse(text);

    // Eğer response_url varsa, asıl çıktı orada.
    const responseUrl =
      statusJson?.response_url ||
      statusJson?.response?.url ||
      statusJson?.output?.url;

    if (typeof responseUrl === "string") {
      const finalResp = await fetch(responseUrl, {
        headers: { Authorization: `Key ${key}`, Accept: "application/json" },
      });
      const finalText = await finalResp.text().catch(() => "");
      if (!finalResp.ok) {
        console.error("FAL response_url error", finalResp.status, finalText);
        throw new Error(
          `FAL response_url error: ${finalResp.status} ${finalText}`
        );
      }
      const finalJson = JSON.parse(finalText);
      return finalJson; // <- normalize bundan sonra yapılacak
    }

    // Bazı durumlarda status yanıtında direkt images olabilir
    return statusJson;
  }

  throw new Error("FAL polling timeout");
}

async function callFal(key: string, payload: Record<string, unknown>) {
  const { status_url } = await queueRequest(key, payload);
  const finalOut = await waitForFinalResponse(key, status_url);
  return finalOut;
}

export const tryOn = onCall(async (req) => {
  const uid = req.auth?.uid;
  if (!uid) throw new HttpsError("unauthenticated", "Login required");

  const payload = (req.data ?? {}) as Record<string, unknown>;

  const r1 = await db.runTransaction(reserveKeyTx);
  if (!r1) {
    throw new HttpsError("resource-exhausted", "No API key with enough credits");
  }

  try {
    const out = await callFal(r1.key, payload);
    const normalized = normalizeFalOutput(out);

    await db.collection("usage").add({
      uid,
      keyId: r1.id,
      cost: REQUEST_COST,
      at: admin.firestore.FieldValue.serverTimestamp(),
    });

    return { images: normalized.images };
  } catch (e: any) {
    console.error("Primary key failed:", e?.message || e);
    await refund(r1.id);

    const r2 = await db.runTransaction(reserveKeyTx);
    if (!r2) {
      throw new HttpsError("unavailable", "Provider failed; no backup key");
    }

    try {
      const out2 = await callFal(r2.key, payload);
      const normalized2 = normalizeFalOutput(out2);

      await db.collection("usage").add({
        uid,
        keyId: r2.id,
        cost: REQUEST_COST,
        at: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { images: normalized2.images };
    } catch (e2: any) {
      console.error("Backup key failed:", e2?.message || e2);
      await refund(r2.id);
      throw new HttpsError(
        "unavailable",
        String(e2?.message || "Provider failed on backup key")
      );
    }
  }
});
