import SwiftUI
import SwiftData
import Combine


struct TaskListView: View {
    
    @StateObject private var viewModel = TaskListViewModel()
    
    @Query(sort: \LocalAppTask.createdAt, order: .reverse) private var tasks: [LocalAppTask]
    

    @Environment(\.modelContext) private var modelContext

    @State private var selectedStatus: AppTaskStatus? = nil
    @State private var showFilterDialog: Bool = false
    
 
    @State private var now: Date = Date()
    

    private let dueSoonThreshold: TimeInterval = 24 * 60 * 60
    

    private var filteredTasks: [LocalAppTask] {
        guard let status = selectedStatus else { return tasks }
        return tasks.filter { $0.status == status }
    }
    
  
    private var selectedFilterText: String {
        selectedStatus?.rawValue ?? "Hepsi"
    }
    

    private var showNoTasksForSelectedState: Bool {
        if let _ = selectedStatus {
            return filteredTasks.isEmpty && !tasks.isEmpty
        }
        return false
    }
    
    var body: some View {
        ZStack {

            LinearGradient(
                colors: [Color.blue.opacity(0.25), Color.cyan.opacity(0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 0) {
          
                HeaderArea(
                    selectedFilterText: selectedFilterText,
                    onFilterTap: { showFilterDialog = true }
                )
                .padding(.top, 8)
                .padding(.horizontal, 20)
                
        
                Spacer(minLength: 8)
                    .frame(height: 8)
                
                Group {
                    if tasks.isEmpty {
                        EmptyStateView()
                            .padding(.horizontal, 20)
                    } else if showNoTasksForSelectedState {
                        NoTasksForFilterView(message: "Bu durumda görev bulunmuyor.")
                            .padding(.horizontal, 20)
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 14, pinnedViews: []) {
                                ForEach(filteredTasks) { task in
                                    NavigationLink(destination: TaskDetailView(task: task)) {
                                        TaskCardRow(
                                            task: task,
                                            now: now,
                                            dueSoonThreshold: dueSoonThreshold
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                            .padding(.top, 4)
                        }
                    }
                }
                .padding(.top, 8)
                
                Spacer(minLength: 0)
            }
        }
        .confirmationDialog("Duruma göre filtrele", isPresented: $showFilterDialog, titleVisibility: .visible) {
            Button("Hepsi") { selectedStatus = nil }
            Divider()
            ForEach(AppTaskStatus.allCases, id: \.self) { status in
                Button(status.rawValue) { selectedStatus = status }
            }
            Button("İptal", role: .cancel) { }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onAppear {
            viewModel.setup(modelContext: modelContext)
        }

        .onReceive(Timer.publish(every: 60, on: .main, in: .common).autoconnect()) { date in
            now = date
        }
    }
}

private struct HeaderArea: View {
    let selectedFilterText: String
    let onFilterTap: () -> Void
    
    var body: some View {
        VStack(spacing: 12) {

            HStack {
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.title2)
                    .opacity(0)
                    .frame(width: 24)
                
                Spacer()
                
                VStack(spacing: 4) {
                    Text("Görevlerim")
                        .font(.largeTitle.bold())
                        .foregroundColor(.white)
                    Text("Tüm görevlerin güncel listesi")
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.8))
                }
                
                Spacer()
                
                Image(systemName: "rectangle.portrait.and.arrow.right")
                    .font(.title2)
                    .opacity(0)
                    .frame(width: 24)
            }
            
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Button(action: onFilterTap) {
                        HStack(spacing: 8) {
                            Image(systemName: "line.3.horizontal.decrease.circle")
                            Text("Filtrele")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 14)
                        .background(
                            Capsule().fill(Color.white.opacity(0.12))
                        )
                        .overlay(
                            Capsule().stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                    
                    Spacer()
                }
                
                Text("Seçili: \(selectedFilterText)")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))
            }
        }
    }
}

private struct TaskCardRow: View {
    let task: LocalAppTask
    let now: Date
    let dueSoonThreshold: TimeInterval
    
    // Yalnızca tamamlanmayan görevlerde ve 24 saatten az kalmışsa uyarı üret
    var slaStatus: SLAStatus {
        // Tamamlanan görev: uyarı yok (nötr kabul edilir)
        guard task.status != .completed else { return .onTime }
        // Süre geçtiyse
        if task.slaDate <= now { return .overdue }
        // 24 saatten az kaldıysa
        if task.slaDate.timeIntervalSince(now) <= dueSoonThreshold { return .dueSoon }
        // 24+ saat varsa uyarı yok
        return .onTime
    }
    
    var slaColor: Color {
        switch slaStatus {
        case .onTime: return .clear // 24+ saat için renklendirme yok
        case .dueSoon: return .orange.opacity(0.9)
        case .overdue: return .red.opacity(0.9)
        }
    }
    
    var statusColor: Color {
        switch task.status {
        case .planned: return .blue
        case .toDo: return .orange
        case .inProgress: return .purple
        case .inReview: return .teal
        case .completed: return .green
        }
    }
    
    // Geri sayımı sadece dueSoon/overdue için göster
    var countdownText: String? {
        guard task.status != .completed else { return nil }
        guard slaStatus != .onTime else { return nil } // 24+ saat: metin yok
        let delta = task.slaDate.timeIntervalSince(now)
        if delta <= 0 {
            let abs = -delta
            let (h, m) = Self.hAndM(from: abs)
            return "Geçti \(h)s \(m)d"
        } else {
            let (h, m) = Self.hAndM(from: delta)
            return "\(h)s \(m)d"
        }
    }
    
    static func hAndM(from interval: TimeInterval) -> (Int, Int) {
        let minutes = Int(interval / 60)
        return (minutes / 60, minutes % 60)
    }
    
    var body: some View {
        ZStack(alignment: .leading) {
            // Sol SLA şeridi: sadece dueSoon/overdue (onTime’da yok)
            if slaStatus != .onTime {
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(slaColor)
                    .frame(width: 5)
                    .padding(.vertical, 6)
                    .padding(.leading, 6)
            }
            
            // Kart gövdesi
            HStack(alignment: .center, spacing: 12) {
                Circle()
                    .fill(statusColor)
                    .frame(width: 10, height: 10)
                
                VStack(alignment: .leading, spacing: 8) {
                    HStack(alignment: .firstTextBaseline) {
                        Text(task.title)
                            .font(.headline)
                            .foregroundColor(.white)
                            .lineLimit(1)
                        Spacer(minLength: 8)
                        StatusBadge(status: task.status)
                    }
                    
                    HStack(spacing: 8) {
                        if !task.assignedTo.isEmpty {
                            Label(task.assignedTo, systemImage: "person.fill")
                                .foregroundColor(.white.opacity(0.85))
                                .font(.caption)
                                .lineLimit(1)
                        }
                        Spacer()
                        HStack(spacing: 6) {
                            Image(systemName: "clock")
                            Text("SLA: \(task.slaDate.formatted(date: .numeric, time: .shortened))")
                            if let countdown = countdownText {
                                Text("•")
                                Text(countdown)
                                    .fontWeight(.semibold)
                                    .foregroundColor(slaStatus == .overdue ? .red : .white.opacity(0.9))
                            }
                        }
                        .foregroundColor(.white.opacity(0.9))
                        .font(.caption)
                        .lineLimit(1)
                    }
                }
                .padding(.vertical, 16)
                .padding(.trailing, 8)
            }
            .padding(.leading, slaStatus != .onTime ? 6 : 0) // sol şerit varsa mesafe bırak
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .frame(minHeight: 84)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(Color.black.opacity(0.55))
                    .shadow(color: Color.black.opacity(0.25), radius: 10, x: 0, y: 6)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
        }
    }
}

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

private struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "tray")
                .font(.system(size: 44))
                .foregroundColor(.white.opacity(0.8))
            Text("Henüz bir görev oluşturulmamış.")
                .foregroundColor(.white.opacity(0.9))
                .font(.headline)
            Text("Yeni görevler eklendiğinde burada görünecek.")
                .foregroundColor(.white.opacity(0.7))
                .font(.subheadline)
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


private struct NoTasksForFilterView: View {
    let message: String
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: "info.circle")
            Text(message)
        }
        .font(.subheadline.weight(.semibold))
        .foregroundColor(.white)
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.black.opacity(0.45))
        .overlay(
            RoundedRectangle(cornerRadius: 12).stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .cornerRadius(12)
    }
}


enum SLAStatus {
    case onTime
    case dueSoon
    case overdue
}

struct TaskListView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TaskListView()
        }
        .preferredColorScheme(.dark)
    }
}
