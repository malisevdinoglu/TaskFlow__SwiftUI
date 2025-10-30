//
//  LocalAppTask.swift
//  TaskFlow
//
//  Created by Mehmet Ali Sevdinoğlu on 25.10.2025.
//

import Foundation
import SwiftData


@Model
class LocalAppTask {
    
    
    @Attribute(.unique) var firebaseId: String
    
    var title: String
    
  
    @Attribute(originalName: "description") // Veritabanında 'description' olarak sakla
    var taskDescription: String

    var statusRawValue: String
    
    var assignedTo: String
    var createdAt: Date
    var slaDate: Date
    
    var location: String?
    var priority: String?
    var category: String?
    var signatureData: Data?
    var mediaURLs: [String]?
    private var checklistData: Data?
    
    
    var checklist: [ChecklistItem]? {
            get {
                guard let data = checklistData else { return nil }
                // JSON Data'yı [ChecklistItem] dizisine decode et
                return try? JSONDecoder().decode([ChecklistItem].self, from: data)
            }
            set {
                // [ChecklistItem] dizisini JSON Data'ya encode et
                checklistData = try? JSONEncoder().encode(newValue)
            }
        }
   
    var status: AppTaskStatus {
        get {
  
            return AppTaskStatus(rawValue: statusRawValue) ?? .planned
        }
        set {
            
            statusRawValue = newValue.rawValue
        }
    }
   
    init(firebaseId: String, title: String, taskDescription: String, status: AppTaskStatus, assignedTo: String, createdAt: Date, slaDate: Date, location: String? = nil, priority: String? = nil, category: String? = nil,signatureData: Data? = nil,mediaURLs: [String]? = nil,checklist: [ChecklistItem]? = nil) {
        self.firebaseId = firebaseId
        self.title = title
        self.taskDescription = taskDescription
        self.statusRawValue = status.rawValue
        self.assignedTo = assignedTo
        self.createdAt = createdAt
        self.slaDate = slaDate
        self.location = location
        self.priority = priority
        self.category = category
        self.signatureData = signatureData
        self.mediaURLs = mediaURLs
        self.checklist = checklist
    }
    
    convenience init(from fbTask: AppTask) {
            let id = fbTask.id ?? UUID().uuidString
            
            self.init(
                firebaseId: id,
                title: fbTask.title,
                taskDescription: fbTask.description,
                status: fbTask.status,
                assignedTo: fbTask.assignedTo,
                createdAt: fbTask.createdAt,
                slaDate: fbTask.slaDate,
                location: fbTask.location,
                priority: fbTask.priority,
                category: fbTask.category,
                signatureData: nil,
                mediaURLs: fbTask.mediaURLs,
                checklist: fbTask.checklist
                
            )
        }
}
