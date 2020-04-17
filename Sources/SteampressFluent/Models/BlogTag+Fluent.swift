import Fluent
import SteamPress

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

public struct CreateBlogTag: Migration {
    
    public init() {}
    
    #warning("Match name to old migration")
    
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("BlogTag")
            .id()
            .field("name", .string, .required)
            .unique(on: "name")
            .create()
    }
    
    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("BlogTag").delete()
    }
}

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
