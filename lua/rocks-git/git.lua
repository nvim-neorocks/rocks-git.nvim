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

---@param args string[] git CLI arguments
---@param on_exit fun(sc: vim.SystemCompleted)|nil Called asynchronously when the git command exits.
---@param opts? SystemOpts
---@return vim.SystemObj
---@see vim.system
local function git_cli(args, on_exit, opts)
    opts = opts or {}
    local git_cmd = vim.list_extend({
        "git",
    }, args)
    log.info(git_cmd)
    return vim.system(git_cmd, opts, on_exit)
end

---Clones the package.
---@param pkg Package
---@param on_exit fun(sc: vim.SystemCompleted)|nil Called asynchronously when the git command exits.
---@param opts? SystemOpts
---@return vim.SystemObj
---@see vim.system
function git.clone(pkg, on_exit, opts)
    local args = { "clone", pkg.url, "--recurse-submodules", "--shallow-submodules", "--no-single-branch" }
    if pkg.branch then
        vim.list_extend(args, { "-b", pkg.branch })
    end
    table.insert(args, pkg.dir)
    return git_cli(args, on_exit, opts)
end

---Checks out the `rev` specified by the package, if one is specified.
---@param pkg Package
---@param on_exit fun(sc: vim.SystemCompleted)|nil Called asynchronously when the git command exits.
---@return vim.SystemObj | nil
---@see vim.system
function git.checkout(pkg, on_exit)
    if not pkg.rev then
        return
    end
    local args = { "checkout", pkg.rev, "--force", "--recurse-submodules" }
    return git_cli(args, on_exit, {
        cwd = pkg.dir,
    })
end

---Fetches updates to the package
---@param pkg Package
---@param on_exit fun(sc: vim.SystemCompleted)|nil Called asynchronously when the git command exits.
---@return vim.SystemObj | nil
---@see vim.system
function git.fetch(pkg, on_exit)
    local args = { "fetch" }
    return git_cli(args, on_exit, {
        cwd = pkg.dir,
    })
end

---Pulls the package
---@param pkg Package
---@param on_exit fun(sc: vim.SystemCompleted)|nil Called asynchronously when the git command exits.
---@return vim.SystemObj | nil
---@see vim.system
function git.pull(pkg, on_exit)
    local args = { "pull", "--recurse-submodules", "--update-shallow" }
    return git_cli(args, on_exit, {
        cwd = pkg.dir,
    })
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

---@param pkg Package
---@return string | nil rev The git hash or tag that is currently checked out
function git.get_rev(pkg)
    local git_dir = vim.fs.joinpath(pkg.dir, ".git")
    local head_ref = read_line(vim.fs.joinpath(git_dir, "HEAD"))
    if not head_ref then
        return
    end
    head_ref = head_ref:gsub("ref: ", "")
    local tag = head_ref:match("tags/(.+)")
    return tag or read_line(vim.fs.joinpath(git_dir, head_ref))
end

return git
