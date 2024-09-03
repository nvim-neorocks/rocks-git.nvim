{
  description = "Use rocks.nvim to install plugins from git!";

  nixConfig = {
    extra-substituters = "https://neorocks.cachix.org";
    extra-trusted-public-keys = "neorocks.cachix.org-1:WqMESxmVTOJX7qoBC54TwrMMoVI1xAM+7yFin8NRfwk=";
  };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs";

    neorocks.url = "github:nvim-neorocks/neorocks";

    gen-luarc.url = "github:mrcjkb/nix-gen-luarc-json";

    rocks-nvim-flake.url = "github:nvim-neorocks/rocks.nvim";

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
    gen-luarc,
    rocks-nvim-flake,
    flake-parts,
    pre-commit-hooks,
    ...
  }: let
    name = "rocks-git.nvim";

    plugin-overlay = import ./nix/plugin-overlay.nix {
      inherit name self inputs;
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
            neorocks.overlays.default
            gen-luarc.overlays.default
            rocks-nvim-flake.overlays.default
            test-overlay
            plugin-overlay
          ];
        };

        mk-luarc = nvim:
          pkgs.mk-luarc {
            nvim = pkgs.neovim-nightly;
            plugins = with pkgs.luajitPackages; [
              inputs.rocks-nvim-flake.packages.${pkgs.system}.rocks-nvim
              nvim-nio
            ];
          };

        luarc-nightly = mk-luarc pkgs.neovim-nightly;
        luarc-stable = mk-luarc pkgs.neovim-unwrapped;

        mk-typecheck = luarc:
          pre-commit-hooks.lib.${system}.run {
            src = self;
            hooks = {
              lua-ls = {
                enable = true;
                settings.configuration = luarc;
              };
            };
          };

        type-check-nightly = mk-typecheck luarc-nightly;
        type-check-stable = mk-typecheck luarc-stable;

        pre-commit-check = pre-commit-hooks.lib.${system}.run {
          src = self;
          hooks = {
            alejandra.enable = true;
            stylua.enable = true;
            luacheck.enable = true;
            editorconfig-checker.enable = true;
          };
        };

        devShell = pkgs.integration-nightly.overrideAttrs (oa: {
          name = "rocks-git.nvim devShell";
          shellHook = ''
            ${pre-commit-check.shellHook}
            ln -fs ${pkgs.luarc-to-json luarc-nightly} .luarc.json
          '';
          buildInputs =
            self.checks.${system}.pre-commit-check.enabledPackages
            ++ (with pkgs; [
              lua-language-server
              docgen
            ])
            ++ oa.buildInputs;
          doCheck = false;
        });
      in {
        devShells = {
          default = devShell;
          inherit devShell;
        };

        packages = rec {
          default = rocks-git-nvim;
          inherit (pkgs.luajitPackages) rocks-git-nvim;
          inherit
            (pkgs)
            docgen
            neovim-with-rocks
            ;
        };

        # TODO: add type-check-stable when ready
        checks = {
          inherit
            pre-commit-check
            type-check-nightly
            type-check-stable
            ;
          inherit (pkgs) integration-nightly;
        };
      };
      flake = {
        overlays.default = plugin-overlay;
      };
    };
}
