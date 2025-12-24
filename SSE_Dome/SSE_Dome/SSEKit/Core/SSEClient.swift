import Foundation

// 定义回调闭包类型
public typealias SSEEventHandler = (SSEEvent) -> Void
public typealias SSEStateChangeHandler = (SSEState) -> Void
public typealias SSEErrorHandler = (Error) -> Void

/// 用于管理 Server-Sent Events 连接的核心客户端类。
public final class SSEClient {
    
    // MARK: - 公共属性
    
    /// 接收到事件时的回调
    public var onEvent: SSEEventHandler?
    /// 连接状态改变时的回调
    public var onStateChange: SSEStateChangeHandler?
    /// 发生错误时的回调
    public var onError: SSEErrorHandler?
    
    /// 最近一次接收到的事件 ID (Last-Event-ID)
    public private(set) var lastEventId: String?
    
    /// 当前连接状态
    public private(set) var state: SSEState = .idle {
        didSet {
            guard oldValue != state else { return }
            notifyStateChange(state)
        }
    }
    
    // MARK: - 私有属性
    private let config: SSEConfig
    private let parser = SSEParser()
    private let session = SSESession()
    // 使用私有队列处理内部逻辑，确保线程安全
    private let queue = DispatchQueue(label: "com.ssekit.client.queue", qos: .utility)
    
    // 心跳与重连相关
    private var heartbeatTimer: DispatchSourceTimer?
    private var lastMessageTime: Date = Date()
    private var reconnectAttempt: Int = 0
    private var isReconnecting = false
    
    // MARK: - 初始化
    public init(config: SSEConfig) {
        self.config = config
    }
    
    public convenience init(url: URL, headers: [String: String] = [:]) {
        self.init(config: SSEConfig(url: url, headers: headers))
    }
    
    // MARK: - 公共方法
    
    /// 连接到 SSE 流。
    public func connect() {
        queue.async { [weak self] in
            guard let self = self else { return }
            // 如果已经连接或正在连接，则忽略
            guard self.state == .idle || self.state == .closed || self.isReconnecting else {
                SSELogger.log("已连接或正在连接中，忽略本次调用。")
                return
            }
            
            self.state = .connecting
            self.startSession()
        }
    }
    
    /// 断开连接。
    public func disconnect() {
        queue.async { [weak self] in
            self?.internalDisconnect()
        }
    }
    
    // MARK: - 私有逻辑
    
    private func startSession() {
        // 准备请求
        var request = URLRequest(url: config.url, timeoutInterval: config.timeoutInterval)
        request.httpMethod = "GET"
        request.setValue("text/event-stream", forHTTPHeaderField: "Accept")
        request.setValue("no-cache", forHTTPHeaderField: "Cache-Control")
        
        // 添加用户自定义 Headers
        config.headers.forEach { key, value in
            request.setValue(value, forHTTPHeaderField: key)
        }
        
        // Last-Event-ID 支持 (断点续传)
        if let lastId = lastEventId, !lastId.isEmpty {
            request.setValue(lastId, forHTTPHeaderField: "Last-Event-ID")
            SSELogger.log("使用 Last-Event-ID 恢复连接: \(lastId)")
        }
        
        // 设置 Session 回调
        session.onReceive = { [weak self] data in
            self?.handleReceive(data)
        }
        
        session.onCompletion = { [weak self] error in
            self?.handleCompletion(error: error)
        }
        
        session.onResponseCheck = { [weak self] statusCode in
            return self?.validateResponse(code: statusCode) ?? false
        }
        
        session.start(request: request)
        
        if config.enableHeartbeat {
            startHeartbeat()
        }
    }
    
    private func internalDisconnect() {
        stopHeartbeat()
        session.stop()
        state = .closed
        isReconnecting = false
        reconnectAttempt = 0
        parser.reset()
        SSELogger.log("连接已断开")
    }
    
    private func handleReceive(_ data: Data) {
        queue.async { [weak self] in
            guard let self = self else { return }
            self.lastMessageTime = Date()
            
            if self.state != .open {
                self.state = .open
                self.reconnectAttempt = 0 // 连接成功，重置重连计数
                self.isReconnecting = false
            }
            
            guard let text = String(data: data, encoding: .utf8) else {
                SSELogger.log("无法解码 UTF-8 数据")
                return
            }
            
            let events = self.parser.parse(chunk: text)
            for event in events {
                if let id = event.id {
                    self.lastEventId = id
                }
                
                // 将事件回调分发到主线程
                DispatchQueue.main.async {
                    self.onEvent?(event)
                }
            }
        }
    }
    
    private func validateResponse(code: Int) -> Bool {
        // SSE 连接必须是 200 OK
        if code == 200 {
            return true
        }
        // 如果是 204 No Content，表示服务器告知没有更多数据，应停止
        if code == 204 {
            internalDisconnect()
            return false
        }
        return false
    }
    
    private func handleCompletion(error: Error?) {
        queue.async { [weak self] in
            guard let self = self else { return }
            
            self.stopHeartbeat()
            
            if let error = error {
                SSELogger.log("连接关闭，错误信息: \(error.localizedDescription)")
                DispatchQueue.main.async { self.onError?(error) }
                self.attemptReconnect(reason: error)
            } else {
                // 服务器优雅关闭连接
                SSELogger.log("服务器优雅地关闭了连接")
                self.state = .closed
                // 通常优雅关闭不重连，除非配置强制要求
                if self.config.enableAutoReconnect {
                     self.attemptReconnect(reason: NSError(domain: "SSE", code: 0, userInfo: [NSLocalizedDescriptionKey: "Server Closed"]))
                }
            }
        }
    }
    
    // MARK: - 重连逻辑
    
    private func attemptReconnect(reason: Error) {
        guard config.enableAutoReconnect else {
            state = .closed
            return
        }
        
        // 检查错误是否致命（例如 401 未授权, 403 禁止访问通常不应重试）
        if let urlError = reason as? URLError {
            if urlError.code == .userCancelledAuthentication || urlError.code == .badServerResponse {
                 state = .closed
                 return
            }
        }
        
        isReconnecting = true
        reconnectAttempt += 1
        
        let delay = config.reconnectPolicy.nextDelay(after: reconnectAttempt)
        SSELogger.log("尝试第 \(reconnectAttempt) 次重连，延迟 \(delay) 秒")
        
        queue.asyncAfter(deadline: .now() + delay) { [weak self] in
            self?.connect()
        }
    }
    
    // MARK: - 心跳检测
    
    private func startHeartbeat() {
        stopHeartbeat()
        lastMessageTime = Date()
        
        let timer = DispatchSource.makeTimerSource(queue: queue)
        timer.schedule(deadline: .now() + 5, repeating: 5)
        timer.setEventHandler { [weak self] in
            self?.checkHeartbeat()
        }
        heartbeatTimer = timer
        timer.resume()
    }
    
    private func stopHeartbeat() {
        heartbeatTimer?.cancel()
        heartbeatTimer = nil
    }
    
    private func checkHeartbeat() {
        guard state == .open else { return }
        
        let interval = Date().timeIntervalSince(lastMessageTime)
        if interval > config.heartbeatTimeout {
            SSELogger.log("心跳超时。正在重连...")
            // 终止会话以触发清理和重连逻辑
            session.stop()
            handleCompletion(error: NSError(domain: "SSEKit", code: -999, userInfo: [NSLocalizedDescriptionKey: "心跳超时"]))
        }
    }
    
    private func notifyStateChange(_ newState: SSEState) {
        DispatchQueue.main.async { [weak self] in
            self?.onStateChange?(newState)
        }
    }
}
