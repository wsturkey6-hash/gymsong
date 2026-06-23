import Foundation
import SwiftData

@Model
final class WorkoutSession {
    @Attribute(.unique) var id: UUID
    var program: Program?
    var weekNumber: Int
    var dayNumber: Int
    var focus: String
    var scheduledDate: Date
    var status: SessionStatus
    var startedAt: Date?
    var completedAt: Date?
    var notes: String?

    @Relationship(deleteRule: .cascade, inverse: \SessionExercise.session)
    var exercises: [SessionExercise] = []

    init(
        id: UUID = UUID(),
        program: Program? = nil,
        weekNumber: Int,
        dayNumber: Int,
        focus: String = "",
        scheduledDate: Date,
        status: SessionStatus = .pending,
        startedAt: Date? = nil,
        completedAt: Date? = nil,
        notes: String? = nil
    ) {
        self.id = id
        self.program = program
        self.weekNumber = weekNumber
        self.dayNumber = dayNumber
        self.focus = focus
        self.scheduledDate = scheduledDate
        self.status = status
        self.startedAt = startedAt
        self.completedAt = completedAt
        self.notes = notes
    }
}
