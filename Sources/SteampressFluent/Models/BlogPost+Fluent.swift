import SteamPress
import Fluent

//extension BlogPost: Model {
//    public typealias ID = Int
//    public typealias Database = PostgreSQLDatabase
//    public static var idKey: IDKey { return \.blogID }
//}

final class FluentBlogPost: Model {
    
    typealias IDValue = Int
    static let schema = "BlogPost"
    
    @ID(custom: "postID")
    var id: Int?
    
    @Field(key: "title")
    var title: String
    
    @Field(key: "contents")
    var contents: String
    
    @Parent(key: "author")
    var author: FluentBlogUser
    
    @Field(key: "created")
    var created: Date
    
    @Field(key: "lastEdited")
    var lastEdited: Date?
    
    @Field(key: "slugUrl")
    var slugUrl: String
    
    @Field(key: "published")
    var published: Bool
    
    @Siblings(through: BlogPostTagPivot.self, from: \.$post, to: \.$tag)
    var tags: [FluentBlogTag]
    
    init() {}
    init(id: Int?, title: String, contents: String, author: Int, creationDate: Date, slugUrl: String,
         published: Bool) {
        self.id = id
        self.title = title
        self.contents = contents
        self.$author.id = author
        self.created = creationDate
        self.slugUrl = slugUrl
        self.lastEdited = nil
        self.published = published
    }
}

extension FluentBlogPost {
    func toBlogPost() -> BlogPost {
        BlogPost(blogID: self.id, title: self.title, contents: self.contents, authorID: self.$author.id, creationDate: self.created, slugUrl: self.slugUrl, published: self.published)
    }
}

extension BlogPost {
    func toFluentPost() -> FluentBlogPost {
        FluentBlogPost(id: self.blogID, title: self.title, contents: self.contents, author: self.author, creationDate: self.created, slugUrl: self.slugUrl, published: self.published)
    }
}

public struct CreateBlogPost: Migration {
    
    public init() {}
    
    public let name = "BlogPost"
    
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("BlogPost")
            .field("postID", .int, .identifier(auto: true))
            .field("title", .string, .required)
            .field("contents", .string, .required)
            .field("author", .int, .required, .references("BlogUser", "userID"))
            .field("created", .datetime, .required)
            .field("lastEdited", .datetime)
            .field("slugUrl", .string, .required)
            .field("published", .bool, .required)
            .unique(on: "slugUrl")
            .create()
    }
    
    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("BlogPost").delete()
    }
}
