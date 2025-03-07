---@mod rocks-git.parser
---
---@brief [[
---
---Parsing functions
---
---@brief ]]

-- Copyright (C) 2023 Neorocks Org.
--
-- Version:    0.1.0
-- License:    GPLv3
-- Created:    27 Feb 2024
-- Updated:    08 Apr 2024
-- Homepage:   https://github.com/nvim-neorocks/rocks-git.nvim
-- Maintainer: mrcjkb <marc@jakobi.dev>

local config = require("rocks-git.config")

local parser = {}

---@class GitInstallSpec
---@field opt? boolean If 'true', will not be loaded on startup. Can be loaded manually with `:packadd!`.
---@field rev? string Git revision or tag to checkout.
---@field branch? string Git branch to checkout.
---@field build? string Shell or Vimscript command to run after install/update. Will run a vim command if prefixed with ':'.
---@field ignore_tags? boolean Ignore tags when updating and prioritise git revisions.

---@param str string
---@return boolean
function parser.is_git_url(str)
    return str:match("^https?://") ~= nil or str:match("^git@") ~= nil
end

---@param str string
---@return boolean
function parser.is_repo_shorthand(str)
    if #(vim.split(str, "/")) ~= 2 then
        return false
    end
    if str:find(":") == nil then
        return true
    end
    local prefix = str:match("([^:]+):[^/]+/[^/]")
    return prefix == "gitlab" or prefix == "sourcehut" or prefix == "github" or prefix == "codeberg"
end

local shorthand_format_map = {
    github = "https://github.com/%s.git",
    gitlab = "https://gitlab.com/%s.git",
    sourcehut = "https://git.sr.ht/~%s",
    codeberg = "https://codeberg.org/~%s.git",
}

---@param str string
---@return string?
local function parse_shorthand_url(str)
    local prefix, owner_repo = str:match("([^:]+):([^/]+/[^/]+)")
    local url_format = prefix and shorthand_format_map[prefix]
    return url_format and url_format:format(owner_repo)
end

---@param str string
function parser.parse_git_url(str)
    return parser.is_git_url(str) and str or parse_shorthand_url(str) or config.url_format:format(str)
end

---@param url string
---@return string?
function parser.plugin_name_from_git_uri(url)
    return url:match("/([^%/]+)%.git$") or url:match("/([^%/]+)$")
end

---@param str string
---@return boolean?
local function str_to_bool(str)
    local map = { ["true"] = true, ["1"] = true, ["false"] = false, ["0"] = false }
    return map[str]
end

---@enum GitInstallSpecField
local GitInstallSpecField = {
    rev = tostring,
    opt = str_to_bool,
    branch = tostring,
    build = tostring,
    ignore_tags = str_to_bool,
}

---@class ParseInstallArgsResult
---@field invalid_args string[]
---@field conflicting_args string[]
---@field spec GitInstallSpec

---@param args string[]
---@return ParseInstallArgsResult
function parser.parse_install_args(args)
    ---@type ParseInstallArgsResult
    local result = vim.iter(args):fold({ invalid_args = {}, conflicting_args = {}, spec = {} }, function(acc, arg)
        ---@cast acc ParseInstallArgsResult
        local field, value = arg:match("^([^=]+)=(.+)")
        if not field or not value then
            table.insert(acc.invalid_args, arg)
            return acc
        end
        local mapper = GitInstallSpecField[field]
        if not mapper then
            table.insert(acc.invalid_args, arg)
            return acc
        end
        local mapped_value = mapper(value)
        if mapped_value == nil then
            table.insert(acc.invalid_args, arg)
            return acc
        end
        if acc.spec[field] and acc.spec[field] ~= mapped_value then
            table.insert(acc.conflicting_args, arg)
            table.insert(acc.conflicting_args, field .. "=" .. tostring(acc.spec[field]))
            return acc
        end
        acc.spec[field] = mapped_value
        return acc
    end)
    if not result.spec.rev and #result.invalid_args == 1 and result.invalid_args[1]:find("=") == nil then
        -- Single arg without a field prefix = version.
        result.spec.rev = result.invalid_args[1]
        result.invalid_args = {}
    end
    return result
end

---@param stdout string
---@return string | nil
---@return vim.Version | nil
function parser.parse_git_latest_semver_tag(stdout)
    local latest_tag = nil
    local latest_version = nil
    for tag in stdout:gmatch("refs/tags/([^\n]+)") do
        local version = parser.get_version(tag)
        if version and latest_version and version > latest_version then
            latest_tag = tag
            latest_version = version
        elseif version and not latest_version then
            latest_tag = tag
            latest_version = version
        end
    end
    return latest_tag, latest_version
end

---@param rev string?
---@return boolean
function parser.is_version(rev)
    if not rev then
        return false
    end
    if tonumber(rev) then
        return true
    end
    local version_str = rev:gsub("v", "")
    return vim.iter(vim.gsplit(version_str, ".", { plain = true })):all(function(str)
        return tonumber(str) ~= nil
    end)
end

---@param rev string?
---@return vim.Version?
function parser.get_version(rev)
    if not parser.is_version(rev) then
        return
    end
    local ok, version = pcall(vim.version.parse, rev)
    return ok and version or nil
end

return parser
