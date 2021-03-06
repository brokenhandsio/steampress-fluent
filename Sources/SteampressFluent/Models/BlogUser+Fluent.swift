import SteamPress
import Fluent

final class FluentBlogUser: Model {
    
    typealias IDValue = Int
    static let schema = "BlogUser"
    
    @ID(custom: "userID")
    var id: Int?
    
    @Field(key: "name")
    var name: String
    
    @Field(key: "username")
    var username: String
    
    @Field(key: "password")
    var password: String
    
    @Field(key: "resetPasswordRequired")
    var resetPasswordRequired: Bool
    
    @Field(key: "profilePicture")
    var profilePicture: String?
    
    @Field(key: "twitterHandle")
    var twitterHandle: String?
    
    @Field(key: "biography")
    var biography: String?
    
    @Field(key: "tagline")
    var tagline: String?
    
    @Children(for: \.$author)
    var posts: [FluentBlogPost]
    
    init() {}
    init(userID: Int?, name: String, username: String, password: String, resetPasswordRequired: Bool, profilePicture: String?, twitterHandle: String?, biography: String?, tagline: String?) {
        self.id = userID
        self.name = name
        self.username = username.lowercased()
        self.password = password
        self.resetPasswordRequired = resetPasswordRequired
        self.profilePicture = profilePicture
        self.twitterHandle = twitterHandle
        self.biography = biography
        self.tagline = tagline
    }
}

extension FluentBlogUser {
    func toBlogUser() -> BlogUser {
        return BlogUser(userID: self.id, name: self.name, username: self.username, password: self.password, resetPasswordRequired: self.resetPasswordRequired, profilePicture: self.profilePicture, twitterHandle: self.twitterHandle, biography: self.biography, tagline: self.tagline)
    }
}

extension BlogUser {
    func toFluentUser() -> FluentBlogUser {
        FluentBlogUser(userID: self.userID, name: self.name, username: self.username, password: self.password, resetPasswordRequired: self.resetPasswordRequired, profilePicture: self.profilePicture, twitterHandle: self.twitterHandle, biography: self.biography, tagline: self.tagline)
    }
}

public struct CreateBlogUser: Migration {
    
    public init() {}
    
    public let name = "BlogUser"
    
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        database.schema("BlogUser")
            .field("userID", .int, .identifier(auto: true))
            .field("name", .string, .required)
            .field("username", .string, .required)
            .field("password", .string, .required)
            .field("resetPasswordRequired", .bool, .required)
            .field("profilePicture", .string)
            .field("twitterHandle", .string)
            .field("biography", .string)
            .field("tagline", .string)
            .unique(on: "username")
            .create()
    }
    
    public func revert(on database: Database) -> EventLoopFuture<Void> {
        database.schema("BlogUser").delete()
    }
}
