import SwiftUI

enum SidebarDestination: String, CaseIterable, Identifiable {
    case home = "Home"
    case lessons = "Lessons"
    case flashcards = "Flashcards"
    case quizzes = "Quizzes"
    case games = "Games"
    case schedule = "Schedule"
    case labPrep = "Lab Prep"
    case assignmentLog = "Assignment Log"
    case studyMaterials = "Study Materials"
    case glossary = "Glossary"
    case weakSpots = "Weak Spots"
    case progress = "Progress"
    case search = "Search"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "house.fill"
        case .lessons: return "book.fill"
        case .flashcards: return "rectangle.on.rectangle.angled"
        case .quizzes: return "checkmark.circle.fill"
        case .games: return "gamecontroller.fill"
        case .schedule: return "calendar"
        case .labPrep: return "flask.fill"
        case .assignmentLog: return "doc.text.magnifyingglass"
        case .studyMaterials: return "folder.fill"
        case .glossary: return "character.book.closed.fill"
        case .weakSpots: return "exclamationmark.triangle.fill"
        case .progress: return "chart.bar.fill"
        case .search: return "magnifyingglass"
        case .settings: return "gearshape.fill"
        }
    }
}

struct SidebarNavigationView: View {
    @State private var selection: SidebarDestination? = .home

    var body: some View {
        NavigationSplitView {
            List(SidebarDestination.allCases, selection: $selection) { dest in
                Label(dest.rawValue, systemImage: dest.icon)
                    .tag(dest)
            }
            .navigationTitle("BIO 40A")
        } detail: {
            if let selection {
                detailView(for: selection)
            } else {
                HomeView()
            }
        }
    }

    @ViewBuilder
    private func detailView(for destination: SidebarDestination) -> some View {
        switch destination {
        case .home:
            NavigationStack { HomeView() }
        case .lessons:
            NavigationStack { LessonsListView() }
        case .flashcards:
            NavigationStack { FlashcardDeckView() }
        case .quizzes:
            NavigationStack { QuizSetupView() }
        case .games:
            NavigationStack { GamesMenuView() }
        case .schedule:
            NavigationStack { ScheduleView() }
        case .labPrep:
            NavigationStack { LabPrepListView() }
        case .assignmentLog:
            NavigationStack { AssignmentLogListView() }
        case .studyMaterials:
            NavigationStack { StudyMaterialLibraryView() }
        case .glossary:
            NavigationStack { GlossaryView() }
        case .weakSpots:
            NavigationStack { WeakSpotsView() }
        case .progress:
            NavigationStack { ProgressDashboardView() }
        case .search:
            NavigationStack { SearchContentView() }
        case .settings:
            NavigationStack { SettingsView() }
        }
    }
}
