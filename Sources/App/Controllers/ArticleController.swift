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
    
    init(droplet: Droplet) {
        drop = droplet
    }
    

    func index(_ req: Request) throws -> ResponseRepresentable {
        return try Article.all().makeJSON()
    }
    
    func create(_ req: Request) throws -> ResponseRepresentable {
        // Qiitaの投稿を生成
        
        return "success"
    }
    
    
    // MARK: - private
    
    private func fedtchArticles(page: Int, perPage: Int) throws -> [Article] {
        let response: Response = try drop.client.get("https://qiita.com/api/v2/items", query: [
            "page": page,
            "per_page": perPage
            ])
        guard let jsonArray = response.json?.array else {
            throw Abort.badRequest
        }
        for json in jsonArray {
            let article = try Article(json: json)
            articles.append(article)
        }
        return articles
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
