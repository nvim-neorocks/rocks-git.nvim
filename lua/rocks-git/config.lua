---@mod rocks-git.config
---
---@brief [[
---
---rocks-git can be configured by adding a `[rocks-git]` table
---to your rocks.toml.
---
---See the |RocksGitConfig| type for configuration options.
---
---@brief ]]

-- Copyright (C) 2023 Neorocks Org.
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    17 Dec 2023
-- Updated:    28 Feb 2024
-- Homepage:   https://github.com/nvim-neorocks/rocks-git.nvim
-- Maintainer: mrcjkb <marc@jakobi.dev>

---@class RocksGitConfig
---@field path string Where to install git plugins (see |packages|)
---@field url_format string Git URL format (Lua format string)

local rocks = require("rocks.api")

---@type RocksGitConfig
local default_config = {
    ---@diagnostic disable-next-line: param-type-mismatch
    path = vim.fs.joinpath(vim.fn.stdpath("data"), "site", "pack", "rocks"),
    url_format = "https://github.com/%s.git",
}

local user_configuration = rocks.get_rocks_toml()

local config = vim.tbl_deep_extend("force", default_config, user_configuration["rocks-git"] or {})

---@type RocksGitConfig
return config
