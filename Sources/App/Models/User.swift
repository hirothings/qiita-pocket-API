//
//  User.swift
//  qiita-pocket-API
//
//  Created by hirothings on 2017/09/10.
//
//

import Vapor
import FluentProvider
import Foundation

final class User: Model {
    let storage = Storage()
    let userID: String
    let profileImageURL: String
    let articleID: Identifier
    
    // parent relation
    var article: Parent<User, Article> {
        return parent(id: articleID)
    }
    
    static let userID_key: String = "user_id"
    static let profileImageURL_key: String = "profile_image_url"
    static let articleID_key = "article_id"
    
    init(
        userID: String,
        profileImageURL: String,
        articleID: Identifier
    ) {
        self.userID = userID
        self.profileImageURL = profileImageURL
        self.articleID = articleID
    }
    
    init(row: Row) throws {
        self.userID = try row.get(User.userID_key)
        self.profileImageURL = try row.get(User.profileImageURL_key)
        self.articleID = try row.get(User.articleID_key)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(User.userID_key, userID)
        try row.set(User.profileImageURL_key, profileImageURL)
        try row.set(User.articleID_key, articleID)
        return row
    }
}

extension User: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { (builder: Creator) in
            builder.id()
            builder.foreignKey(User.articleID_key, references: Article.idKey, on: Article.self)
            builder.string(User.userID_key)
            builder.string(User.profileImageURL_key)
            builder.parent(Article.self)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

extension User: JSONRepresentable {
    func makeJSON() throws -> JSON {
        var json = JSON()
        try json.set("id", self.userID)
        try json.set(User.profileImageURL_key, self.profileImageURL)
        
        return json
    }
}
