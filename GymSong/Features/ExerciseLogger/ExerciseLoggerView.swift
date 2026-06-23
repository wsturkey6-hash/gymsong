import SwiftUI
import SwiftData

struct ExerciseLoggerView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Bindable var session: WorkoutSession
    private let timer = RestTimerService.shared

    @State private var selectedExerciseIndex: Int = 0

    private var sortedExercises: [SessionExercise] {
        session.exercises.sorted { $0.orderIndex < $1.orderIndex }
    }

    var body: some View {
        VStack(spacing: 0) {
            if let endsAt = timer.activeEndsAt {
                RestTimerBanner(endsAt: endsAt, exerciseName: timer.activeExerciseName ?? "") {
                    Task { await timer.cancel() }
                }
            }

            Group {
                if sortedExercises.isEmpty {
                    ContentUnavailableView("這個 session 沒有動作", systemImage: "questionmark.folder")
                } else {
                    TabView(selection: $selectedExerciseIndex) {
                        ForEach(Array(sortedExercises.enumerated()), id: \.element.id) { idx, se in
                            ExercisePagerCard(sessionExercise: se, sessionId: session.id.uuidString)
                                .tag(idx)
                        }
                    }
                    .tabViewStyle(.page(indexDisplayMode: .always))
                }
            }
        }
        .navigationTitle(session.focus.isEmpty ? "訓練" : session.focus)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    if session.status != .completed {
                        Button("標記為完成", systemImage: "checkmark.circle") { markComplete() }
                    }
                    Button("跳過此次", systemImage: "forward", role: .destructive) { markSkipped() }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .onAppear {
            if session.status == .pending {
                session.status = .inProgress
                session.startedAt = .now
            }
        }
    }

    private func markComplete() {
        session.status = .completed
        session.completedAt = .now
        try? modelContext.save()
        dismiss()
    }

    private func markSkipped() {
        session.status = .skipped
        try? modelContext.save()
        dismiss()
    }
}

private struct RestTimerBanner: View {
    let endsAt: Date
    let exerciseName: String
    let onCancel: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "timer").font(.title3).foregroundStyle(.orange)
            VStack(alignment: .leading, spacing: 2) {
                Text("休息中：\(exerciseName)").font(.caption)
                Text(timerInterval: Date.now...endsAt, countsDown: true)
                    .font(.title3.bold().monospacedDigit())
            }
            Spacer()
            Button("跳過", action: onCancel)
                .buttonStyle(.bordered)
                .controlSize(.small)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(.thinMaterial)
    }
}

private struct ExercisePagerCard: View {
    @Environment(\.modelContext) private var modelContext
    @Bindable var sessionExercise: SessionExercise
    let sessionId: String

    @State private var repsInput: Int = 0
    @State private var weightInput: Double = 0

    private var sortedLogs: [SetLog] {
        sessionExercise.setLogs.sorted { $0.setIndex < $1.setIndex }
    }

    private var nextSetIndex: Int {
        (sortedLogs.last?.setIndex ?? 0) + 1
    }

    private var allDone: Bool {
        sortedLogs.count >= sessionExercise.plannedSets
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                header

                planCard

                if !sortedLogs.isEmpty {
                    loggedSetsList
                }

                if allDone {
                    HStack {
                        Image(systemName: "checkmark.seal.fill").foregroundStyle(.green)
                        Text("這個動作的組數已完成")
                    }
                    .font(.callout)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.green.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                } else {
                    nextSetEntry
                }
            }
            .padding()
        }
        .onAppear { resetInputsFromLastSet() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(sessionExercise.exercise?.name ?? "未知動作")
                .font(.title2.bold())
            if let muscle = sessionExercise.exercise?.primaryMuscle {
                Text(muscle).font(.caption).foregroundStyle(.secondary)
            }
        }
    }

    private var planCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("計畫").font(.caption.bold()).foregroundStyle(.secondary)
            let weightText: String = sessionExercise.plannedWeight.map { "\($0.formatted(.number)) kg" } ?? "自選"
            HStack(spacing: 16) {
                stat("組數", "\(sortedLogs.count)/\(sessionExercise.plannedSets)")
                stat("每組次數", sessionExercise.plannedReps)
                stat("重量", weightText)
                stat("休息", "\(sessionExercise.plannedRestSeconds)s")
            }
            if let notes = sessionExercise.notes, !notes.isEmpty {
                Text(notes).font(.caption).foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func stat(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label).font(.caption2).foregroundStyle(.secondary)
            Text(value).font(.subheadline.bold())
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var loggedSetsList: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("已紀錄").font(.caption.bold()).foregroundStyle(.secondary)
            ForEach(sortedLogs) { log in
                HStack {
                    Text("第 \(log.setIndex) 組").frame(width: 70, alignment: .leading)
                    Text("\(log.actualReps) 下")
                    Text("·")
                    Text("\(log.actualWeight.formatted(.number)) kg")
                    Spacer()
                    Text(log.completedAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption).foregroundStyle(.secondary)
                }
                .font(.subheadline)
                .padding(.vertical, 4)
            }
        }
    }

    private var nextSetEntry: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("第 \(nextSetIndex) 組").font(.headline)

            HStack(spacing: 16) {
                VStack(alignment: .leading) {
                    Text("次數").font(.caption).foregroundStyle(.secondary)
                    Stepper(value: $repsInput, in: 0...50) {
                        Text("\(repsInput)").font(.title2.bold().monospacedDigit())
                    }
                }
                VStack(alignment: .leading) {
                    Text("重量 (kg)").font(.caption).foregroundStyle(.secondary)
                    Stepper(value: $weightInput, in: 0...500, step: 2.5) {
                        Text(weightInput.formatted(.number.precision(.fractionLength(0...1))))
                            .font(.title2.bold().monospacedDigit())
                    }
                }
            }

            Button(action: logSet) {
                Label("記錄這組", systemImage: "checkmark.circle.fill")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
            .disabled(repsInput == 0)
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func resetInputsFromLastSet() {
        if let last = sortedLogs.last {
            repsInput = last.actualReps
            weightInput = last.actualWeight
        } else {
            // Pre-fill from plan.
            repsInput = Int(sessionExercise.plannedReps.prefix(while: { $0.isNumber })) ?? 0
            weightInput = sessionExercise.plannedWeight ?? 0
        }
    }

    private func logSet() {
        let now = Date.now
        let restAfter = sortedLogs.last.map { Int(now.timeIntervalSince($0.completedAt)) }

        let log = SetLog(
            sessionExercise: sessionExercise,
            setIndex: nextSetIndex,
            actualReps: repsInput,
            actualWeight: weightInput,
            completedAt: now,
            restAfterSeconds: restAfter
        )
        modelContext.insert(log)
        try? modelContext.save()

        // Auto-start rest timer if more sets remain.
        let plannedSets = sessionExercise.plannedSets
        let justLoggedCount = sortedLogs.count + 1  // sortedLogs is from the previous render
        if justLoggedCount < plannedSets {
            let exerciseName = sessionExercise.exercise?.name ?? "下一組"
            let nextLabel = "第 \(justLoggedCount + 1) 組 / 共 \(plannedSets) 組"
            let duration = TimeInterval(sessionExercise.plannedRestSeconds)
            Task {
                await RestTimerService.shared.start(
                    duration: duration,
                    exerciseName: exerciseName,
                    nextSetLabel: nextLabel,
                    sessionId: sessionId
                )
            }
        } else {
            Task { await RestTimerService.shared.cancel() }
        }
    }
}
