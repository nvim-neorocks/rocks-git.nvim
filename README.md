<!-- markdownlint-disable -->
<br />
<div align="center">
  <a href="https://github.com/nvim-neorocks/rocks-git.nvim">
    <img src="./rocks-header.svg" alt="rocks-git.nvim">
  </a>
  <p align="center">
    <br />
    <a href="./doc/rocks-git.txt"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/nvim-neorocks/rocks-git.nvim/issues/new?assignees=&labels=bug">Report Bug</a>
    ·
    <a href="https://github.com/nvim-neorocks/rocks-git.nvim/issues/new?assignees=&labels=enhancement">Request Feature</a>
    ·
    <a href="https://github.com/nvim-neorocks/rocks.nvim/discussions/new?category=q-a">Ask Question</a>
  </p>
  <p>
    <strong>
      Use <a href="https://github.com/nvim-neorocks/rocks.nvim/">rocks.nvim</a> to install plugins from git!
    </strong>
  </p>
</div>
<!-- markdownlint-restore -->

[![LuaRocks][luarocks-shield]][luarocks-url]

## :star2: Summary

`rocks-git.nvim` extends [`rocks.nvim`](https://github.com/nvim-neorocks/rocks-git.nvim)
with the ability to install plugins into `packpath` directories ([`:h packages`](https://neovim.io/doc/user/repeat.html#packages))
from git repositories.

It does so by hooking into the `:Rocks {install|update|sync|prune}` commands,
allowing you to add `plugins` entries to your `rocks.toml` as follows:

```toml
[plugins.neorg]
git = "nvim-neorg/neorg"

# or...

[plugins]
neorg = { git = "nvim-neorg/neorg" }
```

> [!IMPORTANT]
>
> This plugin is meant as a **simple, minimal** bridge for plugins that cannot
> be installed with luarocks.
>
> For Lua plugins, we recommend requesting (or creating a PR)
> to upload them to luarocks, as this enables proper SemVer versioning.

## :pencil: Requirements

- `rocks.nvim >= 2.12.0`
- The `git` command line utility.

## :hammer: Installation

Simply run `:Rocks install rocks-git.nvim`,
and you are good to go!

## :books: Usage

You can use the same `:Rocks {install|update|sync|prune}` commands as you would
use to install rocks with `rocks.nvim`.

The only difference is the `:Rocks install {plugin} {args?}` command.

Arguments:

- `plugin`: The plugin short name[^1], e.g. `owner/repo` or a git HTTPS/SSH URL.
- `args`: (optional) `key=value` pairs, see [Configuration options](#configuration-options).

If a plugin is not pinned to a revision or tag with the `rev` field,
`:Rocks sync` will always update it to the latest remote revision.

### Configuration options

The following fields can be set in a `rocks.toml` entry
that is managed by this plugin:

| Field    | Type      | Required?             | Description                                                                                          |
|:--       |:--        |:--                    |:--                                                                                                   |
| `name`   | `string`  | Yes                   | Name of the plugin                                                                                   |
| `git`    | `string`  | Yes                   | Git short name[^1], e.g. `"nvim-neorocks/rocks-git.nvim"` or a git URL.                              |
| `opt`    | `boolean` | No (default: `false`) | Plugins with `opt = true` will not be loaded on startup. See `:h packadd`                            |
| `rev`    | `string`  | No                    | Git revision or tag to checkout                                                                      |
| `branch` | `string`  | No                    | Git branch to checkout                                                                               |
| `build`  | `string`  | No                    | Shell or Vimscript command to run after install/update. Will run a vim command if prefixed with `:`  |

[^1]: Also supports `github:`, `gitlab:` and `sourcehut:` prefixes, e.g. `gitlab:owner/repo` (HTTPS only).

> [!TIP]
>
> See also [`:h rocks-git`](./doc/rocks-git.txt).

## :stethoscope: Troubleshooting

Git commands and error logs will show up in `:Rocks log`.

## :book: License

`rocks-git.nvim` is licensed under [GPLv3](./LICENSE).

## :green_heart: Contributing

Contributions are more than welcome!
See [CONTRIBUTING.md](./CONTRIBUTING.md) for a guide.

[luarocks-shield]: https://img.shields.io/luarocks/v/neorocks/rocks-git.nvim?logo=lua&color=purple&style=for-the-badge
[luarocks-url]: https://luarocks.org/modules/neorocks/rocks-git.nvim
