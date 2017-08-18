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
    static let name_key: String = "name"
    
    init(name: String, articleID: Identifier) {
        self.name = name
        self.articleID = articleID
    }
    
    init(row: Row) throws {
        name = try row.get(Tag.name_key)
        articleID = try row.get(Article.articleID_key)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Tag.name_key, name)
        try row.set(Article.articleID_key, articleID)
        return row
    }
}

extension Tag: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { builder in
            builder.id()
            builder.foreignKey(Article.articleID_key, references: Article.idKey, on: Article.self)
            builder.string(Tag.name_key)
            builder.string(Article.articleID_key)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}
