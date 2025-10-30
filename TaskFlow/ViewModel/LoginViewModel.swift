//
//  LoginViewModel.swift
//  TaskFlow
//
//  Created by Mehmet Ali Sevdinoğlu on 15.10.2025.
//

import Foundation
import Combine
import FirebaseAuth

class LoginViewModel: ObservableObject {
    
    @Published var email = ""
    @Published var password = ""
    @Published var errorMessage = ""
    
    init() {}
 
    func login() {
       
        guard !email.trimmingCharacters(in: .whitespaces).isEmpty,
              !password.trimmingCharacters(in: .whitespaces).isEmpty else {
            
            print("HATA: E-posta veya şifre boş.")
            errorMessage = "Lütfen e-posta ve şifre alanlarını doldurun."
            return
        }
        
        Auth.auth().signIn(withEmail: email, password: password) { result, error in
  
            if let error = error {
                print("Firebase HATA DÖNDÜ: \(error.localizedDescription)")
                self.errorMessage = "Giriş başarısız: \(error.localizedDescription)"
                print("HATA: \(error.localizedDescription)")
            } else {
               
                print("Kullanıcı başarıyla giriş yaptı!")
                self.errorMessage = ""
                // TODO: Giriş başarılı olduğunda Anasayfa'ya yönlendirme yapılacak.
            }
        }
    }
}
