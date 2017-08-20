import Vapor
import RxSwift

extension Droplet {
    func setupRoutes() throws {
        let articles = ArticleController(droplet: self)
        
        get("articles", handler: articles.index)
        post("articles", handler: articles.create)
        post("stockers", handler: articles.stockers)
    }
}
