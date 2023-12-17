# Contributing guide

Contributions are more than welcome!

## Commit messages / PR title

Please ensure your pull request title conforms to [Conventional Commits](https://www.conventionalcommits.org/en/v1.0.0/).

## CI

Our CI checks are run using [`nix`](https://nixos.org/download.html#download-nix).

## Development

### Dev environment

We use the following tools:

#### Formatting

- [`.editorconfig`](https://editorconfig.org/) (with [`editorconfig-checker`](https://github.com/editorconfig-checker/editorconfig-checker))
- [`stylua`](https://github.com/JohnnyMorganz/StyLua) [Lua]
- [`alejandra`](https://github.com/kamadorueda/alejandra) [Nix]

#### Linting

- [`luacheck`](https://github.com/mpeterv/luacheck)

#### Static type checking

- [`lua-language-server`](https://github.com/LuaLS/lua-language-server/wiki/Diagnosis-Report#create-a-report)

### Nix devShell

- Requires [flakes](https://nixos.wiki/wiki/Flakes) to be enabled.

We provide a `flake.nix` that can bootstrap all of the above development tools.

To enter a development shell:

```console
nix develop
```

To apply formatting, while in a devShell, run

```console
pre-commit run --all
```

If you use [`direnv`](https://direnv.net/),
just run `direnv allow` and you will be dropped in this devShell.

### Running checks with Nix

If you just want to run all checks that are available, run:

```console
nix flake check -L --option sandbox false
```

For formatting and linting:

```console
nix build .#checks.<your-system>.pre-commit-check -L
```

<!-- For static type checking: -->
<!---->
<!-- ```console -->
<!-- nix build .#checks.<your-system>.type-check-nightly -L -->
<!-- ``` -->
