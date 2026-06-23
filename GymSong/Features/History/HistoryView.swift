import SwiftUI
import SwiftData

struct HistoryView: View {
    @Query(sort: \WorkoutSession.scheduledDate, order: .reverse)
    private var allSessions: [WorkoutSession]

    private var completed: [WorkoutSession] {
        allSessions
            .filter { $0.status == .completed }
            .sorted { (a, b) in
                (a.completedAt ?? a.scheduledDate) > (b.completedAt ?? b.scheduledDate)
            }
    }

    var body: some View {
        NavigationStack {
            Group {
                if completed.isEmpty {
                    ContentUnavailableView(
                        "還沒有完成過訓練",
                        systemImage: "clock",
                        description: Text("完成一個 session 後會出現在這裡。")
                    )
                } else {
                    List(completed) { session in
                        NavigationLink {
                            HistoryDetailView(session: session)
                        } label: {
                            HistoryRow(session: session)
                        }
                    }
                }
            }
            .navigationTitle("歷史紀錄")
        }
    }
}

private struct HistoryRow: View {
    let session: WorkoutSession

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Text(session.focus.isEmpty ? "訓練" : session.focus).bold()
                Spacer()
                Text(displayDate).font(.caption).foregroundStyle(.secondary)
            }
            Text("W\(session.weekNumber) · Day \(session.dayNumber) · \(totalSets) 組")
                .font(.caption).foregroundStyle(.secondary)
        }
        .padding(.vertical, 2)
    }

    private var totalSets: Int {
        session.exercises.reduce(0) { $0 + $1.setLogs.count }
    }

    private var displayDate: String {
        let date = session.completedAt ?? session.scheduledDate
        return date.formatted(date: .abbreviated, time: .omitted)
    }
}

private struct HistoryDetailView: View {
    let session: WorkoutSession

    var body: some View {
        List {
            Section {
                VStack(alignment: .leading, spacing: 6) {
                    Text(session.focus.isEmpty ? "訓練" : session.focus)
                        .font(.title3.bold())
                    if let start = session.startedAt, let end = session.completedAt {
                        Text("時長：\(durationLabel(from: start, to: end))")
                            .font(.caption).foregroundStyle(.secondary)
                    }
                    Text("W\(session.weekNumber) · Day \(session.dayNumber)")
                        .font(.caption).foregroundStyle(.secondary)
                }
            }

            ForEach(session.exercises.sorted(by: { $0.orderIndex < $1.orderIndex })) { se in
                Section(se.exercise?.name ?? "未知動作") {
                    ForEach(se.setLogs.sorted(by: { $0.setIndex < $1.setIndex })) { log in
                        HStack {
                            Text("第 \(log.setIndex) 組").frame(width: 70, alignment: .leading)
                            Text("\(log.actualReps) × \(log.actualWeight.formatted(.number)) kg")
                            Spacer()
                            if let rest = log.restAfterSeconds {
                                Text("休息 \(rest)s").font(.caption).foregroundStyle(.secondary)
                            }
                        }
                        .font(.subheadline)
                    }
                    if let totalVolume = exerciseVolume(se) {
                        Text("總量：\(totalVolume.formatted(.number)) kg")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
        .navigationTitle(session.completedAt?.formatted(date: .abbreviated, time: .omitted) ?? "紀錄")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func exerciseVolume(_ se: SessionExercise) -> Double? {
        let logs = se.setLogs
        guard !logs.isEmpty else { return nil }
        return logs.reduce(0.0) { $0 + Double($1.actualReps) * $1.actualWeight }
    }

    private func durationLabel(from start: Date, to end: Date) -> String {
        let secs = Int(end.timeIntervalSince(start))
        let m = secs / 60
        let s = secs % 60
        if m > 0 { return "\(m) 分 \(s) 秒" }
        return "\(s) 秒"
    }
}
