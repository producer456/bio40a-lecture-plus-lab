import SwiftUI

struct TabNavigationView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: BodySystem.nervous.tabIcon)
            }
            .tag(0)

            NavigationStack {
                LabPrepListView()
            }
            .tabItem {
                Label("Lab Prep", systemImage: "flask.fill")
            }
            .tag(1)

            NavigationStack {
                InteractiveLearningListView()
            }
            .tabItem {
                Label("Interactive", systemImage: BodySystem.muscular.tabIcon)
            }
            .tag(2)

            NavigationStack {
                LessonsListView()
            }
            .tabItem {
                Label("Lessons", systemImage: BodySystem.skeletal.tabIcon)
            }
            .tag(3)

            NavigationStack {
                PracticeMenuView()
            }
            .tabItem {
                Label("Practice", systemImage: BodySystem.cardiovascular.tabIcon)
            }
            .tag(4)

            NavigationStack {
                MoreView()
            }
            .tabItem {
                Label("More", systemImage: BodySystem.organ.tabIcon)
            }
            .tag(5)
        }
        .tint(tabTint)
        .animation(.easeInOut(duration: 0.25), value: selectedTab)
    }

    private var tabTint: Color {
        switch selectedTab {
        case 0: return BodySystem.nervous.primaryColor
        case 1: return .purple
        case 2: return BodySystem.muscular.primaryColor
        case 3: return BodySystem.skeletal.primaryColor
        case 4: return BodySystem.cardiovascular.primaryColor
        case 5: return BodySystem.organ.primaryColor
        default: return .blue
        }
    }
}
