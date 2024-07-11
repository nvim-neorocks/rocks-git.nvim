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

    rocks-nvim-flake = {
      url = "github:nvim-neorocks/rocks.nvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
    name = "rocks.nvim";

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
            test-overlay
            plugin-overlay
          ];
        };

        luarc = pkgs.mk-luarc {
          nvim = pkgs.neovim-nightly;
          plugins = with pkgs.luajitPackages; [
            rocks-nvim
            nvim-nio
          ];
          disabled-diagnostics = [
            # caused by a nio luaCATS bug
            "redundant-return-value"
          ];
        };

        type-check-nightly = pre-commit-hooks.lib.${system}.run {
          src = self;
          hooks = {
            lua-ls = {
              enable = true;
              settings = {
                lua-ls.configuration = luarc;
              };
            };
          };
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

        devShell = pkgs.integration-nightly.overrideAttrs (oa: {
          name = "rocks-git.nvim devShell";
          shellHook = ''
            ${pre-commit-check.shellHook}
            ln -fs ${pkgs.luarc-to-json luarc} .luarc.json
          '';
          buildInputs =
            self.checks.${system}.pre-commit-check.enabledPackages
            ++ (with pkgs; [
              lua-language-server
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
            ;
          inherit (pkgs) integration-nightly;
        };
      };
      flake = {
        overlays.default = plugin-overlay;
      };
    };
}
