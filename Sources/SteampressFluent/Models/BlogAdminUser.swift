import Fluent
import Crypto

public struct BlogAdminUser: PostgreSQLMigration {
    
    public static func prepare(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        do {
            let password = try String.random()
            print("Admin's password in \(password)")
            let passwordHash = try BCrypt.hash(password)
            let adminUser = BlogUser(name: "Admin", username: "admin", password: passwordHash, profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil)
            return adminUser.save(on: conn).transform(to: ())
        } catch {
            return conn.future(error: SteamPressFluentError(message: "Failed to create admin user"))
        }
    }
    
    public static func revert(on conn: PostgreSQLConnection) -> EventLoopFuture<Void> {
        return .done(on: conn)
    }
}
