{pkgs, ...}: {
  home.packages = [
    # Search nixpkgs on the command line
    # nix-search <searchterm>
    pkgs.nix-search-cli

    # Search nixpkgs on the command line and and temporarily install (until reboot)
    # pkgs <searchterm>
    (pkgs.self.mkScript {
      name = "pkgs";
      path = [
        pkgs.nix-search-cli
        pkgs.fzf
        pkgs.jq
      ];
      env.NIXPKGS_ALLOW_UNFREE = "1";
      text =
        # bash
        ''
          # Temporarily store current, persist history
          current="$HOME/.local/share/pkgs"
          history="$HOME/.local/share/pkgs-history"
          touch $current
          touch $history

          # Without search term, list packages currently/previously installed to profile
          if [[ -z "''${1-}" ]]; then
            nix profile list --json | jq -r '.elements | keys[]' >$current
            if [[ -s "$current" ]]; then
              echo "Currently installed:"
              cat $current
            else
              echo "Nothing currently installed."
            fi
            if [[ -n "$(comm -23 <(sort $history) <(sort $current))" ]]; then
              echo
              echo "Previously installed:"
              comm -23 <(sort $history) <(sort $current)
            fi

          # With search term, list matching packages and install selection to profile
          else
            nix-search -m 100 "$1" |
              fzf --preview 'nix-search -dm 1 {}' |
              cut -d' ' -f1 |
              xargs -r -I{} nix profile install --impure github:NixOS/nixpkgs/nixpkgs-unstable#{}

            # Add package to history
            nix profile list --json | jq -r '.elements | keys[]' >>$history
            sort -u $history -o $history
          fi
        '';
    })
  ];

  # Installed packages are wiped at reboot, but persist list of what was installed
  persist.storage.files = [".local/share/pkgs-history"];
}
