import Vapor

public func routes(_ router: Router, masterKey: String, downloadsBaseURL: URL) throws {
    let usersController = UsersController(masterKey: masterKey)
    try router.register(collection: usersController)

    let shortcutsController = ShortcutsController(masterKey: masterKey)
    try router.register(collection: shortcutsController)

    let websiteController = WebsiteController(downloadsBaseURL: downloadsBaseURL)
    try router.register(collection: websiteController)
    
    let invitesController = InvitesController()
    try router.register(collection: invitesController)
}
