-- NOTE: This rockspec is used for running busted tests only,
-- not for publishing to LuaRocks.org

local _MODREV, _SPECREV = "scm", "-1"
rockspec_format = "3.0"
package = "rocks-git.nvim"
version = _MODREV .. _SPECREV

dependencies = {
    "lua >= 5.1",
    "nvim-nio",
    "rocks.nvim >= 2.12.0",
}

test_dependencies = {
    "nvim-nio",
}

source = {
    url = "git://github.com/nvim-neorocks/" .. package,
}

build = {
    type = "builtin",
    copy_directories = {
        'doc',
        "plugin",
    },
}
