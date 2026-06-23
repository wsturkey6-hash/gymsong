import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]

    @State private var apiKeyInput: String = ""
    @State private var hasStoredKey: Bool = false
    @State private var showSavedToast = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Claude API Key") {
                    SecureField(hasStoredKey ? "已儲存（再輸入會覆蓋）" : "sk-ant-...", text: $apiKeyInput)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    HStack {
                        Button("儲存") {
                            let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            KeychainStore.save(trimmed, for: .anthropicAPIKey)
                            apiKeyInput = ""
                            hasStoredKey = true
                            showSavedToast = true
                        }
                        .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        Spacer()

                        if hasStoredKey {
                            Button("清除", role: .destructive) {
                                KeychainStore.delete(.anthropicAPIKey)
                                hasStoredKey = false
                            }
                        }
                    }

                    Text("API Key 存在裝置 Keychain，不會傳出去。前往 console.anthropic.com 取得。")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let profile = profiles.first {
                    Section("訓練偏好") {
                        Stepper(
                            value: Binding(
                                get: { profile.defaultRestSeconds },
                                set: { profile.defaultRestSeconds = $0 }
                            ),
                            in: 30...600,
                            step: 15
                        ) {
                            Text("預設組間休息：\(formatRest(profile.defaultRestSeconds))")
                        }
                    }

                    Section("個人資料") {
                        Picker("訓練目標", selection: Binding(
                            get: { profile.goal },
                            set: { profile.goal = $0 }
                        )) {
                            ForEach(TrainingGoal.allCases) { Text($0.label).tag($0) }
                        }

                        Stepper(value: Binding(
                            get: { profile.daysPerWeek },
                            set: { profile.daysPerWeek = $0 }
                        ), in: 2...6) {
                            Text("每週訓練：\(profile.daysPerWeek) 天")
                        }

                        Picker("經驗水平", selection: Binding(
                            get: { profile.experience },
                            set: { profile.experience = $0 }
                        )) {
                            ForEach(ExperienceLevel.allCases) { Text($0.label).tag($0) }
                        }
                    }
                }
            }
            .navigationTitle("設定")
            .onAppear {
                hasStoredKey = KeychainStore.read(.anthropicAPIKey) != nil
            }
            .overlay(alignment: .bottom) {
                if showSavedToast {
                    Text("已儲存")
                        .padding(.horizontal, 16).padding(.vertical, 8)
                        .background(.thinMaterial, in: Capsule())
                        .padding(.bottom, 32)
                        .task {
                            try? await Task.sleep(for: .seconds(1.5))
                            showSavedToast = false
                        }
                }
            }
        }
    }

    private func formatRest(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        if m > 0 && s > 0 { return "\(m) 分 \(s) 秒" }
        if m > 0 { return "\(m) 分" }
        return "\(s) 秒"
    }
}
