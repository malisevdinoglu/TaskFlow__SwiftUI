# TaskFlow

TaskFlow; görev atama, ilerleme takibi, SLA uyarıları, imza toplama ve PDF rapor üretimi sağlayan modern bir iOS uygulamasıdır. Uygulama SwiftUI + SwiftData ile yerel verileri yönetir, Firebase Firestore/Storage ile bulut senkronizasyonu yapar, yerel bildirimlerle SLA hatırlatmaları sunar. Koyu tema, kart tabanlı arayüz ve Tab Bar navigasyonu ile Apple tasarım ilkeleriyle uyumludur.

## İçindekiler
- [Özellikler](#özellikler)
- [Mimari Genel Bakış](#mimari-genel-bakış)
- [Ekranlar](#ekranlar)
- [Kurulum](#kurulum)
- [Çalıştırma](#çalıştırma)
- [Kullanım Akışı](#kullanım-akışı)
- [Teknik Detaylar](#teknik-detaylar)
- [Proje Yapısı](#proje-yapısı)
- [Sık Karşılaşılan Sorunlar](#sık-karşılaşılan-sorunlar)
- [Yol Haritası](#yol-haritası)
- [Lisans](#lisans)
- [Katkı](#katkı)
- [İletişim](#iletişim)

---

## Özellikler

- Kimlik Doğrulama ve Rol Yönetimi
  - Firebase Authentication ile giriş (e‑posta/şifre).
  - Firestore’dan kullanıcı rolü (admin/kullanıcı) alınır.
  - Admin kullanıcılar için “Yeni Görev” oluşturma butonu.

- Görev Yönetimi
  - Görev listesi (SwiftData’dan @Query ile yerel veri).
  - Duruma göre filtreleme (Planlandı, Yapılacak, Çalışmada, Kontrol, Tamamlandı).
  - Görev detayında durum geçişleri (iş kurallarıyla korunur).

- SLA Kontrolü ve Bildirimler
  - SLA süresi yaklaşan/geçen görevler görsel olarak vurgulanır.
  - Yalnızca 24 saatten az kalan (dueSoon) ve süresi geçen (overdue) görevlerde SLA şeridi ve geri sayım görünür.
  - 24 saatten fazla kalan görevlerde SLA renklendirmesi yapılmaz.
  - Tamamlanan görevlerde SLA uyarısı gösterilmez.
  - Yerel bildirim planlama: SLA’dan 1 saat önce bildirim (test için fallback 5 sn).
  - Bildirime tıklanınca ilgili görev detayına otomatik navigasyon.

- Medya ve İmza
  - PhotosPicker ile fotoğraf ekleme.
  - İmza toplama (çizim ekranı) ve saklama.
  - Firebase Storage’a medya ve imza yükleme/silme.

- PDF Raporlama
  - Tamamlanan görevlerden PDF raporu üretir (ReportView şablonu).
  - MyReportsView ekranında raporları listeler, Quick Look ile ön izleme, paylaşım ve silme.

- Yerel Veri Yönetimi
  - SwiftData @Model (LocalAppTask) ile yerel kalıcılık.
  - Firestore ile iki yönlü senkronizasyon (TaskRepository).

- Modern UI/UX
  - Koyu tema, cam efektli kartlar, tutarlı tipografi.
  - TabView: Ana Sayfa (Dashboard), Görevlerim, Raporlarım, Ayarlar.
  - Apple Human Interface Guidelines ile uyumlu, erişilebilirlik odaklı tasarım.

---

## Mimari Genel Bakış

- Katmanlar
  - View: SwiftUI ekranları (MainView, TaskListView, TaskDetailView, MyReportsView, SettingsView, LoginView).
  - ViewModel: Ekranların durum ve eylemleri (TaskListViewModel, TaskDetailViewModel, NewTaskViewModel, LoginViewModel).
  - Repository: Veri akışını koordine eder (TaskRepository).
  - Services: Dış servislerle konuşur (TaskService – Firestore, StorageService – Storage, LocalNotificationService – UNUserNotificationCenter, PDFService – PDF üretimi).

- Veri Modelleri
  - LocalAppTask (SwiftData): firebaseId, title, taskDescription, statusRawValue/status, assignedTo, createdAt, slaDate, location, priority, category, signatureData, mediaURLs, checklist (JSON encode/decode).
  - AppTask (Firestore, Codable): id, title, description, status, assignedTo, createdAt, slaDate, location, priority, category, signatureStorageURL, mediaURLs, checklist.
  - AppTaskStatus (CaseIterable): Planlandı, Yapılacak, Çalışmada, Kontrol, Tamamlandı.
  - ChecklistItem: id, text, isCompleted.

- Senkronizasyon
  - TaskRepository.startListeningToFirebase: Firestore snapshot listener ile görevleri çeker ve SwiftData’ya insert/update eder.
  - Yeni görev ekleme, durum güncelleme, imza/medya/checklist değişiklikleri repository üzerinden hem yerelde hem uzakta güncellenir.

---

## Ekranlar

- LoginView
  - Firebase Authentication ile giriş.
  - Koyu tema, kart tabanlı düzen.

- MainView (Dashboard)
  - Bugünün Özeti: Bekleyen / Aktif / Tamamlanan (dikey kartlar).
  - Admin için “Yeni Görev” butonu.
  - Bildirime tıklamayla gelen taskId için TaskDetailView’e geçiş.

- TaskListView
  - @Query ile SwiftData’dan görevleri çeker.
  - Duruma göre filtreleme dialog’u.
  - SLA Görselleştirmesi:
    - 24+ saat kalanlarda SLA şeridi ve sayaç yok.
    - 24 saatten az kalanlarda turuncu sol şerit + geri sayım.
    - Süresi geçenlerde kırmızı sol şerit + kırmızı geri sayım.
    - Tamamlanan görevlerde SLA tamamen gizli.
  - Canlı SLA güncellemesi: Her 60 saniyede bir “now” güncellenir (Combine Timer).

- TaskDetailView
  - Durum geçişleri:
    - Kontrol’e geçiş için en az bir medya gerekli.
    - Tamamlandı için imza zorunlu; checklist varsa tüm maddeler tamamlanmış olmalı.
  - Medya ekleme ve silme.
  - Checklist yönetimi (ekle, işaretle, sil).
  - İmza ekleme/silme.
  - Tamamlandı durumunda PDF rapor üretimi ve paylaşımı.

- MyReportsView
  - Belgeler klasöründeki “TaskFlowRapor-*.pdf” dosyalarını listeler.
  - Quick Look ile ön izleme, paylaşma ve silme.
  - SwiftData’dan başlık eşlemesi (taskId -> title).

- SettingsView
  - Kullanıcı bilgisi (e‑posta, rol).
  - Tema seçimi (placeholder).
  - Çıkış yap butonu.

---

## Kurulum

### Gereksinimler
- Xcode 15+
- iOS 17+ (SwiftData için)
- Swift Package Manager ile Firebase paketleri

### Firebase Yapılandırması
1. Firebase Console’da bir iOS uygulaması oluşturun (Bundle ID’niz ile).
2. GoogleService-Info.plist dosyasını projeye ekleyin ve hedefe dahil edin.
3. Firestore ve Authentication (Email/Password) etkinleştirin.
4. Storage’ı etkinleştirin. Test aşamasında uygun kuralları uygulayın.
5. Firestore “users” koleksiyonunda, Authentication UID ile aynı id’ye sahip kullanıcı belgeleri oluşturup “role” alanını ayarlayın (admin/user).

### Bildirimler
- AppDelegate (TaskFlowApp.swift) içinde UNUserNotificationCenterDelegate ayarlı.
- Uygulama açılışında kullanıcıdan izin istenir; kabul edilirse yerel bildirim planlanır.
- Bildirime tıklanınca: AppDelegate.didReceive -> NotificationCenter .taskNotificationTapped -> MainView.onReceive -> ilgili TaskDetailView’e navigasyon.

### SwiftData
- .modelContainer(for: LocalAppTask.self) App girişinde tanımlı.
- @Query ile View’larda veri otomatik güncellenir.

---

## Çalıştırma
1. Projeyi Xcode ile açın.
2. GoogleService-Info.plist dosyasını eklediğinizden emin olun.
3. Signing & Capabilities altında Team ve Bundle ID ayarlarını yapın.
4. iOS 17+ simülatör veya gerçek cihaz seçin.
5. Build & Run.

---

## Kullanım Akışı
1. Giriş yapın (Firebase Authentication).
2. Dashboard’da (MainView) Bugünün Özeti’ni görüntüleyin. Admin iseniz “Yeni Görev” oluşturun.
3. Görevlerim sekmesinde görevleri listeleyin ve duruma göre filtreleyin.
4. SLA uyarılarını takip edin:
   - 24 saatten az kala turuncu şerit + geri sayım.
   - Geçmişse kırmızı şerit + kırmızı geri sayım.
   - Tamamlanan görevlerde SLA görünmez.
5. Görev detayında:
   - Medya ekleyin, checklist’i yönetin, imza toplayın.
   - İş kuralları sağlanınca durumu “Tamamlandı” yapın.
6. Tamamlanan görev için PDF rapor oluşturun ve “Raporlarım” sekmesinden görüntüleyin/paylaşın.

---

## Teknik Detaylar

### SLA Mantığı (TaskListView)
- dueSoonThreshold: 24 saat (86400 sn).
- onTime: 24+ saat -> SLA şeridi ve geri sayım görünmez.
- dueSoon: 0–24 saat -> turuncu sol şerit + geri sayım metni.
- overdue: < 0 -> kırmızı sol şerit + kırmızı geri sayım metni.
- completed: SLA şeridi ve sayaç görünmez (nötr).
- Canlı güncelleme: `Timer.publish(every: 60, on: .main, in: .common).autoconnect()` ile `now` güncellenir (import Combine gerekir).

### Bildirimler (LocalNotificationService)
- SLA’den 1 saat önce bildirim planlanır.
- Eğer hedef zaman geçmişteyse (test kolaylığı için) 5 saniye sonraya planlama yapılır.
- Bildirim kimliği: `SLA-<taskId>`.
- Görev tamamlanırsa planlı bildirim iptal edilir.

### PDF Üretimi
- ReportView PDF şablonu olarak kullanılır.
- Çıktı dosya adı: `TaskFlowRapor-<taskId>.pdf`.
- Belgeler klasörüne kaydedilir; MyReportsView listeleyip Quick Look ile önizler.

### Veri Senkronizasyonu (TaskRepository)
- Firestore’dan snapshot listener ile AppTask listesi çekilir.
- SwiftData LocalAppTask ile eşleştirilerek insert/update yapılır.
- Durum, imza, medya ve checklist değişiklikleri hem yerelde hem Firestore’da güncellenir.

### İş Kuralları (TaskDetail)
- Kontrol’e (inReview) geçiş: En az bir medya zorunlu.
- Tamamlandı (completed): İmza zorunlu; checklist varsa tüm maddeler tamamlanmış olmalı.
- Kurallar UI ve ViewModel seviyesinde kontrol edilir.

---

## Proje Yapısı

Aşağıdaki şema ve açıklamalar, projenin modüler yapısını ve her dosyanın sorumluluğunu özetler. Dosya/klasör adları projeye göre ufak farklılık gösterebilir.

```text
TaskFlow/
├─ TaskFlowApp.swift                 # App giriş noktası, modelContainer, auth yönlendirme, bildirim delegesi
│
├─ Models/
│  ├─ LocalAppTask.swift             # SwiftData @Model; yerel görev yapısı ve yardımcı alanlar
│  ├─ AppTask.swift                  # Firestore Codable modeli; uzak veri şeması
│  ├─ ChecklistItem.swift            # Checklist maddesi modeli (id, text, isCompleted)
│  └─ User.swift                     # (Varsa) Auth kullanıcı modeli; Firestore'dan decode edilir
│
├─ ViewModels/
│  ├─ TaskListViewModel.swift        # Liste ekranı; Firebase dinleme/kurulum, repo koordinasyonu
│  ├─ TaskDetailViewModel.swift      # Detay ekranı; durum geçişleri, medya, imza, PDF tetikleme
│  ├─ NewTaskViewModel.swift         # Yeni görev oluşturma formu ve doğrulamalar
│  └─ LoginViewModel.swift           # Giriş işlemleri ve hata yönetimi
│
├─ Views/
│  ├─ MainView.swift                 # Dashboard + TabView (Ana Sayfa/Görevler/Raporlar/Ayarlar)
│  ├─ TaskListView.swift             # Görev listesi, filtre, SLA görselleştirme
│  ├─ TaskDetailView.swift           # Görev detayı, checklist, medya, imza, durum butonları
│  ├─ MyReportsView.swift            # PDF rapor listesi, Quick Look, paylaşım ve silme
│  ├─ SettingsView.swift             # Kullanıcı bilgisi, tema (placeholder), çıkış
│  ├─ NewTaskView.swift              # Yeni görev oluşturma (SwiftData + Firestore senk.)
│  └─ ReportView.swift               # PDF içerik şablonu
│
├─ Services/
│  ├─ TaskService.swift              # Firestore CRUD, checklist ve media URL güncellemeleri
│  ├─ StorageService.swift           # Firebase Storage yükleme/silme (imza, medya)
│  ├─ LocalNotificationService.swift # UNUserNotificationCenter ile SLA bildirim planlama/iptal
│  └─ PDFService.swift               # (Varsa) PDF oluşturma mantığı
│
├─ Repository/
│  └─ TaskRepository.swift           # Servisleri orkestre eder; SwiftData ↔ Firestore senkron
│
├─ Resources/
│  ├─ GoogleService-Info.plist       # Firebase yapılandırma dosyası
│  └─ Assets.xcassets                # Uygulama ikonları ve renk varlıkları
│
└─ README.md                         # Bu dosya
