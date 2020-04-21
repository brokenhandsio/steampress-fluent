import Fluent
import SteamPress
import Vapor

struct FluentTagRepository: BlogTagRepository {
    
    let database: Database
    let databaseType: SteamPressFluentDatabase
    
    func `for`(_ request: Request) -> BlogTagRepository {
        return FluentTagRepository(database: request.db, databaseType: request.application.steampress.fluent.database)
    }
    
    func getAllTags() -> EventLoopFuture<[BlogTag]> {
        FluentBlogTag.query(on: database).all().map { $0.map { $0.toBlogTag() }}
    }
    
    func getAllTagsWithPostCount() -> EventLoopFuture<[(BlogTag, Int)]> {
        let allTagsQuery = FluentBlogTag.query(on: database).all()
        let allPivotsQuery = BlogPostTagPivot.query(on: database).all()
        return allTagsQuery.and(allPivotsQuery).flatMapThrowing { tags, pivots in
            var tags = tags
            if self.databaseType == .mysql {
                tags.reverse()
            }
            
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
        guard let postID = post.blogID else {
            return database.eventLoop.makeFailedFuture(FluentError.idRequired)
        }
        return FluentBlogTag.query(on: database).join(BlogPostTagPivot.self, on: \FluentBlogTag.$id == \BlogPostTagPivot.$tag.$id).filter(BlogPostTagPivot.self, \BlogPostTagPivot.$post.$id == postID).all().map { fluentTags in
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
        guard let postID = post.blogID else {
            return database.eventLoop.makeFailedFuture(FluentError.idRequired)
        }
        return FluentBlogTag.query(on: database).join(BlogPostTagPivot.self, on: \FluentBlogTag.$id == \BlogPostTagPivot.$tag.$id).filter(BlogPostTagPivot.self, \BlogPostTagPivot.$post.$id == postID).all().flatMap { tags in
            let tagIDs = tags.compactMap { $0.id }
            return BlogPostTagPivot.query(on: self.database).filter(\.$post.$id == postID).filter(\.$tag.$id ~~ tagIDs).delete().flatMap { _ in
                self.cleanupTags(on: self.database, tags: tags)
            }
        }
    }
    
    func remove(_ tag: BlogTag, from post: BlogPost) -> EventLoopFuture<Void> {
        guard let tagID = tag.tagID, let postID = post.blogID else {
            return database.eventLoop.makeFailedFuture(FluentError.idRequired)
        }
        return BlogPostTagPivot.query(on: database).filter(\.$post.$id == postID).filter(\.$tag.$id == tagID).delete().flatMap {
            self.cleanupTags(on: self.database, tags: [tag.toFluentBlogTag()])
        }
    }
    
    func cleanupTags(on database: Database, tags: [FluentBlogTag]) -> EventLoopFuture<Void> {
        var tagCleanups = [EventLoopFuture<Void>]()
        for tag in tags {
            guard let tagID = tag.id else {
                return database.eventLoop.makeFailedFuture(FluentError.idRequired)
            }
            
            let tagCleanup: EventLoopFuture<Void> =
                FluentBlogPost.query(on: database)
                    .join(BlogPostTagPivot.self, on: \FluentBlogPost.$id == \BlogPostTagPivot.$post.$id)
                    .filter(BlogPostTagPivot.self, \BlogPostTagPivot.$tag.$id == tagID)
                    .all()
                    .flatMap { posts in
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
        guard let postID = post.blogID, let tagID = tag.tagID else {
            return database.eventLoop.makeFailedFuture(FluentError.idRequired)
        }
        let pivot = BlogPostTagPivot(blogID: postID, tagID: tagID)
        return pivot.save(on: database)
    }
    
}
