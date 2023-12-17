local rocks = require("rocks.api")
local rocks_git = require("rocks-git")

rocks.register_rock_handler({
    get_sync_callback = rocks_git.get_sync_callback,
    get_prune_callback = rocks_git.get_prune_callback,
})
