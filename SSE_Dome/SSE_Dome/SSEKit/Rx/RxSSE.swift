import Foundation
import RxSwift

/// SSEClient 的 RxSwift 扩展支持。
public enum RxSSE {
    
    /// 创建一个 Observable 连接到 SSE 流。
    ///
    /// - Parameters:
    ///   - config: SSE 连接配置对象。
    /// - Returns: 发射 SSEEvent 的 Observable 序列。
    public static func connect(config: SSEConfig) -> Observable<SSEEvent> {
        
        return Observable.create { observer in
            
            let client = SSEClient(config: config)
            
            client.onEvent = { event in
                observer.onNext(event)
            }
            
            client.onError = { error in
                // 如果开启了自动重连，通常不终止序列。
                // 如果希望在 Rx 语义中遇到错误即终止，可在此判断配置。
                if !config.enableAutoReconnect {
                     observer.onError(error)
                }
            }
            
            client.onStateChange = { state in
                if state == .closed {
                    // 如果手动关闭或发生致命错误，可选择结束序列
                    // observer.onCompleted()
                }
            }
            
            client.connect()
            
            return Disposables.create {
                client.disconnect()
            }
        }
    }
    
    /// 简单使用的辅助方法
    public static func connect(url: URL, headers: [String: String] = [:]) -> Observable<SSEEvent> {
        return connect(config: SSEConfig(url: url, headers: headers))
    }
}
