import SwiftUI
import SwiftData

struct TodayWorkoutView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutSession.scheduledDate)
    private var allSessions: [WorkoutSession]

    private var pendingSessions: [WorkoutSession] {
        allSessions.filter { $0.status == .pending || $0.status == .inProgress }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let next = pendingSessions.first {
                    SessionListView(
                        nextSession: next,
                        upcoming: Array(pendingSessions.dropFirst().prefix(6))
                    )
                } else {
                    ContentUnavailableView(
                        "沒有待完成的訓練",
                        systemImage: "checkmark.seal",
                        description: Text("到「課表」分頁生成或重新規劃。")
                    )
                }
            }
            .navigationTitle("今日訓練")
        }
    }
}

private struct SessionListView: View {
    let nextSession: WorkoutSession
    let upcoming: [WorkoutSession]

    var body: some View {
        List {
            Section {
                NavigationLink {
                    ExerciseLoggerView(session: nextSession)
                } label: {
                    VStack(alignment: .leading, spacing: 6) {
                        Text("下一個訓練").font(.caption).foregroundStyle(.secondary)
                        Text(nextSession.focus.isEmpty ? "訓練" : nextSession.focus)
                            .font(.title2.bold())
                        Text("第 \(nextSession.weekNumber) 週 · Day \(nextSession.dayNumber) · \(nextSession.exercises.count) 個動作")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Text(scheduleLabel(nextSession.scheduledDate))
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }

            if !upcoming.isEmpty {
                Section("接下來") {
                    ForEach(upcoming) { session in
                        NavigationLink {
                            ExerciseLoggerView(session: session)
                        } label: {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(session.focus.isEmpty ? "訓練" : session.focus)
                                    Text("W\(session.weekNumber) · Day \(session.dayNumber) · \(session.exercises.count) 動作")
                                        .font(.caption).foregroundStyle(.secondary)
                                }
                                Spacer()
                                Text(scheduleLabel(session.scheduledDate))
                                    .font(.caption2).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }
        }
    }

    private func scheduleLabel(_ date: Date) -> String {
        let cal = Calendar.current
        if cal.isDateInToday(date) { return "今天" }
        if cal.isDateInTomorrow(date) { return "明天" }
        let days = cal.dateComponents([.day], from: cal.startOfDay(for: .now), to: cal.startOfDay(for: date)).day ?? 0
        if days < 0 { return "晚 \(-days) 天（請補做）" }
        if days < 7 { return "\(days) 天後" }
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}
