import Fluent
import SteamPress
import Vapor

struct FluentTagRepository: BlogTagRepository {
    
    let database: Database
    
    func `for`(_ request: Request) -> BlogTagRepository {
        return FluentTagRepository(database: request.db)
    }
    
    func getAllTags() -> EventLoopFuture<[BlogTag]> {
        FluentBlogTag.query(on: database).all().map { $0.map { $0.toBlogTag() }}
    }
    
    func getAllTagsWithPostCount() -> EventLoopFuture<[(BlogTag, Int)]> {
        let allTagsQuery = FluentBlogTag.query(on: database).all()
        let allPivotsQuery = BlogPostTagPivot.query(on: database).all()
        return allTagsQuery.and(allPivotsQuery).flatMapThrowing { tags, pivots in
            return try tags.map { tag in
                let postCount = try pivots.filter { try $0.$tag.id == tag.requireID() }.count
                return (tag.toBlogTag(), postCount)
            }
        }
    }
    
    func getTagsForAllPosts() -> EventLoopFuture<[Int : [BlogTag]]> {
        let allTagsQuery = FluentBlogTag.query(on: database).all()
        let allPivotsQuery = BlogPostTagPivot.query(on: database).all()
        return allTagsQuery.and(allPivotsQuery).map { tags, pivots in
            let pivotsSortedByPost = Dictionary(grouping: pivots) { (pivot) -> Int in
                return pivot.$post.id
            }
            
            let postsWithTags = pivotsSortedByPost.mapValues { value in
                return value.map { pivot in
                    tags.first { $0.id == pivot.$tag.id }
                }
            }.mapValues { $0.compactMap { $0?.toBlogTag() } }
            
            return postsWithTags
        }
    }
    
    func getTags(for post: BlogPost) -> EventLoopFuture<[BlogTag]> {
        let fluentPost = post.toFluentPost()
        return fluentPost.$tags.query(on: database).all().map { fluentTags in
            fluentTags.map { $0.toBlogTag() }
        }
    }
    
    func getTag(_ name: String) -> EventLoopFuture<BlogTag?> {
        FluentBlogTag.query(on: database).filter(\.$name == name).first().map { $0?.toBlogTag() }
    }
    
    func save(_ tag: BlogTag) -> EventLoopFuture<BlogTag> {
        let fluentTag = tag.toFluentBlogTag()
        return fluentTag.save(on: database).map { fluentTag.toBlogTag() }
    }
    
    func deleteTags(for post: BlogPost) -> EventLoopFuture<Void> {
        let fluentPost = post.toFluentPost()
        return fluentPost.$tags.query(on: database).all().flatMap { tags in
            let tagIDs = tags.compactMap { $0.id }
            do {
                let postID = try fluentPost.requireID()
                return BlogPostTagPivot.query(on: self.database).filter(\.$post.$id == postID).filter(\.$tag.$id ~~ tagIDs).delete().flatMap { _ in
                    self.cleanupTags(on: self.database, tags: tags)
                }
            } catch {
                return self.database.eventLoop.makeFailedFuture(error)
            }
        }
    }
    
    func remove(_ tag: BlogTag, from post: BlogPost) -> EventLoopFuture<Void> {
        let fluentPost = post.toFluentPost()
        let fluentTag = tag.toFluentBlogTag()
        return fluentPost.$tags.detach(fluentTag, on: database).flatMap {
            self.cleanupTags(on: self.database, tags: [fluentTag])
        }
    }
    
    func cleanupTags(on database: Database, tags: [FluentBlogTag]) -> EventLoopFuture<Void> {
        var tagCleanups = [EventLoopFuture<Void>]()
        for tag in tags {
            let tagCleanup: EventLoopFuture<Void> = tag.$posts.query(on: database).all().flatMap { posts in
                let cleanupFuture: EventLoopFuture<Void>
                if posts.count == 0 {
                    cleanupFuture = tag.delete(on: database)
                } else {
                    cleanupFuture = database.eventLoop.future()
                }
                return cleanupFuture
            }
            tagCleanups.append(tagCleanup)
        }
        return tagCleanups.flatten(on: database.eventLoop)
    }
    
    func add(_ tag: BlogTag, to post: BlogPost) -> EventLoopFuture<Void> {
        let fluentPost = post.toFluentPost()
        fluentPost.$id.exists = true
        let fluentTag = tag.toFluentBlogTag()
        fluentTag.$id.exists = true
        return fluentPost.$tags.attach(fluentTag, on: database).transform(to: ())
    }
    
}
