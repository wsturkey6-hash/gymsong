import SwiftUI
import SwiftData

struct RootView: View {
    @Query private var profiles: [UserProfile]

    var body: some View {
        if let profile = profiles.first {
            MainTabView(profile: profile)
        } else {
            OnboardingView()
        }
    }
}

struct MainTabView: View {
    let profile: UserProfile

    var body: some View {
        TabView {
            TodayWorkoutView()
                .tabItem { Label("今日", systemImage: "figure.strengthtraining.traditional") }

            ProgramSetupView()
                .tabItem { Label("課表", systemImage: "calendar") }

            HistoryView()
                .tabItem { Label("紀錄", systemImage: "clock.arrow.circlepath") }

            SettingsView()
                .tabItem { Label("設定", systemImage: "gearshape") }
        }
    }
}
