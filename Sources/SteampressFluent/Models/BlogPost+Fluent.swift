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

//extension BlogPost: Migration {
//    public static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
//        Database.create(BlogPost.self, on: connection) { builder in
//            builder.field(for: \.blogID, isIdentifier: true)
//            builder.field(for: \.title)
//            builder.field(for: \.contents)
//            builder.field(for: \.author)
//            builder.field(for: \.created)
//            builder.field(for: \.lastEdited)
//            builder.field(for: \.slugUrl)
//            builder.field(for: \.published)
//            builder.unique(on: \.slugUrl)
//            builder.reference(from: \.author, to: \BlogUser.userID)
//        }
//    }
//}
//
//extension BlogPost {
//    var tags: Siblings<BlogPost, BlogTag, BlogPostTagPivot> {
//        return siblings()
//    }
//}
