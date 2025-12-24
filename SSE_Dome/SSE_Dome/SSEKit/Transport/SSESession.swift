import Foundation

/// URLSession 的封装类，用于处理流式数据任务。
final class SSESession: NSObject {
    
    typealias ReceiveHandler = (Data) -> Void
    typealias CompletionHandler = (Error?) -> Void
    typealias ResponseCheckHandler = (Int) -> Bool
    
    var onReceive: ReceiveHandler?
    var onCompletion: CompletionHandler?
    var onResponseCheck: ResponseCheckHandler?
    
    private var session: URLSession?
    private var dataTask: URLSessionDataTask?
    
    override init() {
        super.init()
    }
    
    func start(request: URLRequest) {
        stop() // 确保状态清理
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = .infinity // 对 SSE 至关重要：永不超时
        config.timeoutIntervalForResource = .infinity
        config.requestCachePolicy = .reloadIgnoringLocalCacheData // 忽略缓存
        
        session = URLSession(configuration: config, delegate: self, delegateQueue: nil)
        dataTask = session?.dataTask(with: request)
        dataTask?.resume()
    }
    
    func stop() {
        dataTask?.cancel()
        session?.invalidateAndCancel()
        dataTask = nil
        session = nil
    }
}

// MARK: - URLSessionDelegate
extension SSESession: URLSessionDataDelegate {
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive response: URLResponse, completionHandler: @escaping (URLSession.ResponseDisposition) -> Void) {
        
        guard let httpResponse = response as? HTTPURLResponse else {
            completionHandler(.cancel)
            return
        }
        
        // 允许 Client 验证状态码（例如必须是 200 OK）
        if let validator = onResponseCheck {
            if validator(httpResponse.statusCode) {
                completionHandler(.allow)
            } else {
                let error = NSError(domain: "SSEKit", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "无效的 HTTP 状态码: \(httpResponse.statusCode)"])
                onCompletion?(error)
                completionHandler(.cancel)
            }
        } else {
            completionHandler(.allow)
        }
    }
    
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        guard !data.isEmpty else { return }
        onReceive?(data)
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        // 如果错误是 "cancelled"，可能是代码主动断开连接
        if let error = error as NSError?, error.code == NSURLErrorCancelled {
            // 这里可以过滤掉主动取消的错误，或者传递给 Client 由上层决定
        }
        onCompletion?(error)
    }
}
