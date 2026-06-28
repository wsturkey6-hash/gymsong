import Foundation
import SwiftData

enum ProgramGeneratorError: LocalizedError {
    case principlesMissing
    case aiFailure(AIError)
    case jsonParseFailed(String)
    case noExercises
    case exerciseNotFound(String)

    var errorDescription: String? {
        switch self {
        case .principlesMissing: return "找不到 monster_training_principles.md"
        case .aiFailure(let err): return err.errorDescription
        case .jsonParseFailed(let detail): return "AI 回應 JSON 解析失敗：\(detail)"
        case .noExercises: return "動作庫為空，無法生成課表"
        case .exerciseNotFound(let id): return "AI 回傳了不存在的動作 id：\(id)"
        }
    }
}

@MainActor
struct ProgramGenerator {
    let modelContext: ModelContext

    /// Generate a multi-week program and persist it to SwiftData.
    /// Returns the new `Program`.
    func generate(profile: UserProfile, weeks: Int = 8) async throws -> Program {
        let exercises = try fetchAvailableExercises(profile: profile)
        guard !exercises.isEmpty else { throw ProgramGeneratorError.noExercises }

        let principles = try loadPrinciples()
        let systemPrompt = buildSystemPrompt(principles: principles)
        let userPrompt = buildUserPrompt(profile: profile, exercises: exercises, weeks: weeks)
        let schema = jsonSchema()

        let responseText: String
        do {
            responseText = try await AIService.generate(
                system: systemPrompt,
                user: userPrompt,
                jsonSchema: schema,
                maxTokens: 16000
            )
        } catch let err as AIError {
            throw ProgramGeneratorError.aiFailure(err)
        }

        let response = try parseResponse(responseText)
        return try persist(response: response, profile: profile, weeks: weeks, exercises: exercises, rawJSON: responseText)
    }

    // MARK: - Inputs

    private func fetchAvailableExercises(profile: UserProfile) throws -> [Exercise] {
        let all = try modelContext.fetch(FetchDescriptor<Exercise>())
        let allowed = Set(profile.equipment)
        // Exercise must use equipment the user has access to.
        return all.filter { allowed.contains($0.equipment) }
    }

    private func loadPrinciples() throws -> String {
        guard let url = Bundle.main.url(forResource: "monster_training_principles", withExtension: "md") else {
            throw ProgramGeneratorError.principlesMissing
        }
        return (try? String(contentsOf: url, encoding: .utf8)) ?? ""
    }

    private func buildSystemPrompt(principles: String) -> String {
        """
        你是一位專業的肌力訓練課程規劃師，依據《怪獸訓練肌力課程設計：打造最強壯版本的自己》（何立安著）的方法論排課表。

        以下是你必須遵循的核心原則：

        \(principles)

        重要規範：
        - 你的回應必須是有效的 JSON，符合給定的 schema。
        - 所有 exercise_id 必須來自使用者提供的 available_exercises 清單。不可自創。
        - 寫 notes 給使用者看時請用繁體中文。
        - 第一週的主要動作 weight_kg 可填 null，附 notes 提醒使用者選擇保守的試重。
        """
    }

    private func buildUserPrompt(profile: UserProfile, exercises: [Exercise], weeks: Int) -> String {
        let exercisesJSON = exercises.map { ex in
            [
                "id": ex.id.uuidString,
                "name": ex.name,
                "category": ex.category.rawValue,
                "primary_muscle": ex.primaryMuscle,
                "equipment": ex.equipment.rawValue,
            ] as [String: Any]
        }
        let data = (try? JSONSerialization.data(withJSONObject: exercisesJSON, options: [.prettyPrinted])) ?? Data()
        let exercisesString = String(data: data, encoding: .utf8) ?? "[]"

        return """
        請為以下使用者生成 \(weeks) 週的訓練計畫：

        - 訓練目標：\(profile.goal.label)（\(profile.goal.rawValue)）
        - 每週訓練天數：\(profile.daysPerWeek)
        - 經驗水平：\(profile.experience.label)（\(profile.experience.rawValue)）
        - 可用器材：\(profile.equipment.map { $0.label }.joined(separator: "、"))
        - 預設組間休息：\(profile.defaultRestSeconds) 秒（可依強度調整）

        可用動作庫（必須只使用清單內的動作 id）：
        \(exercisesString)

        請依照系統訊息的原則排出完整的 \(weeks) 週計畫，包含週期化（積累期 + deload 週）。
        """
    }

    /// JSON schema for Gemini structured output.
    /// Notes:
    /// - Gemini ignores `additionalProperties`, so it's omitted.
    /// - Nullable fields use `nullable: true` instead of `anyOf: [{}, {null}]`.
    private func jsonSchema() -> [String: Any] {
        let exerciseEntry: [String: Any] = [
            "type": "object",
            "properties": [
                "exercise_id": ["type": "string"],
                "sets": ["type": "integer"],
                "reps": ["type": "string"],
                "weight_kg": ["type": "number", "nullable": true],
                "rest_seconds": ["type": "integer"],
                "notes": ["type": "string"],
            ],
            "required": ["exercise_id", "sets", "reps", "rest_seconds", "notes", "weight_kg"],
        ]

        let day: [String: Any] = [
            "type": "object",
            "properties": [
                "day_number": ["type": "integer"],
                "focus": ["type": "string"],
                "exercises": ["type": "array", "items": exerciseEntry],
            ],
            "required": ["day_number", "focus", "exercises"],
        ]

        let week: [String: Any] = [
            "type": "object",
            "properties": [
                "week_number": ["type": "integer"],
                "is_deload": ["type": "boolean"],
                "days": ["type": "array", "items": day],
            ],
            "required": ["week_number", "is_deload", "days"],
        ]

        return [
            "type": "object",
            "properties": [
                "program_name": ["type": "string"],
                "rationale": ["type": "string"],
                "weeks": ["type": "array", "items": week],
            ],
            "required": ["program_name", "rationale", "weeks"],
        ]
    }

    // MARK: - Parsing

    private struct AIProgramResponse: Decodable {
        let programName: String
        let rationale: String
        let weeks: [AIWeek]

        enum CodingKeys: String, CodingKey {
            case programName = "program_name"
            case rationale
            case weeks
        }
    }

    private struct AIWeek: Decodable {
        let weekNumber: Int
        let isDeload: Bool
        let days: [AIDay]

        enum CodingKeys: String, CodingKey {
            case weekNumber = "week_number"
            case isDeload = "is_deload"
            case days
        }
    }

    private struct AIDay: Decodable {
        let dayNumber: Int
        let focus: String
        let exercises: [AIExercise]

        enum CodingKeys: String, CodingKey {
            case dayNumber = "day_number"
            case focus
            case exercises
        }
    }

    private struct AIExercise: Decodable {
        let exerciseId: String
        let sets: Int
        let reps: String
        let weightKg: Double?
        let restSeconds: Int
        let notes: String

        enum CodingKeys: String, CodingKey {
            case exerciseId = "exercise_id"
            case sets
            case reps
            case weightKg = "weight_kg"
            case restSeconds = "rest_seconds"
            case notes
        }
    }

    private func parseResponse(_ text: String) throws -> AIProgramResponse {
        guard let data = text.data(using: .utf8) else {
            throw ProgramGeneratorError.jsonParseFailed("空回應")
        }
        do {
            return try JSONDecoder().decode(AIProgramResponse.self, from: data)
        } catch {
            throw ProgramGeneratorError.jsonParseFailed("\(error.localizedDescription)\n回應前 300 字：\(String(text.prefix(300)))")
        }
    }

    // MARK: - Persistence

    private func persist(
        response: AIProgramResponse,
        profile: UserProfile,
        weeks: Int,
        exercises: [Exercise],
        rawJSON: String
    ) throws -> Program {
        let lookup = Dictionary(uniqueKeysWithValues: exercises.map { ($0.id.uuidString, $0) })

        let program = Program(
            name: response.programName,
            startDate: .now,
            weeks: weeks,
            goal: profile.goal,
            generatedByAI: true,
            aiRawJSON: rawJSON
        )
        modelContext.insert(program)

        let startDate = Calendar.current.startOfDay(for: .now)
        for week in response.weeks.sorted(by: { $0.weekNumber < $1.weekNumber }) {
            for day in week.days.sorted(by: { $0.dayNumber < $1.dayNumber }) {
                let dayOffset = (week.weekNumber - 1) * 7 + (day.dayNumber - 1)
                let scheduled = Calendar.current.date(byAdding: .day, value: dayOffset, to: startDate) ?? startDate

                let session = WorkoutSession(
                    program: program,
                    weekNumber: week.weekNumber,
                    dayNumber: day.dayNumber,
                    focus: day.focus,
                    scheduledDate: scheduled,
                    status: .pending
                )
                modelContext.insert(session)

                for (idx, item) in day.exercises.enumerated() {
                    guard let exercise = lookup[item.exerciseId] else {
                        throw ProgramGeneratorError.exerciseNotFound(item.exerciseId)
                    }
                    let se = SessionExercise(
                        session: session,
                        exercise: exercise,
                        orderIndex: idx,
                        plannedSets: item.sets,
                        plannedReps: item.reps,
                        plannedWeight: item.weightKg,
                        plannedRestSeconds: item.restSeconds,
                        notes: item.notes
                    )
                    modelContext.insert(se)
                }
            }
        }

        try modelContext.save()
        return program
    }
}
