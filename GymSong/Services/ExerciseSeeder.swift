import Foundation
import SwiftData

struct ExerciseSeed: Decodable {
    let name: String
    let nameEnglish: String?
    let category: ExerciseCategory
    let primaryMuscle: String
    let equipment: Equipment
}

enum ExerciseSeeder {
    static func seedIfNeeded(context: ModelContext) {
        let existing = (try? context.fetchCount(FetchDescriptor<Exercise>())) ?? 0
        guard existing == 0 else { return }

        guard let url = Bundle.main.url(forResource: "default_exercises", withExtension: "json") else {
            assertionFailure("default_exercises.json missing from bundle")
            return
        }

        do {
            let data = try Data(contentsOf: url)
            let seeds = try JSONDecoder().decode([ExerciseSeed].self, from: data)
            for seed in seeds {
                let exercise = Exercise(
                    name: seed.name,
                    nameEnglish: seed.nameEnglish,
                    category: seed.category,
                    primaryMuscle: seed.primaryMuscle,
                    equipment: seed.equipment,
                    isCustom: false
                )
                context.insert(exercise)
            }
            try context.save()
        } catch {
            assertionFailure("Failed to seed exercises: \(error)")
        }
    }
}
