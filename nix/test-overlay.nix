{self}: final: prev: let
  mkNeorocksTest = name: nvim:
    with final;
      neorocksTest {
        inherit name;
        pname = "rocks-git.nvim";
        src = self;
        neovim = nvim;
        luaPackages = ps:
          with ps; [
            nvim-nio
            rocks-nvim
          ];

        extraPackages = [
          git
        ];

        preCheck = ''
          # Neovim expects to be able to create log files, etc.
          export HOME=$(realpath .)
        '';
      };

  docgen = final.writeShellApplication {
    name = "docgen";
    runtimeInputs = with final; [
      lemmy-help
    ];
    text = ''
      mkdir -p doc
      lemmy-help lua/rocks-git/{init,config}.lua > doc/rocks-git.txt
    '';
  };
in {
  inherit docgen;
  integration-nightly = mkNeorocksTest "integration-nightly" final.neovim-nightly;
}
