{pkgs, ...}: {
  home.packages = [
    # Search nixpkgs on the command line
    # nix-search package
    pkgs.nix-search-cli

    # Search nixpkgs on the command line and and temporarily install (until reboot)
    # pkgs package
    #
    # Remove installed package from history and profile
    # pkgs -package
    #
    # List packages in profile and history
    # pkgs
    (pkgs.self.mkScript {
      name = "pkgs";
      path = [
        pkgs.fzf
        pkgs.gnused
        pkgs.gum
        pkgs.jq
        pkgs.nix-search-cli
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
              gum style --foreground=29 <$current
            fi
            if [[ -n "$(comm -23 <(sort $history) <(sort $current))" ]]; then
              comm -23 <(sort $history) <(sort $current) | gum style --foreground=124
            fi

          # If argument starts with -hyphen, uninstall that -package from profile
          elif [[ "''${1-}" == -* ]]; then
            pkg="''${1##-}" # strip -hyphen from argument
            tmp=$(mktemp) # remove from history
            sed "/^$pkg$/d" "$history" >$tmp
            cat $tmp >$history
            rm $tmp
            nix profile remove "$pkg" # uninstall from profile

          # With any other argument, list matching packages and install selection to profile
          else
            pkg="$1"
            nix-search -m 100 "$pkg" |
              fzf --preview 'nix-search -dm 1 {}' |
              cut -d' ' -f1 |
              xargs -r -I{} nix profile add --impure github:NixOS/nixpkgs/nixpkgs-unstable#{}

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
