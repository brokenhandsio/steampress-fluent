import FluentPostgreSQL
import SteamPress

struct FluentPostgresPostRepository: BlogPostRepository, Service {
    
    func getAllPostsSortedByPublishDate(includeDrafts: Bool, on container: Container) -> EventLoopFuture<[BlogPost]> {
        container.withPooledConnection(to: .psql) { connection in
            let query = BlogPost.query(on: connection).sort(\.created, .descending)
            if !includeDrafts {
                query.filter(\.published == true)
            }
            return query.all()
        }
    }
    
    func getAllPostsSortedByPublishDate(includeDrafts: Bool, on container: Container, count: Int, offset: Int) -> EventLoopFuture<[BlogPost]> {
        container.withPooledConnection(to: .psql) { connection in
            let query = BlogPost.query(on: connection).sort(\.created, .descending)
            if !includeDrafts {
                query.filter(\.published == true)
            }
            let upperLimit = count + offset
            return query.range(offset..<upperLimit).all()
        }
    }
    
    func getAllPostsCount(includeDrafts: Bool, on container: Container) -> EventLoopFuture<Int> {
        container.withPooledConnection(to: .psql) { connection in
            let query = BlogPost.query(on: connection)
            if !includeDrafts {
                query.filter(\.published == true)
            }
            return query.count()
        }
    }
    
    func getAllPostsSortedByPublishDate(for user: BlogUser, includeDrafts: Bool, on container: Container, count: Int, offset: Int) -> EventLoopFuture<[BlogPost]> {
        container.withPooledConnection(to: .psql) { connection in
            let query = try user.posts.query(on: connection).sort(\.created, .descending)
            if !includeDrafts {
                query.filter(\.published == true)
            }
            let upperLimit = count + offset
            return query.range(offset..<upperLimit).all()
        }
    }
    
    func getPostCount(for user: BlogUser, on container: Container) -> EventLoopFuture<Int> {
        container.withPooledConnection(to: .psql) { connection in
            try user.posts.query(on: connection).filter(\.published == true).count()
        }
    }
    
    func getPost(slug: String, on container: Container) -> EventLoopFuture<BlogPost?> {
        container.withPooledConnection(to: .psql) { connection in
            BlogPost.query(on: connection).filter(\.slugUrl == slug).first()
        }
    }
    
    func getPost(id: Int, on container: Container) -> EventLoopFuture<BlogPost?> {
        container.withPooledConnection(to: .psql) { connection in
            BlogPost.query(on: connection).filter(\.blogID == id).first()
        }
    }
    
    func getSortedPublishedPosts(for tag: BlogTag, on container: Container, count: Int, offset: Int) -> EventLoopFuture<[BlogPost]> {
        container.withPooledConnection(to: .psql) { connection in
            let query = try tag.posts.query(on: connection).filter(\.published == true).sort(\.created, .descending)
            let upperLimit = count + offset
            return query.range(offset..<upperLimit).all()
        }
    }
    
    func getPublishedPostCount(for tag: BlogTag, on container: Container) -> EventLoopFuture<Int> {
        container.withPooledConnection(to: .psql) { connection in
            return try tag.posts.query(on: connection).filter(\.published == true).count()
        }
    }
    
    func findPublishedPostsOrdered(for searchTerm: String, on container: Container, count: Int, offset: Int) -> EventLoopFuture<[BlogPost]> {
        container.withPooledConnection(to: .psql) { connection in
            let query = BlogPost.query(on: connection).sort(\.created, .descending).filter(\.published == true)
            
            let upperLimit = count + offset
            let paginatedQuery = query.range(offset..<upperLimit)
                
            return paginatedQuery.group(.or) { or in
                or.filter(\.title, .ilike, "%\(searchTerm)%")
                or.filter(\.contents, .ilike, "%\(searchTerm)%")
            }.all()
        }
    }
    
    func getPublishedPostCount(for searchTerm: String, on container: Container) -> EventLoopFuture<Int> {
        container.withPooledConnection(to: .psql) { connection in
            BlogPost.query(on: connection).filter(\.published == true).group(.or) { or in
                or.filter(\.title, .ilike, "%\(searchTerm)%")
                or.filter(\.contents, .ilike, "%\(searchTerm)%")
            }.count()
        }
    }
    
    func save(_ post: BlogPost, on container: Container) -> EventLoopFuture<BlogPost> {
        container.withPooledConnection(to: .psql) { connection in
            post.save(on: connection)
        }
    }
    
    func delete(_ post: BlogPost, on container: Container) -> EventLoopFuture<Void> {
        container.withPooledConnection(to: .psql) { connection in
            post.delete(on: connection)
        }
    }
    
}

