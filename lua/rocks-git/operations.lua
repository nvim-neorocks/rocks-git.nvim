---@mod rocks-git.operations
---
---@brief [[
---
---Operations for installing, syncing and updating plugins.
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

local operations = {}

local git = require("rocks-git.git")
local rockspec = require("rocks-git.rockspec")
local log = require("rocks.log")
local nio = require("nio")

---@param on_progress fun(message: string) | nil
---@param on_error fun(message: string)
---@param pkg rocks-git.Package
---@return boolean success
---@async
local function build_if_required(on_progress, on_error, pkg)
    if not pkg.build then
        return true
    end
    if on_progress then
        on_progress(("rocks-git: Building %s"):format(pkg.name))
    end
    if pkg.build:sub(1, 1) == ":" then
        ---@diagnostic disable-next-line: param-type-mismatch
        local ok, err = pcall(vim.cmd, pkg.build)
        if not ok then
            log.error(err)
            on_error(("rocks-git: Failed to build %s"):format(pkg.name))
            return false
        end
    else
        local cmd = {}
        for word in pkg.build:gmatch("%S+") do
            table.insert(cmd, word)
        end
        log.info(cmd)
        local future = nio.control.future()
        ---@param sc vim.SystemCompleted
        local function callback(sc)
            if sc.code == 0 then
                future.set(true)
            else
                log.error(sc.stderr)
                future.set_error(sc.stderr)
            end
        end
        local ok, err = pcall(vim.system, cmd, { cwd = pkg.dir }, callback)
        if not ok then
            ---@type vim.SystemCompleted
            local sc = {
                code = 1,
                signal = 0,
                stderr = ("Failed to invoke %s.build: %s"):format(pkg.name, err),
            }
            callback(sc)
        end
        ok, err = pcall(future.wait)
        if not ok then
            on_error(("rocks-git: Failed to build %s: %s"):format(pkg.name, err))
            return false
        end
    end
    return true
end

---@param on_progress fun(message: string)
---@param on_error fun(message: string)
---@param on_success fun(opts: rock_handler.on_success.Opts) | nil
---@param pkg rocks-git.Package
operations.install = nio.create(function(on_progress, on_error, on_success, pkg)
    if pkg.rev then
        on_progress(("rocks-git: %s -> %s"):format(pkg.name, pkg.rev))
    else
        on_progress(("rocks-git: %s (latest)"):format(pkg.name))
    end
    local future = git.clone(pkg)
    local ok = pcall(future.wait)
    if not ok then
        on_error(("rocks-git: Failed to clone %s"):format(pkg.url))
        return false
    end
    local futureOpt = git.checkout(pkg)
    if futureOpt then
        ok = pcall(futureOpt.wait)
        if not ok then
            on_error(("rocks-git: Failed to checkout %s"):format(pkg.rev))
            return false
        end
    end
    ok = build_if_required(on_progress, on_error, pkg)
    if ok then
        if pkg.rev then
            on_progress(("rocks-git: Installed %s -> %s"):format(pkg.name, pkg.rev))
        else
            on_progress(("rocks-git: Installed %s"):format(pkg.name))
        end
        if type(on_success) == "function" then
            local is_semver = pkg.rev and pcall(vim.version.parse, pkg.rev)
            on_success({
                action = "install",
                rock = {
                    name = pkg.name,
                    version = is_semver and pkg.rev or "scm",
                },
                dependencies = rockspec.get_dependencies(pkg),
            })
        end
        return true
    end
    return false
end, 4)

---@param on_progress fun(message: string) | nil
---@param on_error fun(message: string)
---@param pkg rocks-git.Package
---@return boolean
local update_pull = nio.create(function(on_progress, on_error, pkg)
    local future = git.pull(pkg)
    local ok = pcall(future.wait)
    if not ok then
        on_error(("rocks-git: Failed to pull %s"):format(pkg.name))
        return ok
    end
    ok = build_if_required(on_progress, on_error, pkg)
    if ok and on_progress then
        on_progress(("rocks-git: Updated %s (unpinned)"):format(pkg.name))
    end
    return ok
end, 3)

---@param on_progress fun(message: string)
---@param on_error fun(message: string)
---@param pkg rocks-git.Package
local update_to_rev = nio.create(function(on_progress, on_error, pkg)
    local future = git.fetch(pkg)
    local ok = pcall(future.wait)
    if not ok then
        log.warn("rocks-git: Error while fetching package updates during sync")
    end
    local futureOpt = git.checkout(pkg)
    if futureOpt and not pcall(futureOpt.wait) then
        on_error(("rocks-git: Failed to checkout %s"):format(pkg.rev))
    end
    ok = build_if_required(on_progress, on_error, pkg)
    return ok
end, 3)

---@param pkg rocks-git.Package
---@param on_success? fun(opts: rock_handler.on_success.Opts) | nil
local function install_semver_stub(pkg, on_success)
    local is_semver = pkg.rev and pcall(vim.version.parse, pkg.rev)
    if is_semver and type(on_success) == "function" then
        on_success({
            action = "install",
            rock = {
                name = pkg.name,
                version = pkg.rev,
            },
            dependencies = rockspec.get_dependencies(pkg),
        })
    end
end

---@param on_progress fun(message: string)
---@param on_error fun(message: string)
---@param on_success? fun(opts: rock_handler.on_success.Opts) | nil
---@param pkg rocks-git.Package
local function ensure_installed(on_progress, on_error, on_success, pkg)
    if not vim.uv.fs_stat(pkg.dir) then
        operations.install(on_progress, on_error, on_success, pkg)
    end
end

---@param on_progress fun(message: string)
---@param on_error fun(message: string)
---@param on_success? fun(opts: rock_handler.on_success.Opts) | nil
---@param pkg rocks-git.Package
operations.sync = nio.create(function(on_progress, on_error, on_success, pkg)
    if not pkg.rev then
        ensure_installed(on_progress, on_error, on_success, pkg)
        return
    end
    local rev = git.get_checked_out_rev(pkg)
    if rev == pkg.rev then
        return
    else
        on_progress(("rocks-git: %s"):format(pkg.name))
        local ok = update_to_rev(on_progress, on_error, pkg)
        if ok then
            install_semver_stub(pkg, on_success)
        end
        if ok and pkg.rev then
            on_progress(("rocks-git: %s -> %s"):format(pkg.name, pkg.rev))
        elseif ok then
            on_progress(("rocks-git: Synced %s"):format(pkg.name))
        end
    end
end, 4)

---@param on_progress fun(message: string)
---@param on_error fun(message: string)
---@param on_success? fun(opts: rock_handler.on_success.Opts) | nil
---@param pkg rocks-git.Package
operations.update = nio.create(function(on_progress, on_error, on_success, pkg)
    local version_tuple = git.get_latest_remote_semver_tag(pkg.url).wait()
    ---@cast version_tuple tag_version_tuple
    local prev = pkg.rev or git.get_checked_out_rev(pkg)
    pkg.rev = version_tuple[1]
    local ok
    if not pkg.rev then
        ok = update_pull(nil, on_error, pkg)
        pkg.rev = git.get_checked_out_rev(pkg)
    else
        ok = update_to_rev(on_progress, on_error, pkg)
    end
    if ok then
        install_semver_stub(pkg, on_success)
        on_progress(("rocks-git: Updated %s: %s -> %s"):format(pkg.name, prev, pkg.rev))
        return pkg
    else
        pkg.rev = prev
        return pkg
    end
end, 4)

---@param dir string
---@return fun(_:unknown, path:string):(name: string, type: string)
local function iter_subdirs(dir)
    return coroutine.wrap(function()
        local handle = vim.uv.fs_scandir(dir)
        while handle do
            local name, type = vim.uv.fs_scandir_next(handle)
            if not name then
                return
            elseif type == "directory" then
                for child, child_type in iter_subdirs(vim.fs.joinpath(dir, name)) do
                    coroutine.yield(child, child_type)
                end
            end
            coroutine.yield(vim.fs.joinpath(dir, name), type)
        end
    end)
end

---@param dir string
---@return boolean | nil success
function operations.prune(dir)
    for name, type in iter_subdirs(dir) do
        local ok = (type == "directory") and vim.uv.fs_rmdir(name) or vim.uv.fs_unlink(name)
        if not ok then
            return ok
        end
    end
    return vim.uv.fs_rmdir(dir)
end

return operations
