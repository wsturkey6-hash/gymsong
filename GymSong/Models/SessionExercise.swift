import Foundation
import SwiftData

@Model
final class SessionExercise {
    @Attribute(.unique) var id: UUID
    var session: WorkoutSession?
    var exercise: Exercise?
    var orderIndex: Int
    var plannedSets: Int
    var plannedReps: String
    var plannedWeight: Double?
    var plannedRestSeconds: Int
    var notes: String?

    @Relationship(deleteRule: .cascade, inverse: \SetLog.sessionExercise)
    var setLogs: [SetLog] = []

    init(
        id: UUID = UUID(),
        session: WorkoutSession? = nil,
        exercise: Exercise? = nil,
        orderIndex: Int,
        plannedSets: Int,
        plannedReps: String,
        plannedWeight: Double? = nil,
        plannedRestSeconds: Int = 120,
        notes: String? = nil
    ) {
        self.id = id
        self.session = session
        self.exercise = exercise
        self.orderIndex = orderIndex
        self.plannedSets = plannedSets
        self.plannedReps = plannedReps
        self.plannedWeight = plannedWeight
        self.plannedRestSeconds = plannedRestSeconds
        self.notes = notes
    }
}
