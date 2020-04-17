import Fluent
import SteamPress
import Vapor

struct FluentPostRepository: BlogPostRepository {
    
    let database: Database
    
    func `for`(_ request: Request) -> BlogPostRepository {
        return FluentPostRepository(database: request.db)
    }
    
    func getAllPostsSortedByPublishDate(includeDrafts: Bool) -> EventLoopFuture<[BlogPost]> {
        let query = FluentBlogPost.query(on: database).sort(\.$created, .descending)
        if !includeDrafts {
            query.filter(\.$published == true)
        }
        return query.all().map { $0.map { $0.toBlogPost() }}
    }
    
    func getAllPostsSortedByPublishDate(includeDrafts: Bool, count: Int, offset: Int) -> EventLoopFuture<[BlogPost]> {
        let query = FluentBlogPost.query(on: database).sort(\.$created, .descending)
        if !includeDrafts {
            query.filter(\.$published == true)
        }
        let upperLimit = count + offset
        return query.range(offset..<upperLimit).all().map { $0.map { $0.toBlogPost() }}
    }
    
    func getAllPostsCount(includeDrafts: Bool) -> EventLoopFuture<Int> {
        let query = FluentBlogPost.query(on: database)
        if !includeDrafts {
            query.filter(\.$published == true)
        }
        return query.count()
    }
    
    func getAllPostsSortedByPublishDate(for user: BlogUser, includeDrafts: Bool, count: Int, offset: Int) -> EventLoopFuture<[BlogPost]> {
        guard let authorID = user.userID else {
            return database.eventLoop.makeFailedFuture(FluentError.idRequired)
        }
        let query = FluentBlogPost.query(on: database).filter(\.$author.$id == authorID).sort(\.$created, .descending)
        if !includeDrafts {
            query.filter(\.$published == true)
        }
        let upperLimit = count + offset
        return query.range(offset..<upperLimit).all().map { $0.map { $0.toBlogPost() }}
    }
    
    func getPostCount(for user: BlogUser) -> EventLoopFuture<Int> {
        let fluentUser = user.toFluentUser()
        return fluentUser.$posts.query(on: database).filter(\.$published == true).count()
    }
    
    func getPost(slug: String) -> EventLoopFuture<BlogPost?> {
        FluentBlogPost.query(on: database).filter(\.$slugUrl == slug).first().map { $0?.toBlogPost() }
    }
    
    func getPost(id: Int) -> EventLoopFuture<BlogPost?> {
        FluentBlogPost.query(on: database).filter(\.$id == id).first().map { $0?.toBlogPost() }
    }
    
    func getSortedPublishedPosts(for tag: BlogTag, count: Int, offset: Int) -> EventLoopFuture<[BlogPost]> {
        let fluentTag = tag.toFluentBlogTag()
        let query = fluentTag.$posts.query(on: database).filter(\.$published == true).sort(\.$created, .descending)
        let upperLimit = count + offset
        return query.range(offset..<upperLimit).all().map { $0.map { $0.toBlogPost() }}
    }
    
    func getPublishedPostCount(for tag: BlogTag) -> EventLoopFuture<Int> {
        let fluentTag = tag.toFluentBlogTag()
        return fluentTag.$posts.query(on: database).filter(\.$published == true).count()
    }
    
    func findPublishedPostsOrdered(for searchTerm: String, count: Int, offset: Int) -> EventLoopFuture<[BlogPost]> {
        let query = FluentBlogPost.query(on: database).sort(\.$created, .descending).filter(\.$published == true)
        
        let upperLimit = count + offset
        let paginatedQuery = query.range(offset..<upperLimit)
        
        return paginatedQuery.group(.or) { or in
            or.filter(\.$title, .custom("ilike"), "%\(searchTerm)%")
            or.filter(\.$contents, .custom("ilike"), "%\(searchTerm)%")
//            or.filter(\.$contents, .ilike, "%\(searchTerm)%")
        }.all().map { $0.map { $0.toBlogPost() }}
    }
    
    func getPublishedPostCount(for searchTerm: String) -> EventLoopFuture<Int> {
        FluentBlogPost.query(on: database).filter(\.$published == true).group(.or) { or in
            or.filter(\.$title, .custom("ilike"), "%\(searchTerm)%")
            or.filter(\.$contents, .custom("ilike"), "%\(searchTerm)%")
        }.count()
    }
    
    func save(_ post: BlogPost) -> EventLoopFuture<BlogPost> {
        let fluentPost = post.toFluentPost()
        return fluentPost.save(on: database).map { fluentPost.toBlogPost() }
    }
    
    func delete(_ post: BlogPost) -> EventLoopFuture<Void> {
        let fluentPost = post.toFluentPost()
        return fluentPost.delete(on: database)
    }
    
}

