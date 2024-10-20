# Changelog

## [2.4.1](https://github.com/nvim-neorocks/rocks-git.nvim/compare/v2.4.0...v2.4.1) (2024-10-20)


### Bug Fixes

* ensure packpath directories exist ([#69](https://github.com/nvim-neorocks/rocks-git.nvim/issues/69)) ([f1a5224](https://github.com/nvim-neorocks/rocks-git.nvim/commit/f1a5224b916c950456757b98102e8814a78924c9))

## [2.4.0](https://github.com/nvim-neorocks/rocks-git.nvim/compare/v2.3.2...v2.4.0) (2024-10-18)


### Features

* `ignore_tags` option ([#67](https://github.com/nvim-neorocks/rocks-git.nvim/issues/67)) ([fdf945b](https://github.com/nvim-neorocks/rocks-git.nvim/commit/fdf945ba7ee26ff1db2ae5acb3683c472817c537))


### Bug Fixes

* **update:** don't overwrite semver tag if latest tag is not semver ([fca321d](https://github.com/nvim-neorocks/rocks-git.nvim/commit/fca321d20e87298d0ff92efb1d4f1cfe9296f929))
* **update:** non-semver packages with no branch checked out fail to update ([93cd2c3](https://github.com/nvim-neorocks/rocks-git.nvim/commit/93cd2c34e1cb80ed6866454c3c3927f0d7158cb3))
* **update:** packages with non-semver rev not updated ([#64](https://github.com/nvim-neorocks/rocks-git.nvim/issues/64)) ([796b36a](https://github.com/nvim-neorocks/rocks-git.nvim/commit/796b36a5395ddade760bd37e63658ba862b0fdb8))

## [2.3.2](https://github.com/nvim-neorocks/rocks-git.nvim/compare/v2.3.1...v2.3.2) (2024-10-14)


### Bug Fixes

* set cwd when cloning repositories ([#60](https://github.com/nvim-neorocks/rocks-git.nvim/issues/60)) ([7c5c476](https://github.com/nvim-neorocks/rocks-git.nvim/commit/7c5c4764012c51343347a4eaf4dff55d96d80473))

## [2.3.1](https://github.com/nvim-neorocks/rocks-git.nvim/compare/v2.3.0...v2.3.1) (2024-09-17)


### Bug Fixes

* prevent `vim.system` panics ([#58](https://github.com/nvim-neorocks/rocks-git.nvim/issues/58)) ([b9e820c](https://github.com/nvim-neorocks/rocks-git.nvim/commit/b9e820c45b6d78d723c58985012f0fe87e5decee))

## [2.3.0](https://github.com/nvim-neorocks/rocks-git.nvim/compare/v2.2.0...v2.3.0) (2024-09-16)


### Features

* **install:** pin current revision if no semver tag is found ([#56](https://github.com/nvim-neorocks/rocks-git.nvim/issues/56)) ([5e0a3f8](https://github.com/nvim-neorocks/rocks-git.nvim/commit/5e0a3f84fe0eb8c77d28aea4d1ec63e930b65d66))


### Bug Fixes

* **sync:** install unpinned packages if they are not installed ([#55](https://github.com/nvim-neorocks/rocks-git.nvim/issues/55)) ([a127bbd](https://github.com/nvim-neorocks/rocks-git.nvim/commit/a127bbd3f10b4ddb850bb6d30ac2143602d04543))

## [2.2.0](https://github.com/nvim-neorocks/rocks-git.nvim/compare/v2.1.0...v2.2.0) (2024-09-03)


### Features

* **experimental:** install rockspec dependencies ([#51](https://github.com/nvim-neorocks/rocks-git.nvim/issues/51)) ([0a2815a](https://github.com/nvim-neorocks/rocks-git.nvim/commit/0a2815a1c250d05e148f99027a25f2f4b6e5995f))

## [2.1.0](https://github.com/nvim-neorocks/rocks-git.nvim/compare/v2.0.2...v2.1.0) (2024-09-02)


### Features

* **experimental:** recognise rocks-git packages as dependencies ([#44](https://github.com/nvim-neorocks/rocks-git.nvim/issues/44)) ([702c84d](https://github.com/nvim-neorocks/rocks-git.nvim/commit/702c84d0f99a2551e12e7fa4c27582a268af6537))

## [2.0.2](https://github.com/nvim-neorocks/rocks-git.nvim/compare/v2.0.1...v2.0.2) (2024-08-15)


### Bug Fixes

* accept https URLs that don't end in .git ([#47](https://github.com/nvim-neorocks/rocks-git.nvim/issues/47)) ([089dcae](https://github.com/nvim-neorocks/rocks-git.nvim/commit/089dcaeffe1ff24c8a6af26ba3055d39f779e69d))

## [2.0.1](https://github.com/nvim-neorocks/rocks-git.nvim/compare/v2.0.0...v2.0.1) (2024-07-18)


### Bug Fixes

* save lowercase git URIs to rocks.toml ([#41](https://github.com/nvim-neorocks/rocks-git.nvim/issues/41)) ([9d37beb](https://github.com/nvim-neorocks/rocks-git.nvim/commit/9d37beb41ac36e97a55edaf52747c5d3e9c16a0d))

## [2.0.0](https://github.com/nvim-neorocks/rocks-git.nvim/compare/v1.5.1...v2.0.0) (2024-07-11)


### ⚠ BREAKING CHANGES

* always pin plugins on install and update

### Features

* always pin plugins on install and update ([d0f8d3e](https://github.com/nvim-neorocks/rocks-git.nvim/commit/d0f8d3e3fb8eb4d3f2f3e29991f697ba04ceb487))


### Bug Fixes

* **update:** ignore rocks with `pin = true` ([c2dc072](https://github.com/nvim-neorocks/rocks-git.nvim/commit/c2dc0720bfd10d094f9d1eb2f8a5aa1c9dde1c17))

## [1.5.1](https://github.com/nvim-neorocks/rocks-git.nvim/compare/v1.5.0...v1.5.1) (2024-05-17)


### Bug Fixes

* sync: use provided branch if set ([#29](https://github.com/nvim-neorocks/rocks-git.nvim/issues/29)) ([625dac1](https://github.com/nvim-neorocks/rocks-git.nvim/commit/625dac1a29aa7f0f56c5af9142c4dbb5871ce9ee))

## [1.5.0](https://github.com/nvim-neorocks/rocks-git.nvim/compare/v1.4.0...v1.5.0) (2024-05-01)


### Features

* support codeberg: short name prefix ([#26](https://github.com/nvim-neorocks/rocks-git.nvim/issues/26)) ([e81ee24](https://github.com/nvim-neorocks/rocks-git.nvim/commit/e81ee245b0e46fdac1bacd487fbab461eb464ab5))

## [1.4.0](https://github.com/nvim-neorocks/rocks-git.nvim/compare/v1.3.2...v1.4.0) (2024-04-08)


### Features

* support `github:`, `gitlab:` and `sourcehut:` short name prefixes ([#24](https://github.com/nvim-neorocks/rocks-git.nvim/issues/24)) ([3d8b1cd](https://github.com/nvim-neorocks/rocks-git.nvim/commit/3d8b1cd291aef12e5693bea979c83f744b7a8813))

## [1.3.2](https://github.com/nvim-neorocks/rocks-git.nvim/compare/v1.3.1...v1.3.2) (2024-04-08)


### Bug Fixes

* sourcehut support ([#22](https://github.com/nvim-neorocks/rocks-git.nvim/issues/22)) ([d6eb133](https://github.com/nvim-neorocks/rocks-git.nvim/commit/d6eb133c026f9fe30e0da2ed70493536a9114f84))

## [1.3.1](https://github.com/nvim-neorocks/rocks-git.nvim/compare/v1.3.0...v1.3.1) (2024-04-02)


### Bug Fixes

* **install:** edge case when parsing args ([976e1e1](https://github.com/nvim-neorocks/rocks-git.nvim/commit/976e1e18b141d2fdf216be684da5a2e5516ce5a8))

## [1.3.0](https://github.com/nvim-neorocks/rocks-git.nvim/compare/v1.2.1...v1.3.0) (2024-02-29)


### Features

* hook into `:Rocks install` and `:Rocks update` ([3c71055](https://github.com/nvim-neorocks/rocks-git.nvim/commit/3c71055029cb38eb3cc08e7e0d212fa68d6cd64b))

## [1.2.1](https://github.com/nvim-neorocks/rocks-git.nvim/compare/v1.2.0...v1.2.1) (2024-01-01)


### Bug Fixes

* **sync:** checkout remote HEAD if not checked out and no rev is set ([#11](https://github.com/nvim-neorocks/rocks-git.nvim/issues/11)) ([ec3da19](https://github.com/nvim-neorocks/rocks-git.nvim/commit/ec3da19f449d3a0d18b01d58682213fd88edaf23))

## [1.2.0](https://github.com/nvim-neorocks/rocks-git.nvim/compare/v1.1.1...v1.2.0) (2024-01-01)


### Features

* async git operations with `nvim-nio` ([#9](https://github.com/nvim-neorocks/rocks-git.nvim/issues/9)) ([2a46f54](https://github.com/nvim-neorocks/rocks-git.nvim/commit/2a46f549ff9b7742dece161f62a5edf0ec400b6d))

## [1.1.1](https://github.com/nvim-neorocks/rocks-git.nvim/compare/v1.1.0...v1.1.1) (2023-12-25)


### Bug Fixes

* prevent plugin from being sourced more than once ([08dc786](https://github.com/nvim-neorocks/rocks-git.nvim/commit/08dc786d6e415cdc6fe07f17a2c8506104f762fe))

## [1.1.0](https://github.com/nvim-neorocks/rocks-git.nvim/compare/v1.0.3...v1.1.0) (2023-12-17)


### Features

* **prune:** better messages when moving between 'opt'/'start' ([bb1cca9](https://github.com/nvim-neorocks/rocks-git.nvim/commit/bb1cca9df3f366866f16a035f0bd369b13d1d9ac))


### Bug Fixes

* **sync:** inverted `rev` equality check ([6e8d64f](https://github.com/nvim-neorocks/rocks-git.nvim/commit/6e8d64f51d19d8a90c98b33f8dfeced3bd742119))

## [1.0.3](https://github.com/nvim-neorocks/rocks-git.nvim/compare/v1.0.2...v1.0.3) (2023-12-17)


### Bug Fixes

* **operations:** wrong progress messages ([c944980](https://github.com/nvim-neorocks/rocks-git.nvim/commit/c944980ea387220ec878098b273bef90092033fb))

## [1.0.2](https://github.com/nvim-neorocks/rocks-git.nvim/compare/v1.0.1...v1.0.2) (2023-12-17)


### Bug Fixes

* **prune:** remove mismatched `opt`/`start` plugins ([4f06886](https://github.com/nvim-neorocks/rocks-git.nvim/commit/4f06886adf6a79f49b035ec530c9bc9becb13fdc))

## [1.0.1](https://github.com/nvim-neorocks/rocks-git.nvim/compare/v1.0.0...v1.0.1) (2023-12-17)


### Bug Fixes

* **deps:** bump rocks.nvim min version to non-broken version ([7e41cdb](https://github.com/nvim-neorocks/rocks-git.nvim/commit/7e41cdbca334267d6bbab29ddccd3ba174271e59))

## 1.0.0 (2023-12-17)


### Features

* initial implementation ([#1](https://github.com/nvim-neorocks/rocks-git.nvim/issues/1)) ([e71193e](https://github.com/nvim-neorocks/rocks-git.nvim/commit/e71193e85818c9a5bf71943c3d3f96115f0b032f))
