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
    var articles: [Article] = []
    
    private var bag: DisposeBag! = DisposeBag()
    
    init(droplet: Droplet) {
        drop = droplet
    }
    

    func index(_ req: Request) throws -> ResponseRepresentable {
        return try Article.all().makeJSON()
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
        let response: Response = try! drop.client.get("https://qiita.com/api/v2/items", query: [
            "page": page,
            "per_page": perPage
            ])
        print("-- response --")
        print(response.description)
        print("-- /response --")
        guard let jsonArray = response.json?.array else {
            return
        }
        for json in jsonArray {
            saveEntities(json)
        }
    }
    
    private func saveEntities(_ json: JSON) {
        let article = try! Article(json: json)
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
