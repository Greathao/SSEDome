import Foundation

/// 标记协议：表示可以从 SSE 事件中解码的数据结构。
/// 本质上是 Codable 的别名，但为 SSE 提供了语义层。
public protocol SSEPayload: Codable {}

/// 如果服务器发送标准 JSON 信封格式，可使用此通用 Payload 结构。
public struct SSEGenericPayload<T: Codable>: SSEPayload {
    public let timestamp: TimeInterval
    public let data: T
}

extension SSEEvent {
    /// 辅助方法：判断事件是否匹配特定的类型枚举。
    public func isType(_ type: SSEEventType) -> Bool {
        return self.event == type.rawValue
    }
}
