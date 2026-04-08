import SwiftUI

struct TabNavigationView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            NavigationStack {
                HomeView()
            }
            .tabItem {
                Label("Home", systemImage: "house.fill")
            }
            .tag(0)

            NavigationStack {
                LessonsListView()
            }
            .tabItem {
                Label("Learn", systemImage: "book.fill")
            }
            .tag(1)

            NavigationStack {
                PracticeMenuView()
            }
            .tabItem {
                Label("Practice", systemImage: "gamecontroller.fill")
            }
            .tag(2)

            NavigationStack {
                ScheduleView()
            }
            .tabItem {
                Label("Schedule", systemImage: "calendar")
            }
            .tag(3)

            NavigationStack {
                MoreView()
            }
            .tabItem {
                Label("More", systemImage: "ellipsis.circle")
            }
            .tag(4)
        }
        .tint(.blue)
    }
}
