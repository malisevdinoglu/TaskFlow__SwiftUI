//
//  CheckListItem.swift
//  TaskFlow
//
//  Created by Mehmet Ali Sevdinoğlu on 25.10.2025.
//
import Foundation


struct ChecklistItem: Codable, Identifiable, Hashable {
    
 
    var id: String = UUID().uuidString
    var text: String
    var isCompleted: Bool = false
}
