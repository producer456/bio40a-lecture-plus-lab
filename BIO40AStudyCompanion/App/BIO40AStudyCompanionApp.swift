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
            PerformanceRecord.self,
            AssignmentReflection.self,
            StudyMaterial.self
        ])
    }
}

struct ContentRootView: View {
    @Environment(\.horizontalSizeClass) private var sizeClass
    @State private var contentService = ContentService()
    @AppStorage("userName") private var userName = ""
    @State private var showNamePrompt = false

    var body: some View {
        Group {
            if sizeClass == .regular {
                SidebarNavigationView()
            } else {
                TabNavigationView()
            }
        }
        .environment(contentService)
        .onAppear {
            if userName.isEmpty {
                showNamePrompt = true
            }
        }
        .sheet(isPresented: $showNamePrompt) {
            WelcomeNameView(userName: $userName, isPresented: $showNamePrompt)
                .interactiveDismissDisabled(userName.isEmpty)
        }
    }
}

// MARK: - Welcome Name Prompt

struct WelcomeNameView: View {
    @Binding var userName: String
    @Binding var isPresented: Bool
    @State private var nameInput = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Spacer()

                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(.blue)

                VStack(spacing: 8) {
                    Text("Welcome to BIO 40A Study")
                        .font(.title2)
                        .fontWeight(.bold)
                    Text("What should we call you?")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                TextField("Your first name", text: $nameInput)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .focused($isFocused)
                    .submitLabel(.done)
                    .onSubmit { saveName() }

                Button {
                    saveName()
                } label: {
                    Text("Let's Go!")
                        .fontWeight(.semibold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(nameInput.trimmingCharacters(in: .whitespaces).isEmpty ? Color.gray : Color.blue, in: RoundedRectangle(cornerRadius: 12))
                        .foregroundStyle(.white)
                }
                .disabled(nameInput.trimmingCharacters(in: .whitespaces).isEmpty)
                .padding(.horizontal, 40)

                Spacer()
                Spacer()
            }
            .onAppear { isFocused = true }
        }
    }

    private func saveName() {
        let trimmed = nameInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        userName = trimmed
        isPresented = false
    }
}
