import Fluent
import SteamPress
import Vapor

struct FluentPostgresUserRepository: BlogUserRepository {
    
    let database: Database
    
    func `for`(_ request: Request) -> BlogUserRepository {
        return FluentPostgresUserRepository(database: request.db)
    }
    
    func getAllUsers() -> EventLoopFuture<[BlogUser]> {
        BlogUser.query(on: database).all()
    }
    
    func getAllUsersWithPostCount() -> EventLoopFuture<[(BlogUser, Int)]> {
        let allUsersQuery = BlogUser.query(on: database).all()
        let allPostsQuery = BlogPost.query(on: database).filter(\.$published == true).all()
        return allUsersQuery.and(allPostsQuery).map { users, posts in
            let postsByUserID = [Int: [BlogPost]](grouping: posts, by: { $0[keyPath: \.author] })
            return users.map { user in
                guard let userID = user.userID else {
                    return (user, 0)
                }
                let userPostCount = postsByUserID[userID]?.count ?? 0
                return (user, userPostCount)
            }
        }
    }
    
    func getUser(id: Int) -> EventLoopFuture<BlogUser?> {
        return BlogUser.query(on: database).filter(\.$userID == id).first()
    }
    
    func getUser(name: String) -> EventLoopFuture<BlogUser?> {
        BlogUser.query(on: database).filter(\.$name == name).first()
    }
    
    func getUser(username: String) -> EventLoopFuture<BlogUser?> {
        BlogUser.query(on: database).filter(\.$username == username).first()
    }
    
    func save(_ user: BlogUser) -> EventLoopFuture<BlogUser> {
        user.save(on: database).map { user }
    }
    
    func delete(_ user: BlogUser) -> EventLoopFuture<Void> {
        user.delete(on: database)
    }
    
    func getUsersCount() -> EventLoopFuture<Int> {
        BlogUser.query(on: database).count()
    }
    
    
}
