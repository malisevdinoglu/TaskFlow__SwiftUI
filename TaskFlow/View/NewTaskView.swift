import SwiftUI
import SwiftData // SwiftData'yı kullanmak için eklendi

struct NewTaskView: View {
    
    @StateObject private var viewModel = NewTaskViewModel()
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    // Koyu tema için ortak metin alanı stili (TaskDetailView ile tutarlı kontrast)
    struct DarkTextFieldStyle: TextFieldStyle {
        func _body(configuration: TextField<Self._Label>) -> some View {
            configuration
                .padding(.horizontal, 14)
                .padding(.vertical, 12)
                .background(Color.white.opacity(0.08))
                .cornerRadius(12)
                .foregroundColor(.white)
                .tint(.white)
        }
    }

    init() {
        UITextView.appearance().backgroundColor = .clear
    }

    var body: some View {
        ZStack {
            // MainView ile birebir aynı gradyan arka plan
            LinearGradient(
                colors: [Color.blue.opacity(0.25), Color.cyan.opacity(0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    
                    // Başlık ve kısa bilgi
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Yeni Görev Oluştur")
                            .font(.largeTitle.bold())
                            .foregroundColor(.white)
                        Text("Zorunlu alanlar * ile işaretlenmiştir.")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.6))
                    }
                    .padding(.top, 4)
                    
                    // Kart form (TaskDetailView'deki kart diline uyum)
                    VStack(alignment: .leading, spacing: 16) {
                        
                        Group {
                            Text("Görev Adı *")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white.opacity(0.9))
                            TextField("Örn: Sunucu Bakımı", text: $viewModel.title)
                                .textFieldStyle(DarkTextFieldStyle())
                                .accessibilityLabel("Görev Adı")
                        }
                        
                        Group {
                            Text("Atanan Kişi/Ekip *")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white.opacity(0.9))
                            TextField("Örn: A Ekibi Teknisyeni", text: $viewModel.assignedTo)
                                .textFieldStyle(DarkTextFieldStyle())
                                .accessibilityLabel("Atanan Kişi veya Ekip")
                        }
                        
                        Group {
                            Text("Açıklama *")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white.opacity(0.9))
                            TextEditor(text: $viewModel.description)
                                .frame(minHeight: 140)
                                .padding(10)
                                .background(Color.white.opacity(0.08))
                                .cornerRadius(12)
                                .foregroundColor(.white)
                                .tint(.white)
                                .accessibilityLabel("Görev Açıklaması")
                        }
                        
                        Group {
                            Text("Hedef Süre (SLA) *")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white.opacity(0.9))
                            
                            VStack(alignment: .leading, spacing: 8) {
                                DatePicker(
                                    "",
                                    selection: $viewModel.slaDate,
                                    in: Date()...,
                                    displayedComponents: [.date, .hourAndMinute]
                                )
                                .datePickerStyle(.graphical)
                                .colorScheme(.dark)
                                .accessibilityLabel("Hedef Süre")
                            }
                            .padding(10)
                            .background(Color.white.opacity(0.08))
                            .cornerRadius(12)
                        }
                        
                        Group {
                            Text("Konum (Pin/Arama)")
                                .font(.subheadline.weight(.semibold))
                                .foregroundColor(.white.opacity(0.9))
                            TextField("Örn: 123. Sokak No: 4", text: $viewModel.location)
                                .textFieldStyle(DarkTextFieldStyle())
                                .accessibilityLabel("Konum")
                        }
                    }
                    .padding(16)
                    .background(Color.white.opacity(0.06))
                    .cornerRadius(16)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.08))
                    )
                    
                    // Hata mesajı (TaskDetailView'deki uyarı diline yakın)
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
                        .accessibilityHint("Zorunlu alanları doldurun")
                    }
                    
                    // Kaydet butonu (başarıda otomatik geri dön)
                    Button(action: {
                        Task {
                            // ViewModel mevcut yapıda async içeride Task ile çalışıyor.
                            // Hata mesajı boş kaldıysa başarı sayacağız.
                            let previousError = viewModel.errorMessage
                            viewModel.saveTask(modelContext: modelContext)
                            
                            // Kısa bir an bekleyip (async çağrı tamamlanması için) hata oluşup oluşmadığını kontrol edelim.
                            try? await Task.sleep(nanoseconds: 300_000_000) // 0.3s
                            
                            if previousError.isEmpty && viewModel.errorMessage.isEmpty {
                                // Başarılı -> ekranı kapat
                                dismiss()
                            }
                        }
                    }) {
                        Text("Kaydet")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 56)
                            .background(Color.blue)
                            .cornerRadius(14)
                    }
                    .padding(.top, 6)
                    .accessibilityLabel("Görevi Kaydet")
                }
                .padding(.horizontal)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("Görev Oluştur")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .preferredColorScheme(.dark) // MainView ile aynı koyu görünümü zorla
    }
}

// Preview
struct NewTaskView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NewTaskView()
        }
        .preferredColorScheme(.dark) // Önizlemede de koyu görünüm
    }
}
