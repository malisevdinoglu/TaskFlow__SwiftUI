//
//  AppTask.swift
//  TaskFlow
//
//  Created by Mehmet Ali Sevdinoğlu on 24.10.2025.
//


import Foundation
import FirebaseFirestore

enum AppTaskStatus: String, Codable, CaseIterable {
    case planned = "Planlandı"
    case toDo = "Yapılacak"
    case inProgress = "Çalışmada"
    case inReview = "Kontrol"
    case completed = "Tamamlandı"
}

struct AppTask: Codable, Identifiable {

    @DocumentID var id: String?

    let title: String
    let description: String
    var status: AppTaskStatus
    let assignedTo: String

    let createdAt: Date
    let slaDate: Date

    var location: String?
    var priority: String?
    var category: String?
    var signatureStorageURL: String?
    
    var mediaURLs: [String]?
    
    var checklist: [ChecklistItem]?
}
