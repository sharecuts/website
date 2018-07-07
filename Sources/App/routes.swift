import Vapor

public func routes(_ router: Router, masterKey: String) throws {
    let usersController = UsersController(masterKey: masterKey)
    try router.register(collection: usersController)

    let shortcutsController = ShortcutsController()
    try router.register(collection: shortcutsController)

    let websiteController = WebsiteController()
    try router.register(collection: websiteController)
}
