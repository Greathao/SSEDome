import Foundation

/// 健壮的 Server-Sent Events 事件流解析器。
/// 正确处理分片（Chunked Transfer）和 UTF-8 字符序列，避免因 TCP 包边界导致的解析错误。
final class SSEParser {
    
    private var buffer: String = ""
    
    /// 解析接收到的数据块并返回完整的事件列表。
    /// - Parameter chunk: 从网络接收到的原始字符串片段。
    /// - Returns: 本次解析完成的 `SSEEvent` 数组。
    func parse(chunk: String) -> [SSEEvent] {
        buffer += chunk
        
        var events: [SSEEvent] = []
        
        // SSE 消息通过双换行符 (\n\n) 分隔。
        // 我们必须检查缓冲区是否包含完整的消息终止符。
        // 如果 \n\n 还没完全到达，不能在流中间进行分割，需要等待后续数据包。
        
        while let range = buffer.range(of: "\n\n") {
            // 提取完整的一个消息块
            let messageBlock = String(buffer[..<range.lowerBound])
            // 从缓冲区移除该消息块和分隔符
            buffer.removeSubrange(..<range.upperBound)
            
            if let event = parseBlock(messageBlock) {
                events.append(event)
            }
        }
        
        return events
    }
    
    /// 将单个文本块（以 \n\n 分隔）解析为 SSEEvent。
    private func parseBlock(_ block: String) -> SSEEvent? {
        // 跳过空块（通常是保活信号 keep-alive）
        if block.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            return nil
        }
        
        var id: String?
        var eventName = "message"
        var dataLines: [String] = []
        var retry: TimeInterval?
        
        let lines = block.components(separatedBy: "\n")
        
        for line in lines {
            // 忽略以冒号 : 开头的注释行
            if line.hasPrefix(":") { continue }
            
            if line.hasPrefix("data:") {
                let value = line.dropFirst(5) // 移除 "data:"
                // 规范说明：如果值以 U+0020 SPACE 开头，则移除它。
                if value.hasPrefix(" ") {
                    dataLines.append(String(value.dropFirst()))
                } else {
                    dataLines.append(String(value))
                }
            } else if line.hasPrefix("id:") {
                id = line.dropFirst(3).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("event:") {
                eventName = line.dropFirst(6).trimmingCharacters(in: .whitespaces)
            } else if line.hasPrefix("retry:") {
                if let ms = Double(line.dropFirst(6).trimmingCharacters(in: .whitespaces)) {
                    retry = ms / 1000.0
                }
            }
        }
        
        // 如果没有数据，且事件类型是默认的 message，且没有 ID，通常视为无效或仅作为控制信号。
        // 本库确保返回有意义的事件。
        if dataLines.isEmpty && eventName == "message" && id == nil {
            return nil
        }
        
        let dataString = dataLines.joined(separator: "\n")
        return SSEEvent(id: id, event: eventName, data: dataString, retryInterval: retry)
    }
    
    /// 重置解析器状态（清空缓冲区）。
    func reset() {
        buffer = ""
    }
}
