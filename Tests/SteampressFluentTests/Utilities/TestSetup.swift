import Vapor
import Fluent
import SteampressFluent
import FluentPostgresDriver
import FluentMySQLDriver

struct TestSetup {
    static func getApp(enableAdminUser: Bool = false) throws -> Application {
        
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
            if Environment.get("MYSQL_TEST") != nil {
                databasePort = 3307
            } else {
                databasePort = 5433
            }
        }
        
        if Environment.get("MYSQL_TEST") != nil {
            app.databases.use(.mysql(
                hostname: hostname,
                port: databasePort,
                username: username,
                password: password,
                database: databaseName
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
        
        if Environment.get("MYSQL_TEST") != nil {
            app.steampress.fluent.database = .postgres
        } else {
            app.steampress.fluent.database = .mysql
        }
        try app.boot()
        return app
    }
}
