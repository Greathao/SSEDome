import Foundation

/// SSEKit 的简单日志工具。
public final class SSELogger {
    
    public enum Level: Int {
        case none = 0
        case error = 1
        case debug = 2
    }
    
    public static var logLevel: Level = .debug
    
    static func log(_ message: String, level: Level = .debug) {
        guard level.rawValue <= logLevel.rawValue else { return }
        
        let prefix = level == .error ? "❌ [SSEKit Error]" : "ℹ️ [SSEKit]"
        print("\(prefix) \(message)")
    }
}
