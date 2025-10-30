//
//  TaskRepository.swift
//  TaskFlow
//
//  Created by Mehmet Ali Sevdinoğlu on 25.10.2025.
//

import Foundation
import SwiftData
import FirebaseFirestore

class TaskRepository {
    
    init() {
        print("TaskRepository: INIT - Depo başlatıldı.")
    }
    
    private let taskService = TaskService()
    private let notificationService = LocalNotificationService()
    private let storageService = StorageService()
    private var tasksListener: ListenerRegistration?
    
    @MainActor
    func startListeningToFirebase(modelContext: ModelContext) {
        stopListeningToFirebase()
        print("Repository: Firebase dinleyicisi başlatılıyor...")
        self.tasksListener = taskService.fetchTasks { [weak self] firebaseTasks in
            guard let self = self else { return }
            print("Repository: Firebase'den \(firebaseTasks.count) görev alındı.")
            for (idx, t) in firebaseTasks.enumerated() {
                let clCount = t.checklist?.count ?? 0
                let mediaCount = t.mediaURLs?.count ?? 0
                print("Repository: [FB ->\(idx)] id=\(t.id ?? "nil") title=\(t.title) status=\(t.status.rawValue) checklist=\(clCount) media=\(mediaCount)")
            }
            self.syncTasks(from: firebaseTasks, to: modelContext)
        }
    }
    
    func stopListeningToFirebase() {
        print("Repository: Firebase dinleyicisi durduruluyor.")
        tasksListener?.remove()
        tasksListener = nil
    }
    
    @MainActor
    private func syncTasks(from firebaseTasks: [AppTask], to modelContext: ModelContext) {
        for fbTask in firebaseTasks {
            guard let fbId = fbTask.id else { continue }
            let fetchDescriptor = FetchDescriptor<LocalAppTask>(
                predicate: #Predicate { $0.firebaseId == fbId }
            )
            do {
                let existingLocalTasks = try modelContext.fetch(fetchDescriptor)
                if let existingTask = existingLocalTasks.first {
                    existingTask.title = fbTask.title
                    existingTask.taskDescription = fbTask.description
                    existingTask.status = fbTask.status
                    existingTask.assignedTo = fbTask.assignedTo
                    existingTask.slaDate = fbTask.slaDate
                    existingTask.location = fbTask.location
                    existingTask.mediaURLs = fbTask.mediaURLs
                    existingTask.checklist = fbTask.checklist
                    print("Repository.syncTasks: UPDATE id=\(fbId) checklist=\(fbTask.checklist?.count ?? 0) media=\(fbTask.mediaURLs?.count ?? 0)")
                } else {
                    let newLocalTask = LocalAppTask(from: fbTask)
                    modelContext.insert(newLocalTask)
                    print("Repository.syncTasks: INSERT id=\(fbId) checklist=\(fbTask.checklist?.count ?? 0) media=\(fbTask.mediaURLs?.count ?? 0)")
                }
            } catch {
                print("HATA: SwiftData senkronizasyonunda hata oluştu: \(error.localizedDescription)")
            }
        }
    }

    @MainActor
    func saveNewTask(_ task: AppTask, to modelContext: ModelContext) async throws {
        let newFirebaseId = try await taskService.saveTask(task)
        var taskWithRealId = task
        taskWithRealId.id = newFirebaseId
        let newLocalTask = LocalAppTask(from: taskWithRealId)
        modelContext.insert(newLocalTask)
        print("Repository: NotificationService çağrılmak üzere. Task ID: \(newLocalTask.firebaseId), SLA: \(newLocalTask.slaDate)")
        notificationService.scheduleSLANotification(for: newLocalTask)
        print("Repository: Yeni görev hem Firebase'e hem de yerel SwiftData'ya kaydedildi. GERÇEK ID: \(newFirebaseId)")
    }
    
    @MainActor
    func updateTaskStatus(task: LocalAppTask, newStatus: AppTaskStatus) async throws {
        try await taskService.updateTaskStatus(taskId: task.firebaseId, newStatus: newStatus)
        task.status = newStatus
        if newStatus == .completed {
            notificationService.cancelNotification(for: task.firebaseId)
        } else {
            notificationService.scheduleSLANotification(for: task)
        }
        print("Repository: Görev durumu hem Firebase'de hem de yerelde güncellendi.")
    }
    
    @MainActor
    func saveSignature(data: Data, for task: LocalAppTask) async throws {
        let taskId = task.firebaseId
        do {
            let downloadURL = try await storageService.uploadSignature(data: data, for: taskId)
            task.signatureData = data
            try await taskService.updateTaskSignatureURL(taskId: taskId, url: downloadURL)
            print("Repository: İmza başarıyla yerel SwiftData'ya ve Firebase'e (Storage+Firestore) senkronize edildi.")
        } catch {
            print("HATA: İmza kaydedilemedi - \(error.localizedDescription)")
            throw error
        }
    }
    
    @MainActor
    func deleteSignature(for task: LocalAppTask) async throws {
        let taskId = task.firebaseId
        do {
            try await storageService.deleteSignature(for: taskId)
            try await taskService.clearTaskSignatureURL(taskId: taskId)
            task.signatureData = nil
            print("Repository: İmza hem Storage'tan hem Firestore'dan hem de yerelden temizlendi.")
        } catch {
            print("HATA: İmza temizlenemedi - \(error.localizedDescription)")
            throw error
        }
    }
    
    @MainActor
    func uploadMediaAndSync(mediaData: [Data], for task: LocalAppTask) async throws {
        let taskId = task.firebaseId
        var uploadedURLs: [String] = task.mediaURLs ?? []
        for data in mediaData {
            do {
                let downloadURL = try await storageService.uploadMedia(data: data, taskId: taskId)
                uploadedURLs.append(downloadURL)
            } catch {
                print("HATA: Bir medya dosyası yüklenemedi - \(error.localizedDescription)")
            }
        }
        task.mediaURLs = uploadedURLs
        do {
            try await taskService.updateTaskMediaURLs(taskId: taskId, urls: uploadedURLs)
            print("Repository: Medya URL'leri başarıyla yerel SwiftData'ya ve Firebase Firestore'a senkronize edildi.")
        } catch {
            print("HATA: Medya URL'leri Firestore'a güncellenemedi - \(error.localizedDescription)")
            throw error
        }
    }
    
    @MainActor
    func updateChecklistItemStatus(for task: LocalAppTask, itemId: String, isCompleted: Bool) async throws {
        let taskId = task.firebaseId
        guard var currentChecklist = task.checklist else {
            print("HATA: Görevde checklist bulunamadı.")
            return
        }
        guard let itemIndex = currentChecklist.firstIndex(where: { $0.id == itemId }) else {
            print("HATA: Checklist maddesi ID'si bulunamadı.")
            return
        }
        let oldValue = currentChecklist[itemIndex].isCompleted
        currentChecklist[itemIndex].isCompleted = isCompleted
        task.checklist = currentChecklist
        print("Repository.updateChecklistItemStatus: local update -> id=\(itemId) \(oldValue) -> \(isCompleted). New completedCount=\(currentChecklist.filter{$0.isCompleted}.count)/\(currentChecklist.count)")
        do {
            try await taskService.updateTaskChecklist(taskId: taskId, checklist: currentChecklist)
            print("Repository: Checklist maddesi durumu başarıyla yerel SwiftData'ya ve Firebase Firestore'a senkronize edildi.")
        } catch {
            print("HATA: Checklist Firestore'a güncellenemedi - \(error.localizedDescription)")
            throw error
        }
    }
    
    @MainActor
    func addChecklistItem(for task: LocalAppTask, text: String) async throws {
        let taskId = task.firebaseId
        var list = task.checklist ?? []
        let newItem = ChecklistItem(id: UUID().uuidString, text: text, isCompleted: false)
        list.append(newItem)
        task.checklist = list
        print("Repository.addChecklistItem: local append -> '\(text)'. New count=\(list.count)")
        do {
            try await taskService.updateTaskChecklist(taskId: taskId, checklist: list)
            print("Repository: Checklist'e madde eklendi ve Firestore ile senkronize edildi.")
        } catch {
            print("HATA: Madde eklenemedi (Firestore) - \(error.localizedDescription)")
            throw error
        }
    }
    
    @MainActor
    func removeChecklistItem(for task: LocalAppTask, itemId: String) async throws {
        let taskId = task.firebaseId
        guard var list = task.checklist else { return }
        let before = list.count
        list.removeAll { $0.id == itemId }
        task.checklist = list
        print("Repository.removeChecklistItem: local remove -> id=\(itemId). \(before) -> \(list.count)")
        do {
            try await taskService.updateTaskChecklist(taskId: taskId, checklist: list)
            print("Repository: Checklist maddesi silindi ve Firestore ile senkronize edildi.")
        } catch {
            print("HATA: Madde silinemedi (Firestore) - \(error.localizedDescription)")
            throw error
        }
    }
    
    @MainActor
    func deleteMediaURL(_ url: String, for task: LocalAppTask) async throws {
        do {
            try await storageService.deleteMedia(at: url)
        } catch {
            throw error
        }
        var list = task.mediaURLs ?? []
        let before = list.count
        list.removeAll { $0 == url }
        task.mediaURLs = list
        print("Repository.deleteMediaURL: local remove -> \(before) -> \(list.count)")
        do {
            try await taskService.updateTaskMediaURLs(taskId: task.firebaseId, urls: list)
            print("Repository: Medya URL'i Firestore'dan güncellendi (silindi).")
        } catch {
            print("HATA: Firestore mediaURLs güncellenemedi - \(error.localizedDescription)")
            throw error
        }
    }
    
    // EKLE: Görevi sil (Storage + Firestore + Yerel + Bildirim)
    @MainActor
    func deleteTask(_ task: LocalAppTask, in modelContext: ModelContext) async throws {
        let taskId = task.firebaseId
        
        // 1) Bildirimi iptal et
        notificationService.cancelNotification(for: taskId)
        
        // 2) Storage temizlikleri (best effort)
        do { try await storageService.deleteSignature(for: taskId) } catch {
            print("UYARI: İmza silme sırasında hata: \(error.localizedDescription)")
        }
        do { try await storageService.deleteAllMedia(for: taskId) } catch {
            print("UYARI: Medya silme sırasında hata: \(error.localizedDescription)")
        }
        
        // 3) Firestore belgesini sil
        try await taskService.deleteTask(taskId: taskId)
        
        // 4) Yerel SwiftData'dan sil
        modelContext.delete(task)
        
        print("Repository: Görev tüm katmanlardan silindi. id=\(taskId)")
    }
}
