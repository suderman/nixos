{
  pkgs,
  perSystem,
  ...
}: {
  home.packages = [
    pkgs.nix-search-cli
    (perSystem.self.mkScript {
      name = "pkg";
      path = [
        pkgs.coreutils
        pkgs.nix-search-cli
        pkgs.fzf
      ];
      text = ''
        if [[ -z "''${1-}" ]]; then
          nix-search
        else
          nix-search -m 100 "$1" |
            fzf --preview 'nix-search -dm 1 {}' |
            cut -d' ' -f1 |
            xargs -r -I{} nix profile install github:NixOS/nixpkgs/nixpkgs-unstable#{}
        fi
      '';
    })
  ];
}
