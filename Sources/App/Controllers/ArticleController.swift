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

final class ArticleController {
    
    let drop: Droplet
    let baseURL = "https://qiita.com/api/v2/"
    var articles: [Article] = []
    
    private var bag: DisposeBag! = DisposeBag()
    
    init(droplet: Droplet) {
        drop = droplet
    }
    
    func index(_ req: Request) throws -> ResponseRepresentable {
        guard let period = req.query?["period"]?.string else {
            throw Abort.badRequest
        }
        let tag = req.query?["tag"]?.string ?? ""
        return "request: \(period), \(tag)"
    }
    
    func create(_ req: Request) throws -> ResponseRepresentable {
        let interval = Observable<Int>.interval(3, scheduler: SerialDispatchQueueScheduler(qos: .default))
        let maxPage: Int = 2
        
        interval
            .subscribe(onNext: {
                let page = $0 + 1
                print("page: \(page)")
                self.fetchArticles(page: page, perPage: 1)
                if page == maxPage {
                    dump(self.articles)
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
        let response: Response = try! drop.client.get(baseURL + "items/\(article.itemID))/stockers", query: [
            "page": page,
            "per_page": perPage
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
}


extension ArticleController: ResourceRepresentable {
    func makeResource() -> Resource<Article> {
        return Resource(
            index: index,
            create: create
        )
    }
}
