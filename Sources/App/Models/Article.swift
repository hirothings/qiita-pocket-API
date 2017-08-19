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

final class Article: Model {
    var storage: Storage = Storage()
    
    static let idType: IdentifierType = .int
    let itemID: String
    let title: String
    let profileImageURL: String
    let url: String
    var stockCount: Int = 0
    var tags: Children<Article, Tag> {
        return children()
    }
    
    static let title_key: String = "title"
    static let itemID_key: String = "item_id"
    static let profileImageURL_key: String = "profile_image_url"
    static let url_key: String = "url"
    static let stockCount_key: String = "stock_count"
    static let tags_key: String = "tags"
    
    init(
        title: String,
        itemID: String,
        profileImageURL: String,
        url: String
        ) {
        self.title = title
        self.itemID = itemID
        self.profileImageURL = profileImageURL
        self.url = url
    }
    
    init(row: Row) throws {
        self.title = try row.get(Article.title_key)
        self.itemID = try row.get(Article.itemID_key)
        self.profileImageURL = try row.get(Article.profileImageURL_key)
        self.url = try row.get(Article.url_key)
        self.stockCount = try row.get(Article.stockCount_key)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Article.title_key, title)
        try row.set(Article.itemID_key, itemID)
        try row.set(Article.profileImageURL_key, profileImageURL)
        try row.set(Article.url_key, url)
        try row.set(Article.stockCount_key, stockCount)
        return row
    }
}

extension Article: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { (builder: Creator) in
            builder.id()
            builder.string(Article.title_key)
            builder.string(Article.itemID_key)
            builder.string(Article.profileImageURL_key)
            builder.string(Article.url_key)
            builder.string(Article.stockCount_key)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension Article: JSONConvertible {
    convenience init(json: JSON) throws {
        let user = try User(node: json["user"])
        try self.init(
            title: json.get(Article.title_key),
            itemID: json.get("id"),
            profileImageURL: user.profileImageURL,
            url: json.get(Article.url_key)
        )
    }
    
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set(Article.title_key, title)
        try json.set(Article.profileImageURL_key, profileImageURL)
        try json.set(Article.url_key, url)
        try json.set(Article.tags_key, try tags.all().flatMap { t in t.name } )
        try json.set(Article.stockCount_key, stockCount)
        return json
    }
}


final class User: NodeInitializable {
    var profileImageURL: String
    
    init(node: Node) throws {
        self.profileImageURL = try node.get(Article.profileImageURL_key)
    }
}

