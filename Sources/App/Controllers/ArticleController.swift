//
//  ArticleController.swift
//  qiita-pocket-API
//
//  Created by hirothings on 2017/08/18.
//
//

import Vapor
import HTTP
import FluentProvider
import Foundation

enum Period: String {
    case week
    case month
}

final class ArticleController {
    
    let drop: Droplet
    let baseURL = "https://qiita.com/api/v2/"
    let maxPage: Int = 100
    let perPage: Int = 100
    var articles: [Article] = []
    
    
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
            .sort(Article.likesCount_key, .descending)
            .limit(20, offset: 1)
            .all()
            .makeJSON()
    }
    
    func create(_ req: Request) throws -> ResponseRepresentable {
        try (1...100).forEach { page throws in
            print("page: \(page)")
            do {
                try self.fetchArticles(page: page, perPage: self.perPage)
            }
            catch {
                drop.log.error(error)
            }
        }
        return "loading.."
    }
    
    
    // MARK: - private
    
    private func fetchArticles(page: Int, perPage: Int) throws {
        let response: Response = try drop.client.get(baseURL + "items", query: [
            "page": page,
            "per_page": perPage
        ], [
            "Authorization": "Bearer f2992b1d5db0954c2537df5ace511b727c9e05ad" // TODO: 後でgit管理外に移す
        ])
        
        guard let jsonArray = response.json?.array else {
            return
        }
        for json in jsonArray {
            let article = try Article(json: json)
            try Article.save(article)
            try saveEntities(itemID: article.itemID, json: json)
        }
    }
    
    private func saveEntities(itemID: String, json: JSON) throws {
        guard
            let article = try Article.makeQuery().filter(Article.itemID_key == itemID).first(),
            let tags = json["tags"]?.array,
            let userJSON = json["user"]
        else {
            return
        }
        
        // user
        let user = try User(
            userID: userJSON.get("id"),
            profileImageURL: userJSON.get(User.profileImageURL_key),
            articleID: article.id!)
        try User.save(user)

        
        // tags
        try tags.forEach { t throws in
            let name: String = try t.get("name")
            let tag = Tag(name: name, articleID: article.id!)
            try Tag.save(tag)
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
            .filter(raw: "created_at between '\(sinceStr)' and '\(nowStr)'")
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
