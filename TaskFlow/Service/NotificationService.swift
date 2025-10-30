//
//  NotificationService.swift
//  TaskFlow
//
//  Created by Mehmet Ali Sevdinoğlu on 26.10.2025.
//

import Foundation
import UserNotifications // Bildirimleri yönetmek için

class LocalNotificationService {
    init() {
            print("NotificationService: INIT - Servis başlatıldı.")
        }
   
    private let notificationCenter = UNUserNotificationCenter.current()
    
    @MainActor
        func scheduleSLANotification(for task: LocalAppTask) {
            print("NotificationService: scheduleSLANotification fonksiyonuna girildi. Task: \(task.title)") // Log 1

            let taskId = task.firebaseId

            let now = Date()
            print("NotificationService: Tarih kontrolü yapılıyor. Now: \(now), SLA: \(task.slaDate)") // Log 2
            if task.slaDate <= now {
                print("NotificationService: SLA tarihi geçmiş, bildirim planlanmadı. Task: \(task.title)") // Log (Hata Durumu 1)
                cancelNotification(for: taskId)
                return
            }

            // Bildirim içeriğini oluştur (Aynı kaldı)
            let content = UNMutableNotificationContent()
            content.title = "Görev Süresi Yaklaşıyor!"
            content.body = "'\(task.title)' görevinin hedef süresi (SLA) dolmak üzere."
            content.sound = UNNotificationSound.default

            // --- TETİKLEYİCİ MANTIĞI GÜNCELLENDİ (Test için Basitleştirildi) ---
            // Hedef zamanı hesapla: SLA'den 1 saat öncesi
            let targetTime = task.slaDate.addingTimeInterval(-3600) // -1 saat
            var triggerTimeInterval: TimeInterval

            // Hedef zaman gelecek mi?
            if targetTime > now {
                // Gelecekse, şu andan hedef zamana kadar olan süreyi (saniye) hesapla
                triggerTimeInterval = targetTime.timeIntervalSince(now)
                print("NotificationService: Bildirim normal zamanında planlanıyor (\(String(format: "%.1f", triggerTimeInterval)) saniye sonra).") // Log 3a
            } else {
                // Hedef zaman geçmişteyse, test için 5 saniye sonraya ayarla
                triggerTimeInterval = 5.0
                print("NotificationService: Bildirim zamanı geçmişte kaldı, 5 saniye sonraya ayarlanıyor.") // Log 3b
            }
            
            // Takvim yerine 'TimeInterval' (süre) tetikleyicisi kullanalım (Daha basit)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerTimeInterval, repeats: false)
            // --- TETİKLEYİCİ GÜNCELLEMESİ BİTTİ ---

            let requestIdentifier = "SLA-\(taskId)"
            let request = UNNotificationRequest(identifier: requestIdentifier, content: content, trigger: trigger)

            print("NotificationService: Bildirim isteği oluşturuldu. ID: \(requestIdentifier), Trigger Süresi: \(String(format: "%.1f", trigger.timeInterval))s") // Log 4

            // İsteği bildirim merkezine ekle
            notificationCenter.add(request) { error in
                // Bu blok @MainActor üzerinde çalışmalı
                if let error = error {
                    // Hata varsa logla
                    print("HATA: Bildirim planlanamadı (notificationCenter.add callback) - \(error.localizedDescription)") // Log (Hata Durumu 2)
                } else {
                    // Başarılıysa logla (yaklaşık zamanı hesaplayarak)
                    let approxTriggerDate = Date().addingTimeInterval(triggerTimeInterval)
                    print("NotificationService: Bildirim başarıyla planlandı. ID: \(requestIdentifier), Yaklaşık Zaman: \(approxTriggerDate.formatted())") // Log 5 (Başarı)
                }
            }
            // notificationCenter.add asenkron olabilir, bu log hemen ardından çalışır
            print("NotificationService: notificationCenter.add çağrıldı.") // Log 6
        } // scheduleSLANotification biter
    
    @MainActor
    func cancelNotification(for taskId: String) {
        let requestIdentifier = "SLA-\(taskId)"
        
        notificationCenter.removePendingNotificationRequests(withIdentifiers: [requestIdentifier])
        print("NotificationService: Bildirim iptal edildi (eğer varsa). ID: \(requestIdentifier)")
    }
    
    @MainActor
    func cancelAllNotifications() {
        notificationCenter.removeAllPendingNotificationRequests()
        print("NotificationService: Tüm planlanmış bildirimler iptal edildi.")
    }
}
