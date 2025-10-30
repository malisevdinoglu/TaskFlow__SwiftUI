import Foundation
import SwiftData
import Combine

@MainActor
class NewTaskViewModel: ObservableObject {
    
    @Published var title: String = ""
    @Published var description: String = ""
    @Published var assignedTo: String = ""
    @Published var slaDate: Date = Date()
    @Published var location: String = ""
    
    @Published var errorMessage: String = ""
    
   
    private let repository = TaskRepository()
    private let notificationService = LocalNotificationService()
   
    func saveTask(modelContext: ModelContext) {

        guard !title.isEmpty, !description.isEmpty, !assignedTo.isEmpty else {
            errorMessage = "Lütfen tüm zorunlu (*) alanları doldurun."
            return
        }
        
        
        let newTask = AppTask(
            id: nil,
            title: title,
            description: description,
            status: .planned,
            assignedTo: assignedTo,
            createdAt: Date(),
            slaDate: slaDate,
            location: location.isEmpty ? nil : location,
            priority: nil,
            category: nil
        )
        
      
        Task {
            do {
                try await repository.saveNewTask(newTask, to: modelContext)
                
                print("Görev başarıyla kaydedildi! (Hem yerel hem uzak)")
                
            } catch {
                
                self.errorMessage = "Görev kaydedilemedi: \(error.localizedDescription)"
                
            }
        }
    }
}
