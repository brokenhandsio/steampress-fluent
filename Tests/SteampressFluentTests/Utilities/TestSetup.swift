import Vapor
import Fluent
import SteampressFluent
import FluentPostgresDriver
import FluentMySQLDriver

struct TestSetup {
    static func getApp(enableAdminUser: Bool = false) throws -> Application {
        
        let app = Application(.testing)
        let databaseType = TestSetup.getDatabaseType()
        
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
            if databaseType == .mysql {
                databasePort = 3307
            } else {
                databasePort = 5433
            }
        }
        
        if databaseType == .mysql {
            app.databases.use(.mysql(
                hostname: hostname,
                port: databasePort,
                username: username,
                password: password,
                database: databaseName,
                tlsConfiguration: .none
                ), as: .mysql)
        } else {
            app.databases.use(.postgres(
                hostname: hostname,
                port: databasePort,
                username: username,
                password: password,
                database: databaseName
            ), as: .psql)
        }
        app.logger.logLevel = .trace
        
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
        
        if databaseType == .mysql {
            app.steampress.fluent.database = .mysql
        } else {
            app.steampress.fluent.database = .postgres
        }
        try app.boot()
        return app
    }
    
    static func getDatabaseType() -> SteamPressFluentDatabase {
        if Environment.get("MYSQL_TEST") != nil {
            return .mysql
        } else {
            return .postgres
        }
    }
}
