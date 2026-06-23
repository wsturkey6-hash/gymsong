import Foundation
import SwiftData

@Model
final class UserProfile {
    var goal: TrainingGoal
    var daysPerWeek: Int
    var experience: ExperienceLevel
    var equipment: [Equipment]
    var defaultRestSeconds: Int
    var createdAt: Date

    init(
        goal: TrainingGoal = .general,
        daysPerWeek: Int = 3,
        experience: ExperienceLevel = .beginner,
        equipment: [Equipment] = [.bodyweight],
        defaultRestSeconds: Int = 120,
        createdAt: Date = .now
    ) {
        self.goal = goal
        self.daysPerWeek = daysPerWeek
        self.experience = experience
        self.equipment = equipment
        self.defaultRestSeconds = defaultRestSeconds
        self.createdAt = createdAt
    }
}
