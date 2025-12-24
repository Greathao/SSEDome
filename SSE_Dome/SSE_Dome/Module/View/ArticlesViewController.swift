//
//  ArticlesViewController.swift
//

import UIKit
import RxSwift
import RxCocoa

class ArticlesViewController: UIViewController {

    private let tableView = UITableView()

    // 关键词展示使用水平滚动的 CollectionView
    private let keywordView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 100, height: 30) // ⚠️ 必须设置 itemSize，否则 cell 不显示
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .lightGray
        return cv
    }()

    private let viewModel = ArticlesViewModel()
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white

        // ⚠️ 确保 frame 设置正确
        setupTableView()
        setupKeywordView()

        // ⚠️ 绑定 ViewModel
        bindViewModel()

        // 连接 SSE
        viewModel.connectSSE()
    }

    private func setupTableView() {
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.frame = CGRect(x: 0, y: 0, width: view.bounds.width, height: view.bounds.height/2)
        view.addSubview(tableView)
    }

    private func setupKeywordView() {
        keywordView.register(UICollectionViewCell.self, forCellWithReuseIdentifier: "keywordCell")
        keywordView.frame = CGRect(x: 0, y: view.bounds.height/2, width: view.bounds.width, height: view.bounds.height/2)
        view.addSubview(keywordView)
    }

    private func bindViewModel() {
        // --------------------------
        // 绑定文章列表到 TableView
        // --------------------------
        viewModel.articles
            // ⚠️ 一定使用 cellType，否则 RxCocoa 无法创建 cell
            .bind(to: tableView.rx.items(cellIdentifier: "cell", cellType: UITableViewCell.self)) { index, article, cell in
                cell.textLabel?.text = article.title
            }
            .disposed(by: disposeBag)

        // --------------------------
        // 绑定关键词列表到 CollectionView
        // --------------------------
        viewModel.keywords
            .bind(to: keywordView.rx.items(cellIdentifier: "keywordCell", cellType: UICollectionViewCell.self)) { index, keyword, cell in
                // 清理旧视图 ⚠️
                cell.contentView.subviews.forEach { $0.removeFromSuperview() }

                // 添加 label
                let label = UILabel(frame: cell.contentView.bounds)
                label.text = keyword
                label.textAlignment = .center
                label.font = .systemFont(ofSize: 14)
                label.backgroundColor = .white
                label.layer.cornerRadius = 5
                label.layer.masksToBounds = true
                cell.contentView.addSubview(label)
            }
            .disposed(by: disposeBag)

        // --------------------------
        // 点击文章
        // --------------------------
        tableView.rx.modelSelected(Article.self)
            .subscribe(onNext: { [weak self] article in
                self?.viewModel.sendClickArticle(article)
            })
            .disposed(by: disposeBag)

        // --------------------------
        // 点击关键词
        // --------------------------
        keywordView.rx.modelSelected(String.self)
            .subscribe(onNext: { [weak self] keyword in
                self?.viewModel.sendClickKeyword(keyword)
            })
            .disposed(by: disposeBag)
    }
}
