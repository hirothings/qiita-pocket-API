//
//  Tag.swift
//  qiita-pocket-API
//
//  Created by hirothings on 2017/08/18.
//
//

import Vapor
import FluentProvider
import HTTP

final class Tag: Model {
    let storage = Storage()
    let name: String
    let articleID: Identifier
    
    // parent relation
    var article: Parent<Tag, Article> {
        return parent(id: articleID)
    }
    
    static let name_key: String = "name"
    static let articleID_key = "article_id"
    
    init(name: String, articleID: Identifier) {
        self.name = name
        self.articleID = articleID
    }
    
    init(row: Row) throws {
        name = try row.get(Tag.name_key)
        articleID = try row.get(Tag.articleID_key)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Tag.name_key, name)
        try row.set(Tag.articleID_key, articleID)
        return row
    }
}

extension Tag: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.foreignKey(Tag.articleID_key, references: Article.idKey, on: Article.self)
            builder.string(Tag.name_key)
            builder.parent(Article.self)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension Tag: JSONRepresentable {
    // Qiita APIの構造に合わせてDictionaryにする
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set("name", self.name)
        
        return json
    }
}


