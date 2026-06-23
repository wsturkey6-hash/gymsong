import Foundation
import SwiftData

@Model
final class SetLog {
    @Attribute(.unique) var id: UUID
    var sessionExercise: SessionExercise?
    var setIndex: Int
    var actualReps: Int
    var actualWeight: Double
    var completedAt: Date
    var restAfterSeconds: Int?
    var rpe: Int?

    init(
        id: UUID = UUID(),
        sessionExercise: SessionExercise? = nil,
        setIndex: Int,
        actualReps: Int,
        actualWeight: Double,
        completedAt: Date = .now,
        restAfterSeconds: Int? = nil,
        rpe: Int? = nil
    ) {
        self.id = id
        self.sessionExercise = sessionExercise
        self.setIndex = setIndex
        self.actualReps = actualReps
        self.actualWeight = actualWeight
        self.completedAt = completedAt
        self.restAfterSeconds = restAfterSeconds
        self.rpe = rpe
    }
}
