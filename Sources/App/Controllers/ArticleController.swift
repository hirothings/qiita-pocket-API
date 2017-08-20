//
//  ArticleController.swift
//  qiita-pocket-API
//
//  Created by hirothings on 2017/08/18.
//
//

import Vapor
import HTTP
import RxSwift
import FluentProvider
import Foundation

enum Period: String {
    case week
    case month
}

final class ArticleController {
    
    let drop: Droplet
    let baseURL = "https://qiita.com/api/v2/"
    let maxPage: Int = 3
    let periodSec: RxTimeInterval = 5.0
    var articles: [Article] = []
    
    private var bag: DisposeBag! = DisposeBag()
    
    init(droplet: Droplet) {
        drop = droplet
    }
    
    func index(_ req: Request) throws -> ResponseRepresentable {
        guard let _period = req.query?["period"]?.string, let period = Period(rawValue: _period) else {
            throw Abort.badRequest
        }
        var articles: Query<Article> = try searchArticles(within: period)
        if let tag = req.query?["tag"]?.string {
            articles = try searchArticles(with: tag, articles: articles)
        }
        return try articles
            .sort(Article.stockCount_key, .descending)
            .all()
            .makeJSON()
    }
    
    func create(_ req: Request) throws -> ResponseRepresentable {
        let interval = Observable<Int>.interval(periodSec, scheduler: SerialDispatchQueueScheduler(qos: .default))
        
        interval
            .subscribe(onNext: {
                let page = $0 + 1
                print("page: \(page)")
                self.fetchArticles(page: page, perPage: 100)
                if page == self.maxPage {
                    print("complete")
                    self.bag = nil
                }
            })
            .disposed(by: bag)
        
        return "success"
    }
    
    
    // MARK: - private
    
    private func fetchArticles(page: Int, perPage: Int) {
        let response: Response = try! drop.client.get(baseURL + "items", query: [
            "page": page,
            "per_page": perPage
        ], [
            "Authorization": "Bearer f2992b1d5db0954c2537df5ace511b727c9e05ad" // TODO: 後でgit管理外に移す
        ])
        
        guard let jsonArray = response.json?.array else {
            return
        }
        for json in jsonArray {
            let article = try! Article(json: json)
            var page = 1
            var stockCount = 0
            while true {
                let tuple = fetchStockCount(page: page, perPage: 100, article: article)
                stockCount += tuple.count
                page += 1
                if !tuple.hasNextPage { break }
            }
            article.stockCount = stockCount
            saveEntities(article, json: json)
        }
    }
    
    private func fetchStockCount(page: Int, perPage: Int, article: Article) -> (count: Int, hasNextPage: Bool) {
        let response: Response = try! drop.client.get(baseURL + "items/\(article.itemID)/stockers", query: [
            "page": page,
            "per_page": perPage
        ], [
            "Authorization": "Bearer f2992b1d5db0954c2537df5ace511b727c9e05ad" // TODO: 後でgit管理外に移す
        ])
        
        print("-- response --")
        print(response.description)
        print("-- /response --")
        
        guard let json = response.json?.array else {
            return (0, false)
        }
        let linkHeader = response.headers["Link"]!
        return (json.count, linkHeader.contains("rel=\"next\""))
    }
    
    private func saveEntities(_ article: Article, json: JSON) {
        try! article.save()
        guard let tags = json["tags"]?.array else {
            return
        }
        tags.forEach { t in
            let name: String = try! t.get("name")
            let tag = Tag(name: name, articleID: article.id!)
            try! tag.save()
        }
    }
    
    private func searchArticles(within period: Period) throws -> Query<Article> {
        var since: Date
        let calender = Calendar.current
        switch period {
        case .week:
            since = Date(timeInterval: -60*60*24*7, since: Date())
        case .month:
            since = calender.date(byAdding: .month, value: -1, to: Date())!
        }
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZZZZZ"
        let sinceStr = formatter.string(from: since)
        let now = Date()
        let nowStr = formatter.string(from: now)
        
        return try Article
            .makeQuery()
            .filter(raw: "published_at between '\(sinceStr)' and '\(nowStr)'")
    }
    
    private func searchArticles(with tag: String, articles: Query<Article>) throws -> Query<Article> {
        return try articles
            .makeQuery()
            .join(Tag.self) // 子ModelのTagとJoin
            .filter(raw: "upper(`tags`.`name`) = upper('\(tag)')") // 大文字・個別の区別をなくすためにsqliteのupper関数を使う
    }
}


extension ArticleController: ResourceRepresentable {
    func makeResource() -> Resource<Article> {
        return Resource(
            index: index,
            create: create
        )
    }
}
