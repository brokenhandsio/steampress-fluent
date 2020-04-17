import Vapor
import Fluent
import SteampressFluent
import FluentPostgresDriver
import FluentMySQLDriver

struct TestSetup {
    static func getApp(enableAdminUser: Bool = false) throws -> Application {
//        var services = Services.default()
//        try services.register(FluentPostgreSQLProvider())
//
//        var databases = DatabasesConfig()
//
//        let databaseConfig = PostgreSQLDatabaseConfig(hostname: hostname, port: databasePort, username: username, database: databaseName, password: password)
//        let database = PostgreSQLDatabase(config: databaseConfig)
//        databases.add(database: database, as: .psql)
//        databases.enableLogging(on: .psql)
//        services.register(databases)
        
        let app = Application(.testing)
        
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
        app.databases.use(.postgres(
            hostname: hostname,
            port: databasePort,
            username: username,
            password: password,
            database: databaseName
        ), as: .psql)
        
        app.migrations.add(CreateBlogUser())
        app.migrations.add(CreateBlogPost())
        app.migrations.add(CreateBlogTag())
        app.migrations.add(CreatePostTagPivot())
        if enableAdminUser {
            app.migrations.add(BlogAdminUser())
        }
        
        do {
            try app.autoRevert().wait()
            try app.autoMigrate().wait()
        } catch {
            print("Error running migrations \(error)")
        }
        
        return app
    }
}
