//
//  TaskListViewModel.swift
//  TaskFlow
//
//  Created by Mehmet Ali Sevdinoğlu on 24.10.2025.
//

import Foundation
import Combine
import SwiftData // SwiftData'yı kullanmak için eklendi

@MainActor // SwiftData işlemleri ana thread'de olmalı
class TaskListViewModel: ObservableObject {
    
    // Artık @Published var tasks dizisine ihtiyacımız yok.
    // Görevleri doğrudan SwiftData'dan alacağız.
    
    // Repository'mize (Depo) bir referans
    private let repository = TaskRepository()
    
    // SwiftData veritabanını yönetmek için context
    private var modelContext: ModelContext?
    
    init() {
        // Bu ViewModel'in artık bir 'modelContext'e ihtiyacı var,
        // bu yüzden 'init'i boş bırakıyoruz.
        // 'setup' fonksiyonu View'dan çağrılacak.
    }
    
    // Bu fonksiyon, 'TaskListView'dan 'modelContext' alındığında çağrılır.
    func setup(modelContext: ModelContext) {
        // 1. Context'i sakla
        self.modelContext = modelContext
        
        // 2. Repository'ye, Firebase'i dinlemesini ve
        // gelen verileri bu 'modelContext'e senkronize etmesini söyle.
        repository.startListeningToFirebase(modelContext: modelContext)
    }
    
    // ViewModel yok edildiğinde (örn: kullanıcı çıkış yaptığında)
    // Firebase dinleyicisini durdur
    deinit {
        repository.stopListeningToFirebase()
    }
    
    // Not: 'fetchTasks' fonksiyonu artık gerekli değil,
    // çünkü 'TaskListView' görevleri @Query ile doğrudan SwiftData'dan alacak.
}
