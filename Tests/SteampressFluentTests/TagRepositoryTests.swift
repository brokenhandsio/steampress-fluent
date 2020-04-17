import XCTest
@testable import SteampressFluent
import Vapor
import Fluent

class TagRepositoryTests: XCTestCase {
    
    // MARK: - Properties
    var app: Application!
    var repository: FluentTagRepository!
    
    // MARK: - Overrides
    
    override func setUpWithError() throws {
        app = try! TestSetup.getApp()
        repository = FluentTagRepository(database: app.db)
    }
    
    override func tearDownWithError() throws {
        app.shutdown()
    }
    
    // MARK: - Tests
    
    func testSavingTag() throws {
        let newTag = BlogTag(name: "SteamPress")
        let savedTag = try repository.save(newTag).wait()
        
        XCTAssertNotNil(savedTag.tagID)
        
        let tagFromDB = try FluentBlogTag.query(on: app.db).filter(\.$id == savedTag.tagID!).first().wait()
        XCTAssertEqual(tagFromDB?.name, newTag.name)
    }
    
    func testGetingATag() throws {
        let tagName = "Engineering"
        let tag = FluentBlogTag(id: nil, name: tagName)
        try tag.save(on: app.db).wait()
        
        let retrievedTag = try repository.getTag(tagName).wait()
        
        XCTAssertEqual(retrievedTag?.name, tagName)
        XCTAssertEqual(retrievedTag?.tagID, tag.id)
    }
    
    func testGettingAllTags() throws {
        let tagName1 = "Engineering"
        let tagName2 = "SteamPress"
        try FluentBlogTag(id: nil, name: tagName1).save(on: app.db).wait()
        try FluentBlogTag(id: nil, name: tagName2).save(on: app.db).wait()
        
        let tags = try repository.getAllTags().wait()
        
        XCTAssertEqual(tags.count, 2)
        XCTAssertEqual(tags.first?.name, tagName1)
        XCTAssertEqual(tags.last?.name, tagName2)
    }
    
    func testErrorOccursWhenSavingATagWithNameThatAlreadyExists() throws {
        let tagName = "SteamPress"
        var errorOccurred = false
        try FluentBlogTag(id: nil, name: tagName).save(on: app.db).wait()
        do {
            try FluentBlogTag(id: nil, name: tagName).save(on: app.db).wait()
        } catch {
            errorOccurred = true
        }
        
        XCTAssertTrue(errorOccurred)
    }
    
    func testAddingTagToPost() throws {
        let tag = FluentBlogTag(id: nil, name: "SteamPress")
        try tag.save(on: app.db).wait()
        let user = FluentBlogUser(userID: nil, name: "Alice", username: "alice", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil)
        try user.save(on: app.db).wait()
        let post = try FluentBlogPost(id: nil, title: "A Post", contents: "Some contents", author: user.requireID(), creationDate: Date(), slugUrl: "a-post", published: true)
        try post.save(on: app.db).wait()
        
        try repository.add(tag.toBlogTag(), to: post.toBlogPost()).wait()
        
        let tagLinks = try BlogPostTagPivot.query(on: app.db).all().wait()
        XCTAssertEqual(tagLinks.count, 1)
        XCTAssertEqual(tagLinks.first?.$tag.id, tag.id)
        XCTAssertEqual(tagLinks.first?.$post.id, post.id)
    }
    
    func testRemovingTagFromPost() throws {
        let tag = FluentBlogTag(id: nil, name: "SteamPress")
        try tag.save(on: app.db).wait()
        let tag2 = FluentBlogTag(id: nil, name: "Testing")
        try tag2.save(on: app.db).wait()
        let user = FluentBlogUser(userID: nil, name: "Alice", username: "alice", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil)
        try user.save(on: app.db).wait()
        let post = try FluentBlogPost(id: nil, title: "A Post", contents: "Some contents", author: user.requireID(), creationDate: Date(), slugUrl: "a-post", published: true)
        try post.save(on: app.db).wait()
        _ = try post.$tags.attach(tag, on: app.db).wait()
        _ = try post.$tags.attach(tag2, on: app.db).wait()
        
        try repository.remove(tag.toBlogTag(), from: post.toBlogPost()).wait()
        
        let tagLinks = try BlogPostTagPivot.query(on: app.db).all().wait()
        XCTAssertEqual(tagLinks.count, 1)
        
        let allTags = try FluentBlogTag.query(on: app.db).all().wait()
        XCTAssertEqual(allTags.count, 1)
        XCTAssertEqual(allTags.first?.name, tag2.name)
    }
    
    func testGettingTagsForPost() throws {
        let tag1 = FluentBlogTag(id: nil, name: "SteamPress")
        try tag1.save(on: app.db).wait()
        let tag2 = FluentBlogTag(id: nil, name: "Engineering")
        try tag2.save(on: app.db).wait()
        let user = FluentBlogUser(userID: nil, name: "Alice", username: "alice", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil)
        try user.save(on: app.db).wait()
        let post = try FluentBlogPost(id: nil, title: "A Post", contents: "Some contents", author: user.requireID(), creationDate: Date(), slugUrl: "a-post", published: true)
        try post.save(on: app.db).wait()
        
        _ = try post.$tags.attach(tag1, on: app.db).wait()
        _ = try post.$tags.attach(tag2, on: app.db).wait()
        
        let postTags =  try repository.getTags(for: post.toBlogPost()).wait()
        XCTAssertEqual(postTags.count, 2)
        XCTAssertEqual(postTags.first?.name, tag1.name)
        XCTAssertEqual(postTags.last?.name, tag2.name)
    }
    
    func testDeletingTagsForPost() throws {
        let tag1 = FluentBlogTag(id: nil, name: "SteamPress")
        try tag1.save(on: app.db).wait()
        let tag2 = FluentBlogTag(id: nil, name: "Engineering")
        try tag2.save(on: app.db).wait()
        let user = FluentBlogUser(userID: nil, name: "Alice", username: "alice", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil)
        try user.save(on: app.db).wait()
        let post = try FluentBlogPost(id: nil, title: "A Post", contents: "Some contents", author: user.requireID(), creationDate: Date(), slugUrl: "a-post", published: true)
        try post.save(on: app.db).wait()
        
        _ = try post.$tags.attach(tag1, on: app.db).wait()
        _ = try post.$tags.attach(tag2, on: app.db).wait()
        
        try repository.deleteTags(for: post.toBlogPost()).wait()
        
        let tagCount = try FluentBlogTag.query(on: app.db).count().wait()
        XCTAssertEqual(tagCount, 0)
        
        let pivotCount = try BlogPostTagPivot.query(on: app.db).count().wait()
        XCTAssertEqual(pivotCount, 0)
    }
    
    func testDeletingTagsForPostDoesntDeleteTagIfItsAttachedToAnotherPost() throws {
        let tag1 = try BlogTag(name: "SteamPress").save(on: app.db).wait()
        let tag2 = try BlogTag(name: "Engineering").save(on: app.db).wait()
        let user = try BlogUser(name: "Alice", username: "alice", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil).save(on: app.db).wait()
        let post = try BlogPost(title: "A Post", contents: "Some contents", author: user, creationDate: Date(), slugUrl: "a-post", published: true).save(on: app.db).wait()
        let post2 = try BlogPost(title: "Another Post", contents: "Some other contents", author: user, creationDate: Date(), slugUrl: "another-post", published: true).save(on: app.db).wait()
        
        _ = try post.tags.attach(tag1, on: app.db).wait()
        _ = try post.tags.attach(tag2, on: app.db).wait()
        _ = try post2.tags.attach(tag2, on: app.db).wait()
        
        try repository.deleteTags(for: post).wait()
        
        let tagCount = try BlogTag.query(on: app.db).count().wait()
        XCTAssertEqual(tagCount, 1)
        
        let pivotCount = try BlogPostTagPivot.query(on: app.db).count().wait()
        XCTAssertEqual(pivotCount, 1)
    }
    
    func testGettingAllTagsWithPostCount() throws {
        let tag1 = try BlogTag(name: "SteamPress").save(on: app.db).wait()
        let tag2 = try BlogTag(name: "Engineering").save(on: app.db).wait()
        let user = try BlogUser(name: "Alice", username: "alice", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil).save(on: app.db).wait()
        let post1 = try BlogPost(title: "A Post", contents: "Some contents", author: user, creationDate: Date(), slugUrl: "a-post", published: true).save(on: app.db).wait()
        let post2 = try BlogPost(title: "A Second Post", contents: "Some contents", author: user, creationDate: Date(), slugUrl: "a-second-post", published: true).save(on: app.db).wait()
        let post3 = try BlogPost(title: "A Third Post", contents: "Some contents", author: user, creationDate: Date(), slugUrl: "a-third-post", published: true).save(on: app.db).wait()
        
        _ = try post1.tags.attach(tag1, on: app.db).wait()
        _ = try post2.tags.attach(tag2, on: app.db).wait()
        _ = try post3.tags.attach(tag1, on: app.db).wait()
        
        let tagsWithPostCount = try repository.getAllTagsWithPostCount().wait()
        
        XCTAssertEqual(tagsWithPostCount.count, 2)
        XCTAssertEqual(tagsWithPostCount.first?.0.name, tag1.name)
        XCTAssertEqual(tagsWithPostCount.first?.1, 2)
        XCTAssertEqual(tagsWithPostCount.last?.0.name, tag2.name)
        XCTAssertEqual(tagsWithPostCount.last?.1, 1)
    }
    
    func testGettingAllTagsWithPostID() throws {
        let tag1 = try BlogTag(name: "SteamPress").save(on: app.db).wait()
        let tag2 = try BlogTag(name: "Engineering").save(on: app.db).wait()
        let user = try BlogUser(name: "Alice", username: "alice", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil).save(on: app.db).wait()
        let post1 = try BlogPost(title: "A Post", contents: "Some contents", author: user, creationDate: Date(), slugUrl: "a-post", published: true).save(on: app.db).wait()
        let post2 = try BlogPost(title: "A Second Post", contents: "Some contents", author: user, creationDate: Date(), slugUrl: "a-second-post", published: true).save(on: app.db).wait()
        let post3 = try BlogPost(title: "A Third Post", contents: "Some contents", author: user, creationDate: Date(), slugUrl: "a-third-post", published: true).save(on: app.db).wait()
        
        _ = try post1.tags.attach(tag1, on: app.db).wait()
        _ = try post2.tags.attach(tag2, on: app.db).wait()
        _ = try post3.tags.attach(tag1, on: app.db).wait()
        
        let tagsWithPosts = try repository.getTagsForAllPosts().wait()
        
        XCTAssertEqual(tagsWithPosts[post1.blogID!]?.count, 1)
        XCTAssertEqual(tagsWithPosts[post1.blogID!]?.first?.name, tag1.name)
        XCTAssertEqual(tagsWithPosts[post2.blogID!]?.count, 1)
        XCTAssertEqual(tagsWithPosts[post2.blogID!]?.first?.name, tag2.name)
        XCTAssertEqual(tagsWithPosts[post3.blogID!]?.count, 1)
        XCTAssertEqual(tagsWithPosts[post3.blogID!]?.first?.name, tag1.name)
    }
}
