---@mod rocks.config.internal
---
---@brief [[
---
---Internal configuration.
---
---NOTE: (mrcjkb) I'm going with YAGNI on user-configuration here.
---But I've organised it in a way that would let us extend
---a user config if needed
---
---@brief ]]

-- Copyright (C) 2023 Neorocks Org.
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    17 Dec 2023
-- Updated:    17 Dec 2023
-- Homepage:   https://github.com/nvim-neorocks/rocks-git.nvim
-- Maintainer: mrcjkb <marc@jakobi.dev>

---@class (exact) RocksGitConfig
---@field path string Packpath in which to install plugins
---@field default_url_format string Git URL format

---@type RocksGitConfig
local default_config = {
    ---@diagnostic disable-next-line: param-type-mismatch
    path = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "rocks"),
    default_url_format = "https://github.com/%s.git",
}

return default_config
