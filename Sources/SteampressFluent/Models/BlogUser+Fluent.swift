import SteamPress
import Fluent

//extension BlogUser: Migration {
//    public static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
//        Database.create(BlogUser.self, on: connection) { builder in
//            builder.field(for: \.userID, isIdentifier: true)
//            builder.field(for: \.name)
//            builder.field(for: \.username)
//            builder.field(for: \.password)
//            builder.field(for: \.resetPasswordRequired)
//            builder.field(for: \.profilePicture)
//            builder.field(for: \.twitterHandle)
//            builder.field(for: \.biography)
//            builder.field(for: \.tagline)
//            builder.unique(on: \.username)
//        }
//    }
//}

//extension BlogUser {
//    var posts: Children<BlogUser, BlogPost> {
//        return children(\.author)
//    }
//}

public final class FluentBlogUser: Model {    
    
    public typealias IDValue = Int
    public static let schema = "BlogUser"
    
    @ID(custom: "userID")
    public var id: Int?
    
    @Field(key: "name")
    public var name: String
    
    @Field(key: "username")
    public var username: String
    
    @Field(key: "password")
    public var password: String
    
    @Field(key: "resetPasswordRequired")
    public var resetPasswordRequired: Bool
    
    @Field(key: "profilePicture")
    public var profilePicture: String?
    
    @Field(key: "twitterHandle")
    public var twitterHandle: String?
    
    @Field(key: "biography")
    public var biography: String?
    
    @Field(key: "tagline")
    public var tagline: String?
    
    public init() {}
    public init(userID: Int?, name: String, username: String, password: String, profilePicture: String?, twitterHandle: String?, biography: String?, tagline: String?) {
        self.id = userID
        self.name = name
        self.username = username.lowercased()
        self.password = password
        self.profilePicture = profilePicture
        self.twitterHandle = twitterHandle
        self.biography = biography
        self.tagline = tagline
    }
}

extension FluentBlogUser {
    func toBlogUser() -> BlogUser {
        return BlogUser(userID: self.id, name: self.name, username: self.username, password: self.password, profilePicture: self.profilePicture, twitterHandle: self.twitterHandle, biography: self.biography, tagline: self.tagline)
    }
}

extension BlogUser {
    func toFluentUser() -> FluentBlogUser {
        return FluentBlogUser(userID: self.userID, name: self.name, username: self.username, password: self.password, profilePicture: self.profilePicture, twitterHandle: self.twitterHandle, biography: self.biography, tagline: self.tagline)
    }
}
