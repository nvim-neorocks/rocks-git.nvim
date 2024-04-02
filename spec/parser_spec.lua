local parser = require("rocks-git.parser")
describe("Parser", function()
    describe("is_git_url", function()
        it("Can recognize git SSH URLs", function()
            local url = "git@github.com:nvim-neorocks/rocks-git.nvim.git"
            assert.True(parser.is_git_url(url))
        end)

        it("Can recognize git HTTPS URLs", function()
            local url = "https://github.com/nvim-neorocks/rocks-git.nvim.git"
            assert.True(parser.is_git_url(url))
        end)

        it("Can recognize non-git URLs", function()
            local url = "https://github.com/nvim-neorocks/rocks-git.nvim"
            assert.False(parser.is_git_url(url))
        end)
    end)

    describe("is_github_shorthand", function()
        it("Can recognize GitHub shorthand", function()
            local url = "nvim-neorocks/rocks-git.nvim"
            assert.True(parser.is_github_shorthand(url))
        end)
    end)

    describe("plugin_name_from_git_uri", function()
        it("Can get plugin name from git SSH URLs", function()
            local url = "git@github.com:nvim-neorocks/rocks-git.nvim.git"
            assert.same("rocks-git.nvim", parser.plugin_name_from_git_uri(url))
        end)

        it("Can get plugin name from git HTTPS URLs", function()
            local url = "https://github.com/nvim-neorocks/rocks-git.nvim.git"
            assert.same("rocks-git.nvim", parser.plugin_name_from_git_uri(url))
        end)

        it("Can get plugin name from GitHub shorthand", function()
            local url = "nvim-neorocks/rocks-git.nvim"
            assert.same("rocks-git.nvim", parser.plugin_name_from_git_uri(url))
        end)
    end)

    describe("parse_git_url", function()
        it("Can parse SSH URL from GitHub shorthand", function()
            local shorthand = "nvim-neorocks/rocks-git.nvim"
            local url = "https://github.com/nvim-neorocks/rocks-git.nvim.git"
            assert.same(url, parser.parse_git_url(shorthand))
        end)
    end)

    describe("parse_install_args", function()
        it("Parses GitInstallSpec from version", function()
            assert.same({ rev = "1.0.0" }, parser.parse_install_args({ "1.0.0" }).spec)
            assert.same({ rev = "2.0.0" }, parser.parse_install_args({ "2.0.0" }).spec)
        end)

        it("Parses GitInstallSpec from arg list", function()
            assert.same({ rev = "1.0.0" }, parser.parse_install_args({ "rev=1.0.0" }).spec)
            assert.same(
                { rev = "1.0.0", opt = true, branch = "main", build = "foo" },
                parser.parse_install_args({ "rev=1.0.0", "opt=true", "branch=main", "build=foo" }).spec
            )
        end)

        it("Detects invalid args", function()
            assert.same(
                { "vranch=main" },
                parser.parse_install_args({ "rev=1.0.0", "opt=true", "vranch=main", "build=foo" }).invalid_args
            )
            assert.same({ "op=true" }, parser.parse_install_args({ "opt=true", "op=true" }).invalid_args)
        end)

        it("Single arg without a field prefix is rev/version", function()
            assert.same({ rev = "1.0.0", opt = true }, parser.parse_install_args({ "1.0.0", "opt=true" }).spec)
            assert.same({ rev = "1.0.0", opt = true }, parser.parse_install_args({ "opt=true", "1.0.0" }).spec)
        end)

        it("Multiple args without a field prefix are invalid", function()
            assert.same({ "1.0.0", "foo" }, parser.parse_install_args({ "1.0.0", "opt=true", "foo" }).invalid_args)
        end)

        it("Non-boolean opt is invalid", function()
            assert.same({ opt = true }, parser.parse_install_args({ "opt=true" }).spec)
            assert.same({ opt = true }, parser.parse_install_args({ "opt=1" }).spec)
            assert.same({ opt = false }, parser.parse_install_args({ "opt=false" }).spec)
            assert.same({ opt = false }, parser.parse_install_args({ "opt=0" }).spec)
            assert.same({ "opt=3" }, parser.parse_install_args({ "opt=3" }).invalid_args)
            assert.same({ "opt=otherwise" }, parser.parse_install_args({ "opt=otherwise" }).invalid_args)
        end)

        it("Does not accept conflicting args", function()
            assert.same(
                { "opt=false", "opt=true" },
                parser.parse_install_args({ "opt=true", "opt=false" }).conflicting_args
            )
        end)
    end)

    it("parse_git_latest_semver_tag", function()
        local stdout = [[
          4987d4159df2f80eb1deda1793ad54082d8ba454        refs/tags/4.7.5
          5e94188c6df48a26c259008cdf3e7d11d379a6e9        refs/tags/4.8.0
          ed780369fa5fe399d8812d473e4108b01633734e        refs/tags/4.9.0
          b44e1db9056d74cc491aa4a3f625f8bdca0d6743        refs/tags/4.10.0
          b5342fcd1f8dc694d375983c60df928b58a02eb4        refs/tags/4.10.1
          6865782798bdca0d8f1b3a598fef878b001422d8        refs/tags/latest
        ]]
        assert.same("4.10.1", parser.parse_git_latest_semver_tag(stdout))
    end)
end)
