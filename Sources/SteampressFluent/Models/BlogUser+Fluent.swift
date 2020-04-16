import SteamPress
import Fluent

extension BlogUser: Model {
    public typealias ID = Int
    public typealias Database = PostgreSQLDatabase
    public static var idKey: IDKey { return \.userID }
}

extension BlogUser: Migration {
    public static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
        Database.create(BlogUser.self, on: connection) { builder in
            builder.field(for: \.userID, isIdentifier: true)
            builder.field(for: \.name)
            builder.field(for: \.username)
            builder.field(for: \.password)
            builder.field(for: \.resetPasswordRequired)
            builder.field(for: \.profilePicture)
            builder.field(for: \.twitterHandle)
            builder.field(for: \.biography)
            builder.field(for: \.tagline)
            builder.unique(on: \.username)
        }
    }
}

extension BlogUser {
    var posts: Children<BlogUser, BlogPost> {
        return children(\.author)
    }
}
