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
        return allTagsQuery.and(allPivotsQuery).map { tags, pivots in
            return try tags.map { tag in
                let postCount = try pivots.filter { try $0.tagID == tag.requireID() }.count
                return (tag, postCount)
            }
        }
    }
    
    func getTagsForAllPosts() -> EventLoopFuture<[Int : [BlogTag]]> {
        let allTagsQuery = FluentBlogTag.query(on: database).all()
        let allPivotsQuery = BlogPostTagPivot.query(on: database).all()
        return allTagsQuery.and(allPivotsQuery).map { tags, pivots in
            let pivotsSortedByPost = Dictionary(grouping: pivots) { (pivot) -> Int in
                return pivot.postID
            }
            
            let postsWithTags = pivotsSortedByPost.mapValues { value in
                return value.map { pivot in
                    tags.first { $0.tagID == pivot.tagID }
                }
            }.mapValues { $0.compactMap { $0 } }
            
            return postsWithTags
        }
    }
    
    func getTags(for post: BlogPost) -> EventLoopFuture<[BlogTag]> {
        try post.tags.query(on: database).all()
    }
    
    func getTag(_ name: String) -> EventLoopFuture<BlogTag?> {
        FluentBlogTag.query(on: database).filter(\.$name == name).first().map { $0?.toBlogTag() }
    }
    
    func save(_ tag: BlogTag) -> EventLoopFuture<BlogTag> {
        let fluentTag = tag.toFluentBlogTag()
        return fluentTag.save(on: database).map { fluentTag.toBlogTag() }
    }
    
    func deleteTags(for post: BlogPost) -> EventLoopFuture<Void> {
        try post.tags.query(on: database).all().flatMap { tags in
            let tagIDs = tags.compactMap { $0.tagID }
            return try BlogPostTagPivot.query(on: database).filter(\.postID == post.requireID()).filter(\.tagID ~~ tagIDs).delete().flatMap { _ in
                try self.cleanupTags(on: database, tags: tags)
            }
        }
    }
    
    func remove(_ tag: BlogTag, from post: BlogPost) -> EventLoopFuture<Void> {
        post.tags.detach(tag, on: database).flatMap {
            try self.cleanupTags(on: database, tags: [tag])
        }
    }
    
    func cleanupTags(on database: Database, tags: [BlogTag]) throws -> EventLoopFuture<Void> {
        var tagCleanups = [EventLoopFuture<Void>]()
        for tag in tags {
            let tagCleanup = try tag.posts.query(on: database).all().flatMap(to: Void.self) { posts in
                let cleanupFuture: EventLoopFuture<Void>
                if posts.count == 0 {
                    cleanupFuture = tag.delete(on: database)
                } else {
                    cleanupFuture = database.future()
                }
                return cleanupFuture
            }
            tagCleanups.append(tagCleanup)
        }
        return tagCleanups.flatten(on: database.eventLoop)
    }
    
    func add(_ tag: BlogTag, to post: BlogPost) -> EventLoopFuture<Void> {
        post.tags.attach(tag, on: database).transform(to: ())
    }
    
}
