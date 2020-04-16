import Vapor
import SteamPress

public struct SteamPressFluentPostgresProvider: Vapor.Provider {

    // MARK: - Properties
    private let blogPath: String?
    private let feedInformation: FeedInformation
    private let postsPerPage: Int
    private let enableAuthorPages: Bool
    private let enableTagPages: Bool
    
    /**
     Initialiser for SteamPress' Provider to add a blog to your Vapor App. You can pass it an optional
     `blogPath` to add the blog to. For instance, if you pass in "blog", your blog will be accessible
     at http://mysite.com/blog/, or if you pass in `nil` your blog will be added to the root of your
     site (i.e. http://mysite.com/)
     - Parameter blogPath: The path to add the blog to (see above).
     - Parameter feedInformation: Information to vend to the RSS and Atom feeds. Defaults to empty information.
     - Parameter postsPerPage: The number of posts to show per page on the main index page of the blog. Defaults to 10.
     - Parameter enableAuthorsPages: Flag used to determine whether to publicly expose the authors endpoints
     or not. Defaults to true.
     - Parameter enableTagsPages: Flag used to determine whether to publicy expose the tags endpoints or not.
     Defaults to true.
     */
    public init(
        blogPath: String? = nil,
        feedInformation: FeedInformation = FeedInformation(),
        postsPerPage: Int = 10,
        enableAuthorPages: Bool = true,
        enableTagPages: Bool = true) {
        self.blogPath = blogPath
        self.feedInformation = feedInformation
        self.postsPerPage = postsPerPage
        self.enableAuthorPages = enableAuthorPages
        self.enableTagPages = enableTagPages
    }

    public func register(_ services: inout Services) throws {
        let provider = SteamPress.Provider(blogPath: blogPath, feedInformation: feedInformation, postsPerPage: postsPerPage, enableAuthorPages: enableAuthorPages, enableTagPages: enableTagPages)
        services.register(FluentPostgresTagRepository(), as: BlogTagRepository.self)
        services.register(FluentUserRepository(), as: BlogUserRepository.self)
        services.register(FluentPostgresPostRepository(), as: BlogPostRepository.self)
        try services.register(provider)
    }
    
    public func didBoot(_ container: Container) throws -> EventLoopFuture<Void> {
        return container.future()
    }
}

