import Foundation
import RxSwift
import RxRelay

class ArticlesViewModel {

    private let disposeBag = DisposeBag()
    let articles = BehaviorRelay<[Article]>(value: [])
    let keywords = BehaviorRelay<[String]>(value: [])

    func connectSSE() {
        guard let url = URL(string: "http://localhost:3000/sse") else {
            print("[SSE] Invalid URL")
            return
        }

        print("[SSE] Connecting to \(url.absoluteString)")

        RxSSE.connect(url: url)
            .observe(on: MainScheduler.instance) // 主线程更新 UI
            .subscribe(onNext: { [weak self] event in
                print("[SSE] Received event: \(event.event), data: \(event.data)")

                switch event.event {
                case "article_list":
                    if let data = event.data.data(using: .utf8) {
                        do {
                            let list = try JSONDecoder().decode([Article].self, from: data)
                            self?.articles.accept(list)
                            print("[SSE] Updated articles: \(list.map { $0.title })")
                        } catch {
                            print("[SSE] Failed to decode articles: \(error)")
                        }
                    }
                case "keyword":
                    if let data = event.data.data(using: .utf8) {
                        do {
                            let kws = try JSONDecoder().decode([String].self, from: data)
                            self?.keywords.accept(kws)
                            print("[SSE] Updated keywords: \(kws)")
                        } catch {
                            print("[SSE] Failed to decode keywords: \(error)")
                        }
                    }
                default:
                    print("[SSE] Unknown event: \(event.event)")
                }
            }, onError: { error in
                print("[SSE] Error: \(error)")
            }, onCompleted: {
                print("[SSE] Connection closed")
            })
            .disposed(by: disposeBag)
    }

    func sendClickArticle(_ article: Article) {
        print("[SSE] Send clickArticle for id: \(article.id)")
        guard let url = URL(string: "http://localhost:3000/clickArticle") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["articleId": article.id])
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("[SSE] clickArticle request error: \(error)")
            } else {
                print("[SSE] clickArticle request sent, response: \(response.debugDescription)")
            }
        }.resume()
    }

    func sendClickKeyword(_ keyword: String) {
        print("[SSE] Send clickKeyword: \(keyword)")
        guard let url = URL(string: "http://localhost:3000/clickKeyword") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try? JSONEncoder().encode(["keyword": keyword])
        URLSession.shared.dataTask(with: request) { _, response, error in
            if let error = error {
                print("[SSE] clickKeyword request error: \(error)")
            } else {
                print("[SSE] clickKeyword request sent, response: \(response.debugDescription)")
            }
        }.resume()
    }
}
