import SwiftUI
import SwiftData

struct ProgramSetupView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [UserProfile]
    @Query(filter: #Predicate<Program> { $0.isActive == true }, sort: \Program.createdAt, order: .reverse)
    private var activePrograms: [Program]

    @State private var isGenerating = false
    @State private var errorMessage: String?
    @State private var weekCount: Int = 8

    var body: some View {
        NavigationStack {
            Group {
                if let program = activePrograms.first {
                    ActiveProgramView(program: program, onRegenerate: regenerate)
                } else {
                    emptyStateView
                }
            }
            .navigationTitle("課表")
            .alert("生成失敗", isPresented: errorBinding) {
                Button("好") { errorMessage = nil }
            } message: {
                Text(errorMessage ?? "")
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 56))
                .foregroundStyle(.tint)

            Text("還沒有課表")
                .font(.title2.bold())

            Text("讓 AI 根據《怪獸訓練》的方法論，幫你排一個 \(weekCount) 週的計畫。")
                .font(.callout)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Stepper("週數：\(weekCount) 週", value: $weekCount, in: 4...16)
                .padding(.horizontal, 32)

            Button(action: generate) {
                if isGenerating {
                    ProgressView().tint(.white).padding(.horizontal, 8)
                } else {
                    Text("生成課表").bold()
                }
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(isGenerating || profiles.first == nil)

            if isGenerating {
                Text("AI 思考中，可能需要 30–60 秒...")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
    }

    private var errorBinding: Binding<Bool> {
        Binding(get: { errorMessage != nil }, set: { if !$0 { errorMessage = nil } })
    }

    private func generate() {
        guard let profile = profiles.first else { return }
        isGenerating = true
        Task {
            defer { isGenerating = false }
            do {
                let generator = ProgramGenerator(modelContext: modelContext)
                _ = try await generator.generate(profile: profile, weeks: weekCount)
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }

    private func regenerate() {
        guard let profile = profiles.first else { return }
        // Deactivate existing programs first.
        for old in activePrograms { old.isActive = false }
        isGenerating = true
        Task {
            defer { isGenerating = false }
            do {
                let generator = ProgramGenerator(modelContext: modelContext)
                _ = try await generator.generate(profile: profile, weeks: weekCount)
            } catch {
                // Re-activate the previous one if generation failed.
                for old in activePrograms { old.isActive = true }
                errorMessage = error.localizedDescription
            }
        }
    }
}

private struct ActiveProgramView: View {
    let program: Program
    let onRegenerate: () -> Void

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(program.name).font(.title3.bold())
                    Text("\(program.weeks) 週 · 目標 \(program.goal.label) · 開始於 \(program.startDate.formatted(date: .abbreviated, time: .omitted))")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            }

            ForEach(groupedByWeek, id: \.weekNumber) { week in
                Section("第 \(week.weekNumber) 週") {
                    ForEach(week.sessions) { session in
                        NavigationLink {
                            SessionPreviewView(session: session)
                        } label: {
                            HStack {
                                Text("Day \(session.dayNumber)").font(.subheadline).foregroundStyle(.secondary).frame(width: 50, alignment: .leading)
                                VStack(alignment: .leading) {
                                    Text(session.focus.isEmpty ? "訓練" : session.focus)
                                    Text("\(session.exercises.count) 個動作")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                            }
                        }
                    }
                }
            }

            Section {
                Button(role: .destructive, action: onRegenerate) {
                    Label("重新生成課表", systemImage: "arrow.clockwise")
                }
            } footer: {
                Text("會把目前的課表標記為不啟用，並開始一次新的 AI 生成。歷史紀錄仍會保留。")
            }
        }
    }

    private struct WeekGroup {
        let weekNumber: Int
        let sessions: [WorkoutSession]
    }

    private var groupedByWeek: [WeekGroup] {
        let grouped = Dictionary(grouping: program.sessions, by: \.weekNumber)
        return grouped.keys.sorted().map { week in
            WeekGroup(
                weekNumber: week,
                sessions: (grouped[week] ?? []).sorted { $0.dayNumber < $1.dayNumber }
            )
        }
    }
}

private struct SessionPreviewView: View {
    let session: WorkoutSession

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 4) {
                    Text("第 \(session.weekNumber) 週 · Day \(session.dayNumber)")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text(session.focus.isEmpty ? "訓練" : session.focus)
                        .font(.title3.bold())
                }
            }
            Section("動作") {
                ForEach(session.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })) { se in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(se.exercise?.name ?? "未知動作").bold()
                        Text(prescriptionLine(for: se))
                            .font(.subheadline).foregroundStyle(.secondary)
                        if let notes = se.notes, !notes.isEmpty {
                            Text(notes).font(.caption).foregroundStyle(.secondary)
                        }
                    }
                    .padding(.vertical, 2)
                }
            }
        }
        .navigationTitle("Day \(session.dayNumber)")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func prescriptionLine(for se: SessionExercise) -> String {
        let core = "\(se.plannedSets) × \(se.plannedReps)"
        let weight: String
        if let w = se.plannedWeight {
            weight = " @ \(w.formatted(.number)) kg"
        } else {
            weight = "（自選重量）"
        }
        return core + weight + " · 休息 \(se.plannedRestSeconds) 秒"
    }
}
