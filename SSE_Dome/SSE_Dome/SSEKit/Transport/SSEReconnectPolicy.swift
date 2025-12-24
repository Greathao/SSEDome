import Foundation

/// 协议：定义重连延迟策略。
public protocol SSEReconnectPolicy {
    /// 计算下一次重连尝试前的延迟时间。
    /// - Parameter attempt: 当前尝试的次数（从 1 开始）。
    /// - Returns: 延迟时间（秒）。
    func nextDelay(after attempt: Int) -> TimeInterval
}

/// 固定延迟策略。
/// 每次重连等待固定的时间。
public struct FixedReconnectPolicy: SSEReconnectPolicy {
    private let interval: TimeInterval
    
    public init(interval: TimeInterval = 3.0) {
        self.interval = interval
    }
    
    public func nextDelay(after attempt: Int) -> TimeInterval {
        return interval
    }
}

/// 指数退避策略（生产环境推荐）。
/// 延迟呈指数级增长：1s, 2s, 4s, 8s... 直到达到最大值。
/// 包含随机抖动（Jitter）以防止惊群效应。
public struct ExponentialBackoffPolicy: SSEReconnectPolicy {
    private let initialInterval: TimeInterval
    private let maxInterval: TimeInterval
    private let multiplier: Double
    
    /// 初始化指数退避策略
    /// - Parameters:
    ///   - initialInterval: 初始间隔（秒）
    ///   - maxInterval: 最大间隔（秒）
    ///   - multiplier: 增长倍数
    public init(initialInterval: TimeInterval = 1.0, maxInterval: TimeInterval = 30.0, multiplier: Double = 2.0) {
        self.initialInterval = initialInterval
        self.maxInterval = maxInterval
        self.multiplier = multiplier
    }
    
    public func nextDelay(after attempt: Int) -> TimeInterval {
        let delay = initialInterval * pow(multiplier, Double(attempt - 1))
        // 添加随机抖动 (+/- 10%)
        let jitter = Double.random(in: 0.9...1.1)
        return min(delay * jitter, maxInterval)
    }
}
