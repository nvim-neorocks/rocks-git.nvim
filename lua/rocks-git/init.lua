---@toc rocks-git.contents

---@mod rocks-git rocks-git.nvim
---
---@brief [[
---
---Adds the ability to manage plugins from git to rocks.nvim!
---
---This plugin hooks into the `:Rocks {install|update|sync|prune}` commands.
---
---An entry in the rocks.toml configuration file
---can be extended to match the `PackageSpec` type.
---
---The `:Rocks install {plugin} {args?}` command is extended by this module as follows:
---
---Arguments:
---
--- - `plugin`: The plugin, e.g. `owner/repo` or a git HTTPS/SSH URL.
---             Can also be one of the following short hands (HTTPS only):
---               - gitlab:owner/repo
---               - sourcehut:owner/repo
---               - github:owner/repo
---               - codeberg:owner/repo
--- - `args`: (optional) `key=value` pairs, see [Configuration options](#configuration-options).
---
---
---
---@brief ]]

-- Copyright (C) 2023 Neorocks Org.
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    17 Dec 2023
-- Updated:    27 Feb 2024
-- Homepage:   https://github.com/nvim-neorocks/rocks-git.nvim
-- Maintainer: mrcjkb <marc@jakobi.dev>

local rocks_git = {}

local rocks = require("rocks.api")
local operations = require("rocks-git.operations")
local parser = require("rocks-git.parser")
local git = require("rocks-git.git")
local config = require("rocks-git.config")
local nio = require("nio")

---@class PackageSpec: RockSpec
---@field name string Name of the plugin.
---@field git string Git short name, e.g. 'nvim-neorocks/rocks-git.nvim', or a git URL.
---@field opt? boolean If 'true', will not be loaded on startup. Can be loaded manually with `:packadd!`.
---@field rev? string Git revision or tag to checkout.
---@field branch? string Git branch to checkout.
---@field build? string Shell or Vimscript command to run after install/update. Will run a vim command if prefixed with ':'.
---@field ignore_tags? boolean Ignore tags when updating and prioritise git revisions.

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
---@class rocks-git.Package: PackageSpec
---@field dir string
---@field url string

---@param spec PackageSpec
---@return rocks-git.Package
local function mk_package(spec)
    return vim.tbl_deep_extend("keep", {
        url = parser.parse_git_url(spec.git),
        dir = vim.fs.joinpath(config.path, (spec.opt and "opt" or "start"), spec.name),
    }, spec)
end

---@param rocks_toml MutRocksTomlRef
---@param spec PackageSpec
local function mut_update_rocks_toml(rocks_toml, spec)
    -- toml-edit's metatable con't set a table directly.
    -- Each field has to be set individually.
    rocks_toml.plugins[spec.name] = {}
    ---@diagnostic disable-next-line: inject-field
    rocks_toml.plugins[spec.name].git = spec.git
    ---@diagnostic disable-next-line: inject-field
    rocks_toml.plugins[spec.name].rev = spec.rev
    ---@diagnostic disable-next-line: inject-field
    rocks_toml.plugins[spec.name].opt = spec.opt
    ---@diagnostic disable-next-line: inject-field
    rocks_toml.plugins[spec.name].branch = spec.branch
    ---@diagnostic disable-next-line: inject-field
    rocks_toml.plugins[spec.name].build = spec.build
    ---@diagnostic disable-next-line: inject-field
    rocks_toml.plugins[spec.name].ignore_tags = spec.ignore_tags
end

---@package
---@param mut_rocks_toml MutRocksTomlRef
---@param arg_list string[]
---@return rock_handler_callback | nil
rocks_git.get_install_callback = nio.create(function(mut_rocks_toml, arg_list)
    if #arg_list < 1 then
        return
    end
    local git_rock = arg_list[1]:lower()
    if not parser.is_repo_shorthand(git_rock) and not parser.is_git_url(git_rock) then
        return
    end
    ---@type string[]
    local args = #arg_list == 1 and {} or { unpack(arg_list, 2, #arg_list) }
    ---@param on_progress fun(msg: string)
    ---@param on_error fun(msg: string)
    ---@param on_success? fun(opts: rock_handler.on_success.Opts)
    return nio.create(function(on_progress, on_error, on_success)
        local parse_result = args and parser.parse_install_args(args) or { spec = {}, invalid_args = {} }
        if not vim.tbl_isempty(parse_result.invalid_args) then
            on_error(("rocks-git: invalid install args: %s"):format(vim.inspect(parse_result.invalid_args)))
            return false
        end
        if not vim.tbl_isempty(parse_result.conflicting_args) then
            on_error(("rocks-git: conflicting install args: %s"):format(vim.inspect(parse_result.conflicting_args)))
            return false
        end
        local checkout_spec = parse_result.spec

        local name = parser.plugin_name_from_git_uri(git_rock)
        if not name then
            on_error(("rocks-git: Could not infer plugin name from %s"):format(git_rock))
            return false
        end

        if not checkout_spec.rev and not checkout_spec.ignore_tags and not checkout_spec.branch then
            on_progress(("rocks-git: fetching %s tags from remote"):format(name))
            local version_tuple = git.get_latest_remote_semver_tag(parser.parse_git_url(git_rock)).wait()
            ---@cast version_tuple tag_version_tuple
            checkout_spec.rev = version_tuple[1]
        end

        ---@type PackageSpec
        local spec = {
            name = name,
            git = git_rock,
            opt = checkout_spec.opt,
            rev = checkout_spec.rev,
            branch = checkout_spec.branch,
            build = checkout_spec.build,
        }
        local pkg = mk_package(spec)
        if vim.uv.fs_stat(pkg.dir) then
            local future = nio.control.future()
            vim.schedule(function()
                vim.ui.input({
                    prompt = ("%s is already checked out. Delete and reinstall? [y/n] "):format(pkg.name),
                }, function(yesno)
                    future.set(yesno and yesno:match("^y.*") ~= nil or false)
                end)
            end)
            local reinstall = future.wait()
            if reinstall then
                operations.prune(pkg.dir)
            else
                on_error("rocks-git: Installation aborted.")
                return
            end
        end
        local ok = operations.install(on_progress, on_error, on_success, pkg)
        if ok then
            if not pkg.rev then
                pkg.rev = git.get_checked_out_rev(pkg)
            end
            mut_update_rocks_toml(mut_rocks_toml, pkg)
        end
    end, 2)
end, 2)

---@package
---@param spec RockSpec
---@return rock_handler_callback | nil
rocks_git.get_sync_callback = nio.create(function(spec)
    ---@cast spec RockSpec
    if not spec.git then
        return
    end
    ---@cast spec PackageSpec
    ---@param on_progress fun(msg: string)
    ---@param on_error fun(msg: string)
    ---@param on_success? fun(opts: rock_handler.on_success.Opts)
    return nio.create(function(on_progress, on_error, on_success)
        local pkg = mk_package(spec)
        if not vim.uv.fs_stat(pkg.dir) then
            operations.install(on_progress, on_error, on_success, pkg)
            return
        end
        operations.sync(on_progress, on_error, on_success, pkg)
    end, 3)
end, 1)

---@package
---@type async fun(rocks_toml: MutRocksTomlRef): rock_handler_callback[]
rocks_git.get_update_callbacks = nio.create(function(mut_rocks_toml)
    ---@cast mut_rocks_toml MutRocksTomlRef
    local rocks_toml = rocks.get_rocks_toml() -- we cannot iterate over MutRocksTomlRef
    return vim
        .iter(vim.tbl_values(rocks_toml.plugins))
        :filter(function(spec)
            return type(spec.git) == "string"
        end)
        :map(mk_package)
        ---@param pkg rocks-git.Package
        :filter(function(pkg)
            return pkg.pin ~= true and (pkg.rev == nil or git.is_outdated(pkg))
        end)
        ---@param pkg rocks-git.Package
        :map(function(pkg)
            ---@param on_progress fun(msg: string)
            ---@param on_error fun(msg: string)
            ---@param on_success? fun(opts: rock_handler.on_success.Opts)
            return nio.create(function(on_progress, on_error, on_success)
                ---@cast on_progress fun(msg: string)
                ---@cast on_error fun(msg: string)
                local updated_pkg = operations.update(on_progress, on_error, on_success, pkg)
                mut_update_rocks_toml(mut_rocks_toml, updated_pkg)
            end, 2)
        end)
        :totable()
end, 1)

---@package
---@param user_rocks RockSpec[]
---@return rock_handler_callback | nil
rocks_git.get_prune_callback = nio.create(function(user_rocks)
    ---@cast user_rocks RockSpec[]
    ---@param on_progress fun(msg: string)
    ---@param on_error fun(msg: string)
    return function(on_progress, on_error)
        for _, packdir in pairs({ "start", "opt" }) do
            local path = vim.fs.joinpath(config.path, packdir)
            local handle = vim.uv.fs_scandir(path)
            while handle do
                local name, type = vim.uv.fs_scandir_next(handle)
                if type == "directory" then
                    local user_rock = user_rocks[name]
                    ---@cast user_rock PackageSpec
                    local prune = false
                    local msg_append = ""
                    if not user_rock then
                        prune = true
                    elseif user_rock.opt == true and packdir == "start" then
                        prune = true
                        msg_append = " from 'start'"
                    elseif not user_rock.opt and packdir == "opt" then
                        prune = true
                        msg_append = " from 'opt'"
                    end
                    if prune then
                        local dir = vim.fs.joinpath(path, name)
                        on_progress(("rocks-git: Removing %s%s"):format(name, msg_append))
                        local ok = operations.prune(dir)
                        if ok then
                            on_progress(("rocks-git: Removed %s%s"):format(name, msg_append))
                        else
                            on_error(("rocks-git: Failed to remove %s%s"):format(name, msg_append))
                        end
                    end
                elseif not name then
                    break
                end
            end
        end
    end
end, 1)

return rocks_git
