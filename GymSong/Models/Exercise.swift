import Foundation
import SwiftData

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var nameEnglish: String?
    var category: ExerciseCategory
    var primaryMuscle: String
    var equipment: Equipment
    var isCustom: Bool
    var notes: String?

    init(
        id: UUID = UUID(),
        name: String,
        nameEnglish: String? = nil,
        category: ExerciseCategory,
        primaryMuscle: String,
        equipment: Equipment,
        isCustom: Bool = false,
        notes: String? = nil
    ) {
        self.id = id
        self.name = name
        self.nameEnglish = nameEnglish
        self.category = category
        self.primaryMuscle = primaryMuscle
        self.equipment = equipment
        self.isCustom = isCustom
        self.notes = notes
    }
}
