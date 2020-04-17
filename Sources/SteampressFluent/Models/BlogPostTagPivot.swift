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

//extension BlogPostTagPivot: Migration {
//    public static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
//        Database.create(BlogPostTagPivot.self, on: connection) { builder in
//            builder.field(for: \.id, isIdentifier: true)
//            builder.field(for: \.postID)
//            builder.field(for: \.tagID)
//            builder.reference(from: \.postID, to: \BlogPost.blogID, onDelete: .cascade)
//            builder.reference(from: \.tagID, to: \BlogTag.tagID, onDelete: .cascade)
//        }
//    }
//}
