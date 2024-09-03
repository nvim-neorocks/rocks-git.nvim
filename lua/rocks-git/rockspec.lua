---@mod rocks-git.rockspec
---
---@brief [[
---
---Get dependencies from a rockspec in the repository root
---
---@brief ]]

-- Copyright (C) 2024 Neorocks Org.
--
-- License:    GPLv3
-- Created:    03 Sep 2024
-- Updated:    03 Sep 2024
-- Homepage:   https://github.com/nvim-neorocks/rocks-git.nvim
-- Maintainer: mrcjkb <marc@jakobi.dev>

local log = require("rocks.log")

local rockspec = {}

---@param pkg rocks-git.Package
---@return string[]
function rockspec.get_dependencies(pkg)
    local rockspec_paths = vim.fs.find(function(name, path)
        return pkg.dir == path
            and vim
                .iter({ "scm", "dev", "git" })
                ---@param specrev string
                :map(function(specrev)
                    return pkg.name .. "%-" .. specrev .. "%-%d.rockspec"
                end)
                ---@param pattern string
                :any(function(pattern)
                    return name:match(pattern) ~= nil
                end)
    end, {
        path = pkg.dir,
        upward = false,
    })
    if vim.tbl_isempty(rockspec_paths) then
        return {}
    end
    local rockspec_path = rockspec_paths[1]
    local rockspec_tbl = {}
    xpcall(function()
        loadfile(rockspec_path, "t", rockspec_tbl)()
    end, function(err)
        log.error("rocks-git: Could not load rockspec: " .. err)
    end)
    return rockspec_tbl.dependencies or {}
end

return rockspec
