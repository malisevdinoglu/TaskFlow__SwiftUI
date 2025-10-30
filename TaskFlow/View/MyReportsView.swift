//
//  MyReportsView.swift
//  TaskFlow
//
//  Created by Mehmet Ali Sevdinoğlu on 28.10.2025.
//

import SwiftUI
import QuickLook
import Combine
import SwiftData

struct ReportItem: Identifiable, Hashable {
    let id = UUID()
    let url: URL
    let fileName: String
    let fileSize: Int64
    let createdAt: Date?
    let taskId: String? // PDF adından çıkarılan Firebase task ID
     
    init(url: URL) {
        self.url = url
        self.fileName = url.lastPathComponent
        // resourceValues -> fileSize (Int?) -> Int64
        let values = try? url.resourceValues(forKeys: [.fileSizeKey, .creationDateKey])
        self.fileSize = Int64(values?.fileSize ?? 0)
        self.createdAt = values?.creationDate
        self.taskId = ReportItem.parseTaskId(from: url.lastPathComponent)
    }
    
    // "TaskFlowRapor-<id>.pdf" biçiminden <id>’yi ayıklar
    private static func parseTaskId(from fileName: String) -> String? {
        // Örn: "TaskFlowRapor-abc123.pdf"
        guard fileName.hasPrefix("TaskFlowRapor-"), fileName.lowercased().hasSuffix(".pdf") else { return nil }
        let base = fileName.replacingOccurrences(of: ".pdf", with: "")
        let comps = base.split(separator: "-", maxSplits: 1, omittingEmptySubsequences: true)
        // comps[0] = "TaskFlowRapor", comps[1] = "<id>"
        guard comps.count == 2 else { return nil }
        return String(comps[1])
    }
    
    var humanReadableSize: String {
        ByteCountFormatter.string(fromByteCount: fileSize, countStyle: .file)
    }
}

@MainActor
final class MyReportsViewModel: ObservableObject {
    @Published var reports: [ReportItem] = []
    @Published var selected: ReportItem?
    @Published var isShowingQuickLook: Bool = false
    
    private let fileManager = FileManager.default
    
    func loadReports() {
        let docs = URL.documentsDirectory
        guard let items = try? fileManager.contentsOfDirectory(at: docs, includingPropertiesForKeys: [.creationDateKey, .fileSizeKey], options: [.skipsHiddenFiles]) else {
            reports = []
            return
        }
        // Sadece “TaskFlowRapor-*.pdf”
        let filtered = items.filter { $0.lastPathComponent.hasPrefix("TaskFlowRapor-") && $0.pathExtension.lowercased() == "pdf" }
        let mapped = filtered.map { ReportItem(url: $0) }
        // Yeni olan en üstte
        reports = mapped.sorted { (a, b) in
            let ad = a.createdAt ?? .distantPast
            let bd = b.createdAt ?? .distantPast
            return ad > bd
        }
    }
    
    func delete(at offsets: IndexSet) {
        for index in offsets {
            let item = reports[index]
            do {
                try fileManager.removeItem(at: item.url)
            } catch {
                print("Rapor silinemedi: \(error.localizedDescription)")
            }
        }
        loadReports()
    }
    
    func openSelected() {
        guard selected != nil else { return }
        isShowingQuickLook = true
    }
}

struct MyReportsView: View {
    @StateObject private var viewModel = MyReportsViewModel()
    // SwiftData’dan tüm görevleri çek (id -> başlık eşlemesi için)
    @Query(sort: \LocalAppTask.createdAt, order: .reverse) private var allTasks: [LocalAppTask]
    
    // taskId -> title sözlüğü
    private var titleByTaskId: [String: String] {
        Dictionary(uniqueKeysWithValues: allTasks.map { ($0.firebaseId, $0.title) })
    }
    
    var body: some View {
        ZStack {
            // Main/TaskList ile aynı gradyan arka plan
            LinearGradient(
                colors: [Color.blue.opacity(0.25), Color.cyan.opacity(0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 16) {
                // Üst başlık (TaskList ile uyumlu)
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.title2)
                        .opacity(0)
                        .frame(width: 24)
                    
                    Spacer()
                    
                    VStack(spacing: 4) {
                        Text("Raporlarım")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        Text("Oluşturulan PDF raporlarınız")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.8))
                    }
                    
                    Spacer()
                    
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.title2)
                        .opacity(0)
                        .frame(width: 24)
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                
                if viewModel.reports.isEmpty {
                    EmptyStateView()
                        .padding(.horizontal, 20)
                        .padding(.top, 6)
                } else {
                    // Kart kapsayıcı içinde liste
                    CardContainer {
                        VStack(alignment: .leading, spacing: 12) {
                            Label("Rapor Listesi", systemImage: "doc.plaintext.fill")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            
                            List(selection: Binding(get: {
                                viewModel.selected.map { Set([ $0.id ]) } ?? Set<UUID>()
                            }, set: { newSelection in
                                if let id = newSelection.first,
                                   let item = viewModel.reports.first(where: { $0.id == id }) {
                                    viewModel.selected = item
                                } else {
                                    viewModel.selected = nil
                                }
                            })) {
                                ForEach(viewModel.reports) { item in
                                    ReportRow(
                                        item: item,
                                        isSelected: item.id == viewModel.selected?.id,
                                        title: taskTitle(for: item) ?? item.fileName
                                    )
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        viewModel.selected = item
                                    }
                                    .listRowBackground(Color.clear)
                                }
                                .onDelete(perform: viewModel.delete)
                            }
                            .listStyle(.plain)
                            .scrollContentBackground(.hidden)
                            .frame(maxHeight: 420) // makul bir yükseklik, ekran taşmasın
                        }
                        .padding(12)
                    }
                    .padding(.horizontal, 20)
                    
                    // Alt eylem butonları (TaskList stilinde)
                    HStack(spacing: 12) {
                        Button {
                            viewModel.openSelected()
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "doc.viewfinder")
                                Text("PDF Aç")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 14)
                            .frame(maxWidth: .infinity)
                            .background(
                                Capsule().fill(Color.blue)
                            )
                            .shadow(color: Color.blue.opacity(0.35), radius: 10, x: 0, y: 6)
                        }
                        .disabled(viewModel.selected == nil)
                        .opacity(viewModel.selected == nil ? 0.6 : 1.0)
                        
                        if let url = viewModel.selected?.url {
                            ShareLink(item: url) {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Paylaş")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background(
                                    Capsule().fill(Color.blue)
                                )
                                .shadow(color: Color.blue.opacity(0.35), radius: 10, x: 0, y: 6)
                            }
                            .disabled(viewModel.selected == nil)
                            .opacity(viewModel.selected == nil ? 0.6 : 1.0)
                        } else {
                            Button {} label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Paylaş")
                                }
                                .font(.headline)
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.vertical, 14)
                                .frame(maxWidth: .infinity)
                                .background(
                                    Capsule().fill(Color.blue.opacity(0.5))
                                )
                            }
                            .disabled(true)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                }
            }
        }
        .onAppear {
            viewModel.loadReports()
        }
        .sheet(isPresented: $viewModel.isShowingQuickLook) {
            if let url = viewModel.selected?.url {
                QuickLookPreview(url: url)
            }
        }
        .navigationTitle("") // başlık içeride gösteriliyor
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
    }
    
    private func taskTitle(for item: ReportItem) -> String? {
        guard let id = item.taskId else { return nil }
        return titleByTaskId[id]
    }
}

// MARK: - Satır Bileşeni

private struct ReportRow: View {
    let item: ReportItem
    let isSelected: Bool
    let title: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "doc.richtext.fill")
                .foregroundColor(.white)
                .padding(10)
                .background((isSelected ? Color.blue.opacity(0.35) : Color.white.opacity(0.12)))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            
            VStack(alignment: .leading, spacing: 6) {
                Text(title)
                    .foregroundColor(.white)
                    .font(.headline)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if let date = item.createdAt {
                        Text(date.formatted(date: .abbreviated, time: .shortened))
                    }
                    Text("•")
                    Text(item.humanReadableSize)
                }
                .foregroundColor(.white.opacity(0.75))
                .font(.caption)
                
                if title != item.fileName {
                    Text(item.fileName)
                        .foregroundColor(.white.opacity(0.55))
                        .font(.caption2)
                        .lineLimit(1)
                }
                
                // Yer tutucu statüler (ileride gerçek metriklere bağlanabilir)
                Text("Süre: —  •  Puan: —  •  SLA: —")
                    .foregroundColor(.white.opacity(0.55))
                    .font(.caption2)
            }
            Spacer(minLength: 0)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 8)
        .background(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(isSelected ? Color.blue.opacity(0.18) : Color.black.opacity(0.35))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .stroke(isSelected ? Color.blue.opacity(0.9) : Color.white.opacity(0.08), lineWidth: isSelected ? 2 : 1)
        )
    }
}

// MARK: - Boş Durum Kartı (TaskList uyumlu)

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "doc")
                .font(.system(size: 44))
                .foregroundColor(.white.opacity(0.85))
            Text("Henüz rapor bulunmuyor.")
                .foregroundColor(.white.opacity(0.95))
                .font(.headline)
            Text("Tamamlanan görevlerden PDF rapor oluşturduğunuzda burada listelenecek.")
                .foregroundColor(.white.opacity(0.75))
                .font(.subheadline)
                .multilineTextAlignment(.center)
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(Color.black.opacity(0.5))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Kart Kapsayıcı (Main/TaskList ile uyumlu)

private struct CardContainer<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.black.opacity(0.55))
                .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - QuickLook

private struct QuickLookPreview: UIViewControllerRepresentable {
    let url: URL
    
    func makeCoordinator() -> Coordinator {
        Coordinator(url: url)
    }
    
    func makeUIViewController(context: Context) -> QLPreviewController {
        let controller = QLPreviewController()
        controller.dataSource = context.coordinator
        return controller
    }
    
    func updateUIViewController(_ uiViewController: QLPreviewController, context: Context) {}
    
    final class Coordinator: NSObject, QLPreviewControllerDataSource {
        private let url: URL
        init(url: URL) {
            self.url = url
        }
        func numberOfPreviewItems(in controller: QLPreviewController) -> Int { 1 }
        func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
            url as NSURL
        }
    }
}

#Preview {
    NavigationStack {
        MyReportsView()
    }
    .preferredColorScheme(.dark)
}
