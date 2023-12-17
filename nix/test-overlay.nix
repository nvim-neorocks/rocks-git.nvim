{self}: final: prev: let
  docgen = final.writeShellApplication {
    name = "docgen";
    runtimeInputs = with final; [
      lemmy-help
    ];
    text = ''
      mkdir -p doc
      lemmy-help lua/rocks-git/init.lua > doc/rocks-git.txt
    '';
  };
in {
  inherit docgen;
}
