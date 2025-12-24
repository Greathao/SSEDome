import Foundation

/// 表示 SSE 连接的生命周期状态。
public enum SSEState: Equatable {
    /// 客户端已初始化，但尚未连接。
    case idle
    
    /// 客户端正在尝试建立连接。
    case connecting
    
    /// 连接已建立且处于活跃状态。
    case open
    
    /// 连接已被用户显式关闭，或因不可恢复的错误而永久关闭。
    case closed
    
    public static func == (lhs: SSEState, rhs: SSEState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle),
             (.connecting, .connecting),
             (.open, .open),
             (.closed, .closed):
            return true
        default:
            return false
        }
    }
}
