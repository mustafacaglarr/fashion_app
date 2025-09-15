import 'package:flutter/material.dart';

class PrivacySettingsView extends StatelessWidget {
  const PrivacySettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;

    Widget sectionTitle(String text) => Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(text, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
    );

    Widget bullet(String text) => Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("•  "),
        Expanded(child: Text(text, style: t.bodyMedium)),
      ],
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Gizlilik')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Özet kartı
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(.04), blurRadius: 10, offset: const Offset(0,6))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Gizlilik İlkeleri", style: t.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                const SizedBox(height: 6),
                Text(
                  "Bu sayfa; uygulamamızda işlenen kişisel veriler, işleme amaçları, hukuki dayanaklar, saklama süreleri ve kullanıcı hakları hakkında bilgilendirme sağlar. "
                  "Kapsam; KVKK (6698) ve GDPR ile uyumludur.",
                  style: t.bodyMedium?.copyWith(color: Colors.black87),
                ),
              ],
            ),
          ),

          sectionTitle("İşlenen Veri Kategorileri"),
          bullet("Hesap verileri: ad-soyad (opsiyonel), e-posta."),
          bullet("Kullanım verileri: uygulama içi etkileşimler, hata/performans logları (anonimleştirilmiş)."),
          bullet("Cihaz verileri: model, işletim sistemi sürümü, dil/bölge."),
          bullet("İşleme görselleri: kullanıcının yüklediği model fotoğrafı ve kıyafet görseli (yalnızca işleme amacıyla, kalıcı depolama olmadan)."),

          sectionTitle("İşleme Amaçları"),
          bullet("Hizmetin sunulması: sanal deneme (try-on) çıktısının üretilmesi."),
          bullet("Hesap yönetimi: kimlik doğrulama, oturum devamlılığı."),
          bullet("Güvenlik: kötüye kullanım tespiti, sahte/zararlı içerik önleme."),
          bullet("Ürün geliştirme: anonimleştirilmiş kullanım istatistikleriyle deneyimi iyileştirme."),
          bullet("Yasal yükümlülükler: talep/uyuşmazlık durumlarında mevzuata uygun hareket edilmesi."),

          sectionTitle("Hukuki Dayanak"),
          bullet("Açık rıza (GDPR m.6/1-a, KVKK m.5/1): görsel işleme işlemleri."),
          bullet("Sözleşmenin ifası (GDPR m.6/1-b): hizmetin sağlanması ve hesap yönetimi."),
          bullet("Meşru menfaat (GDPR m.6/1-f): dolandırıcılık önleme, güvenlik ve ürün geliştirme."),
          bullet("Hukuki yükümlülük (GDPR m.6/1-c): kayıt tutma, resmi taleplere yanıt."),

          sectionTitle("Saklama Süresi"),
          bullet("Try-on görselleri: yalnızca işleme anında kullanılır; iş tamamlanınca sistemden silinir."),
          bullet("Hesap verileri: hesabınız silinene kadar veya mevzuat gereği tutulması gereken süre kadar."),
          bullet("Log ve analitik veriler: mümkün olduğunca anonimleştirilmiş biçimde sınırlı süreyle."),

          sectionTitle("Aktarım & Üçüncü Taraflar"),
          bullet("Kimlik doğrulama/altyapı sağlayıcıları (ör. kimlik doğrulama, hata/performans izleme)."),
          bullet("Görsel işleme sağlayıcısı: yalnızca talep ettiğiniz try-on çıktısını üretmek için görsel(ler) geçici olarak işlenir; kalıcı depolama yapılmaz."),
          bullet("Hizmet tedarikçileri, yalnızca sözleşmesel gizlilik ve güvenlik yükümlülükleri altında ve amacına uygun şekilde erişebilir."),

          sectionTitle("Yurt Dışına Aktarım"),
          bullet("Bazı hizmet sağlayıcılar yurt dışında bulunabilir. Aktarım, yeterlilik kararı, standart sözleşme maddeleri ve ek güvenlik önlemleri ile gerçekleştirilir."),

          sectionTitle("Güvenlik"),
          bullet("İletim ve depolamada uygun teknik/idari tedbirler (şifreleme, erişim kontrolü, ağ güvenliği)."),
          bullet("Yetkisiz erişim, ifşa, değişiklik ve imhaya karşı risk temelli yaklaşım."),

          sectionTitle("Kullanıcı Hakları"),
          bullet("Veriye erişim ve bilgi talebi."),
          bullet("Düzeltme ve güncelleme."),
          bullet("Silme (unutulma hakkı) ve hesap kapatma."),
          bullet("İşlemenin kısıtlanması ve aktarılabilirlik."),
          bullet("Rızanın geri alınması (geri alma, geri alma öncesi işlemenin hukuka uygunluğunu etkilemez)."),
          bullet("İtiraz hakkı (meşru menfaat gerekçeli işlemlere karşı)."),

          sectionTitle("Çocukların Verileri"),
          bullet("Hizmet 13 yaş altı çocuklara yönelik değildir. Bu kapsamdaki kayıtlar tespit edilirse hesap kapatılır ve veriler silinir."),

          sectionTitle("Çerezler & Benzeri Teknolojiler"),
          bullet("Uygulama içi tercihlerin hatırlanması ve performans ölçümü için cihazda sınırlı veri saklama yapılabilir. Tarayıcı tabanlı bir modül kullanımında, zorunlu ve tercihe bağlı çerezler ayrıştırılır."),

          sectionTitle("İletişim"),
          bullet("Veri Sorumlusu: Uygulama Operatörü"),
          bullet("E-posta: privacy@yourapp.example"),
          bullet("Adres: (şirket adresi)"),

          sectionTitle("Güncellemeler"),
          bullet("Gizlilik politikası zaman zaman güncellenebilir. Önemli değişiklikleri uygulama içi bildirim ve/veya e-posta ile duyururuz."),

        
        ],
      ),
    );
  }
}
