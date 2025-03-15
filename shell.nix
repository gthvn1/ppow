let
  #nixpkgs = fetchTarball "https://github.com/NixOS/nixpkgs/tarball/nixos-24.11";
  #pkgs = import nixpkgs { config = {}; overlays = []; };
  pkgs = import <nixpkgs> {};
in

pkgs.mkShell {
  packages = with pkgs; [
    gmp
    libev
    ocamlPackages.graphics
    ocamlPackages.ssl
    opam
    pkg-config
  ];

  # using local opam. If a $HOME/.opam already exists it will do nothing
  shellHook = ''
    opam init --bare -n 1>/dev/null 2>&1
    eval $(opam env)
  '';

  COLORTERM = "truecolor";
}
