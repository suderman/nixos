{ lib, this, jq, wl-clipboard }: this.lib.mkShellScript {

  # Parse output of nix flake prefetch for pkgs.fetchFromGitHub { ... }
  # > fetchgithub suderman/mpd-url
  # owner = "suderman";
  # repo = "mpd-url";
  # rev = "cd8dab8385f09f4b114a9d995044936e30fc1188";
  # sha256 = "sha256-YI/fMxp82lJnq5wH8pv5s1NOC2logOoW37psMsvW8BU=";
  name = "fetchgithub";
  inputs = [ jq wl-clipboard ];
  text = ''
    if [[ $# -lt 1 ]]; then
      echo "Usage: fetchgithub user/repo"
      exit 1
    fi

    json=$(nix flake prefetch --json "github:$1")

    out="";
    out="''${out}owner = \"$(echo "$json" | jq -r '.original.owner')\";\n"
    out="''${out}repo = \"$(echo "$json" | jq -r '.original.repo')\";\n"
    out="''${out}rev = \"$(echo "$json" | jq -r '.locked.rev')\";\n"
    out="''${out}sha256 = \"$(echo "$json" | jq -r '.hash')\";\n"

    printf "$out" | wl-copy
    printf "$out"
  '';

}
