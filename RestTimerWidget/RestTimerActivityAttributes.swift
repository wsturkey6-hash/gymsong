//  ⚠️ 重要：這個檔案必須與 GymSong/Shared/RestTimerActivityAttributes.swift
//  保持完全一致。Live Activity 在 app 與 widget extension 之間透過
//  名稱與結構匹配；任何欄位差異都會導致 widget 不顯示。

import ActivityKit
import Foundation

struct RestTimerActivityAttributes: ActivityAttributes {
    struct ContentState: Codable, Hashable {
        var endsAt: Date
        var exerciseName: String
        var nextSetLabel: String
    }

    // 固定屬性：建立 Live Activity 後不變
    var sessionId: String
}
