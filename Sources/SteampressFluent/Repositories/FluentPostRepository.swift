import Fluent
import SteamPress
import Vapor

struct FluentPostRepository: BlogPostRepository {
    
    let database: Database
    
    func `for`(_ request: Request) -> BlogPostRepository {
        return FluentPostRepository(database: request.db)
    }
    
    func getAllPostsSortedByPublishDate(includeDrafts: Bool) -> EventLoopFuture<[BlogPost]> {
        let query = BlogPost.query(on: database).sort(\.created, .descending)
        if !includeDrafts {
            query.filter(\.published == true)
        }
        return query.all()
    }
    
    func getAllPostsSortedByPublishDate(includeDrafts: Bool, count: Int, offset: Int) -> EventLoopFuture<[BlogPost]> {
        let query = BlogPost.query(on: database).sort(\.created, .descending)
        if !includeDrafts {
            query.filter(\.published == true)
        }
        let upperLimit = count + offset
        return query.range(offset..<upperLimit).all()
    }
    
    func getAllPostsCount(includeDrafts: Bool) -> EventLoopFuture<Int> {
        let query = BlogPost.query(on: database)
        if !includeDrafts {
            query.filter(\.published == true)
        }
        return query.count()
    }
    
    func getAllPostsSortedByPublishDate(for user: BlogUser, includeDrafts: Bool, count: Int, offset: Int) -> EventLoopFuture<[BlogPost]> {
        let query = try user.posts.query(on: database).sort(\.created, .descending)
        if !includeDrafts {
            query.filter(\.published == true)
        }
        let upperLimit = count + offset
        return query.range(offset..<upperLimit).all()
    }
    
    func getPostCount(for user: BlogUser) -> EventLoopFuture<Int> {
        try user.posts.query(on: database).filter(\.published == true).count()
    }
    
    func getPost(slug: String) -> EventLoopFuture<BlogPost?> {
        BlogPost.query(on: database).filter(\.slugUrl == slug).first()
    }
    
    func getPost(id: Int) -> EventLoopFuture<BlogPost?> {
        BlogPost.query(on: database).filter(\.blogID == id).first()
    }
    
    func getSortedPublishedPosts(for tag: BlogTag, count: Int, offset: Int) -> EventLoopFuture<[BlogPost]> {
        let query = try tag.posts.query(on: database).filter(\.published == true).sort(\.created, .descending)
        let upperLimit = count + offset
        return query.range(offset..<upperLimit).all()
    }
    
    func getPublishedPostCount(for tag: BlogTag) -> EventLoopFuture<Int> {
        return try tag.posts.query(on: database).filter(\.published == true).count()
    }
    
    func findPublishedPostsOrdered(for searchTerm: String, count: Int, offset: Int) -> EventLoopFuture<[BlogPost]> {
        let query = BlogPost.query(on: database).sort(\.created, .descending).filter(\.published == true)
        
        let upperLimit = count + offset
        let paginatedQuery = query.range(offset..<upperLimit)
        
        return paginatedQuery.group(.or) { or in
            or.filter(\.title, .ilike, "%\(searchTerm)%")
            or.filter(\.contents, .ilike, "%\(searchTerm)%")
        }.all()
    }
    
    func getPublishedPostCount(for searchTerm: String) -> EventLoopFuture<Int> {
        BlogPost.query(on: database).filter(\.published == true).group(.or) { or in
            or.filter(\.title, .ilike, "%\(searchTerm)%")
            or.filter(\.contents, .ilike, "%\(searchTerm)%")
        }.count()
    }
    
    func save(_ post: BlogPost) -> EventLoopFuture<BlogPost> {
        post.save(on: database)
    }
    
    func delete(_ post: BlogPost) -> EventLoopFuture<Void> {
        post.delete(on: database)
    }
    
}

