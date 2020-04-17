import XCTest
@testable import SteampressFluent
import Vapor
import Fluent

class UserRepositoryTests: XCTestCase {
    
    // MARK: - Properties
    var app: Application!
    var repository: FluentUserRepository!
    
    // MARK: - Overrides
    
    override func setUpWithError() throws {
        app = try TestSetup.getApp()
        repository = FluentUserRepository(database: app.db)
    }
    
    override func tearDownWithError() throws {
        app.shutdown()
    }
    
    // MARK: - Tests
    
    func testSavingUser() throws {
        let newUser = BlogUser(name: "Alice", username: "alice", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil)
        let savedUser = try repository.save(newUser, on: app).wait()
        
        XCTAssertNotNil(savedUser.userID)
        
        let userFromDB = try BlogUser.query(on: app.db).filter(\.userID == savedUser.userID).first().wait()
        XCTAssertEqual(userFromDB?.username, newUser.username)
    }
    
    func testGetingAUserByUsername() throws {
        let username = "alice"
        let newUser = FluentBlogUser(userID: nil, name: "Alice", username: username, password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil)
        try newUser.save(on: app.db).wait()

        let retrievedUser = try repository.getUser(username: username, on: app).wait()

        XCTAssertEqual(retrievedUser?.username, username)
        XCTAssertEqual(retrievedUser?.userID, newUser.userID)
    }
    
    func testGettingAUserByID() throws {
        let newUser = FluentBlogUser(userID: nil, name: "Alice", username: "alice", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil)
        try newUser.save(on: app.db).wait()
        
        let retrievedUser = try repository.getUser(id: newUser.id!).wait()
        
        XCTAssertEqual(retrievedUser?.username, newUser.username)
    }
    
    func testGettingAUserByName() throws {
        let name = "Alice"
        let newUser = FluentBlogUser(userID: nil, name: name, username: "alice", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil)
        try newUser.save(on: app.db).wait()

        let retrievedUser = try repository.getUser(name: name).wait()

        XCTAssertEqual(retrievedUser?.name, name)
        XCTAssertEqual(retrievedUser?.userID, newUser.id)
    }
    
    func testGettingAllUsers() throws {
        let name1 = "Alice"
        let name2 = "Bob"
        try FluentBlogUser(userID: nil, name: name1, username: "alice", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil).save(on: app.db).wait()
        try FluentBlogUser(userID: nil, name: name2, username: "bob", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil).save(on: app.db).wait()
        
        let users = try repository.getAllUsers().wait()

        XCTAssertEqual(users.count, 2)
        XCTAssertEqual(users.first?.name, name1)
        XCTAssertEqual(users.last?.name, name2)
    }
    
    func testUsersCount() throws {
        try FluentBlogUser(userID: nil, name: "Alice", username: "alice", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil).save(on: app.db).wait()
        try FluentBlogUser(userID: nil, name: "Bob", username: "bob", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil).save(on: app.db).wait()
        
        let count = try repository.getUsersCount().wait()
        
        XCTAssertEqual(count, 2)
    }
    
    func testDeletingAUser() throws {
        let user = BlogUser(userID: nil, name: "Alice", username: "alice", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil)
        try user.toFluentUser().save(on: app.db).wait()
        
        let count = try FluentBlogUser.query(on: app.db).count().wait()
        XCTAssertEqual(count, 1)
        
        try repository.delete(user).wait()
        
        let countAfterDelete = try FluentBlogUser.query(on: app.db).count().wait()
        XCTAssertEqual(countAfterDelete, 0)
    }
    
    func testCreatingUserWithExistingUsernameFails() throws {
        let username = "alice"
        var errorOccurred = false
        try FluentBlogUser(userID: nil, name: "Alice", username: username, password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil).save(on: app.db).wait()
        do {
            try FluentBlogUser(userID: nil, name: "Bob", username: username, password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil).save(on: app.db).wait()
        } catch {
            errorOccurred = true
        }
        
        XCTAssertTrue(errorOccurred)
    }
    
    func testGettingUsersWithPostCounts() throws {
        let postAuthor = FluentBlogUser(userID: nil, name: "Alice", username: "alice", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil)
        try postAuthor.save(on: app.db).wait()
        let otherUser = FluentBlogUser(userID: nil, name: "Bob", username: "bob", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil)
        try otherUser.save(on: app.db).wait()
        let newUser = FluentBlogUser(userID: nil, name: "Luke", username: "luke", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil)
        try newUser.save(on: app.db).wait()
        
        try FluentBlogPost(id: nil, title: "A new post", contents: "Some Contents about vapor", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(-360), slugUrl: "a-new-post", published: true).save(on: app.db).wait()
        try FluentBlogPost(id: nil, title: "A different Vapor post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(360), slugUrl: "a-different-post", published: true).save(on: app.db).wait()
        try FluentBlogPost(id: nil, title: "A third post", contents: "Some other contents containing vapor", author: postAuthor.requireID(), creationDate: Date(), slugUrl: "a-third-post", published: true).save(on: app.db).wait()
        try FluentBlogPost(id: nil, title: "A draft Vapor post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(60), slugUrl: "a-draft-post", published: true).save(on: app.db).wait()
        try FluentBlogPost(id: nil, title: "An unrelated draft post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(10), slugUrl: "an-unrelated-draft-post", published: false).save(on: app.db).wait()
        try FluentBlogPost(id: nil, title: "An unrelated post", contents: "Some other contents", author: otherUser.requireID(), creationDate: Date().addingTimeInterval(30), slugUrl: "an-unrelated-post", published: true).save(on: app.db).wait()
        
        let usersWithPostCount = try repository.getAllUsersWithPostCount().wait()
        XCTAssertEqual(usersWithPostCount.count, 3)
        XCTAssertEqual(usersWithPostCount.first?.1, 4)
        XCTAssertEqual(usersWithPostCount.first?.0.username, postAuthor.username)
        XCTAssertEqual(usersWithPostCount.last?.1, 0)
        XCTAssertEqual(usersWithPostCount.last?.0.username, newUser.username)
        XCTAssertEqual(usersWithPostCount[1].0.username, otherUser.username)
        XCTAssertEqual(usersWithPostCount[1].1, 1)
    }
    
    func testAdminUserMigrationsCreatesAdminUser() throws {
        app = try TestSetup.getApp(enableAdminUser: true)
        let user = try XCTUnwrap(FluentBlogUser.query(on: app.db).first().wait())
        XCTAssertEqual(user.username, "admin")
        XCTAssertEqual(user.name, "Admin")
    }
}

