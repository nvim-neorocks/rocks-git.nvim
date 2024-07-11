{
  name,
  self,
  inputs,
}: final: prev: let
  luaPackage-override = luaself: luaprev: let
    rocks-nvim = inputs.rocks-nvim-flake.packages.${final.system}.rocks-nvim;
  in {
    rocks-git-nvim = luaself.callPackage ({
      luaOlder,
      buildLuarocksPackage,
      lua,
    }:
      buildLuarocksPackage {
        pname = name;
        version = "scm-1";
        knownRockspec = "${self}/rocks-git.nvim-scm-1.rockspec";
        src = self;
        disabled = luaOlder "5.1";
        propagatedBuildInputs = [
          rocks-nvim
        ];
      }) {};
  };
  luajit = prev.luajit.override {
    packageOverrides = luaPackage-override;
  };
  luajitPackages = prev.luajitPackages // final.luajit.pkgs;
  lua5_1 = prev.lua5_1.override {
    packageOverrides = luaPackage-override;
  };
  lua51Packages = prev.lua51Packages // final.lua5_1.pkgs;

  neovim-with-rocks = let
    rocks = inputs.rocks-nvim-flake.packages.${final.system}.rocks-nvim;
    rocks-git = final.luajitPackages.rocks-git-nvim;
    neovimConfig = final.neovimUtils.makeNeovimConfig {
      withPython3 = true;
      viAlias = false;
      vimAlias = false;
      plugins = [
        {
          plugin = final.vimPlugins.rocks-git-nvim;
          optional = true;
        }
      ];
    };
  in
    (final.wrapNeovimUnstable final.neovim-nightly (neovimConfig
      // {
        luaRcContent =
          /*
          lua
          */
          ''
            -- Copied from installer.lua
            local rocks_config = {
                rocks_path = vim.fn.stdpath("data") .. "/rocks",
                luarocks_binary = "${final.luajitPackages.luarocks}/bin/luarocks",
            }

            vim.g.rocks_nvim = rocks_config

            local luarocks_path = {
                vim.fs.joinpath("${rocks}", "share", "lua", "5.1", "?.lua"),
                vim.fs.joinpath("${rocks}", "share", "lua", "5.1", "?", "init.lua"),
                vim.fs.joinpath("${rocks-git}", "share", "lua", "5.1", "?.lua"),
                vim.fs.joinpath("${rocks-git}", "share", "lua", "5.1", "?", "init.lua"),
                vim.fs.joinpath(rocks_config.rocks_path, "share", "lua", "5.1", "?.lua"),
                vim.fs.joinpath(rocks_config.rocks_path, "share", "lua", "5.1", "?", "init.lua"),
            }
            package.path = package.path .. ";" .. table.concat(luarocks_path, ";")

            local luarocks_cpath = {
                vim.fs.joinpath(rocks_config.rocks_path, "lib", "lua", "5.1", "?.so"),
                vim.fs.joinpath(rocks_config.rocks_path, "lib64", "lua", "5.1", "?.so"),
            }
            package.cpath = package.cpath .. ";" .. table.concat(luarocks_cpath, ";")

            vim.opt.runtimepath:append(vim.fs.joinpath("${rocks}", "rocks.nvim-scm-1-rocks", "rocks.nvim", "*"))
          '';
        wrapRc = true;
        wrapperArgs =
          final.lib.escapeShellArgs neovimConfig.wrapperArgs
          + " "
          + ''--set NVIM_APPNAME "nvimrocks"'';
      }))
    .overrideAttrs (oa: {
      nativeBuildInputs =
        oa.nativeBuildInputs
        ++ [
          final.luajit.pkgs.wrapLua
          # rocks
        ];
    });
in {
  inherit
    luajit
    luajitPackages
    lua5_1
    lua51Packages
    neovim-with-rocks
    ;

  rocks-git-nvim = luajitPackages.rocks-git-nvim;
  vimPlugins =
    prev.vimPlugins
    // {
      rocks-git-nvim = final.neovimUtils.buildNeovimPlugin {
        pname = name;
        version = "dev";
        src = self;
      };
    };
}
