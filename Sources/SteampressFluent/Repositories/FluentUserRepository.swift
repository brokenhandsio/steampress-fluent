import Fluent
import SteamPress
import Vapor

struct FluentUserRepository: BlogUserRepository {
    
    let database: Database
    
    func `for`(_ request: Request) -> BlogUserRepository {
        return FluentUserRepository(database: request.db)
    }
    
    func getAllUsers() -> EventLoopFuture<[BlogUser]> {
        FluentBlogUser.query(on: database).all().map { $0.map { $0.toBlogUser() }}
    }
    
    func getAllUsersWithPostCount() -> EventLoopFuture<[(BlogUser, Int)]> {
        let allUsersQuery = FluentBlogUser.query(on: database).all()
        let allPostsQuery = FluentBlogPost.query(on: database).filter(\.$published == true).all()
        return allUsersQuery.and(allPostsQuery).map { users, posts in
            let postsByUserID = [Int: [FluentBlogPost]](grouping: posts, by: { $0[keyPath: \.$author.id] })
            return users.map { user in
                guard let userID = user.id else {
                    return (user.toBlogUser(), 0)
                }
                let userPostCount = postsByUserID[userID]?.count ?? 0
                return (user.toBlogUser(), userPostCount)
            }
        }
    }
    
    func getUser(id: Int) -> EventLoopFuture<BlogUser?> {
        return FluentBlogUser.query(on: database).filter(\.$id == id).first().map { $0?.toBlogUser() }
    }
    
    func getUser(name: String) -> EventLoopFuture<BlogUser?> {
        FluentBlogUser.query(on: database).filter(\.$name == name).first().map { $0?.toBlogUser() }
    }
    
    func getUser(username: String) -> EventLoopFuture<BlogUser?> {
        FluentBlogUser.query(on: database).filter(\.$username == username).first().map { $0?.toBlogUser() }
    }
    
    func save(_ user: BlogUser) -> EventLoopFuture<BlogUser> {
        let fluentUser = user.toFluentUser()
        return fluentUser.save(on: database).map { fluentUser.toBlogUser() }
    }
    
    func delete(_ user: BlogUser) -> EventLoopFuture<Void> {
        let fluentUser = user.toFluentUser()
        return fluentUser.delete(on: database)
    }
    
    func getUsersCount() -> EventLoopFuture<Int> {
        FluentBlogUser.query(on: database).count()
    }
    
    
}
