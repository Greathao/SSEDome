// server.js
const express = require('express');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

let clients = [];

// SSE 连接
app.get('/sse', (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');

  // 保存客户端
  clients.push(res);

  // 首次发送文章列表
  sendEvent(res, 'article_list', [
    { id: 1, title: "文章 1", content: "内容 1" },
    { id: 2, title: "文章 2", content: "内容 2" }
  ]);

  // 关闭连接时移除客户端
  req.on('close', () => {
    clients = clients.filter(c => c !== res);
  });
});

// 点击文章 -> 返回关键词
app.post('/clickArticle', (req, res) => {
  const { articleId } = req.body;
  const keywords = ["Swift", "RxSwift", "SSE"];

  clients.forEach(client => {
    sendEvent(client, 'keyword', keywords);
  });

  res.json({ status: "ok" });
});

// 点击关键词 -> 返回相关文章
app.post('/clickKeyword', (req, res) => {
  const { keyword } = req.body;

  const articles = [
    { id: 101, title: `关于 ${keyword} 的文章 1`, content: "..." },
    { id: 102, title: `关于 ${keyword} 的文章 2`, content: "..." }
  ];

  clients.forEach(client => {
    sendEvent(client, 'article_list', articles);
  });

  res.json({ status: "ok" });
});

// 发送 SSE 事件
function sendEvent(client, event, data) {
  client.write(`event: ${event}\n`);
  client.write(`data: ${JSON.stringify(data)}\n\n`);
}

// 启动服务
app.listen(3000, () => {
  console.log('SSE server running at http://localhost:3000/sse');
});
