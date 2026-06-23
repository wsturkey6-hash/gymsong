//
//  Item.swift
//  GymSong
//
//  Created by 宋正威 on 2026/6/23.
//

import Foundation
import SwiftData

@Model
final class Item {
    var timestamp: Date
    
    init(timestamp: Date) {
        self.timestamp = timestamp
    }
}
