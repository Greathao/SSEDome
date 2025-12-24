import Foundation

/// 辅助协议：用于定义类型安全的事件名称。
/// 应用层可以扩展 `String` 或创建遵循 RawRepresentable 的枚举。
public protocol SSEEventTypeProtocol {
    var eventName: String { get }
}

/// SSE 事件类型的标准实现。
/// 你可以扩展此枚举或使用自定义的 String 枚举。
public enum SSEEventType: String, SSEEventTypeProtocol {
    case message // 默认事件类型
    case ping
    case error
    
    // 如需自定义事件，请在此添加或直接在业务代码中使用字符串
    
    public var eventName: String {
        return self.rawValue
    }
}

// 允许直接使用 String 作为事件类型
extension String: SSEEventTypeProtocol {
    public var eventName: String { return self }
}
