import Foundation
import FirebaseFirestore
// FirebaseStorage'a burada ihtiyacımız yok, o StorageService'te kaldı.

class TaskService {
    
    private let db = Firestore.firestore()
    private let tasksCollection = "tasks"
    
    func saveTask(_ task: AppTask) async throws -> String {
        var mutableTask = task
        let newDocumentRef = db.collection(tasksCollection).document()
        let newId = newDocumentRef.documentID
        mutableTask.id = newId
        do {
            try await newDocumentRef.setData(from: mutableTask)
            return newId
        } catch {
            print("HATA: Görev setData ile kaydedilemedi - \(error.localizedDescription)")
            throw error
        }
    }
    
    func fetchTasks(completion: @escaping ([AppTask]) -> Void) -> ListenerRegistration? {
        let listener = db.collection(tasksCollection)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    print("HATA: Görevler çekilemedi - \(error.localizedDescription)")
                    completion([])
                    return
                }
                guard let documents = querySnapshot?.documents else {
                    print("Belgeler bulunamadı.")
                    completion([])
                    return
                }
                let tasks = documents.compactMap { document -> AppTask? in
                    do {
                        return try document.data(as: AppTask.self)
                    } catch {
                        print("HATA: Belge dönüştürülemedi - \(error.localizedDescription)")
                        return nil
                    }
                }
                completion(tasks)
            }
        return listener
    }
    
    func updateTaskStatus(taskId: String, newStatus: AppTaskStatus) async throws {
        do {
            try await db.collection(tasksCollection).document(taskId).updateData([
                "status": newStatus.rawValue
            ])
            print("Görev durumu başarıyla güncellendi: \(newStatus.rawValue)")
        } catch {
            print("HATA: Görev durumu güncellenemedi - \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateTaskSignatureURL(taskId: String, url: String) async throws {
        do {
            try await db.collection(tasksCollection).document(taskId).updateData([
                "signatureStorageURL": url
            ])
            print("TaskService: İmza URL'i Firestore'a başarıyla güncellendi.")
        } catch {
            print("HATA: İmza URL'i güncellenemedi - \(error.localizedDescription)")
            throw error
        }
    }
    
    func clearTaskSignatureURL(taskId: String) async throws {
        do {
            try await db.collection(tasksCollection).document(taskId).updateData([
                "signatureStorageURL": FieldValue.delete()
            ])
            print("TaskService: signatureStorageURL alanı silindi.")
        } catch {
            print("HATA: signatureStorageURL silinemedi - \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateTaskMediaURLs(taskId: String, urls: [String]) async throws {
        do {
            try await db.collection(tasksCollection).document(taskId).updateData([
                "mediaURLs": urls
            ])
            print("TaskService: Medya URL listesi Firestore'a başarıyla güncellendi.")
        } catch {
            print("HATA: Medya URL listesi güncellenemedi - \(error.localizedDescription)")
            throw error
        }
    }
    
    func updateTaskChecklist(taskId: String, checklist: [ChecklistItem]) async throws {
        do {
            let checklistData = checklist.map { item -> [String: Any] in
                return ["id": item.id, "text": item.text, "isCompleted": item.isCompleted]
            }
            try await db.collection(tasksCollection).document(taskId).updateData([
                "checklist": checklistData
            ])
            print("TaskService: Checklist Firestore'a başarıyla güncellendi.")
        } catch {
            print("HATA: Checklist güncellenemedi - \(error.localizedDescription)")
            throw error
        }
    }
    
    // EKLE: Firestore'da görevi sil
    func deleteTask(taskId: String) async throws {
        do {
            try await db.collection(tasksCollection).document(taskId).delete()
            print("TaskService: Görev Firestore'dan silindi. id=\(taskId)")
        } catch {
            print("HATA: Görev Firestore'dan silinemedi - \(error.localizedDescription)")
            throw error
        }
    }

}
