import SwiftUI
import SwiftData

@main
struct BIO40AStudyCompanionApp: App {
    var body: some Scene {
        WindowGroup {
            ContentRootView()
        }
        .modelContainer(for: [
            StudyProgress.self,
            FlashcardProgress.self,
            QuizAttempt.self,
            UserBookmark.self,
            PerformanceRecord.self
        ])
    }
}

struct ContentRootView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var contentService = ContentService()

    var body: some View {
        Group {
            if sizeClass == .regular {
                SidebarNavigationView()
            } else {
                TabNavigationView()
            }
        }
        .environment(contentService)
    }
}
