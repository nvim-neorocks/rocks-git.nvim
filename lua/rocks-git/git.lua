---@mod rocks.git
---
---@brief [[
---
---Interface for interacting with Git
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

local git = {}

local log = require("rocks.log")
local parser = require("rocks-git.parser")
local nio = require("nio")

---@param args string[] git CLI arguments
---@param on_exit fun(sc: vim.SystemCompleted)|nil Called asynchronously when the git command exits.
---@param opts? vim.SystemOpts
---@return vim.SystemObj | nil
---@see vim.system
local function git_cli(args, on_exit, opts)
    opts = opts or {}
    local git_cmd = vim.list_extend({
        "git",
    }, args)
    log.info(git_cmd)
    ---@type boolean, vim.SystemObj | string
    local ok, so_or_err = pcall(vim.system, git_cmd, opts, on_exit)
    if ok then
        ---@cast so_or_err vim.SystemObj
        return so_or_err
    else
        ---@cast so_or_err string
        ---@type vim.SystemCompleted
        local sc = {
            code = 1,
            signal = 0,
            stderr = ("Failed to invoke git: %s"):format(so_or_err),
        }
        if on_exit then
            on_exit(sc)
        end
    end
end

---Clones the package.
---@param pkg rocks-git.Package
---@param on_exit fun(sc: vim.SystemCompleted)|nil Called asynchronously when the git command exits.
---@return vim.SystemObj | nil
---@see vim.system
local function clone(pkg, on_exit)
    local args = { "clone", pkg.url, "--recurse-submodules", "--shallow-submodules", "--no-single-branch" }
    if pkg.branch then
        vim.list_extend(args, { "-b", pkg.branch })
    end
    table.insert(args, vim.fs.basename(pkg.dir))
    return git_cli(args, on_exit, {
        -- This is always the 'start' or 'opt' directory.
        -- Setting the cwd should prevent issues like
        -- https://github.com/nvim-neorocks/rocks.nvim/issues/554#
        cwd = vim.fs.dirname(pkg.dir),
    })
end

---Clones the package.
---@param pkg rocks-git.Package
---@return nio.control.Future
function git.clone(pkg)
    local future = nio.control.future()
    clone(pkg, function(sc)
        ---@cast sc vim.SystemCompleted
        if sc.code == 0 then
            future.set(true)
        else
            log.error(sc)
            future.set_error(sc.stderr)
        end
    end)
    return future
end

---Checks out the `rev` specified by the package, if one is specified.
---@param pkg rocks-git.Package
---@param on_exit fun(sc: vim.SystemCompleted)|nil Called asynchronously when the git command exits.
---@return vim.SystemObj | nil
---@see vim.system
local function checkout(pkg, on_exit)
    local args = { "checkout", pkg.rev, "--force", "--recurse-submodules" }
    return git_cli(args, on_exit, {
        cwd = pkg.dir,
    })
end

---Checks out the `rev` specified by the package, if one is specified.
---@param pkg rocks-git.Package
---@return nio.control.Future | nil future Returns `nil` if the package doesn't have a `rev` attribute
function git.checkout(pkg)
    if not pkg.rev then
        return
    end
    local future = nio.control.future()
    checkout(pkg, function(sc)
        ---@cast sc vim.SystemCompleted
        if sc.code == 0 then
            future.set(true)
        else
            log.error(sc)
            future.set_error(sc.stderr)
        end
    end)
    return future
end

---Fetches updates to the package
---@param pkg rocks-git.Package
---@param on_exit fun(sc: vim.SystemCompleted)|nil Called asynchronously when the git command exits.
---@return vim.SystemObj | nil
---@see vim.system
local function fetch(pkg, on_exit)
    local args = { "fetch" }
    return git_cli(args, on_exit, {
        cwd = pkg.dir,
    })
end

---Checks out the `rev` specified by the package, if one is specified.
---@param pkg rocks-git.Package
---@return nio.control.Future
function git.fetch(pkg)
    local future = nio.control.future()
    ---@cast pkg rocks-git.Package
    fetch(pkg, function(sc)
        ---@cast sc vim.SystemCompleted
        if sc.code == 0 then
            future.set(true)
        else
            log.error(sc)
            future.set_error(sc.stderr)
        end
    end)
    return future
end

---Pulls the package
---@param pkg rocks-git.Package
---@param on_exit fun(sc: vim.SystemCompleted)|nil Called asynchronously when the git command exits.
---@return vim.SystemObj | nil
---@see vim.system
local function pull(pkg, on_exit)
    local args = { "pull", "--recurse-submodules", "--update-shallow" }
    return git_cli(args, on_exit, {
        cwd = pkg.dir,
    })
end

---Pulls the package
---@param pkg rocks-git.Package
---@return nio.control.Future
function git.pull(pkg)
    local future = nio.control.future()
    pull(pkg, function(sc)
        ---@cast sc vim.SystemCompleted
        if sc.code == 0 then
            future.set(true)
        else
            log.error(sc)
            future.set_error(sc.stderr)
        end
    end)
    return future
end

---@param path string
---@return string | nil
local function read_line(path)
    local file = io.open(path)
    if file then
        local line = file:read()
        file:close()
        return line
    end
end

---@param pkg rocks-git.Package
---@return string | nil rev The git hash or tag that is currently checked out
function git.get_checked_out_rev(pkg)
    local git_dir = vim.fs.joinpath(pkg.dir, ".git")
    local head_ref = read_line(vim.fs.joinpath(git_dir, "HEAD"))
    if not head_ref then
        return
    end
    head_ref = head_ref:gsub("ref: ", "")
    local tag = head_ref:match("tags/(.+)")
    return tag or read_line(vim.fs.joinpath(git_dir, head_ref))
end

---@param pkg rocks-git.Package
---@return string | nil head The remote HEAD branch name
function git.get_head_branch(pkg)
    local git_dir = vim.fs.joinpath(pkg.dir, ".git")
    local remote_head_ref = read_line(vim.fs.joinpath(git_dir, "refs", "remotes", "origin", "HEAD"))
    if not remote_head_ref then
        return
    end
    remote_head_ref = remote_head_ref:gsub("ref: refs/remotes/origin/", "")
    return remote_head_ref
end

---@param url string
---@param on_exit fun(sc: vim.SystemCompleted)|nil Called asynchronously when the git command exits.
---@return vim.SystemObj | nil
local function get_latest_remote_version_tag(url, on_exit)
    local args = { "ls-remote", "--tags", url }
    return git_cli(args, on_exit)
end

---@alias tag_version_tuple { [1]: string?, [2]: vim.Version?}

---@param url string
---@return nio.control.Future
function git.get_latest_remote_semver_tag(url)
    local future = nio.control.future()
    get_latest_remote_version_tag(url, function(sc)
        ---@cast sc vim.SystemCompleted
        if sc.code == 0 then
            local latest_tag, latest_version = parser.parse_git_latest_semver_tag(sc.stdout or "")
            if latest_tag and latest_version then
                future.set({ latest_tag, latest_version })
            else
                log.warn("Could not parse latest tag from: " .. sc.stdout)
                future.set({})
            end
        else
            log.warn(sc.stderr)
            future.set({})
        end
    end)
    return future
end

---@type async fun(pkg: rocks-git.Package):boolean
git.is_outdated = nio.create(function(pkg)
    ---@cast pkg rocks-git.Package
    local future = nio.control.future()
    if not pkg.rev then
        git_cli({ "status", "--untracked-files=no" }, function(sc)
            if sc.code ~= 0 then
                log.error(sc)
                future.set(false)
            else
                future.set(sc.stdout:match("Your branch is up to date") == nil)
            end
        end, { cwd = pkg.dir })
        return future.wait()
    end
    local is_semver, version = pcall(vim.version.parse, pkg.rev)
    if is_semver and version then
        local version_tuple = git.get_latest_remote_semver_tag(pkg.url).wait()
        ---@cast version_tuple tag_version_tuple
        local latest_version = version_tuple[2]
        if not latest_version then
            log.error(("rocks-git: could not determine latest version for %s"):format(vim.inspect(pkg)))
            return false
        end
        return version:__lt(latest_version)
    end
    log.info(("rocks-git: rev is not semver. Cannot determine if outdated: %s"):format(vim.inspect(pkg)))
    return false
end, 1)

return git
