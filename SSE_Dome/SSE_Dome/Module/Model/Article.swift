//
//  Model.swift
//  SSE_Dome
//
//  Created by mac on 12/23/25.
//

import Foundation

struct Article: Decodable {
    let id: Int          // ✅ 改为 Int
    let title: String
    let content: String
}
