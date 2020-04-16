import SteamPress
import Fluent

//extension BlogUser: Migration {
//    static func prepare(on connection: PostgreSQLConnection) -> EventLoopFuture<Void> {
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
    
    init() {}
    init(userID: Int?, name: String, username: String, password: String, profilePicture: String?, twitterHandle: String?, biography: String?, tagline: String?) {
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
