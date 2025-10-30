import Foundation
import SwiftData
import SwiftUI
import Combine

@MainActor
class TaskDetailViewModel: ObservableObject {
    
    @Published var task: LocalAppTask
    @Published var errorMessage: String = ""
    @Published var pdfURL: URL?
    
    private let repository = TaskRepository()
    private let pdfService = PDFService()
    
    // Silme işlemi için ModelContext (detay ekranında attach ediliyor)
    var modelContext: ModelContext?
    
    init(task: LocalAppTask) {
        self.task = task
        if task.status == .completed {
            checkAndGeneratePDF()
        }
        print("TaskDetailVM.init: taskId=\(task.firebaseId) title=\(task.title) status=\(task.status.rawValue) checklistCount=\(task.checklist?.count ?? 0) mediaCount=\(task.mediaURLs?.count ?? 0)")
    }
    
    func attach(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    func updateTaskStatus(to newStatus: AppTaskStatus) {
        if newStatus == task.status { return }
        
        // "Kontrol"e geçişte medya zorunluluğu
        if newStatus == .inReview {
            let hasAtLeastOneMedia = !(task.mediaURLs?.isEmpty ?? true)
            if !hasAtLeastOneMedia {
                self.errorMessage = "Kontrol aşamasına geçmek için önce en az bir medya yüklemelisiniz."
                print("TaskDetailVM.updateTaskStatus: ENGEL - Medya yokken 'Kontrol'e geçilemez.")
                return
            }
        }
        
        // "Tamamlandı"ya geçişte checklist ve imza zorunluluğu
        if newStatus == .completed {
            // 1) İmza zorunlu
            if task.signatureData == nil || (task.signatureData?.isEmpty ?? true) {
                self.errorMessage = "Görevi tamamlamak için müşteri imzası gereklidir."
                print("TaskDetailVM.updateTaskStatus: ENGEL - İmza yokken 'Tamamlandı'ya geçilemez.")
                return
            }
            // 2) Checklist varsa tüm maddeler tamamlanmalı
            if let checklist = self.task.checklist, !checklist.isEmpty {
                let allItemsCompleted = checklist.allSatisfy { $0.isCompleted }
                if !allItemsCompleted {
                    self.errorMessage = "Görevi tamamlamak için önce tüm checklist maddelerini bitirmelisiniz."
                    print("TaskDetailVM.updateTaskStatus: ENGEL - Checklist tamamlanmadı.")
                    return
                }
            }
        }
        
        Task {
            do {
                try await repository.updateTaskStatus(task: self.task, newStatus: newStatus)
                self.errorMessage = ""
                print("TaskDetailVM.updateTaskStatus: Başarılı -> status=\(self.task.status.rawValue)")
                
                if newStatus == .completed {
                    self.pdfURL = await pdfService.createPDF(from: self.task)
                } else {
                    self.pdfURL = nil
                }
            } catch {
                self.errorMessage = "Durum güncellenemedi: \(error.localizedDescription)"
            }
        }
    }
    
    // EKSİK OLAN FONKSİYON GERİ EKLENDİ
    private func checkAndGeneratePDF() {
        let url = URL.documentsDirectory.appending(path: "TaskFlowRapor-\(task.firebaseId).pdf")
        let fileManager = FileManager.default
        
        if fileManager.fileExists(atPath: url.path()) {
            self.pdfURL = url
        } else {
            Task {
                self.pdfURL = await pdfService.createPDF(from: self.task)
            }
        }
    }
    
    func saveSignature(data: Data) {
        Task {
            do {
                try await repository.saveSignature(data: data, for: self.task)
            } catch {
                self.errorMessage = "İmza kaydedilemedi: \(error.localizedDescription)"
            }
        }
    }
    
    func deleteSignature() {
        self.errorMessage = ""
        Task {
            do {
                try await repository.deleteSignature(for: self.task)
            } catch {
                self.errorMessage = "İmza silinemedi: \(error.localizedDescription)"
            }
        }
    }
    
    func uploadMedia(photoData: [Data]) {
        self.errorMessage = ""
        Task {
            do {
                try await repository.uploadMediaAndSync(mediaData: photoData, for: self.task)
                print("TaskDetailVM.uploadMedia: mediaCount=\(self.task.mediaURLs?.count ?? 0)")
            } catch {
                self.errorMessage = "Medya yüklenemedi: \(error.localizedDescription)"
            }
        }
    }
    
    func updateChecklistItem(itemId: String, isCompleted: Bool) {
        self.errorMessage = ""
        Task {
            do {
                try await repository.updateChecklistItemStatus(for: self.task, itemId: itemId, isCompleted: isCompleted)
                let count = self.task.checklist?.filter { $0.isCompleted }.count ?? 0
                let total = self.task.checklist?.count ?? 0
                print("TaskDetailVM.updateChecklistItem: completed=\(count)/\(total)")
            } catch {
                self.errorMessage = "Checklist maddesi güncellenemedi: \(error.localizedDescription)"
            }
        }
    }
    
    func addChecklistItem(text: String) {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return }
        self.errorMessage = ""
        Task {
            do {
                try await repository.addChecklistItem(for: self.task, text: text)
            } catch {
                self.errorMessage = "Checklist maddesi eklenemedi: \(error.localizedDescription)"
            }
        }
    }
    
    func removeChecklistItem(itemId: String) {
        self.errorMessage = ""
        Task {
            do {
                try await repository.removeChecklistItem(for: self.task, itemId: itemId)
            } catch {
                self.errorMessage = "Checklist maddesi silinemedi: \(error.localizedDescription)"
            }
        }
    }
    
    func deleteMedia(url: String) {
        self.errorMessage = ""
        Task {
            do {
                try await repository.deleteMediaURL(url, for: self.task)
            } catch {
                self.errorMessage = "Medya silinemedi: \(error.localizedDescription)"
            }
        }
    }
    
    func deleteTask(onSuccess: @escaping () -> Void) {
        guard let modelContext else {
            self.errorMessage = "İç hata: modelContext bulunamadı."
            return
        }
        self.errorMessage = ""
        Task {
            do {
                try await repository.deleteTask(self.task, in: modelContext)
                onSuccess()
            } catch {
                self.errorMessage = "Görev silinemedi: \(error.localizedDescription)"
            }
        }
    }
}

