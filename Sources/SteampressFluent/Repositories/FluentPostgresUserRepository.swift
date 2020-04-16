import FluentPostgreSQL
import SteamPress
import Vapor

struct FluentPostgresUserRepository: BlogUserRepository, Service {
    
    func getAllUsers(on container: Container) -> EventLoopFuture<[BlogUser]> {
        container.withPooledConnection(to: .psql) { connection in
            BlogUser.query(on: connection).all()
        }
    }
    
    func getAllUsersWithPostCount(on container: Container) -> EventLoopFuture<[(BlogUser, Int)]> {
        container.withPooledConnection(to: .psql) { connection in
            let allUsersQuery = BlogUser.query(on: connection).all()
            let allPostsQuery = BlogPost.query(on: connection).filter(\.published == true).all()
            return map(allUsersQuery, allPostsQuery) { users, posts in
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
    }
    
    func getUser(id: Int, on container: Container) -> EventLoopFuture<BlogUser?> {
        return container.withPooledConnection(to: .psql) { connection in
            return BlogUser.query(on: connection).filter(\.userID == id).first()
        }
    }
    
    func getUser(name: String, on container: Container) -> EventLoopFuture<BlogUser?> {
        container.withPooledConnection(to: .psql) { connection in
            BlogUser.query(on: connection).filter(\.name == name).first()
        }
    }
    
    func getUser(username: String, on container: Container) -> EventLoopFuture<BlogUser?> {
        container.withPooledConnection(to: .psql) { connection in
            BlogUser.query(on: connection).filter(\.username == username).first()
        }
    }
    
    func save(_ user: BlogUser, on container: Container) -> EventLoopFuture<BlogUser> {
        container.withPooledConnection(to: .psql) { connection in
            user.save(on: connection)
        }
    }
    
    func delete(_ user: BlogUser, on container: Container) -> EventLoopFuture<Void> {
        container.withPooledConnection(to: .psql) { connection in
            user.delete(on: connection)
        }
    }
    
    func getUsersCount(on container: Container) -> EventLoopFuture<Int> {
        container.withPooledConnection(to: .psql) { connection in
            BlogUser.query(on: connection).count()
        }
    }
    
    
}
