import Foundation

/// 表示一个服务端发送事件 (Server-Sent Event)。
public struct SSEEvent: Equatable, CustomStringConvertible {
    
    /// 事件的唯一标识符（对应 `id:` 字段）。
    public let id: String?
    
    /// 事件类型（对应 `event:` 字段）。默认为 "message"。
    public let event: String
    
    /// 事件的数据载荷（对应 `data:` 字段）。
    /// 如果有多行数据，会通过换行符拼接。
    public let data: String
    
    /// 服务端建议的重试时间间隔（对应 `retry:` 字段，单位秒）。
    public let retryInterval: TimeInterval?
    
    public init(id: String? = nil, event: String = "message", data: String, retryInterval: TimeInterval? = nil) {
        self.id = id
        self.event = event
        self.data = data
        self.retryInterval = retryInterval
    }
    
    public var description: String {
        return "[SSEEvent] id: \(id ?? "nil"), event: \(event), data_len: \(data.count)"
    }
}

// MARK: - 辅助扩展
extension SSEEvent {
    /// 尝试将数据字符串解码为 Decodable 对象。
    /// - Parameters:
    ///   - type: 目标类型
    ///   - decoder: JSON 解码器
    /// - Returns: 解码后的对象
    /// - Throws: 如果数据不是有效的 UTF-8 或解码失败则抛出异常
    public func decode<T: Decodable>(_ type: T.Type, using decoder: JSONDecoder = JSONDecoder()) throws -> T {
        guard let data = self.data.data(using: .utf8) else {
            throw NSError(domain: "SSEKit", code: -1, userInfo: [NSLocalizedDescriptionKey: "无效的 UTF-8 数据"])
        }
        return try decoder.decode(type, from: data)
    }
}
