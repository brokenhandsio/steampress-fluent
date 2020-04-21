import SteamPress
import Vapor

extension Application {
    public class SteamPressFluent {
        let application: Application
        let lifecycleHandler: SteampressFluentLifecycleHandler
        
        init(application: Application, lifecycleHandler: SteampressFluentLifecycleHandler) {
            self.application = application
            self.lifecycleHandler = lifecycleHandler
        }
        
        func initialize() {
            self.application.storage[Key.self] = .init()
            self.application.lifecycle.use(self.lifecycleHandler)
        }
        
        final class Storage {
            var db: SteamPressFluentDatabase
            
            init() {
                db = .undefined
            }
        }
        
        struct Key: StorageKey {
            typealias Value = Storage
        }
        
        var storage: Storage {
            if self.application.storage[Key.self] == nil {
                self.initialize()
            }
            return self.application.storage[Key.self]!
        }
        
        public var database: SteamPressFluentDatabase {
            get {
                self.storage.db
            }
            set {
                self.storage.db = newValue
            }
        }
    }
}

public enum SteamPressFluentDatabase: Equatable {
    case mysql
    case postgres
    case mongo
    case other(String)
    case undefined
}

extension Application.SteamPress {
    public var fluent: Application.SteamPressFluent {
        .init(application: self.application, lifecycleHandler: SteampressFluentLifecycleHandler())
    }
}

struct SteampressFluentLifecycleHandler: LifecycleHandler {
    func willBoot(_ application: Application) throws {
        application.steampress.blogRepositories.use { (application) -> BlogUserRepository in
            return FluentUserRepository(database: application.db)
        }
        application.steampress.blogRepositories.use { (application) -> BlogTagRepository in
            return FluentTagRepository(database: application.db, databaseType: application.steampress.fluent.database)
        }
        application.steampress.blogRepositories.use { (application) -> BlogPostRepository in
            return FluentPostRepository(database: application.db, databaseType: application.steampress.fluent.database)
        }
    }
}
