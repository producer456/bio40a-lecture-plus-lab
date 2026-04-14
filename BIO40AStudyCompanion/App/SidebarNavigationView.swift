import SwiftUI

enum SidebarDestination: String, CaseIterable, Identifiable {
    case home = "Home"
    case lessons = "Lessons"
    case interactiveLearning = "Interactive Learning"
    case howWeLearn = "How We Learn"
    case flashcards = "Flashcards"
    case quizzes = "Quizzes"
    case games = "Games"
    case schedule = "Schedule"
    case labPrep = "Lab Prep"
    case assignmentLog = "Assignment Log"
    case studyMaterials = "Study Materials"
    case comparisons = "Comparisons"
    case glossary = "Glossary"
    case weakSpots = "Weak Spots"
    case progress = "Progress"
    case search = "Search"
    case settings = "Settings"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .home: return "brain.head.profile"
        case .lessons: return "figure.stand"
        case .interactiveLearning: return "hand.tap.fill"
        case .howWeLearn: return "brain.head.profile.fill"
        case .flashcards: return "rectangle.on.rectangle.angled"
        case .quizzes: return "heart.fill"
        case .games: return "gamecontroller.fill"
        case .schedule: return "calendar"
        case .labPrep: return "flask.fill"
        case .assignmentLog: return "doc.text.magnifyingglass"
        case .studyMaterials: return "folder.fill"
        case .comparisons: return "circle.grid.cross.fill"
        case .glossary: return "character.book.closed.fill"
        case .weakSpots: return "exclamationmark.triangle.fill"
        case .progress: return "chart.bar.fill"
        case .search: return "magnifyingglass"
        case .settings: return "gearshape.fill"
        }
    }

    var tintColor: Color {
        switch self {
        case .home: return BodySystem.nervous.primaryColor
        case .lessons: return BodySystem.skeletal.primaryColor
        case .interactiveLearning: return BodySystem.muscular.primaryColor
        case .howWeLearn: return .purple
        case .flashcards: return BodySystem.endocrine.primaryColor
        case .quizzes: return BodySystem.cardiovascular.primaryColor
        case .games: return BodySystem.integumentary.primaryColor
        case .schedule: return BodySystem.endocrine.primaryColor
        case .labPrep: return .purple
        case .assignmentLog: return BodySystem.nervous.primaryColor
        case .studyMaterials: return BodySystem.skeletal.primaryColor
        case .comparisons: return BodySystem.organ.primaryColor
        case .glossary: return BodySystem.nervous.accentColor
        case .weakSpots: return BodySystem.muscular.primaryColor
        case .progress: return BodySystem.organ.primaryColor
        case .search: return BodySystem.nervous.primaryColor
        case .settings: return .gray
        }
    }
}

struct SidebarNavigationView: View {
    @State private var selection: SidebarDestination? = .home

    var body: some View {
        NavigationSplitView {
            List(SidebarDestination.allCases, selection: $selection) { dest in
                Label {
                    Text(dest.rawValue)
                } icon: {
                    Image(systemName: dest.icon)
                        .foregroundStyle(dest.tintColor)
                }
                .tag(dest)
                .tint(dest.tintColor)
            }
            .scrollContentBackground(.hidden)
            .background(.ultraThinMaterial)
            .tint(selection?.tintColor ?? .blue)
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
        case .interactiveLearning:
            NavigationStack { InteractiveLearningListView() }
        case .howWeLearn:
            NavigationStack { HowWeLearnView() }
        case .flashcards:
            NavigationStack { FlashcardDeckView() }
        case .quizzes:
            NavigationStack { QuizHubView() }
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
        case .comparisons:
            NavigationStack { ComparisonListView() }
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
