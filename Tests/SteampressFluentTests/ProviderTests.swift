@testable import SteampressFluent
import XCTest
import Vapor

class ProviderTests: XCTestCase {
    func testProviderSetsUpSteamPressAndRepositoriesCorrectly() throws {
        let app = try TestSetup.getApp()

        let postRepository = app.steampress.blogRepositories.postRepository
        XCTAssertTrue(type(of: postRepository) == FluentPostRepository.self)
        let tagRepository = app.steampress.blogRepositories.tagRepository
        XCTAssertTrue(type(of: tagRepository) == FluentTagRepository.self)
        let userRepository = app.steampress.blogRepositories.userRepository
        XCTAssertTrue(type(of: userRepository) == FluentUserRepository.self)
        
        app.shutdown()
    }
}
