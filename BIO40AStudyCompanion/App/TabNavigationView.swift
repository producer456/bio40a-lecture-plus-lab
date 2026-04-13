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
                LessonsListView()
            }
            .tabItem {
                Label("Learn", systemImage: BodySystem.skeletal.tabIcon)
            }
            .tag(1)

            NavigationStack {
                HowWeLearnView()
            }
            .tabItem {
                Label("How We Learn", systemImage: "brain.head.profile.fill")
            }
            .tag(2)

            NavigationStack {
                PracticeMenuView()
            }
            .tabItem {
                Label("Practice", systemImage: BodySystem.cardiovascular.tabIcon)
            }
            .tag(3)

            NavigationStack {
                MoreView()
            }
            .tabItem {
                Label("More", systemImage: BodySystem.organ.tabIcon)
            }
            .tag(4)
        }
        .tint(tabTint)
        .animation(.easeInOut(duration: 0.25), value: selectedTab)
    }

    private var tabTint: Color {
        switch selectedTab {
        case 0: return BodySystem.nervous.primaryColor
        case 1: return BodySystem.skeletal.primaryColor
        case 2: return .purple
        case 3: return BodySystem.cardiovascular.primaryColor
        case 4: return BodySystem.organ.primaryColor
        default: return .blue
        }
    }
}
