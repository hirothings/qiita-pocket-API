import Vapor
import RxSwift
import Jobs

extension Droplet {
    func setupRoutes() throws {
        let articles = ArticleController(droplet: self)
        
        get("articles", handler: articles.index)
        post("articles", handler: articles.create)
        post("stockers", handler: articles.stockers)
        
        get("jobs") { request in
            Jobs.add(interval: .seconds(2)) {
                print("👋 I'm printed every 2 seconds!")
            }
            return "Hello"
        }
    }
}
