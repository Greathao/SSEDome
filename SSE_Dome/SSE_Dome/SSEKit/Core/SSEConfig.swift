import Foundation

/// SSE 客户端配置项
public struct SSEConfig {
    
    /// SSE 服务端点的 URL
    public let url: URL
    
    /// 连接请求中包含的自定义 HTTP 请求头。
    /// 注意：`Accept: text/event-stream` 和 `Cache-Control: no-cache` 会自动添加，无需在此设置。
    public let headers: [String: String]
    
    /// 请求的超时时间间隔。对于长连接，默认为 `.infinity`（无穷大）。
    public let timeoutInterval: TimeInterval
    
    /// 当连接意外断开时，是否启用自动重连。
    public let enableAutoReconnect: Bool
    
    /// 指定的重连策略（算法）。
    public let reconnectPolicy: SSEReconnectPolicy
    
    /// 是否在未收到数据时启用内部心跳检测。
    public let enableHeartbeat: Bool
    
    /// 判定连接过期的最大静默时间（秒）。超过此时间未收到任何数据将触发重连。
    public let heartbeatTimeout: TimeInterval
    
    /// 初始化配置
    /// - Parameters:
    ///   - url: 服务端 URL
    ///   - headers: 自定义请求头
    ///   - timeoutInterval: 超时时间，默认无穷大
    ///   - enableAutoReconnect: 是否自动重连，默认 true
    ///   - reconnectPolicy: 重连策略，默认使用指数退避策略
    ///   - enableHeartbeat: 是否启用心跳，默认 true
    ///   - heartbeatTimeout: 心跳超时判定时间，默认 45 秒
    public init(
        url: URL,
        headers: [String: String] = [:],
        timeoutInterval: TimeInterval = .infinity,
        enableAutoReconnect: Bool = true,
        reconnectPolicy: SSEReconnectPolicy = ExponentialBackoffPolicy(),
        enableHeartbeat: Bool = true,
        heartbeatTimeout: TimeInterval = 45.0
    ) {
        self.url = url
        self.headers = headers
        self.timeoutInterval = timeoutInterval
        self.enableAutoReconnect = enableAutoReconnect
        self.reconnectPolicy = reconnectPolicy
        self.enableHeartbeat = enableHeartbeat
        self.heartbeatTimeout = heartbeatTimeout
    }
    
    /// 便捷初始化方法
    public static func `default`(url: URL) -> SSEConfig {
        return SSEConfig(url: url)
    }
}
