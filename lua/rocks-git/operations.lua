---@mod rocks.operations
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
local log = require("rocks.log")
local nio = require("nio")

---@param report_progress fun(message: string)
---@param report_error fun(message: string)
---@param pkg Package
---@return boolean success
---@async
local function build_if_required(report_progress, report_error, pkg)
    if not pkg.build then
        return true
    end
    report_progress(("rocks-git: Building %s"):format(pkg.name))
    if pkg.build:sub(1, 1) == ":" then
        ---@diagnostic disable-next-line: param-type-mismatch
        local ok, err = pcall(vim.cmd, pkg.build)
        if not ok then
            log.error(err)
            report_error(("rocks-git: Failed to build %s"):format(pkg.name))
            return false
        end
    else
        local cmd = {}
        for word in pkg.build:gmatch("%S+") do
            table.insert(cmd, word)
        end
        log.info(cmd)
        local future = nio.control.future()
        vim.system(cmd, { cwd = pkg.dir }, function(sc)
            ---@cast sc vim.SystemCompleted
            if sc.code == 0 then
                future.set(true)
            else
                log.error(sc.stderr)
                future.set_error(sc.stderr)
            end
        end)
        local ok = pcall(future.wait)
        if not ok then
            report_error(("rocks-git: Failed to build %s"):format(pkg.name))
            return false
        end
    end
    return true
end

---@type async fun(report_progress: fun(message: string), report_error: fun(message: string), pkg: Package)
operations.install = nio.create(function(report_progress, report_error, pkg)
    report_progress(("rocks-git: Installing %s"):format(pkg.name))
    local future = git.clone(pkg)
    local ok = pcall(future.wait)
    if not ok then
        report_error(("rocks-git: Failed to clone %s"):format(pkg.url))
    end
    local futureOpt = git.checkout(pkg)
    if futureOpt then
        ok = pcall(futureOpt.wait)
        if not ok then
            report_error(("rocks-git: Failed to checkout %s"):format(pkg.rev))
        end
    end
    ok = build_if_required(report_progress, report_error, pkg)
    if ok then
        report_progress(("rocks-git: Installed %s"):format(pkg.name))
    end
end, 3)

---@type async fun(report_progress: fun(message: string), report_error: fun(message: string), pkg: Package)
operations.sync = nio.create(function(report_progress, report_error, pkg)
    if pkg.rev then
        local rev = git.get_rev(pkg)
        if rev == pkg.rev then
            return
        else
            report_progress(("rocks-git: Scyncing %s"):format(pkg.name))
            local future = git.fetch(pkg)
            local ok = pcall(future.wait)
            if not ok then
                log.warn("rocks-git: Error while fetching package updates during sync")
            end
            local futureOpt = git.checkout(pkg)
            if futureOpt and not pcall(futureOpt.wait) then
                report_error(("rocks-git: Failed to checkout %s"):format(pkg.rev))
            end
            ok = build_if_required(report_progress, report_error, pkg)
            if ok then
                report_progress(("rocks-git: Synced %s"):format(pkg.name))
            end
        end
    else
        report_progress(("rocks-git: Updating %s"):format(pkg.name))
        local head_branch = git.get_head_branch(pkg)
        local rev = git.get_rev(pkg)
        if head_branch ~= rev then
            pkg.rev = head_branch
            local futureOpt = git.checkout(pkg)
            if futureOpt and not pcall(futureOpt.wait) then
                report_error(("rocks-git: Failed to checkout %s"):format(pkg.rev))
            end
        end
        local future = git.pull(pkg)
        local ok = pcall(future.wait)
        if not ok then
            report_error(("rocks-git: Failed to pull %s"):format(pkg.name))
        end
        ok = build_if_required(report_progress, report_error, pkg)
        if ok then
            report_progress(("rocks-git: Updated %s"):format(pkg.name))
        end
    end
end, 3)

---@param dir string
---@return fun(_:any, path:string):(name: string, type: string)
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
