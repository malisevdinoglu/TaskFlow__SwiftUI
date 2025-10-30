//
//  ReportView.swift
//  TaskFlow
//
//  Created by Mehmet Ali Sevdinoğlu on 25.10.2025.
//

import SwiftUI

// Bu View, PDF'imizin taslağıdır.
struct ReportView: View {
    // 'AppTask' -> 'LocalAppTask' olarak değişti
    let task: LocalAppTask
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            
            Text("Görev Raporu: \(task.title)")
                .font(.largeTitle.bold())
                .padding(.bottom, 10)
            
            // 'task.status.rawValue' -> 'task.statusRawValue'
            // veya 'task.status.rawValue' da çalışır (yardımcı değişken sayesinde)
            ReportRowView(label: "Durum", value: task.status.rawValue)
            ReportRowView(label: "Atanan Kişi", value: task.assignedTo)
            ReportRowView(label: "Oluşturulma Tarihi", value: task.createdAt.formatted(date: .long, time: .shortened))
            ReportRowView(label: "Hedeflenen Tarih (SLA)", value: task.slaDate.formatted(date: .long, time: .shortened))
            
            if let location = task.location {
                ReportRowView(label: "Konum", value: location)
            }
            
            Divider()
            
            Text("Görev Açıklaması")
                .font(.title2.bold())
                .padding(.top, 10)
            
            // 'task.description' -> 'task.taskDescription' olarak değişti
            Text(task.taskDescription)
                .font(.body)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer()
        }
        .padding()
        .frame(width: 600)
    }
}

// ... (ReportRowView struct'ı aynı kaldı) ...
struct ReportRowView: View {
    let label: String
    let value: String
    var body: some View {
        HStack {
            Text(label)
                .font(.headline)
                .foregroundColor(.gray)
            Spacer()
            Text(value)
                .font(.body.bold())
        }
        .padding(.bottom, 5)
    }
}

// ... (Preview kodu da 'LocalAppTask' kullanacak şekilde güncellendi) ...
struct ReportView_Previews: PreviewProvider {
    static var previews: some View {
        ReportView(
            task: LocalAppTask(
                firebaseId: "123",
                title: "Sunucu Bakımı",
                taskDescription: "Sunucuların yıllık bakımı yapılacak...",
                status: .completed,
                assignedTo: "Mali Sevdi",
                createdAt: Date(),
                slaDate: Date().addingTimeInterval(86400),
                location: "Merkez Ofis - Veri Merkezi"
            )
        )
    }
}
