---@toc rocks-git.contents

---@mod rocks-git rocks-git.nvim
---
---@brief [[
---
---Adds the ability to manage plugins from git to rocks.nvim!
---
---This plugin hooks into the `:Rocks sync` command.
---
---Note: ~
---   There is no SemVer support!
---
---An entry in the rocks.toml configuration file
---can be extended to match the `PackageSpec` type.
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

local rocks_git = {}

local operations = require("rocks-git.operations")
local config = require("rocks-git.config.internal")

---@class PackageSpec: RockSpec
---@field name string Name of the plugin.
---@field git string Git short name, e.g. 'nvim-neorocks/rocks-git.nvim', or a git URL.
---@field opt? boolean If 'true', will not be loaded on startup. Can be loaded manually with `:packadd!`.
---@field rev? string Git revision or tag to checkout.
---@field branch? string Git branch to checkout.
---@field build? string Shell or Vimscript command to run after install/update. Will run a vim command if prefixed with ':'.

---@brief [[
---
---When calling `:Rocks sync`, this plugin will
---
---  - Install missing plugins in |packpath| directories.
---  - Ensure `rev` is checked out, if one is specified.
---  - Update existing plugins if no `rev` is specified.
---  - Run any `build` commands (after installing or updating).
---
---@brief ]]

---@package
---@class Package: PackageSpec
---@field dir string
---@field url string

---@package
---@param spec RockSpec
---@return fun(report_progress: fun(message: string), report_error: fun(message: string)) | nil
function rocks_git.get_sync_callback(spec)
    if not spec.git then
        return
    end
    ---@cast spec PackageSpec
    return function(report_progress, report_error)
        ---@type Package
        local pkg = vim.tbl_deep_extend("keep", {
            url = (spec.git:match("^https?://") or spec.git:match("^git@")) and spec.git
                -- TODO: Support github:<owner>/<repo> and gitlab:<owner>/<repo>
                or config.default_url_format:format(spec.git),
            dir = vim.fs.joinpath(config.path, (spec.opt and "opt" or "start"), spec.name),
        }, spec)
        if not vim.uv.fs_stat(pkg.dir) then
            operations.install(report_progress, report_error, pkg)
            return
        end
        operations.sync(report_progress, report_error, pkg)
    end
end

---@package
---@param user_rocks RockSpec[]
---@return fun(report_progress: fun(message: string), report_error: fun(message: string))
function rocks_git.get_prune_callback(user_rocks)
    return function(report_progress, report_error)
        for _, packdir in pairs({ "start", "opt" }) do
            local path = vim.fs.joinpath(config.path, packdir)
            local handle = vim.uv.fs_scandir(path)
            while handle do
                local name, type = vim.uv.fs_scandir_next(handle)
                if type == "directory" then
                    local user_rock = user_rocks[name]
                    ---@cast user_rock PackageSpec
                    if
                        not user_rock
                        or user_rock.opt == true and packdir == "start"
                        or not user_rock.opt and packdir == "opt"
                    then
                        local dir = vim.fs.joinpath(path, name)
                        report_progress(("rocks-git: Removing %s"):format(name))
                        local ok = operations.prune(dir)
                        if ok then
                            report_progress(("rocks-git: Removed %s"):format(name))
                        else
                            report_error(("rocks-git: Failed to remove %s"):format(name))
                        end
                    end
                elseif not name then
                    break
                end
            end
        end
    end
end

return rocks_git
