//
//  User.swift
//  TaskFlow
//
//  Created by Mehmet Ali Sevdinoğlu on 25.10.2025.
//

import Foundation
import FirebaseFirestore

// Firestore'daki 'users' koleksiyonundaki belge yapısını temsil eder.
struct User: Codable, Identifiable {
    
    // @DocumentID: Belgenin ID'sini (yani User UID'sini) buraya atar.
    @DocumentID var id: String?
    
    let email: String
    let role: String
    var fullName: String? // Opsiyonel yaptık
}
