//
//  TaskFlowApp.swift
//  TaskFlow
//
//  Created by Mehmet Ali Sevdinoğlu on 15.10.2025.
//

import SwiftUI
import FirebaseCore
import SwiftData
import UserNotifications


// 1. UNUserNotificationCenterDelegate protokolünü ekleyin
class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        FirebaseApp.configure()
        
        // --- YENİ EKLENEN SATIR ---
        // AppDelegate'i bildirim merkezi delegesi olarak ayarla
        UNUserNotificationCenter.current().delegate = self
        // --- BİTTİ ---
        
        requestNotificationPermission()
        
        return true
    }
    
    func requestNotificationPermission() {
        let center = UNUserNotificationCenter.current()
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("HATA: Bildirim izni istenemedi - \(error.localizedDescription)")
            }
            
            if granted {
                print("Bildirim izni verildi.")
                
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            } else {
                print("Bildirim izni reddedildi.")
            }
        }
    }
    
    // --- YENİ EKLENEN DELEGATE METODU (Ön plan bildirimi için - Bu da eklenmeliydi) ---
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let identifier = notification.request.identifier
        let content = notification.request.content
        
        print("AppDelegate: Ön planda bildirim alındı! ID: \(identifier), Başlık: \(content.title)")
        
        completionHandler([.banner, .sound, .list])
    }
    // --- BİTTİ ---
    
    // --- YENİ EKLENEN/GÜNCELLENEN FONKSİYON (Bildirime tıklama için) ---
    // Kullanıcı bir bildirime TIKLADIĞINDA (veya bildirimle etkileşime girdiğinde) bu fonksiyon çağrılır.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let identifier = response.notification.request.identifier // Bildirimin ID'si (örn: "SLA-TASK_ID")
        print("AppDelegate: Kullanıcı bildirime tıkladı. ID: \(identifier)")
        
        // ID'nin "SLA-" ile başlayıp başlamadığını kontrol et
        if identifier.starts(with: "SLA-") {
            // "SLA-" kısmını çıkararak asıl görev ID'sini al
            let taskId = String(identifier.dropFirst(4))
            print("AppDelegate: Görev ID'si çıkarıldı: \(taskId)")
            
            // Bu ID'yi uygulamanın geri kalanına bildirmek için NotificationCenter'ı kullan
            NotificationCenter.default.post(
                name: .taskNotificationTapped, // Özel bildirim adı (aşağıda tanımlandı)
                object: nil,
                userInfo: ["taskId": taskId] // Görev ID'sini sözlüğe ekle
            )
        }
        
        completionHandler()
    }
    // --- BİTTİ ---

} // AppDelegate sınıfı biter


// --- YENİ EKLENEN EXTENSION ---
// Özel bildirim adımızı tanımlamak için
extension Notification.Name {
    static let taskNotificationTapped = Notification.Name("taskNotificationTapped")
}
// --- BİTTİ ---


@main
struct TaskFlowApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    @StateObject private var authViewModel = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            
            Group {
                if authViewModel.authUser != nil {
                    MainView()
                        .environmentObject(authViewModel)
                } else {
                    LoginView()
                }
            }
            
            .modelContainer(for: LocalAppTask.self)
        }
    }
}
