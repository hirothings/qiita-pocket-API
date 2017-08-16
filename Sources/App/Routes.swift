import Vapor

extension Droplet {
    func setupRoutes() throws {

        get("articles/new") { req in
            // Qiitaの投稿を取得
            return "success"
        }
        
        get("articles") { req in
            let articles = try Article.makeQuery().all()
            var json = JSON()
            try json.set("articles", articles)
            return json
        }
    }
}
