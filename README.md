# TaskFlow - iOS Task Management System

<div align="center">

A modern, production-ready iOS task management application built with SwiftUI, featuring real-time synchronization, SLA tracking, digital signatures, and automated PDF reporting.

[Features](#features) • [Architecture](#architecture) • [Installation](#installation) • [Screenshots](#screenshots) • [Tech Stack](#tech-stack)

</div>

---

## 📋 Overview

TaskFlow is a comprehensive task management solution designed for teams and organizations that need to track work assignments, monitor SLA compliance, collect digital signatures, and generate professional reports. The app combines local-first architecture with cloud synchronization to ensure data availability even in offline scenarios.

## ✨ Features

### 🔐 Authentication & Authorization
- Firebase Authentication with email/password
- Role-based access control (Admin/User)
- Secure user session management
- Admin-only task creation capabilities

### 📊 Task Management
- **Complete Task Lifecycle**: Plan → To-Do → In Progress → Review → Completed
- **Status Filtering**: Quick access to tasks by current status
- **Business Rules Enforcement**: 
  - Media required for review status
  - Digital signature mandatory for completion
  - Checklist validation before task closure
- **Real-time Synchronization**: Bidirectional sync between local SwiftData and Firebase Firestore

### ⏰ SLA Tracking & Notifications
- **Visual SLA Indicators**:
  - ✅ On-time (24+ hours remaining): No visual indicator
  - 🟠 Due soon (< 24 hours): Orange stripe + countdown timer
  - 🔴 Overdue: Red stripe + red countdown timer
  - ✔️ Completed: No SLA display
- **Smart Notifications**: Local push notifications 1 hour before SLA deadline
- **Live Updates**: Real-time countdown using Combine framework (updates every 60 seconds)
- **Deep Linking**: Tap notification to navigate directly to task details

### 📸 Media Management
- PhotosPicker integration for image attachments
- Firebase Storage upload/download
- Multiple media attachments per task
- Image deletion with automatic cloud cleanup

### ✍️ Digital Signatures
- Custom drawing canvas for signature capture
- Signature storage in Firebase Storage
- Signature validation for task completion
- View and delete existing signatures

### 📄 PDF Report Generation
- Automated report creation for completed tasks
- Professional report template (ReportView)
- Reports stored locally in Documents folder
- Quick Look preview integration
- Share and export functionality
- Report management interface

### 📝 Checklist System
- Dynamic checklist items per task
- Real-time progress tracking
- Add, check, and remove items
- Completion validation before finishing tasks

### 🎨 Modern UI/UX
- **Dark Theme** with glassmorphic card design
- **Tab-based Navigation**: Dashboard, Tasks, Reports, Settings
- **Consistent Typography** following Apple Human Interface Guidelines
- **Accessibility**: Built with accessibility in mind
- **Responsive Design**: Optimized for all iPhone screen sizes

---

## 🏗️ Architecture

TaskFlow follows a clean, layered architecture that separates concerns and promotes maintainability:

```
┌─────────────────────────────────────────────────────┐
│                     Views (SwiftUI)                  │
│   MainView, TaskListView, TaskDetailView, etc.     │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│                    ViewModels                        │
│  TaskListVM, TaskDetailVM, NewTaskVM, LoginVM       │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│                   Repository                         │
│         TaskRepository (Orchestration Layer)         │
└─────────────────────┬───────────────────────────────┘
                      │
┌─────────────────────▼───────────────────────────────┐
│                    Services                          │
│  TaskService │ StorageService │ NotificationService  │
│  (Firestore) │   (Storage)    │   (Local Alerts)    │
└──────────────────────────────────────────────────────┘
```

### Data Models

#### LocalAppTask (SwiftData)
```swift
@Model
class LocalAppTask {
    var firebaseId: String
    var title: String
    var taskDescription: String
    var statusRawValue: String
    var assignedTo: String
    var createdAt: Date
    var slaDate: Date?
    var location: String?
    var priority: String?
    var category: String?
    var signatureData: Data?
    var mediaURLs: [String]
    var checklist: Data? // JSON encoded ChecklistItem[]
}
```

#### AppTask (Firestore - Codable)
```swift
struct AppTask: Codable, Identifiable {
    let id: String
    var title: String
    var description: String
    var status: AppTaskStatus
    var assignedTo: String
    var createdAt: Date
    var slaDate: Date?
    var location: String?
    var priority: String?
    var category: String?
    var signatureStorageURL: String?
    var mediaURLs: [String]
    var checklist: [ChecklistItem]?
}
```

#### Task Status Flow
```swift
enum AppTaskStatus: String, CaseIterable, Codable {
    case planned = "Planlandı"
    case todo = "Yapılacak"
    case inProgress = "Çalışmada"
    case inReview = "Kontrol"
    case completed = "Tamamlandı"
}
```

### Key Components

#### 1. **Repository Layer** (`TaskRepository`)
- Coordinates between local SwiftData and Firebase Firestore
- Manages bidirectional synchronization
- Handles conflict resolution
- Provides unified data access interface

#### 2. **Service Layer**
- **TaskService**: Firestore CRUD operations
- **StorageService**: Firebase Storage for media/signatures
- **LocalNotificationService**: UNUserNotificationCenter management
- **PDFService**: Report generation logic

#### 3. **View Layer**
- **MainView**: Dashboard with daily summary and TabView navigation
- **TaskListView**: Filtered task list with live SLA indicators
- **TaskDetailView**: Complete task management interface
- **MyReportsView**: PDF report browser with Quick Look
- **SettingsView**: User profile and app settings
- **LoginView**: Firebase Authentication interface

#### 4. **ViewModel Layer**
- Manages UI state and business logic
- Coordinates between View and Repository
- Handles user interactions and validations
- Implements Combine publishers for reactive updates

---

## 🚀 Installation

### Prerequisites

- **Xcode 15+**
- **iOS 17.0+** (Required for SwiftData)
- **Swift 5.9+**
- **Active Firebase project**

### Setup Steps

1. **Clone the repository**
```bash
git clone https://github.com/malisevdinoglu/TaskFlow__SwiftUI.git
cd TaskFlow__SwiftUI
```

2. **Firebase Configuration**
   - Create a new iOS app in [Firebase Console](https://console.firebase.google.com)
   - Download `GoogleService-Info.plist`
   - Add the file to your Xcode project (ensure it's included in the target)

3. **Enable Firebase Services**
   - **Authentication**: Enable Email/Password provider
   - **Firestore Database**: Create database in your preferred region
   - **Storage**: Enable Firebase Storage for media/signatures

4. **Configure Firestore Security Rules** (Development)
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /tasks/{taskId} {
      allow read, write: if request.auth != null;
    }
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
  }
}
```

5. **Configure Storage Security Rules** (Development)
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /signatures/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
    match /media/{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

6. **Create User Roles in Firestore**
   - In Firestore Console, create a `users` collection
   - Add documents with structure:
   ```json
   {
     "email": "admin@example.com",
     "role": "admin",
     "name": "Admin User"
   }
   ```
   - Use the Authentication UID as the document ID

7. **Open in Xcode**
```bash
open TaskFlow.xcodeproj
```

8. **Configure Signing**
   - Select your development team in `Signing & Capabilities`
   - Update Bundle Identifier if needed

9. **Build and Run**
   - Select iOS 17+ Simulator or physical device
   - Press `Cmd + R` to build and run

---

## 📱 Usage

### First Launch

1. **Login/Register** with email and password
2. System fetches user role from Firestore
3. Dashboard displays daily task summary

### Creating Tasks (Admin Only)

1. Tap **"New Task"** button on Dashboard
2. Fill in task details:
   - Title, Description
   - Assigned User
   - SLA Date/Time
   - Location, Priority, Category
   - Optional checklist items
3. Task syncs to Firestore and appears in all users' lists

### Managing Tasks

1. **View Tasks**: Navigate to "My Tasks" tab
2. **Filter by Status**: Tap filter icon to show specific statuses
3. **Task Details**: Tap any task to view/edit details
4. **Status Progression**:
   - Add media before moving to Review
   - Complete checklist items
   - Add signature before marking as Completed
5. **SLA Monitoring**: Live countdown updates every minute

### Generating Reports

1. Complete a task (mark as "Completed")
2. Tap **"Generate PDF Report"** button
3. Report automatically created and saved
4. Navigate to **"My Reports"** tab to view all reports
5. Tap report to preview with Quick Look
6. Use share button to export or send

### Notifications

- App requests notification permission on first launch
- Notifications scheduled 1 hour before SLA deadline
- Tap notification to jump directly to task details
- Notifications auto-cancel when task is completed

---

## 🛠️ Tech Stack

| Category | Technology |
|----------|-----------|
| **UI Framework** | SwiftUI |
| **Architecture** | MVVM + Repository Pattern |
| **Local Persistence** | SwiftData (@Model) |
| **Backend** | Firebase (Firestore, Authentication, Storage) |
| **Reactive Programming** | Combine Framework |
| **Notifications** | UserNotifications (UNUserNotificationCenter) |
| **PDF Generation** | UIGraphicsPDFRenderer |
| **Image Picking** | PhotosUI (PhotosPicker) |
| **Dependency Management** | Swift Package Manager |

### Firebase Dependencies
```swift
dependencies: [
    .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "10.0.0")
]
```

---

## 📂 Project Structure

```
TaskFlow/
├── TaskFlowApp.swift              # App entry point, SwiftData container, delegates
│
├── Models/
│   ├── LocalAppTask.swift         # SwiftData @Model for local persistence
│   ├── AppTask.swift              # Firestore Codable model
│   ├── ChecklistItem.swift        # Checklist item structure
│   └── User.swift                 # User model with role
│
├── ViewModels/
│   ├── TaskListViewModel.swift    # Task list state & Firebase listener
│   ├── TaskDetailViewModel.swift  # Task detail logic, status transitions
│   ├── NewTaskViewModel.swift     # New task creation & validation
│   └── LoginViewModel.swift       # Authentication logic
│
├── Views/
│   ├── MainView.swift            # Dashboard + TabView container
│   ├── TaskListView.swift        # Task list with filters & SLA indicators
│   ├── TaskDetailView.swift     # Task management interface
│   ├── MyReportsView.swift      # PDF report browser
│   ├── SettingsView.swift       # User settings & logout
│   ├── NewTaskView.swift        # Task creation form
│   └── ReportView.swift         # PDF template layout
│
├── Services/
│   ├── TaskService.swift            # Firestore CRUD operations
│   ├── StorageService.swift         # Firebase Storage management
│   ├── LocalNotificationService.swift # Notification scheduling
│   └── PDFService.swift             # PDF generation utilities
│
├── Repository/
│   └── TaskRepository.swift         # Orchestrates services & SwiftData
│
├── Resources/
│   ├── GoogleService-Info.plist     # Firebase configuration
│   └── Assets.xcassets              # App icons & colors
│
└── README.md                        # This file
```

---

## 🔧 Configuration

### SLA Thresholds

```swift
// In TaskListView.swift
private let dueSoonThreshold: TimeInterval = 86400 // 24 hours

// SLA States:
// - onTime: 24+ hours remaining (no indicator)
// - dueSoon: 0-24 hours (orange stripe + countdown)
// - overdue: negative time (red stripe + red countdown)
// - completed: no SLA display
```

### Notification Timing

```swift
// In LocalNotificationService.swift
private let notificationLeadTime: TimeInterval = 3600 // 1 hour before SLA
private let testFallbackDelay: TimeInterval = 5      // For testing if SLA already passed
```

### PDF Settings

```swift
// Report naming convention
let filename = "TaskFlowRapor-\(taskId).pdf"

// Saved to: Documents directory
// Accessible via: Files app → On My iPhone → TaskFlow
```

---

## 🎯 Business Rules

### Status Transition Rules

| From Status | To Status | Requirements |
|------------|-----------|--------------|
| Any | **In Review** | ≥ 1 media attachment required |
| In Review | **Completed** | Digital signature required |
| In Review | **Completed** | All checklist items must be completed (if checklist exists) |

### Role Permissions

| Action | Admin | User |
|--------|-------|------|
| View Tasks | ✅ | ✅ |
| Edit Task Details | ✅ | ✅ |
| Create New Tasks | ✅ | ❌ |
| Delete Tasks | ✅ | ❌ |
| Generate Reports | ✅ | ✅ |
| Manage Checklist | ✅ | ✅ |
| Add Media/Signature | ✅ | ✅ |

---

## 🐛 Troubleshooting

### Common Issues

**Problem**: "GoogleService-Info.plist not found"
- **Solution**: Ensure the file is added to your Xcode project and included in the app target

**Problem**: Tasks not syncing from Firestore
- **Solution**: Check Firebase Console rules, verify internet connection, confirm user is authenticated

**Problem**: Notifications not appearing
- **Solution**: 
  - Go to iOS Settings → TaskFlow → Notifications
  - Ensure notifications are allowed
  - Re-request permission if denied

**Problem**: PDF reports not generating
- **Solution**: Verify task has completed status, check Documents directory write permissions

**Problem**: SwiftData migration errors
- **Solution**: Delete app and reinstall (development only), or implement proper migration strategy

**Problem**: Images not uploading to Firebase Storage
- **Solution**: Check Storage rules, verify network connectivity, ensure file size is within limits

---

## 🗺️ Roadmap

### Planned Features

- [ ] **Multi-language Support** (i18n)
- [ ] **iPad Support** with optimized layouts
- [ ] **Offline Mode** improvements with conflict resolution
- [ ] **Task Templates** for recurring work
- [ ] **Advanced Filtering** (by date range, priority, assignee)
- [ ] **Analytics Dashboard** with charts and insights
- [ ] **Team Chat** integration per task
- [ ] **File Attachments** (PDF, DOC, XLS support)
- [ ] **Recurring Tasks** with automated scheduling
- [ ] **Widget Support** for home screen
- [ ] **Apple Watch Companion App**
- [ ] **Export to CSV/Excel** functionality
- [ ] **Dark/Light Theme Toggle**
- [ ] **Biometric Authentication** (Face ID / Touch ID)

### Improvements

- [ ] Unit Tests coverage
- [ ] UI Tests automation
- [ ] Performance optimization for large task lists
- [ ] Enhanced error handling and user feedback
- [ ] Accessibility improvements (VoiceOver support)
- [ ] Custom notification sounds
- [ ] Batch operations (multi-select tasks)
- [ ] Advanced search with filters

---

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

```
MIT License

Copyright (c) 2024 Erdem Maliş

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request. For major changes, please open an issue first to discuss what you would like to change.

### Contribution Guidelines

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Code Style

- Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/)
- Use SwiftLint for code consistency
- Write clear commit messages
- Add comments for complex logic
- Update documentation for new features

---

## 📧 Contact

**Developer**: 

- GitHub: [@malisevdinoglu](https://github.com/malisevdinoglu)
- LinkedIn: [M.Ali Sevdinoglu](https://linkedin.com/in/mehmet-ali-sevdinoglu)
- Email: [Contact](malisevdinoglu1828@gmail.com)

---

## 🙏 Acknowledgments

- Built with ❤️ using SwiftUI and Firebase
- Inspired by modern task management principles
- Thanks to the Swift and iOS development community
- Firebase for providing robust backend infrastructure
- Apple for excellent development tools and frameworks

---

<div align="center">

**⭐ If you find this project useful, please consider giving it a star!**

Made with 💻 and ☕ by (https://github.com/malisevdinoglu)

</div>
