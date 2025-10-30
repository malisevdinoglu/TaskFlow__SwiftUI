import Foundation
import Combine
import FirebaseAuth
import FirebaseFirestore

class AuthViewModel: ObservableObject {
    
    @Published var authUser: FirebaseAuth.User?
    @Published var currentUser: User?
    
    private var authStateHandler: AuthStateDidChangeListenerHandle?
    private var db = Firestore.firestore() // Firestore veritabanı referansı
    
    init() {
        print("AuthViewModel başlatıldı.")
        
        self.authStateHandler = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            self?.authUser = user
            
            if let user = user {
                print("Oturum durumu değişti: KULLANICI GİRİŞ YAPTI (ID: \(user.uid))")
                self?.fetchUserRole(uid: user.uid)
            } else {
                print("Oturum durumu değişti: KULLANICI ÇIKIŞ YAPTI")
                self?.currentUser = nil
            }
        }
    }
    

    func fetchUserRole(uid: String) {
        print("fetchUserRole: Çağrıldı. UID: \(uid)") // Log 1: Fonksiyon çağrıldı mı?
        db.collection("users").document(uid).getDocument { document, error in
            
            // Hata Kontrolü
            if let error = error {
                print("HATA (fetchUserRole): Kullanıcı rolü çekilemedi - \(error.localizedDescription)") // Hata Logu 1
                return
            }
            
            // Belge Var mı Kontrolü
            guard let document = document, document.exists else {
                print("HATA (fetchUserRole): Kullanıcı belgesi Firestore'da bulunamadı. users/\(uid) doküman ID’si Auth UID ile eşleşmeli.") // Hata Logu 2
                return
            }
            
            // Ham Veriyi Loglama
            let raw = document.data() ?? [:]
            print("DEBUG (fetchUserRole): users/\(uid) ham veri bulundu: \(raw)") // Debug Logu: Veri neye benziyor?
            
            // Codable ile Dönüştürme Denemesi
            do {
                print("fetchUserRole: Belge bulundu, User modeline dönüştürülüyor...") // Log 2
                let userModel = try document.data(as: User.self)
                // Başarılı olursa Ana Thread'de Ata
                DispatchQueue.main.async {
                    self.currentUser = userModel
                    print("fetchUserRole: BAŞARILI! currentUser atandı. Rol: \(userModel.role)") // Log 3 (Başarı)
                }
            } catch {
                // Dönüştürme Başarısız Olduysa
                print("HATA (fetchUserRole): Kullanıcı belgesi User modeline dönüştürülemedi - \(error.localizedDescription). Firestore'daki alan adları/tipleri User.swift modeliyle eşleşmiyor olabilir.") // Hata Logu 3
                
                // --- Güvenlik Ağı (Fallback) - Sadece rolü manuel çekmeyi dene ---
                // Bu kısım normalde çalışmamalı, ama Codable başarısız olursa diye ekledik.
                guard let email = raw["email"] as? String else {
                    print("HATA (fetchUserRole - Fallback): 'email' alanı da ham veride bulunamadı; currentUser set edilmeyecek.")
                    return
                }
                
                if let roleString = raw["role"] as? String, !roleString.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    let temp = User(id: uid, email: email, role: roleString, fullName: raw["fullName"] as? String)
                    DispatchQueue.main.async {
                        self.currentUser = temp
                        print("INFO (fetchUserRole - Fallback): Ham veriden 'role' alındı ve set edildi: \(roleString)")
                    }
                } else {
                    print("UYARI (fetchUserRole - Fallback): 'role' alanı ham veride yok veya geçersiz. currentUser.role set edilmeyecek (UI'da '—'). Firestore verisini düzeltin.")
                }
                // --- Güvenlik Ağı Bitti ---
            }
        }
    }
    // --- GÜNCELLEME BİTTİ ---

    func signOut() {
        do {
            try Auth.auth().signOut()
        } catch {
            print("HATA: Çıkış yapılırken sorun oluştu: \(error.localizedDescription)")
        }
    }
}

