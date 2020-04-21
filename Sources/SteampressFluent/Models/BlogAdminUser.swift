import Fluent
import Vapor

public struct BlogAdminUser: Migration {
    
    public init() {}
    
    public let name = "BlogAdminUser"
    
    public func prepare(on database: Database) -> EventLoopFuture<Void> {
        do {
            let password = try String.random()
            database.logger.notice("Admin's password is \(password)")
            let passwordHash = try BCryptDigest().hash(password)
            let adminUser = FluentBlogUser(userID: nil, name: "Admin", username: "admin", password: passwordHash, resetPasswordRequired: false, profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil)
            return adminUser.save(on: database)
        } catch {
            return database.eventLoop.makeFailedFuture(error)
        }
    }
    
    public func revert(on database: Database) -> EventLoopFuture<Void> {
        return database.eventLoop.future()
    }
}
