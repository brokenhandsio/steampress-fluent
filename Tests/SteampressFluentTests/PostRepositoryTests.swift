import XCTest
@testable import SteampressFluent
import Vapor
import Fluent

class PostRepositoryTests: XCTestCase {
    
    // MARK: - Properties
    var app: Application!
    var repository: FluentPostRepository!
    var postAuthor: FluentBlogUser!
    
    // MARK: - Overrides
    
    override func setUpWithError() throws {
        app = try TestSetup.getApp()
        repository = FluentPostRepository(database: app.db)
        postAuthor = FluentBlogUser(userID: nil, name: "Alice", username: "alice", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil)
        try postAuthor.save(on: app.db).wait()
    }
    
    override func tearDownWithError() throws {
        app.shutdown()
    }
    
    // MARK: - Tests
    
    func testSavingPost() throws {
        let newPost = try BlogPost(title: "A new post", contents: "Some Contents", author: postAuthor.toBlogUser(), creationDate: Date(), slugUrl: "a-new-post", published: true)
        let savedPost = try repository.save(newPost).wait()
        
        XCTAssertNotNil(savedPost.blogID)
        
        let postFromDB = try FluentBlogPost.query(on: app.db).filter(\.$id == savedPost.blogID!).first().wait()
        XCTAssertEqual(postFromDB?.title, newPost.title)
    }
    
    func testDeletingAPost() throws {
        let post = try BlogPost(title: "A new post", contents: "Some Contents", author: postAuthor.toBlogUser(), creationDate: Date(), slugUrl: "a-new-post", published: true)
        try post.toFluentPost().save(on: app.db).wait()
        
        let initialCount = try FluentBlogPost.query(on: app.db).count().wait()
        XCTAssertEqual(initialCount, 1)
        
        try repository.delete(post).wait()
        
        let count = try FluentBlogPost.query(on: app.db).count().wait()
        XCTAssertEqual(count, 0)
    }
    
    func testGetingAPostById() throws {
        let post = try FluentBlogPost(id: nil, title: "A new post", contents: "Some Contents", author: postAuthor.requireID(), creationDate: Date(), slugUrl: "a-new-post", published: true)
        try post.save(on: app.db).wait()
        
        let retrievedPost = try repository.getPost(id: post.id!).wait()
        
        XCTAssertEqual(retrievedPost?.title, post.title)
    }
    
    func testGettingAPostBySlugURL() throws {
        let slugURL = "a-new-post"
        let post = try FluentBlogPost(id: nil, title: "A new post", contents: "Some Contents", author: postAuthor.requireID(), creationDate: Date(), slugUrl: slugURL, published: true)
        try post.save(on: app.db).wait()
        
        let retrievedPost = try repository.getPost(slug: slugURL).wait()
        
        XCTAssertEqual(retrievedPost?.blogID, post.id)
        XCTAssertEqual(post.title, retrievedPost?.title)
    }
    
    func testSlugURLMustBeUnique() throws {
        let slugURL = "a-new-post"
        try FluentBlogPost(id: nil, title: "A new post", contents: "Some Contents", author: postAuthor.requireID(), creationDate: Date(), slugUrl: slugURL, published: true).save(on: app.db).wait()
        var errorOccurred = false
        do {
            try FluentBlogPost(id: nil, title: "A different post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date(), slugUrl: slugURL, published: true).save(on: app.db).wait()
        } catch {
            errorOccurred = true
        }
        
        XCTAssertTrue(errorOccurred)
    }
    
    func testUserMustExistInDBWhenSavingPost() throws {
        let unsavedUser = BlogUser(userID: 99, name: "Bob", username: "bob", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil)
        var errorOccurred = false
        do {
            try FluentBlogPost(id: nil, title: "A new post", contents: "Some contents", author: unsavedUser.userID!, creationDate: Date(), slugUrl: "a-new-post", published: true).save(on: app.db).wait()
        } catch {
            errorOccurred = true
        }
        
        XCTAssertTrue(errorOccurred)
    }
    
    func testGettingPostCountForAUser() throws {
        let otherUser = FluentBlogUser(userID: nil, name: "Bob", username: "bob", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil)
        try otherUser.save(on: app.db).wait()
        try FluentBlogPost(id: nil, title: "A new post", contents: "Some Contents", author: postAuthor.requireID(), creationDate: Date(), slugUrl: "a-new-post", published: true).save(on: app.db).wait()
        try FluentBlogPost(id: nil, title: "A different post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date(), slugUrl: "a-different-post", published: true).save(on: app.db).wait()
        try FluentBlogPost(id: nil, title: "A draft post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date(), slugUrl: "a-draft-post", published: false).save(on: app.db).wait()
        try FluentBlogPost(id: nil, title: "An unrelated post", contents: "Some other contents", author: otherUser.requireID(), creationDate: Date(), slugUrl: "an-unrelated-post", published: true).save(on: app.db).wait()
        
        let count = try repository.getPostCount(for: postAuthor.toBlogUser()).wait()
        
        // Draft posts shouldn't appear in count
        XCTAssertEqual(count, 2)
    }
    
    func testGetPostsOrderedByPublishDate() throws {
        let post1 = try FluentBlogPost(id: nil, title: "A new post", contents: "Some Contents", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(360), slugUrl: "a-new-post", published: true)
        try post1.save(on: app.db).wait()
        let post2 = try FluentBlogPost(id: nil, title: "A different post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(-360), slugUrl: "a-different-post", published: true)
        try post2.save(on: app.db).wait()
        let post3 = try FluentBlogPost(id: nil, title: "A third post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date(), slugUrl: "a-third-post", published: true)
        try post3.save(on: app.db).wait()
        let post4 = try FluentBlogPost(id: nil, title: "A draft post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(60), slugUrl: "a-draft-post", published: false)
        try post4.save(on: app.db).wait()
        
        let publishedPosts = try repository.getAllPostsSortedByPublishDate(includeDrafts: false).wait()
        XCTAssertEqual(publishedPosts.count, 3)
        XCTAssertEqual(publishedPosts.first?.slugUrl, post1.slugUrl)
        XCTAssertEqual(publishedPosts.last?.slugUrl, post2.slugUrl)
        
        let allPosts = try repository.getAllPostsSortedByPublishDate(includeDrafts: true).wait()
        
        XCTAssertEqual(allPosts.count, 4)
        XCTAssertEqual(allPosts.first?.slugUrl, post1.slugUrl)
        XCTAssertEqual(allPosts[1].slugUrl, post4.slugUrl)
        XCTAssertEqual(allPosts[2].slugUrl, post3.slugUrl)
        XCTAssertEqual(allPosts.last?.slugUrl, post2.slugUrl)
    }
    
    func testGetAllPostsCount() throws {
        try FluentBlogPost(id: nil, title: "A new post", contents: "Some Contents", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(360), slugUrl: "a-new-post", published: true).save(on: app.db).wait()
        try FluentBlogPost(id: nil, title: "A different post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(-360), slugUrl: "a-different-post", published: true).save(on: app.db).wait()
        try FluentBlogPost(id: nil, title: "A third post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date(), slugUrl: "a-third-post", published: true).save(on: app.db).wait()
        try FluentBlogPost(id: nil, title: "A draft post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(60), slugUrl: "a-draft-post", published: false).save(on: app.db).wait()
        
        let publishedPostsCount = try repository.getAllPostsCount(includeDrafts: false).wait()
        XCTAssertEqual(publishedPostsCount, 3)
        
        let allPostsCount = try repository.getAllPostsCount(includeDrafts: true).wait()
        
        XCTAssertEqual(allPostsCount, 4)
    }
    
    func testSearchReturnsPublishedPostsInDateOrder() throws {
        let post1 = try FluentBlogPost(id: nil, title: "A new post", contents: "Some Contents about vapor", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(-360), slugUrl: "a-new-post", published: true)
        try post1.save(on: app.db).wait()
        let post2 = try FluentBlogPost(id: nil, title: "A different Vapor post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(360), slugUrl: "a-different-post", published: true)
        try post2.save(on: app.db).wait()
        try FluentBlogPost(id: nil, title: "A third post", contents: "Some other contents containing vapor", author: postAuthor.requireID(), creationDate: Date(), slugUrl: "a-third-post", published: false).save(on: app.db).wait()
        try FluentBlogPost(id: nil, title: "A draft Vapor post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(60), slugUrl: "a-draft-post", published: false).save(on: app.db).wait()
        try FluentBlogPost(id: nil, title: "An unrelated draft post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date(), slugUrl: "an-unrelated-draft-post", published: false).save(on: app.db).wait()
        try FluentBlogPost(id: nil, title: "An unrelated post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date(), slugUrl: "an-unrelated-post", published: true).save(on: app.db).wait()
        
        let posts = try repository.findPublishedPostsOrdered(for: "vapor", count: 10, offset: 0).wait()
        let count = try repository.getPublishedPostCount(for: "vapor").wait()
        
        XCTAssertEqual(posts.count, 2)
        XCTAssertEqual(posts.first?.slugUrl, post2.slugUrl)
        XCTAssertEqual(posts.last?.slugUrl, post1.slugUrl)
        XCTAssertEqual(count, 2)
    }
    
    func testGettingAllPostsForUser() throws {
        let otherUser = FluentBlogUser(userID: nil, name: "Bob", username: "bob", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil)
        try otherUser.save(on: app.db).wait()
        
        let post1 = try FluentBlogPost(id: nil, title: "A new post", contents: "Some Contents about vapor", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(-360), slugUrl: "a-new-post", published: true)
        try post1.save(on: app.db).wait()
        let post2 = try FluentBlogPost(id: nil, title: "A different Vapor post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(360), slugUrl: "a-different-post", published: true)
        try post2.save(on: app.db).wait()
        let post3 = try FluentBlogPost(id: nil, title: "A third post", contents: "Some other contents containing vapor", author: postAuthor.requireID(), creationDate: Date(), slugUrl: "a-third-post", published: true)
        try post3.save(on: app.db).wait()
        let post4 = try FluentBlogPost(id: nil, title: "A draft Vapor post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(60), slugUrl: "a-draft-post", published: true)
        try post4.save(on: app.db).wait()
        let post5 = try FluentBlogPost(id: nil, title: "An unrelated draft post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(10), slugUrl: "an-unrelated-draft-post", published: false)
        try post5.save(on: app.db).wait()
        let post6 = try FluentBlogPost(id: nil, title: "An unrelated post", contents: "Some other contents", author: otherUser.requireID(), creationDate: Date(), slugUrl: "an-unrelated-post", published: true)
        try post6.save(on: app.db).wait()
        
        let firstPosts = try repository.getAllPostsSortedByPublishDate(for: postAuthor.toBlogUser(), includeDrafts: false, count: 2, offset: 0).wait()
        XCTAssertEqual(firstPosts.count, 2)
        XCTAssertEqual(firstPosts.first?.slugUrl, post2.slugUrl)
        XCTAssertEqual(firstPosts.last?.slugUrl, post4.slugUrl)
        
        let secondPosts = try repository.getAllPostsSortedByPublishDate(for: postAuthor.toBlogUser(), includeDrafts: false, count: 2, offset: 2).wait()
        XCTAssertEqual(secondPosts.count, 2)
        XCTAssertEqual(secondPosts.first?.slugUrl, post3.slugUrl)
        XCTAssertEqual(secondPosts.last?.slugUrl, post1.slugUrl)
        
        let thirdPosts = try repository.getAllPostsSortedByPublishDate(for: postAuthor.toBlogUser(), includeDrafts: false, count: 2, offset: 4).wait()
        XCTAssertEqual(thirdPosts.count, 0)
        
        let otherUserPosts = try repository.getAllPostsSortedByPublishDate(for: otherUser.toBlogUser(), includeDrafts: false, count: 10, offset: 0).wait()
        XCTAssertEqual(otherUserPosts.count, 1)
        XCTAssertEqual(otherUserPosts.first?.slugUrl, post6.slugUrl)
        
        let postsWithDrafts = try repository.getAllPostsSortedByPublishDate(for: postAuthor.toBlogUser(), includeDrafts: true, count: 3, offset: 0).wait()
        XCTAssertEqual(postsWithDrafts.count, 3)
        XCTAssertEqual(postsWithDrafts.last?.slugUrl, post5.slugUrl)
    }
    
    func testGettingPaginatedPosts() throws {
        let otherUser = FluentBlogUser(userID: nil, name: "Bob", username: "bob", password: "password", profilePicture: nil, twitterHandle: nil, biography: nil, tagline: nil)
        try otherUser.save(on: app.db).wait()
        
        let post1 = try FluentBlogPost(id: nil, title: "A new post", contents: "Some Contents about vapor", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(-360), slugUrl: "a-new-post", published: true)
        try post1.save(on: app.db).wait()
        let post2 = try FluentBlogPost(id: nil, title: "A different Vapor post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(360), slugUrl: "a-different-post", published: true)
        try post2.save(on: app.db).wait()
        try FluentBlogPost(id: nil, title: "A third post", contents: "Some other contents containing vapor", author: postAuthor.requireID(), creationDate: Date(), slugUrl: "a-third-post", published: true).save(on: app.db).wait()
        let post4 = try FluentBlogPost(id: nil, title: "A draft Vapor post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(60), slugUrl: "a-draft-post", published: true)
        try post4.save(on: app.db).wait()
        let post5 = try FluentBlogPost(id: nil, title: "An unrelated draft post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(10), slugUrl: "an-unrelated-draft-post", published: false)
        try post5.save(on: app.db).wait()
        try FluentBlogPost(id: nil, title: "An unrelated post", contents: "Some other contents", author: otherUser.requireID(), creationDate: Date().addingTimeInterval(30), slugUrl: "an-unrelated-post", published: true).save(on: app.db).wait()
        
        let firstPosts = try repository.getAllPostsSortedByPublishDate(includeDrafts: false, count: 2, offset: 0).wait()
        XCTAssertEqual(firstPosts.count, 2)
        XCTAssertEqual(firstPosts.first?.slugUrl, post2.slugUrl)
        XCTAssertEqual(firstPosts.last?.slugUrl, post4.slugUrl)
        
        let secondPosts = try repository.getAllPostsSortedByPublishDate(includeDrafts: false, count: 2, offset: 4).wait()
        XCTAssertEqual(secondPosts.count, 1)
        XCTAssertEqual(secondPosts.first?.slugUrl, post1.slugUrl)
        
        let thirdPosts = try repository.getAllPostsSortedByPublishDate(includeDrafts: false, count: 4, offset: 4).wait()
        XCTAssertEqual(thirdPosts.count, 1)
        
        let postsWithDrafts = try repository.getAllPostsSortedByPublishDate(includeDrafts: true, count: 4, offset: 0).wait()
        XCTAssertEqual(postsWithDrafts.count, 4)
        XCTAssertEqual(postsWithDrafts.last?.slugUrl, post5.slugUrl)
    }
    
    func testGettingPaginatedPostsForTag() throws {
        let tag = FluentBlogTag(id: nil, name: "Engineering")
        try tag.save(on: app.db).wait()
        let otherTag = FluentBlogTag(id: nil, name: "Boring")
        try otherTag.save(on: app.db).wait()
        
        let post1 = try FluentBlogPost(id: nil, title: "A new post", contents: "Some Contents about vapor", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(-360), slugUrl: "a-new-post", published: true)
        try post1.save(on: app.db).wait()
        let post2 = try FluentBlogPost(id: nil, title: "A different Vapor post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(360), slugUrl: "a-different-post", published: true)
        try post2.save(on: app.db).wait()
        let post3 = try FluentBlogPost(id: nil, title: "A third post", contents: "Some other contents containing vapor", author: postAuthor.requireID(), creationDate: Date(), slugUrl: "a-third-post", published: true)
        try post3.save(on: app.db).wait()
        let post4 = try FluentBlogPost(id: nil, title: "A draft Vapor post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(60), slugUrl: "a-draft-post", published: true)
        try post4.save(on: app.db).wait()
        let post5 = try FluentBlogPost(id: nil, title: "An unrelated draft post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(10), slugUrl: "an-unrelated-draft-post", published: false)
        try post5.save(on: app.db).wait()
        let post6 = try FluentBlogPost(id: nil, title: "An unrelated post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date(), slugUrl: "an-unrelated-post", published: true)
        try post6.save(on: app.db).wait()
        _ = try post1.$tags.attach(tag, on: app.db).wait()
        _ = try post2.$tags.attach(tag, on: app.db).wait()
        _ = try post3.$tags.attach(tag, on: app.db).wait()
        _ = try post4.$tags.attach(tag, on: app.db).wait()
        _ = try post5.$tags.attach(tag, on: app.db).wait()
        _ = try post6.$tags.attach(otherTag, on: app.db).wait()
        
        let firstPosts = try repository.getSortedPublishedPosts(for: tag.toBlogTag(), count: 2, offset: 0).wait()
        XCTAssertEqual(firstPosts.count, 2)
        XCTAssertEqual(firstPosts.first?.slugUrl, post2.slugUrl)
        XCTAssertEqual(firstPosts.last?.slugUrl, post4.slugUrl)
        
        let secondPosts = try repository.getSortedPublishedPosts(for: tag.toBlogTag(), count: 2, offset: 2).wait()
        XCTAssertEqual(secondPosts.count, 2)
        XCTAssertEqual(secondPosts.first?.slugUrl, post3.slugUrl)
        XCTAssertEqual(secondPosts.last?.slugUrl, post1.slugUrl)
        
        let thirdPosts = try repository.getSortedPublishedPosts(for: tag.toBlogTag(), count: 2, offset: 4).wait()
        XCTAssertEqual(thirdPosts.count, 0)
        
        let otherUserPosts = try repository.getSortedPublishedPosts(for: otherTag.toBlogTag(), count: 10, offset: 0).wait()
        XCTAssertEqual(otherUserPosts.count, 1)
        XCTAssertEqual(otherUserPosts.first?.slugUrl, post6.slugUrl)
    }
    
    func testGettingPostCountForATag() throws {
        let tag = FluentBlogTag(id: nil, name: "Engineering")
        try tag.save(on: app.db).wait()
        
        let post1 = try FluentBlogPost(id: nil, title: "A new post", contents: "Some Contents about vapor", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(-360), slugUrl: "a-new-post", published: true)
        try post1.save(on: app.db).wait()
        let post2 = try FluentBlogPost(id: nil, title: "A different Vapor post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(360), slugUrl: "a-different-post", published: true)
        try post2.save(on: app.db).wait()
        let post3 = try FluentBlogPost(id: nil, title: "A third post", contents: "Some other contents containing vapor", author: postAuthor.requireID(), creationDate: Date(), slugUrl: "a-third-post", published: true)
        try post3.save(on: app.db).wait()
        let post4 = try FluentBlogPost(id: nil, title: "A draft Vapor post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(60), slugUrl: "a-draft-post", published: true)
        try post4.save(on: app.db).wait()
        let post5 = try FluentBlogPost(id: nil, title: "An unrelated draft post", contents: "Some other contents", author: postAuthor.requireID(), creationDate: Date().addingTimeInterval(10), slugUrl: "an-unrelated-draft-post", published: false)
        try post5.save(on: app.db).wait()
        _ = try post1.$tags.attach(tag, on: app.db).wait()
        _ = try post2.$tags.attach(tag, on: app.db).wait()
        _ = try post3.$tags.attach(tag, on: app.db).wait()
        _ = try post4.$tags.attach(tag, on: app.db).wait()
        _ = try post5.$tags.attach(tag, on: app.db).wait()
        
        let count = try repository.getPublishedPostCount(for: tag.toBlogTag()).wait()
        
        XCTAssertEqual(count, 4)
    }
}

