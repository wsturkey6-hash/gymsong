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
                Section("Gemini API Key") {
                    SecureField(hasStoredKey ? "已儲存（再輸入會覆蓋）" : "AIza...", text: $apiKeyInput)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    HStack {
                        Button("儲存") {
                            let trimmed = apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines)
                            guard !trimmed.isEmpty else { return }
                            KeychainStore.save(trimmed, for: .geminiAPIKey)
                            apiKeyInput = ""
                            hasStoredKey = true
                            showSavedToast = true
                        }
                        .disabled(apiKeyInput.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

                        Spacer()

                        if hasStoredKey {
                            Button("清除", role: .destructive) {
                                KeychainStore.delete(.geminiAPIKey)
                                hasStoredKey = false
                            }
                        }
                    }

                    Text("API Key 存在裝置 Keychain，不會傳出去。前往 aistudio.google.com/apikey 免費取得（Gemini 2.5 Flash 個人使用通常在每日免費額度內）。")
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

                    Section {
                        ForEach(Equipment.allCases) { item in
                            Toggle(item.label, isOn: Binding(
                                get: { profile.equipment.contains(item) },
                                set: { isOn in
                                    if isOn {
                                        if !profile.equipment.contains(item) {
                                            profile.equipment.append(item)
                                            profile.equipment.sort { $0.rawValue < $1.rawValue }
                                        }
                                    } else {
                                        profile.equipment.removeAll { $0 == item }
                                    }
                                }
                            ))
                        }
                    } header: {
                        Text("可用器材（可複選）")
                    } footer: {
                        if profile.equipment.isEmpty {
                            Text("至少選一項，否則 AI 無法生成課表。")
                                .foregroundStyle(.red)
                        }
                    }
                }
            }
            .navigationTitle("設定")
            .onAppear {
                hasStoredKey = KeychainStore.read(.geminiAPIKey) != nil
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
