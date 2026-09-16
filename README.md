# TaskFlow

TaskFlow, saha ve ekip operasyonlarında görev atamalarını, SLA sürelerini ve iş adımlarını uçtan uca takip eden bir iOS uygulamasıdır. Ekiplerin iş süreçlerini çevrimdışı öncelikli yerel veri saklama, bulut senkronizasyonu, dijital imza doğrulaması ve otomatik PDF raporlama ile tek merkezden yönetmesini sağlar.

##  Özellikler (Features)
- **Rol Tabanlı Görev Yönetimi:** Admin ve kullanıcı yetkilendirmesi; görev oluşturma, kullanıcı atama ve durum yaşam döngüsü (Planlandı, Yapılacak, Çalışmada, Kontrol, Tamamlandı) takibi.
- **Canlı SLA ve Akıllı Bildirimler:** Gerçek zamanlı geri sayım sayacı, dinamik durum şeritleri (yaklaşan/geciken) ve teslim tarihine 1 saat kala tetiklenen yerel bildirimler (UserNotifications).
- **İş Kuralları ve Doğrulama:** Kontrol aşamasına geçişte medya eki, tamamlama aşamasında ise dijital imza ve kontrol listesi (checklist) tamamlama zorunluluğu.
- **Çevrimdışı Öncelikli Senkronizasyon:** SwiftData ile yerel öncelikli çevrimdışı çalışma ve Firebase Firestore ile çift yönlü anlık veri eşitleme.
- **Otomatik PDF Raporlama:** Tamamlanan işler için otomatik PDF servis çıktısı, yerel dosya depolama, Quick Look ile önizleme ve paylaşım desteği.

##  Teknolojiler & Mimari (Tech Stack)
- **Frontend / Mobile / Backend:** Swift 5.9+, SwiftUI (iOS 17+), Firebase (Authentication, Firestore, Storage)
- **Mimari / State / DB:** MVVM + Repository Pattern, Combine, SwiftData (`@Model`), Firestore
- **Sistem API'leri & Araçlar:** UserNotifications, PhotosUI (PhotosPicker), UIGraphicsPDFRenderer, Quick Look, Swift Package Manager

##  Kurulum (Getting Started)
```bash
# 1. Repoyu klonlayın
git clone https://github.com/malisevdinoglu/TaskFlow__SwiftUI.git
cd TaskFlow__SwiftUI

# 2. Firebase Console'dan edindiğiniz GoogleService-Info.plist dosyasını Xcode projesine ekleyin
# (Firebase Authentication, Firestore ve Storage servislerinin etkin olduğundan emin olun)

# 3. Projeyi Xcode ile açın (SPM paketleri otomatik olarak yüklenecektir)
open TaskFlow.xcodeproj

# 4. Target > Signing & Capabilities altından ekibinizi seçin ve derleyin (Cmd + R)
```
