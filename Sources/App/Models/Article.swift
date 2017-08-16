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
    
    var title: String
    var profileImageURL: String
    var url: String
    //    var stockCount: Int
    
    static let title_key: String = "title"
    static let profileImageURL_key: String = "profile_image_url"
    static let url_key: String = "url"
    //    static let stockCount_key: String = "stock_count"
    
    init(
        title: String,
        profileImageURL: String,
        url: String
        //        stockCount: Int
        ) {
        self.title = title
        self.profileImageURL = profileImageURL
        self.url = url
        //        self.stockCount = stockCount
    }
    
    init(row: Row) throws {
        self.title = try row.get(Article.title_key)
        self.profileImageURL = try row.get(Article.profileImageURL_key)
        self.url = try row.get(Article.url_key)
        //        self.stockCount = try row.get(Article.stockCount_key)
    }
    
    func makeRow() throws -> Row {
        var row = Row()
        try row.set(Article.title_key, title)
        try row.set(Article.profileImageURL_key, profileImageURL)
        try row.set(Article.url_key, url)
        //        try row.set(Article.stockCount_key, stockCount)
        return row
    }
}

extension Article: Preparation {
    static func prepare(_ database: Database) throws {
        try database.create(self) { (builder: Creator) in
            builder.id()
            builder.string(Article.title_key)
            builder.string(Article.profileImageURL_key)
            builder.string(Article.url_key)
            //            builder.string(Article.stockCount_key)
        }
    }
    
    static func revert(_ database: Database) throws {
        try database.delete(self)
    }
}

