SSEKit - Enterprise Grade Server-Sent Events Client for Swift

SSEKit 是一个纯 Swift 编写的、健壮的、企业级 Server-Sent Events (SSE) 客户端库。它旨在解决实际生产环境中遇到的复杂网络问题，如 TCP 分包处理、自动重连退避算法、心跳检测以及线程安全。

✨ 核心特性

健壮的解析器: 能够正确处理 TCP 分包（Chunked Transfer）和 UTF-8 多字节字符被截断的情况。

企业级重连策略: 内置指数退避（Exponential Backoff）算法，包含随机抖动（Jitter），防止惊群效应。

线程安全: 内部使用专用串行队列管理状态，确保在多线程环境下的安全性。

自动心跳检测: 支持客户端侧心跳检测，防止僵尸连接。

断点续传: 自动处理 Last-Event-ID，支持连接恢复。

RxSwift 支持: 提供 RxSSE 模块，轻松集成响应式编程。
 

🚀 快速开始

1. 基础连接

最简单的用法只需要提供一个 URL：

import SSEKit

// 创建配置
let url = URL(string: "http://localhost:3000/sse")! // 指向本地测试服务
let config = SSEConfig.default(url: url)

// 初始化客户端
let client = SSEClient(config: config)

// 监听事件
client.onEvent = { event in
    print("收到事件: \(event.event)")
    print("数据: \(event.data)")
    
    // 如果需要解析 JSON
    // struct MyModel: Decodable { ... }
    // if let model = try? event.decode(MyModel.self) { ... }
}

// 监听状态变化
client.onStateChange = { state in
    switch state {
    case .connecting: print("正在连接...")
    case .open:       print("连接成功！")
    case .closed:     print("连接关闭")
    default: break
    }
}

// 开始连接
client.connect()

// 断开连接
// client.disconnect()


2. 高级配置（鉴权与重连）

SSEKit 允许高度定制化配置，包括 HTTP Headers、超时时间和重连策略：

let config = SSEConfig(
    url: URL(string: "[https://api.example.com/v1/stream](https://api.example.com/v1/stream)")!,
    headers: [
        "Authorization": "Bearer YOUR_TOKEN",
        "X-Custom-Header": "Value"
    ],
    timeoutInterval: .infinity,
    enableAutoReconnect: true,
    // 使用指数退避策略：初始等待1秒，最大等待30秒，指数增长
    reconnectPolicy: ExponentialBackoffPolicy(initialInterval: 1.0, maxInterval: 30.0),
    enableHeartbeat: true,
    heartbeatTimeout: 60.0
)

let client = SSEClient(config: config)
client.connect()


🛠 RxSwift 集成

如果你使用 RxSwift，RxSSE 模块提供了一个极其简洁的 API：

import SSEKit
import RxSwift

let disposeBag = DisposeBag()

RxSSE.connect(url: URL(string: "http://localhost:3000/sse")!)
    .subscribe(onNext: { event in
        print("RxEvent: \(event.data)")
    }, onError: { error in
        print("Error: \(error)")
    })
    .disposed(by: disposeBag)


🖥 服务端测试环境 (Node.js)

为了验证客户端功能，你可以使用提供的 sse-server 搭建一个本地 SSE 服务端。

1. 环境准备

确保已安装 Node.js。

2. 目录结构

确保你的 sse-server 目录包含以下文件：

sse-server/
├── package.json
└── server.js


3. 安装依赖与启动

在终端中进入 sse-server 目录并执行以下命令：

# 1. 安装依赖 (express, cors)
npm install express cors

# 2. 启动服务
node server.js


成功启动后，控制台将显示：
SSE server running at http://localhost:3000/sse

4. 接口说明

该测试服务包含以下交互逻辑，可用于测试 SSEKit 的事件接收和业务流程：

GET /sse: 建立 SSE 长连接。

行为: 连接建立成功后，服务端会自动发送初始的 article_list 事件。

POST /clickArticle: 模拟点击文章。

参数: { "articleId": 1 }

行为: 触发此接口后，服务端会向所有连接的客户端广播 keyword 事件。

POST /clickKeyword: 模拟点击关键词。

参数: { "keyword": "Swift" }

行为: 触发此接口后，服务端会向所有连接的客户端广播新的 article_list 事件。

🏗 架构设计

SSEKit 采用模块化设计，代码结构清晰：

Core:

SSEClient: 核心控制器，管理状态机和业务逻辑。

SSEParser: 基于流的解析器，处理原始数据块。

SSEConfig: 配置对象。

Transport:

SSESession: URLSession 的封装，处理底层网络流。

SSEReconnectPolicy: 重连算法协议（提供 Fixed 和 ExponentialBackoff 实现）。

Protocol:

SSEEvent: 事件模型。

SSEPayload: 辅助协议，用于 Codable 扩展。

为什么不用简单的 String.split？

许多简单的 SSE 实现直接使用 data.components(separatedBy: "\n\n") 处理数据。这种方法在生产环境中是不可靠的。

当网络数据包被 TCP 拆分时（例如一个完整的 JSON 被分在两个包里传输），简单的字符串分割会导致 JSON 解析失败。SSEKit 的 SSEParser 维护了一个内部缓冲区，只有在检测到完整的消息边界（\n\n）时才进行解析，确保数据完整性。

📄 License

SSEKit is released under the MIT license. See LICENSE for details.