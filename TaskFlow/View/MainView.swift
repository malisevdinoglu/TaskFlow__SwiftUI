import SwiftUI
import SwiftData

struct MainView: View {
    @EnvironmentObject var authViewModel: AuthViewModel
    
    @State private var navigateToTask: LocalAppTask? = nil
    @State private var isNavigationActive = false
    
    @Query(sort: \LocalAppTask.createdAt, order: .reverse) private var allTasks: [LocalAppTask]
    
    var body: some View {
        TabView {
            // 1) ANA SAYFA (Dashboard)
            NavigationStack {
                ZStack {
                    LinearGradient(
                        colors: [Color.blue.opacity(0.25), Color.cyan.opacity(0.15)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                    .ignoresSafeArea()
                    
                    ScrollView {
                        VStack(spacing: 22) {
                            TopBar(
                                title: "TaskFlow",
                                subtitle: "",
                                onSignOut: { authViewModel.signOut() }
                            )
                            
                            SummaryCardSection(tasks: allTasks) // Dikey listeleyecek şekilde güncellendi
                            
                            // Kısayollar kartı artık gereksiz; Tab Bar’a taşındı.
                            // İsterseniz aşağıdaki satırı kaldırabilirsiniz:
                            // ShortcutsCardSection()
                            
                            Spacer(minLength: 12)
                        }
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 80)
                    }
                    
                    if let user = authViewModel.currentUser, user.role == "admin" {
                        VStack {
                            Spacer()
                            NavigationLink(destination: NewTaskView()) {
                                HStack(spacing: 8) {
                                    Image(systemName: "plus.circle.fill")
                                    Text("Yeni Görev")
                                }
                                .font(.headline)
                                .foregroundColor(.white)
                                .padding(.vertical, 14)
                                .padding(.horizontal, 20)
                                .background(
                                    Capsule().fill(Color.blue)
                                )
                                .shadow(color: Color.blue.opacity(0.35), radius: 12, x: 0, y: 8)
                            }
                            .padding(.bottom, 20)
                        }
                        .padding(.horizontal, 20)
                    }
                }
                .navigationDestination(isPresented: $isNavigationActive) {
                    if let task = navigateToTask {
                        TaskDetailView(task: task)
                    }
                }
            }
            .tabItem {
                Image(systemName: "house.fill")
                Text("Ana Sayfa")
            }
            
            // 2) GÖREVLERİM
            NavigationStack {
                TaskListView()
            }
            .tabItem {
                Image(systemName: "checklist")
                Text("Görevlerim")
            }
            
            // 3) RAPORLARIM
            NavigationStack {
                MyReportsView()
            }
            .tabItem {
                Image(systemName: "doc.text")
                Text("Raporlarım")
            }
            
            // 4) AYARLAR
            NavigationStack {
                SettingsView()
                    .environmentObject(authViewModel)
            }
            .tabItem {
                Image(systemName: "gear")
                Text("Ayarlar")
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .taskNotificationTapped)) { notification in
            print("MainView: taskNotificationTapped bildirimi alındı.")
            if let userInfo = notification.userInfo,
               let taskId = userInfo["taskId"] as? String {
                print("MainView: Bildirimden gelen taskId: \(taskId)")
                if let taskToNavigate = allTasks.first(where: { $0.firebaseId == taskId }) {
                    print("MainView: SwiftData'da görev bulundu: \(taskToNavigate.title)")
                    navigateToTask = taskToNavigate
                    isNavigationActive = true
                } else {
                    print("HATA: MainView - SwiftData'da görev ID'si bulunamadı: \(taskId)")
                }
            }
        }
    }
}

private struct TopBar: View {
    let title: String
    let subtitle: String
    let onSignOut: () -> Void
    
    @State private var showSignOutAlert = false
    
    var body: some View {
        HStack(alignment: .center) {
            Image(systemName: "rectangle.portrait.and.arrow.right")
                .opacity(0)
                .frame(width: 24)
            
            Spacer()
            
            VStack(spacing: 4) {
                Text(title)
                    .font(.largeTitle.bold())
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
            
            Spacer()
            
            Button {
                showSignOutAlert = true
            } label: {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.title2)
                    .foregroundColor(.red)
            }
            .buttonStyle(.plain)
            .alert("Çıkış yapmak istediğinize emin misiniz?", isPresented: $showSignOutAlert) {
                Button("İptal", role: .cancel) {}
                Button("Evet", role: .destructive) {
                    onSignOut()
                }
            }
        }
    }
}

private struct SummaryCardSection: View {
    let tasks: [LocalAppTask]
    
    private var pendingCount: Int {
        tasks.filter { $0.status == .planned }.count
    }
    private var activeCount: Int {
        tasks.filter { $0.status == .toDo || $0.status == .inProgress || $0.status == .inReview }.count
    }
    private var completedCount: Int {
        tasks.filter { $0.status == .completed }.count
    }
    
    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 14) {
                HStack {
                    Label("Bugün Özeti", systemImage: "chart.bar.fill")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    Spacer()
                }
                
                VStack(spacing: 10) {
                    SmallSummaryCard(title: "Bekleyen", count: pendingCount, color: .blue)
                    SmallSummaryCard(title: "Aktif", count: activeCount, color: .orange)
                    SmallSummaryCard(title: "Tamamlanan", count: completedCount, color: .green)
                }
            }
        }
    }
}

private struct SmallSummaryCard: View {
    let title: String
    let count: Int
    let color: Color
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(1)
                .minimumScaleFactor(0.75)
            Text("\(count)")
                .font(.title2.bold())
                .foregroundColor(.white)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .frame(height: 72)
        .background(color.opacity(0.85))
        .cornerRadius(12)
    }
}

private struct ShortcutsCardSection: View {
    var body: some View {
        CardContainer {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Label("Kısayollar", systemImage: "bolt.fill")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    Spacer()
                }
                
                VStack(spacing: 10) {
                    NavigationLink(destination: TaskListView()) {
                        ShortcutRow(title: "Görevlerim", icon: "checklist")
                    }
                    NavigationLink(destination: MyReportsView()) {
                        ShortcutRow(title: "Raporlarım", icon: "doc.text")
                    }
                    NavigationLink(destination: SettingsView()) {
                        ShortcutRow(title: "Ayarlar", icon: "gear")
                    }
                }
            }
        }
    }
}

private struct ShortcutRow: View {
    let title: String
    let icon: String
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.12))
                Image(systemName: icon)
                    .foregroundColor(.white)
                    .font(.headline)
            }
            .frame(width: 36, height: 36)
            
            Text(title)
                .font(.headline)
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .background(Color.white.opacity(0.06))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}

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

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
            .environmentObject(AuthViewModel())
            .preferredColorScheme(.dark)
    }
}
