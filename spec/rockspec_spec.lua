local tempdir = vim.fn.tempname()
local plugin_dir = vim.fs.joinpath(tempdir, "foo.nvim")
vim.env.HOME = tempdir
vim.system({ "rm", "-r", tempdir }):wait()
vim.system({ "mkdir", "-p", plugin_dir }):wait()

local rockspec = require("rocks-git.rockspec")
describe("rockspec", function()
    describe("get_dependencies", function()
        local rockspec_content = [[
package = "foo.nvim"
version = "scm-1"

dependencies = {
  "bar >= 1.0.0",
}
]]
        local fh = io.open(vim.fs.joinpath(plugin_dir, "foo.nvim-scm-1.rockspec"), "w+")
        assert(fh, "Cound not open rockspec for writing")
        fh:write(rockspec_content)
        fh:close()
        ---@diagnostic disable-next-line: missing-fields
        local dependencies = rockspec.get_dependencies({
            name = "foo.nvim",
            dir = plugin_dir,
        })
        assert.same({ "bar >= 1.0.0" }, dependencies)
    end)
end)
