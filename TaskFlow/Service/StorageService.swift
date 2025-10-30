//
//  StorageService.swift
//  TaskFlow
//
//  Created by Mehmet Ali Sevdinoğlu on 25.10.2025.
//
import Foundation
import FirebaseStorage
import UIKit

class StorageService {
    
    private let storage = Storage.storage().reference()
    
    func uploadSignature(data: Data, for taskId: String) async throws -> String {
        let storagePath = "signatures/\(taskId)/signature.png"
        let fileRef = storage.child(storagePath)
        let metadata = StorageMetadata()
        metadata.contentType = "image/png"
        do {
            print("StorageService: İmza yükleniyor...")
            _ = try await fileRef.putDataAsync(data, metadata: metadata)
            let downloadURL = try await fileRef.downloadURL()
            let urlString = downloadURL.absoluteString
            print("StorageService: İmza yüklendi, URL: \(urlString)")
            return urlString
        } catch {
            print("HATA: Firebase Storage'a yüklenemedi - \(error.localizedDescription)")
            throw error
        }
    }
    
    func uploadMedia(data: Data, taskId: String, mediaId: String = UUID().uuidString) async throws -> String {
        let fileExtension = ".jpg"
        let contentType = "image/jpeg"
        let storagePath = "media/\(taskId)/\(mediaId)\(fileExtension)"
        let fileRef = storage.child(storagePath)
        let metadata = StorageMetadata()
        metadata.contentType = contentType
        do {
            print("StorageService: Medya yükleniyor...")
            _ = try await fileRef.putDataAsync(data, metadata: metadata)
            let downloadURL = try await fileRef.downloadURL()
            let urlString = downloadURL.absoluteString
            print("StorageService: Medya yüklendi, URL: \(urlString)")
            return urlString
        } catch {
            print("HATA: Medya Firebase Storage'a yüklenemedi - \(error.localizedDescription)")
            throw error
        }
    }
    
    func deleteMedia(at downloadURL: String) async throws {
        let ref = Storage.storage().reference(forURL: downloadURL)
        do {
            try await ref.delete()
            print("StorageService: Medya Storage'tan silindi.")
        } catch {
            print("HATA: Medya Storage'tan silinemedi - \(error.localizedDescription)")
            throw error
        }
    }
    
    func deleteSignature(for taskId: String) async throws {
        let storagePath = "signatures/\(taskId)/signature.png"
        let fileRef = storage.child(storagePath)
        do {
            try await fileRef.delete()
            print("StorageService: İmza dosyası Storage'tan silindi.")
        } catch {
            // Dosya yoksa hata dönebilir; loglayıp devam etmek isteyebiliriz.
            print("UYARI: İmza dosyası bulunamadı veya silinemedi - \(error.localizedDescription)")
            throw error
        }
    }
    
    // EKLE: Bir görevin tüm medya klasörünü sil (varsa)
    func deleteAllMedia(for taskId: String) async throws {
        let folderRef = storage.child("media/\(taskId)")
        // Firebase Storage listAll iOS’ta mevcut
        do {
            let result = try await folderRef.listAll()
            for item in result.items {
                do { try await item.delete() } catch {
                    print("UYARI: Bir medya dosyası silinemedi - \(error.localizedDescription)")
                }
            }
            print("StorageService: Tüm medya dosyaları silindi (taskId=\(taskId)).")
        } catch {
            print("UYARI: Medya klasörü listelenemedi/silinemedi - \(error.localizedDescription)")
            // klasör yoksa da sorun değil; üst katmanda sessizce devam edebiliriz
        }
    }
}
