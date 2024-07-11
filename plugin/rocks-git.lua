if vim.g.rocks_git_nvim_loaded then
    return
end
local rocks = require("rocks.api")
local rocks_git = require("rocks-git")

rocks.register_rock_handler({
    get_sync_callback = rocks_git.get_sync_callback,
    get_prune_callback = rocks_git.get_prune_callback,
    get_install_callback = rocks_git.get_install_callback,
    get_update_callbacks = rocks_git.get_update_callbacks,
})
vim.g.rocks_git_nvim_loaded = true
