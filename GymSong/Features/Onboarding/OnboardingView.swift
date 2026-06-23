import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext

    @State private var goal: TrainingGoal = .general
    @State private var daysPerWeek: Int = 3
    @State private var experience: ExperienceLevel = .beginner
    @State private var equipment: Set<Equipment> = [.barbell, .dumbbell, .bodyweight]
    @State private var defaultRestSeconds: Int = 120

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Text("先讓我了解你，AI 才能幫你排出合適的訓練課表。")
                        .font(.callout)
                        .foregroundStyle(.secondary)
                }

                Section("訓練目標") {
                    Picker("目標", selection: $goal) {
                        ForEach(TrainingGoal.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("每週訓練天數") {
                    Stepper(value: $daysPerWeek, in: 2...6) {
                        Text("\(daysPerWeek) 天")
                    }
                }

                Section("經驗水平") {
                    Picker("經驗", selection: $experience) {
                        ForEach(ExperienceLevel.allCases) { Text($0.label).tag($0) }
                    }
                    .pickerStyle(.segmented)
                }

                Section("可用器材（可複選）") {
                    ForEach(Equipment.allCases) { item in
                        Toggle(item.label, isOn: Binding(
                            get: { equipment.contains(item) },
                            set: { isOn in
                                if isOn { equipment.insert(item) } else { equipment.remove(item) }
                            }
                        ))
                    }
                }

                Section("預設組間休息") {
                    Stepper(value: $defaultRestSeconds, in: 30...600, step: 15) {
                        Text(formatRest(defaultRestSeconds))
                    }
                }
            }
            .navigationTitle("歡迎使用 GymSong")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("完成") { createProfile() }
                        .disabled(equipment.isEmpty)
                }
            }
        }
    }

    private func createProfile() {
        let profile = UserProfile(
            goal: goal,
            daysPerWeek: daysPerWeek,
            experience: experience,
            equipment: Array(equipment).sorted { $0.rawValue < $1.rawValue },
            defaultRestSeconds: defaultRestSeconds
        )
        modelContext.insert(profile)
        try? modelContext.save()
    }

    private func formatRest(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        if m > 0 && s > 0 { return "\(m) 分 \(s) 秒" }
        if m > 0 { return "\(m) 分" }
        return "\(s) 秒"
    }
}
