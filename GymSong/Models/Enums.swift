import Foundation

enum TrainingGoal: String, Codable, CaseIterable, Identifiable {
    case strength
    case hypertrophy
    case endurance
    case power
    case general

    var id: String { rawValue }

    var label: String {
        switch self {
        case .strength: return "肌力"
        case .hypertrophy: return "肌肥大"
        case .endurance: return "肌耐力"
        case .power: return "爆發力"
        case .general: return "綜合"
        }
    }
}

enum ExperienceLevel: String, Codable, CaseIterable, Identifiable {
    case beginner
    case intermediate
    case advanced

    var id: String { rawValue }

    var label: String {
        switch self {
        case .beginner: return "初學者"
        case .intermediate: return "中階"
        case .advanced: return "進階"
        }
    }
}

enum Equipment: String, Codable, CaseIterable, Identifiable {
    case barbell
    case dumbbell
    case machine
    case bodyweight
    case kettlebell
    case cable
    case bands

    var id: String { rawValue }

    var label: String {
        switch self {
        case .barbell: return "槓鈴"
        case .dumbbell: return "啞鈴"
        case .machine: return "機械"
        case .bodyweight: return "自體重"
        case .kettlebell: return "壺鈴"
        case .cable: return "滑輪"
        case .bands: return "彈力帶"
        }
    }
}

enum ExerciseCategory: String, Codable, CaseIterable, Identifiable {
    case push
    case pull
    case squat
    case hinge
    case core
    case carry

    var id: String { rawValue }

    var label: String {
        switch self {
        case .push: return "推"
        case .pull: return "拉"
        case .squat: return "蹲"
        case .hinge: return "髖屈伸"
        case .core: return "核心"
        case .carry: return "攜帶"
        }
    }
}

enum SessionStatus: String, Codable {
    case pending
    case inProgress
    case completed
    case skipped
}
