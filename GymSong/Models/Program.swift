import Foundation
import SwiftData

@Model
final class Program {
    @Attribute(.unique) var id: UUID
    var name: String
    var startDate: Date
    var weeks: Int
    var goal: TrainingGoal
    var generatedByAI: Bool
    var aiRawJSON: String?
    var createdAt: Date
    var isActive: Bool

    @Relationship(deleteRule: .cascade, inverse: \WorkoutSession.program)
    var sessions: [WorkoutSession] = []

    init(
        id: UUID = UUID(),
        name: String,
        startDate: Date = .now,
        weeks: Int,
        goal: TrainingGoal,
        generatedByAI: Bool = true,
        aiRawJSON: String? = nil,
        createdAt: Date = .now,
        isActive: Bool = true
    ) {
        self.id = id
        self.name = name
        self.startDate = startDate
        self.weeks = weeks
        self.goal = goal
        self.generatedByAI = generatedByAI
        self.aiRawJSON = aiRawJSON
        self.createdAt = createdAt
        self.isActive = isActive
    }
}
