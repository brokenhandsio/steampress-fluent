import SteamPress
import Fluent
import Foundation

final class BlogPostTagPivot: Model {
    
    #warning("Check this")
    static let schema = "BlogPost_BlogTag"
    
    @ID(key: .id)
    var id: UUID?
    
    @Parent(key: "postID")
    var post: FluentBlogPost
    
    @Parent(key: "tagID")
    var tag: FluentBlogTag
    
    init() {}
    init(blogID: FluentBlogPost.IDValue, tagID: FluentBlogTag.IDValue) {
        self.$post.id = blogID
        self.$tag.id = tagID
    }
}

public struct CreatePostTagPivot: Migration {
    
    public init() {}
    
    #warning("Match name to old migration")
    
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        #warning("Check name")
        return database.schema("BlogPost_BlogTag")
            .id()
            .field("postID", .int, .required, .references("BlogPost", "postID", onDelete: .cascade))
            .field("tagID", .int, .required, .references("BlogTag", "tagID", onDelete: .cascade))
            .create()
    }
    
    public func revert(on database: Database) -> EventLoopFuture<Void> {
        #warning("Check name")
        return database.schema("BlogPost_BlogTag").delete()
    }
}
