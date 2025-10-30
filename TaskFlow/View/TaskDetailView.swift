import SwiftUI
import Combine
import PhotosUI

struct TaskDetailView: View {
    
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    
    @StateObject private var viewModel: TaskDetailViewModel
    
    @State private var isShowingSignatureSheet = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var selectedPhotoData: [Data] = []
    @State private var newChecklistText: String = ""
    @State private var mediaToDelete: String?
    @State private var showDeleteAlert: Bool = false
    @State private var showDeleteTaskAlert: Bool = false
    
    // Kontrol aşamasına geçişte medya zorunluluğu uyarısı
    @State private var showMediaRequiredAlert: Bool = false
    // Tamamlandı'ya geçişte imza zorunluluğu uyarısı
    @State private var showSignatureRequiredAlert: Bool = false
    
    init(task: LocalAppTask) {
        _viewModel = StateObject(wrappedValue: TaskDetailViewModel(task: task))
    }
    
    var body: some View {
        ZStack {
            // Proje genelindeki koyu gradyan arka plana uyum
            LinearGradient(
                colors: [Color.blue.opacity(0.25), Color.cyan.opacity(0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    
                    header
                    
                    if !viewModel.errorMessage.isEmpty {
                        HStack(spacing: 10) {
                            Image(systemName: "exclamationmark.triangle.fill")
                                .foregroundColor(.yellow)
                            Text(viewModel.errorMessage)
                                .foregroundColor(.white)
                                .font(.subheadline)
                                .multilineTextAlignment(.leading)
                        }
                        .padding(12)
                        .background(Color.red.opacity(0.25))
                        .cornerRadius(12)
                    }
                    
                    statusButtons
                    
                    if viewModel.task.status == .completed {
                        pdfSection
                    }
                    
                    inProgressMediaSection
                    
                    plannedSection
                    controlSection
                    completedSection
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
                .padding(.bottom, 24)
            }
        }
        .onAppear {
            viewModel.attach(modelContext: modelContext)
        }
        .navigationTitle("Görev Detayı")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(role: .destructive) {
                    showDeleteTaskAlert = true
                } label: {
                    Image(systemName: "trash")
                }
                .tint(.red)
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $isShowingSignatureSheet) {
            SignatureDrawingView(onSave: { data in
                viewModel.saveSignature(data: data)
            })
            .presentationDetents([.medium, .large])
            .colorScheme(.light)
        }
        .alert("Medyayı silmek istiyor musunuz?", isPresented: $showDeleteAlert, presenting: mediaToDelete) { _ in
            Button("İptal", role: .cancel) { mediaToDelete = nil }
            Button("Sil", role: .destructive) {
                if let url = mediaToDelete {
                    viewModel.deleteMedia(url: url)
                }
                mediaToDelete = nil
            }
        } message: { _ in
            Text("Bu işlem görseli buluttan da silecektir.")
        }
        .alert("Görevi silmek istiyor musunuz?", isPresented: $showDeleteTaskAlert) {
            Button("İptal", role: .cancel) {}
            Button("Sil", role: .destructive) {
                viewModel.deleteTask {
                    dismiss()
                }
            }
        } message: {
            Text("Bu işlem görevi yerel veritabanından ve Firebase'den, ayrıca göreve ait medya ve imza dosyalarını da siler.")
        }
        .alert("Kontrol aşamasına geçmek için en az bir medya yüklemelisiniz.", isPresented: $showMediaRequiredAlert) {
            Button("Tamam", role: .cancel) {}
        }
        .alert("Görevi tamamlamak için müşteri imzası gereklidir.", isPresented: $showSignatureRequiredAlert) {
            Button("Tamam", role: .cancel) {}
        }
    }
    
    // MARK: - Alt View’lar (Görsel düzenlemeler)
    
    private var header: some View {
        CardContainer {
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 6) {
                    Text(viewModel.task.title)
                        .font(.title.bold())
                        .foregroundColor(.white)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    
                    HStack(spacing: 8) {
                        StatusBadge(status: viewModel.task.status)
                        Text("Durum: \(viewModel.task.status.rawValue)")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(statusColor(status: viewModel.task.status))
                    }
                }
                Spacer()
            }
            .padding(.vertical, 4)
        }
    }
    
    private var statusButtons: some View {
        // Daha sade, kapsül stilde “segmented” hissi
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(AppTaskStatus.allCases, id: \.self) { status in
                    Button {
                        if status == .completed,
                           (viewModel.task.signatureData == nil || (viewModel.task.signatureData?.isEmpty ?? true)) {
                            showSignatureRequiredAlert = true
                            return
                        }
                        viewModel.updateTaskStatus(to: status)
                    } label: {
                        Text(status.rawValue)
                            .font(.caption.bold())
                            .foregroundColor(.white)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 14)
                            .background(
                                Capsule().fill(statusColor(status: status).opacity(status == viewModel.task.status ? 0.95 : 0.35))
                            )
                            .overlay(
                                Capsule().stroke(Color.white.opacity(0.12), lineWidth: 1)
                            )
                    }
                    .buttonStyle(.plain)
                    .opacity(status == viewModel.task.status ? 1.0 : 0.85)
                }
            }
            .padding(.horizontal, 4)
        }
        .padding(.vertical, 2)
    }
    
    private var pdfSection: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                Label("Rapor", systemImage: "doc.richtext.fill")
                    .font(.title3.bold())
                    .foregroundColor(.white)
                
                if let pdfURL = viewModel.pdfURL {
                    ShareLink(
                        item: pdfURL,
                        subject: Text("Görev Raporu: \(viewModel.task.title)"),
                        message: Text("TaskFlow uygulamasından oluşturulan görev raporu ektedir.")
                    ) {
                        Label("PDF Raporunu Paylaş", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(height: 52)
                            .frame(maxWidth: .infinity)
                            .background(
                                Capsule().fill(Color.green)
                            )
                            .shadow(color: Color.green.opacity(0.35), radius: 10, x: 0, y: 6)
                    }
                } else {
                    Text("PDF raporu hazırlanıyor...")
                        .foregroundColor(.white.opacity(0.75))
                        .font(.subheadline)
                }
            }
            .padding(4)
        }
    }
    
    private var inProgressMediaSection: some View {
        TaskStageSectionView(
            title: "Çalışmada",
            description: "Fotoğraf, video, notlar ve imzalar.",
            isCompleted: viewModel.task.status == .inReview || viewModel.task.status == .completed,
            content: {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Eklenen Medya")
                        .font(.caption.bold())
                        .foregroundColor(.white.opacity(0.9))
                    
                    mediaStrip
                    
                    PhotosPicker(
                        selection: $selectedPhotos,
                        matching: .images,
                        photoLibrary: .shared()
                    ) {
                        Label("Medya Ekle", systemImage: "plus.circle.fill")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.vertical, 12)
                            .frame(maxWidth: .infinity)
                            .background(
                                Capsule().fill(Color.purple)
                            )
                            .shadow(color: Color.purple.opacity(0.35), radius: 10, x: 0, y: 6)
                    }
                    .onChange(of: selectedPhotos) { newItems in
                        Task {
                            selectedPhotoData.removeAll()
                            for item in newItems {
                                if let data = try? await item.loadTransferable(type: Data.self) {
                                    selectedPhotoData.append(data)
                                }
                            }
                            if !selectedPhotoData.isEmpty {
                                viewModel.uploadMedia(photoData: selectedPhotoData)
                                selectedPhotos.removeAll()
                            }
                        }
                    }
                }
                .padding(.top, 2)
            }
        )
    }
    
    private var mediaStrip: some View {
        Group {
            if let mediaURLs = viewModel.task.mediaURLs, !mediaURLs.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        ForEach(mediaURLs, id: \.self) { urlString in
                            ZStack(alignment: .topTrailing) {
                                AsyncImage(url: URL(string: urlString)) { image in
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: 84, height: 84)
                                        .background(Color.white.opacity(0.05))
                                        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                                } placeholder: {
                                    RoundedRectangle(cornerRadius: 10, style: .continuous)
                                        .fill(Color.white.opacity(0.08))
                                        .frame(width: 84, height: 84)
                                }
                                Button {
                                    mediaToDelete = urlString
                                    showDeleteAlert = true
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundColor(.red)
                                        .padding(2)
                                        .background(.white.opacity(0.95))
                                        .clipShape(Circle())
                                }
                                .offset(x: 6, y: -6)
                            }
                        }
                    }
                }
            } else {
                Text("Henüz medya eklenmemiş.")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
    }
    
    private var controlSection: some View {
        let mediaIsEmpty = (viewModel.task.mediaURLs?.isEmpty ?? true)
        let isInProgress = (viewModel.task.status == .inProgress)
        
        return ControlSectionView(
            isInProgress: isInProgress,
            mediaIsEmpty: mediaIsEmpty,
            showMediaRequiredAlert: $showMediaRequiredAlert,
            newChecklistText: $newChecklistText,
            viewModel: viewModel,
            isShowingSignatureSheet: $isShowingSignatureSheet
        )
    }
    
    private var plannedSection: some View {
        TaskStageSectionView(
            title: "Yapılacak",
            description: "Atanmış görev başlıyor. \nAçıklama: \(viewModel.task.taskDescription)",
            isCompleted: viewModel.task.status != .planned
        )
    }
    
    private var completedSection: some View {
        TaskStageSectionView(
            title: "Tamamlandı",
            description: "Görev tamamlandı ve rapor oluşturulmaya hazır.",
            isCompleted: viewModel.task.status == .completed
        )
    }
    
    private func statusColor(status: AppTaskStatus) -> Color {
        switch status {
        case .planned: return .blue
        case .toDo: return .orange
        case .inProgress: return .purple
        case .inReview: return .teal
        case .completed: return .green
        }
    }
}

// MARK: - Kontrol Bölümü (görsel düzenlemeler)

private struct ControlSectionView: View {
    let isInProgress: Bool
    let mediaIsEmpty: Bool
    @Binding var showMediaRequiredAlert: Bool
    @Binding var newChecklistText: String
    @ObservedObject var viewModel: TaskDetailViewModel
    @Binding var isShowingSignatureSheet: Bool
    
    var body: some View {
        ZStack {
            TaskStageSectionView(
                title: "Kontrol",
                description: "Checklist ve müşteri onayı.",
                isCompleted: viewModel.task.status == .completed,
                content: {
                    VStack(alignment: .leading, spacing: 14) {
                        Divider().background(Color.white.opacity(0.1))
                        
                        Text("Checklist")
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(0.9))
                        
                        HStack(spacing: 10) {
                            TextField("Yeni madde ekle...", text: $newChecklistText)
                                .textFieldStyle(.roundedBorder)
                                .disabled(isInProgress && mediaIsEmpty)
                            Button {
                                let text = newChecklistText.trimmingCharacters(in: .whitespacesAndNewlines)
                                guard !text.isEmpty else { return }
                                viewModel.addChecklistItem(text: text)
                                newChecklistText = ""
                            } label: {
                                Image(systemName: "plus.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(.green)
                            }
                            .buttonStyle(.plain)
                            .disabled(isInProgress && mediaIsEmpty)
                        }
                        
                        if let checklist = viewModel.task.checklist, !checklist.isEmpty {
                            VStack(spacing: 8) {
                                ForEach(checklist) { item in
                                    HStack(spacing: 8) {
                                        ChecklistItemToggle(item: item, viewModel: viewModel)
                                            .allowsHitTesting(!(isInProgress && mediaIsEmpty))
                                            .opacity(isInProgress && mediaIsEmpty ? 0.5 : 1)
                                        Button {
                                            viewModel.removeChecklistItem(itemId: item.id)
                                        } label: {
                                            Image(systemName: "trash")
                                                .foregroundColor(.red)
                                        }
                                        .buttonStyle(.plain)
                                        .disabled(isInProgress && mediaIsEmpty)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        } else {
                            Text("Bu görev için checklist maddesi bulunmuyor.")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.7))
                        }
                        
                        Divider().background(Color.white.opacity(0.1))
                        
                        Text("Müşteri İmzası")
                            .font(.caption.bold())
                            .foregroundColor(.white.opacity(0.9))
                        
                        if let signatureData = viewModel.task.signatureData,
                           let uiImage = UIImage(data: signatureData) {
                            VStack(alignment: .leading, spacing: 8) {
                                Image(uiImage: uiImage)
                                    .resizable()
                                    .scaledToFit()
                                    .frame(height: 110)
                                    .background(Color.white)
                                    .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                                
                                Button(action: { viewModel.deleteSignature() }) {
                                    Text("İmzayı Temizle")
                                        .font(.caption)
                                        .foregroundColor(.red)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(
                                            Capsule().fill(Color.white.opacity(0.08))
                                        )
                                }
                                .disabled(isInProgress && mediaIsEmpty)
                            }
                        } else {
                            Button(action: { isShowingSignatureSheet = true }) {
                                Label("İmza Ekle", systemImage: "pencil.and.scribble")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .padding(.vertical, 12)
                                    .frame(maxWidth: .infinity)
                                    .background(
                                        Capsule().fill(Color.orange)
                                    )
                                    .shadow(color: Color.orange.opacity(0.35), radius: 10, x: 0, y: 6)
                            }
                            .disabled(isInProgress && mediaIsEmpty)
                        }
                    }
                }
            )
            .opacity(isInProgress && mediaIsEmpty ? 0.65 : 1.0)
            
            if isInProgress && mediaIsEmpty {
                Color.black.opacity(0.001)
                    .onTapGesture {
                        showMediaRequiredAlert = true
                    }
            }
        }
    }
}

// MARK: - Checklist toggle (stil uyumu)

struct ChecklistItemToggle: View {
    let item: ChecklistItem
    @ObservedObject var viewModel: TaskDetailViewModel

    var body: some View {
        Toggle(isOn: binding(for: item.id)) {
            Text(item.text)
                .foregroundColor(.white)
                .strikethrough(item.isCompleted, color: .gray)
        }
        .tint(.blue)
    }

    private func binding(for itemId: String) -> Binding<Bool> {
        Binding<Bool>(
            get: {
                viewModel.task.checklist?.first { $0.id == itemId }?.isCompleted ?? false
            },
            set: { newValue in
                viewModel.updateChecklistItem(itemId: itemId, isCompleted: newValue)
            }
        )
    }
}

// MARK: - Bölüm kabı (modern cam görünüm)

struct TaskStageSectionView<Content: View>: View {
    let title: String
    let description: String
    let isCompleted: Bool
    @ViewBuilder let content: () -> Content
    
    init(title: String, description: String, isCompleted: Bool) where Content == EmptyView {
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.content = { EmptyView() }
    }
    
    init(title: String, description: String, isCompleted: Bool, @ViewBuilder content: @escaping () -> Content) {
        self.title = title
        self.description = description
        self.isCompleted = isCompleted
        self.content = content
    }
    
    var body: some View {
        CardContainer {
            HStack(alignment: .top, spacing: 12) {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(isCompleted ? .green : .gray)
                    .font(.title2)
                    .padding(.top, 2)
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    Text(description)
                        .foregroundColor(.white.opacity(0.75))
                        .font(.subheadline)
                    content()
                }
            }
        }
        .strikethrough(isCompleted, color: .green.opacity(0.7))
        .opacity(isCompleted ? 0.8 : 1.0)
    }
}

// MARK: - Ortak kart kapsayıcı (Main/TaskList ile aynı dil)

private struct CardContainer<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            content
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(Color.black.opacity(0.55))
                .shadow(color: Color.black.opacity(0.25), radius: 18, x: 0, y: 10)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Durum Rozeti (header içinde kullanılan)

private struct StatusBadge: View {
    let status: AppTaskStatus
    var color: Color {
        switch status {
        case .planned: return .blue
        case .toDo: return .orange
        case .inProgress: return .purple
        case .inReview: return .teal
        case .completed: return .green
        }
    }
    
    var body: some View {
        Text(status.rawValue)
            .font(.caption.bold())
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(color.opacity(0.9))
            .foregroundColor(.white)
            .cornerRadius(8)
            .lineLimit(1)
    }
}

