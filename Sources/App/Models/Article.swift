//
//  Article.swift
//  qiita-pocket-API
//
//  Created by hirothings on 2017/08/17.
//
//

import Vapor
import FluentProvider
import HTTP
import Foundation

final class Article: Model {
    var storage: Storage = Storage()
    
    static let idType: IdentifierType = .int
    var title: String
    let itemID: String
    let createdAt: String
    let url: String
    var likesCount: Int = 0
    var user: Children<Article, User> {
        return children()
    }
    var tags: Children<Article, Tag> {
        return children()
    }
    
    static let title_key: String = "title"
    static let itemID_key: String = "item_id"
    static let createdAt_key: String = "created_at"
    static let url_key: String = "url"
    static let likesCount_key: String = "likes_count"
    static let user_key: String = "user"
    static let tags_key: String = "tags"
    
    init(
        title: String,
        itemID: String,
        createdAt: String,
        url: String,
        likesCount: Int
        ) {
        self.title = title
        self.itemID = itemID
        self.createdAt = createdAt
        self.url = url
        self.likesCount = likesCount
    }
    
    init(row: Row) throws {
        self.title = try row.get(Article.title_key)
        self.itemID = try row.get(Article.itemID_key)
        self.createdAt = try row.get(Article.createdAt_key)
        self.url = try row.get(Article.url_key)
        self.likesCount = try row.get(Article.likesCount_key)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Article.title_key, title)
        try row.set(Article.itemID_key, itemID)
        try row.set(Article.createdAt_key, createdAt)
        try row.set(Article.url_key, url)
        try row.set(Article.likesCount_key, likesCount)
        return row
    }
}

extension Article: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { (builder: Creator) in
            builder.id()
            builder.string(Article.title_key)
            builder.string(Article.itemID_key)
            builder.string(Article.createdAt_key)
            builder.string(Article.url_key)
            builder.int(Article.likesCount_key)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension Article: JSONConvertible {
    convenience init(json: JSON) throws {
        try self.init(
            title: json.get(Article.title_key),
            itemID: json.get("id"),
            createdAt: json.get(Article.createdAt_key),
            url: json.get(Article.url_key),
            likesCount: json.get(Article.likesCount_key)
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(Article.title_key, title)
        try json.set(Article.createdAt_key, createdAt)
        try json.set(Article.url_key, url)
        try json.set(Article.user_key, try user.first())
        try json.set(Article.tags_key, try tags.all())
        try json.set(Article.likesCount_key, likesCount)
        return json
    }
}

extension Article {
    static func save(_ article: Article) {
        if let existedArticle = try! Article.makeQuery().filter(Article.itemID_key == article.itemID).first() {
            existedArticle.title = article.title
            existedArticle.likesCount = article.likesCount
            try! existedArticle.save()
        }
        else {
            try! article.save()
        }
    }
}

