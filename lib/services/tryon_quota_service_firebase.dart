// lib/services/tryon_quota_service_firebase.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class QuotaResult {
  final bool allowed;
  final int remaining;
  final String periodLabel; // 'daily' | 'monthly'
  final String plan;        // 'free' | 'basic' | 'pro' | 'expert'
  final String code;        // 'ok' | 'free_daily_exceeded' | 'paid_monthly_exceeded' | 'no_session' | 'generic'

  const QuotaResult({
    required this.allowed,
    required this.remaining,
    required this.periodLabel,
    required this.plan,
    required this.code,
  });
}

class TryOnQuotaService {
  final FirebaseAuth auth;
  final FirebaseFirestore db;

  TryOnQuotaService({required this.auth, required this.db});

  static const int _freeDaily = 1;
  static const Map<String, int> _monthlyLimits = {
    'basic': 50,
    'pro': 100,
    'expert': 200,
  };

  String _yyyyMmDd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String _yyyyMm(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  Future<QuotaResult> tryConsumeOne() async {
    final user = auth.currentUser;
    if (user == null) {
      return const QuotaResult(
        allowed: false,
        remaining: 0,
        periodLabel: 'daily',
        plan: 'free',
        code: 'no_session',
      );
    }

    final uid = user.uid;
    final usersRef = db.collection('users').doc(uid);
    final quotaRef = usersRef.collection('_meta').doc('quota');

    final now = DateTime.now();
    final today = _yyyyMmDd(now);
    final thisMonth = _yyyyMm(now);

    return await db.runTransaction<QuotaResult>((tx) async {
      final userSnap = await tx.get(usersRef);
      final plan = (userSnap.data()?['plan'] as String?) ?? 'free';

      final quotaSnap = await tx.get(quotaRef);
      int dailyUsed = quotaSnap.data()?['dailyUsed'] as int? ?? 0;
      String dailyDate = quotaSnap.data()?['dailyDate'] as String? ?? today;

      int monthlyUsed = quotaSnap.data()?['monthlyUsed'] as int? ?? 0;
      String monthlyMonth = quotaSnap.data()?['monthlyMonth'] as String? ?? thisMonth;

      if (dailyDate != today) {
        dailyDate = today;
        dailyUsed = 0;
      }
      if (monthlyMonth != thisMonth) {
        monthlyMonth = thisMonth;
        monthlyUsed = 0;
      }

      if (plan == 'free') {
        final remaining = _freeDaily - dailyUsed;
        if (remaining <= 0) {
          return QuotaResult(
            allowed: false,
            remaining: 0,
            periodLabel: 'daily',
            plan: plan,
            code: 'free_daily_exceeded',
          );
        }
        dailyUsed += 1;
      } else {
        final limit = _monthlyLimits[plan] ?? 0;
        final remaining = limit - monthlyUsed;
        if (remaining <= 0) {
          return QuotaResult(
            allowed: false,
            remaining: 0,
            periodLabel: 'monthly',
            plan: plan,
            code: 'paid_monthly_exceeded',
          );
        }
        monthlyUsed += 1;
      }

      tx.set(quotaRef, {
        'dailyUsed': dailyUsed,
        'dailyDate': dailyDate,
        'monthlyUsed': monthlyUsed,
        'monthlyMonth': monthlyMonth,
        'lastUsedAt': FieldValue.serverTimestamp(),
        'planCached': plan,
      }, SetOptions(merge: true));

      if (plan == 'free') {
        return QuotaResult(
          allowed: true,
          remaining: _freeDaily - dailyUsed,
          periodLabel: 'daily',
          plan: plan,
          code: 'ok',
        );
      } else {
        final limit = _monthlyLimits[plan] ?? 0;
        return QuotaResult(
          allowed: true,
          remaining: limit - monthlyUsed,
          periodLabel: 'monthly',
          plan: plan,
          code: 'ok',
        );
      }
    });
  }
}
