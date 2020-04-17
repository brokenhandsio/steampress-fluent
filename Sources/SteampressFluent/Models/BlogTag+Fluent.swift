import Fluent
import SteamPress

//extension BlogTag: Model {
//    public typealias ID = Int
//    public typealias Database = PostgreSQLDatabase
//    public static var idKey: IDKey { return \.tagID }
//}

final class FluentBlogTag: Model {
    typealias IDValue = Int
    static let schema = "BlogTag"
    
    @ID(custom: "tagID")
    var id: Int?
    
    @Field(key: "name")
    var name: String
    
    @Siblings(through: BlogPostTagPivot.self, from: \.$tag, to: \.$post)
    var posts: [FluentBlogPost]
    
    init() {}
    init(id: Int?, name: String) {
        self.id = id
        self.name = name
    }
}

//extension BlogTag: Migration {
//    public static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
//        Database.create(BlogTag.self, on: connection) { builder in
//            builder.field(for: \.tagID, isIdentifier: true)
//            builder.field(for: \.name)
//            builder.unique(on: \.name)
//        }
//    }
//}
//
//extension BlogTag {
//    var posts: Siblings<BlogTag, BlogPost, BlogPostTagPivot> {
//        return siblings()
//    }
//}

extension FluentBlogTag {
    func toBlogTag() -> BlogTag {
        BlogTag(id: self.id, name: self.name)
    }
}

extension BlogTag {
    func toFluentBlogTag() -> FluentBlogTag {
        FluentBlogTag(id: self.tagID, name: self.name)
    }
}
