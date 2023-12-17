{
  description = "Use rocks.nvim to install plugins from git!";

  nixConfig = {
    extra-substituters = "https://neorocks.cachix.org";
    extra-trusted-public-keys = "neorocks.cachix.org-1:WqMESxmVTOJX7qoBC54TwrMMoVI1xAM+7yFin8NRfwk=";
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";

    neorocks.url = "github:nvim-neorocks/neorocks";

    flake-parts.url = "github:hercules-ci/flake-parts";

    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    neorocks,
    flake-parts,
    pre-commit-hooks,
    ...
  }: let
    name = "rocks.nvim";

    plugin-overlay = import ./nix/plugin-overlay.nix {
      inherit name self;
    };
    test-overlay = import ./nix/test-overlay.nix {
      inherit self;
    };
  in
    flake-parts.lib.mkFlake {inherit inputs;} {
      systems = [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-darwin"
      ];
      perSystem = {
        config,
        self',
        inputs',
        system,
        ...
      }: let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [
            plugin-overlay
            neorocks.overlays.default
            test-overlay
          ];
        };

        mkTypeCheck = {
          nvim-api ? [],
          disabled-diagnostics ? [],
        }:
          pre-commit-hooks.lib.${system}.run {
            src = self;
            hooks = {
              lua-ls.enable = true;
            };
            settings = {
              lua-ls = {
                config = {
                  runtime.version = "LuaJIT";
                  Lua = {
                    workspace = {
                      library =
                        nvim-api
                        ++ (with pkgs.lua51Packages; [
                          "${rocks-nvim}/lib/lua/5.1/"
                        ])
                        ++ [
                          "\${3rd}/busted/library"
                          "\${3rd}/luassert/library"
                        ];
                      ignoreDir = [
                        ".git"
                        ".github"
                        ".direnv"
                        "result"
                        "nix"
                        "doc"
                      ];
                    };
                    diagnostics = {
                      libraryFiles = "Disable";
                      disable = disabled-diagnostics;
                    };
                  };
                };
              };
            };
          };

        type-check-nightly = mkTypeCheck {
          nvim-api = [
            "${pkgs.neovim-nightly}/share/nvim/runtime/lua"
            "${pkgs.vimPlugins.neodev-nvim}/types/nightly"
          ];
        };

        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = self;
          hooks = {
            alejandra.enable = true;
            stylua.enable = true;
            luacheck.enable = true;
            editorconfig-checker.enable = true;
          };
        };

        devShell = pkgs.mkShell {
          name = "rocks-git.nvim devShell";
          inherit (pre-commit-check) shellHook;
          buildInputs = with pre-commit-hooks.packages.${system}; [
            alejandra
            lua-language-server
            stylua
            luacheck
            editorconfig-checker
          ];
        };
      in {
        devShells = {
          default = devShell;
          inherit devShell;
        };

        packages = rec {
          default = docgen; # TODO: Package rocks.nvim for nixpkgs
          # default = rocks-git-nvim;
          # inherit (pkgs.vimPlugins) rocks-git-nvim;
          inherit
            (pkgs)
            docgen
            ;
        };

        # TODO: add type-check-stable when ready
        checks = {
          inherit
            pre-commit-check
            # TODO: type-check-nightly
            
            ;
        };
      };
      flake = {
        overlays.default = plugin-overlay;
      };
    };
}
