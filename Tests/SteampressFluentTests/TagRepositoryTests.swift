import XCTest
@testable import SteampressFluent
import Vapor
import Fluent

class TagRepositoryTests: XCTestCase {
    
    // MARK: - Properties
    var app: Application!
    var connection: PostgreSQLConnection!
    var repository = FluentPostgresTagRepository()
    
    // MARK: - Overrides
    
    override func setUp() {
        app = try! TestSetup.getApp()
        connection = try! app.requestPooledConnection(to: .psql).wait()
    }
    
    override func tearDown() {
        try! app.releasePooledConnection(connection, to: .psql)
    }
    
    // MARK: - Tests
    
    func testSavingTag() throws {
        let newTag = BlogTag(name: "SteamPress")
        let savedTag = try repository.save(newTag, on: app).wait()
        
        XCTAssertNotNil(savedTag.tagID)
        
        let tagFromDB = try BlogTag.query(on: connection).filter(\.tagID == savedTag.tagID).first().wait()
        XCTAssertEqual(tagFromDB?.name, newTag.name)
    }
    
    func testGetingATag() throws {
        let tagName = "Engineering"
        let tag = BlogTag(name: tagName)
        _ = try tag.save(on: connection).wait()
        
        let retrievedTag = try repository.getTag(tagName, on: app).wait()
        
        XCTAssertEqual(retrievedTag?.name, tagName)
        XCTAssertEqual(retrievedTag?.tagID, tag.tagID)
    }
    
    func testGettingAllTags() throws {
        let tagName1 = "Engineering"
        let tagName2 = "SteamPress"
        _ = try BlogTag(name: tagName1).save(on: connection).wait()
        _ = try BlogTag(name: tagName2).save(on: connection).wait()
        
        let tags = try repository.getAllTags(on: app).wait()
        
        XCTAssertEqual(tags.count, 2)
        XCTAssertEqual(tags.first?.name, tagName1)
        XCTAssertEqual(tags.last?.name, tagName2)
    }
    
    func testErrorOccursWhenSavingATagWithNameThatAlreadyExists() throws {
        let tagName = "SteamPress"
        var errorOccurred = false
        _ = try BlogTag(name: tagName).save(on: connection).wait()
        do {
            _ = try BlogTag(name: tagName).save(on: connection).wait()
        } catch {
            errorOccurred = true
        }
        
        XCTAssertTrue(errorOccurred)
    }
    
    func testAddingTagToPost() throws {
        let tag = try BlogTag(name: "SteamPress").save(on: connection).wait()
        let user = try BlogUser(name: "Alice", username: "alice", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil).save(on: connection).wait()
        let post = try BlogPost(title: "A Post", contents: "Some contents", author: user, creationDate: Date(), slugUrl: "a-post", published: true).save(on: connection).wait()
        
        try repository.add(tag, to: post, on: app).wait()
        
        let tagLinks = try BlogPostTagPivot.query(on: connection).all().wait()
        XCTAssertEqual(tagLinks.count, 1)
        XCTAssertEqual(tagLinks.first?.tagID, tag.tagID)
        XCTAssertEqual(tagLinks.first?.postID, post.blogID)
    }
    
    func testRemovingTagFromPost() throws {
        let tag = try BlogTag(name: "SteamPress").save(on: connection).wait()
        let tag2 = try BlogTag(name: "Testing").save(on: connection).wait()
        let user = try BlogUser(name: "Alice", username: "alice", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil).save(on: connection).wait()
        let post = try BlogPost(title: "A Post", contents: "Some contents", author: user, creationDate: Date(), slugUrl: "a-post", published: true).save(on: connection).wait()
        _ = try post.tags.attach(tag, on: connection).wait()
        _ = try post.tags.attach(tag2, on: connection).wait()
        
        try repository.remove(tag, from: post, on: app).wait()
        
        let tagLinks = try BlogPostTagPivot.query(on: connection).all().wait()
        XCTAssertEqual(tagLinks.count, 1)
        
        let allTags = try BlogTag.query(on: connection).all().wait()
        XCTAssertEqual(allTags.count, 1)
        XCTAssertEqual(allTags.first?.name, tag2.name)
    }
    
    func testGettingTagsForPost() throws {
        let tag1 = try BlogTag(name: "SteamPress").save(on: connection).wait()
        let tag2 = try BlogTag(name: "Engineering").save(on: connection).wait()
        let user = try BlogUser(name: "Alice", username: "alice", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil).save(on: connection).wait()
        let post = try BlogPost(title: "A Post", contents: "Some contents", author: user, creationDate: Date(), slugUrl: "a-post", published: true).save(on: connection).wait()
        
        _ = try post.tags.attach(tag1, on: connection).wait()
        _ = try post.tags.attach(tag2, on: connection).wait()
        
        let postTags =  try repository.getTags(for: post, on: app).wait()
        XCTAssertEqual(postTags.count, 2)
        XCTAssertEqual(postTags.first?.name, tag1.name)
        XCTAssertEqual(postTags.last?.name, tag2.name)
    }
    
    func testDeletingTagsForPost() throws {
        let tag1 = try BlogTag(name: "SteamPress").save(on: connection).wait()
        let tag2 = try BlogTag(name: "Engineering").save(on: connection).wait()
        let user = try BlogUser(name: "Alice", username: "alice", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil).save(on: connection).wait()
        let post = try BlogPost(title: "A Post", contents: "Some contents", author: user, creationDate: Date(), slugUrl: "a-post", published: true).save(on: connection).wait()
        
        _ = try post.tags.attach(tag1, on: connection).wait()
        _ = try post.tags.attach(tag2, on: connection).wait()
        
        try repository.deleteTags(for: post, on: app).wait()
        
        let tagCount = try BlogTag.query(on: connection).count().wait()
        XCTAssertEqual(tagCount, 0)
        
        let pivotCount = try BlogPostTagPivot.query(on: connection).count().wait()
        XCTAssertEqual(pivotCount, 0)
    }
    
    func testDeletingTagsForPostDoesntDeleteTagIfItsAttachedToAnotherPost() throws {
        let tag1 = try BlogTag(name: "SteamPress").save(on: connection).wait()
        let tag2 = try BlogTag(name: "Engineering").save(on: connection).wait()
        let user = try BlogUser(name: "Alice", username: "alice", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil).save(on: connection).wait()
        let post = try BlogPost(title: "A Post", contents: "Some contents", author: user, creationDate: Date(), slugUrl: "a-post", published: true).save(on: connection).wait()
        let post2 = try BlogPost(title: "Another Post", contents: "Some other contents", author: user, creationDate: Date(), slugUrl: "another-post", published: true).save(on: connection).wait()
        
        _ = try post.tags.attach(tag1, on: connection).wait()
        _ = try post.tags.attach(tag2, on: connection).wait()
        _ = try post2.tags.attach(tag2, on: connection).wait()
        
        try repository.deleteTags(for: post, on: app).wait()
        
        let tagCount = try BlogTag.query(on: connection).count().wait()
        XCTAssertEqual(tagCount, 1)
        
        let pivotCount = try BlogPostTagPivot.query(on: connection).count().wait()
        XCTAssertEqual(pivotCount, 1)
    }
    
    func testGettingAllTagsWithPostCount() throws {
        let tag1 = try BlogTag(name: "SteamPress").save(on: connection).wait()
        let tag2 = try BlogTag(name: "Engineering").save(on: connection).wait()
        let user = try BlogUser(name: "Alice", username: "alice", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil).save(on: connection).wait()
        let post1 = try BlogPost(title: "A Post", contents: "Some contents", author: user, creationDate: Date(), slugUrl: "a-post", published: true).save(on: connection).wait()
        let post2 = try BlogPost(title: "A Second Post", contents: "Some contents", author: user, creationDate: Date(), slugUrl: "a-second-post", published: true).save(on: connection).wait()
        let post3 = try BlogPost(title: "A Third Post", contents: "Some contents", author: user, creationDate: Date(), slugUrl: "a-third-post", published: true).save(on: connection).wait()
        
        _ = try post1.tags.attach(tag1, on: connection).wait()
        _ = try post2.tags.attach(tag2, on: connection).wait()
        _ = try post3.tags.attach(tag1, on: connection).wait()
        
        let tagsWithPostCount = try repository.getAllTagsWithPostCount(on: app).wait()
        
        XCTAssertEqual(tagsWithPostCount.count, 2)
        XCTAssertEqual(tagsWithPostCount.first?.0.name, tag1.name)
        XCTAssertEqual(tagsWithPostCount.first?.1, 2)
        XCTAssertEqual(tagsWithPostCount.last?.0.name, tag2.name)
        XCTAssertEqual(tagsWithPostCount.last?.1, 1)
    }
    
    func testGettingAllTagsWithPostID() throws {
        let tag1 = try BlogTag(name: "SteamPress").save(on: connection).wait()
        let tag2 = try BlogTag(name: "Engineering").save(on: connection).wait()
        let user = try BlogUser(name: "Alice", username: "alice", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil).save(on: connection).wait()
        let post1 = try BlogPost(title: "A Post", contents: "Some contents", author: user, creationDate: Date(), slugUrl: "a-post", published: true).save(on: connection).wait()
        let post2 = try BlogPost(title: "A Second Post", contents: "Some contents", author: user, creationDate: Date(), slugUrl: "a-second-post", published: true).save(on: connection).wait()
        let post3 = try BlogPost(title: "A Third Post", contents: "Some contents", author: user, creationDate: Date(), slugUrl: "a-third-post", published: true).save(on: connection).wait()
        
        _ = try post1.tags.attach(tag1, on: connection).wait()
        _ = try post2.tags.attach(tag2, on: connection).wait()
        _ = try post3.tags.attach(tag1, on: connection).wait()
        
        let tagsWithPosts = try repository.getTagsForAllPosts(on: app).wait()
        
        XCTAssertEqual(tagsWithPosts[post1.blogID!]?.count, 1)
        XCTAssertEqual(tagsWithPosts[post1.blogID!]?.first?.name, tag1.name)
        XCTAssertEqual(tagsWithPosts[post2.blogID!]?.count, 1)
        XCTAssertEqual(tagsWithPosts[post2.blogID!]?.first?.name, tag2.name)
        XCTAssertEqual(tagsWithPosts[post3.blogID!]?.count, 1)
        XCTAssertEqual(tagsWithPosts[post3.blogID!]?.first?.name, tag1.name)
    }
}
