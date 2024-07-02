{
  name,
  self,
  inputs,
}: final: prev: let
  rocks-nvim = inputs.rocks-nvim-input.packages.${final.system}.rocks-nvim;
  luaPackage-override = luaself: luaprev: {
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
in {
  inherit
    luajit
    luajitPackages
    ;

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
