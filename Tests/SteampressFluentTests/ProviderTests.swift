@testable import SteampressFluent
import XCTest
import Vapor

class ProviderTests: XCTestCase {
    func testProviderSetsUpSteamPressAndRepositoriesCorrectly() throws {
        var services = Services.default()
        try services.register(FluentPostgreSQLProvider())
        
        var databases = DatabasesConfig()
        let hostname: String
        if let envHostname = Environment.get("DB_HOSTNAME") {
            hostname = envHostname
        } else {
            hostname = "localhost"
        }
        let username = "steampress"
        let password = "password"
        let databaseName = "steampress-test"
        let databasePort: Int
        if let envPort = Environment.get("DB_PORT"), let envPortInt = Int(envPort) {
            databasePort = envPortInt
        } else {
            databasePort = 5433
        }
        let databaseConfig = PostgreSQLDatabaseConfig(hostname: hostname, port: databasePort, username: username, database: databaseName, password: password)
        let database = PostgreSQLDatabase(config: databaseConfig)
        databases.add(database: database, as: .psql)
        services.register(databases)

        /// Configure migrations
        var migrations = MigrationConfig()
        migrations.add(model: BlogTag.self, database: .psql)
        migrations.add(model: BlogUser.self, database: .psql)
        migrations.add(model: BlogPost.self, database: .psql)
        migrations.add(model: BlogPostTagPivot.self, database: .psql)
        services.register(migrations)
        
        var config = Config.default()
        
        var commandConfig = CommandConfig.default()
        commandConfig.useFluentCommands()
        services.register(commandConfig)
        
        let provider = SteamPressFluentPostgresProvider()
        try services.register(provider)
        config.prefer(MemoryKeyedCache.self, for: KeyedCache.self)
        
        let app = try Application(config: config, services: services)
        
        let postRepository = try app.make(BlogPostRepository.self)
        XCTAssertTrue(type(of: postRepository) == FluentPostgresPostRepository.self)
        let tagRepository = try app.make(BlogTagRepository.self)
        XCTAssertTrue(type(of: tagRepository) == FluentPostgresTagRepository.self)
        let userRepository = try app.make(BlogUserRepository.self)
        XCTAssertTrue(type(of: userRepository) == FluentPostgresUserRepository.self)
        
        var revertEnv = Environment.testing
        revertEnv.arguments = ["vapor", "revert", "--all", "-y"]
        _ = try Application(config: config, environment: revertEnv, services: services).asyncRun().wait()
    }
}
