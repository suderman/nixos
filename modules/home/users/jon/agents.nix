{
  config,
  lib,
  pkgs,
  ...
}: let
  agentConfigurationCheckout = pkgs.writeShellApplication {
    name = "agent-configuration-checkout";
    runtimeInputs = [pkgs.coreutils pkgs.git];
    text = ''
      repository="$HOME/.agents"
      remote=https://github.com/suderman/agents.git
      legacy_skills="''${XDG_STATE_HOME:-$HOME/.local/state}/agents/legacy-skills"

      clone_replacing_symlink() {
        local temporary

        temporary="$(mktemp -d "$HOME/.agents.checkout.XXXXXX")"
        trap 'rm -rf -- "$temporary"' RETURN
        git clone "$remote" "$temporary"
        rm -- "$repository"
        mv -T -- "$temporary" "$repository"
        trap - RETURN
      }

      retire_legacy_skills_checkout() {
        local entries

        shopt -s nullglob dotglob
        entries=("$repository"/*)
        shopt -u nullglob dotglob
        [[ ''${#entries[@]} -eq 1 && "''${entries[0]}" == "$repository/skills" && -d "$repository/skills/.git" ]] || return 1

        if [[ -e "$legacy_skills" || -L "$legacy_skills" ]]; then
          echo "Cannot preserve legacy agent skills: $legacy_skills already exists" >&2
          exit 1
        fi

        mkdir -p -- "$(dirname -- "$legacy_skills")"
        mv -- "$repository/skills" "$legacy_skills"
        echo "Preserved legacy agent skills at $legacy_skills" >&2
      }

      if [[ -L "$repository" ]]; then
        resolved="$(readlink -f -- "$repository" || true)"
        if [[ ! -d "$resolved/.git" ]]; then
          echo "Refusing to replace agent configuration symlink: $repository -> $resolved" >&2
          exit 1
        fi
        clone_replacing_symlink
      elif [[ -d "$repository/.git" ]]; then
        :
      elif [[ ! -e "$repository" ]]; then
        git clone "$remote" "$repository"
      elif [[ -d "$repository" ]]; then
        retire_legacy_skills_checkout || true
        if [[ -n "$(ls -A "$repository")" ]]; then
          echo "Agent configuration directory is not empty: $repository" >&2
          exit 1
        fi
        git clone "$remote" "$repository"
      else
        echo "Agent configuration is not a Git checkout: $repository" >&2
        exit 1
      fi
    '';
  };
in {
  # Keep the complete curated configuration as one writable Git checkout.
  persist.storage.directories = [
    ".agents"
    # Retain the retired fleet and Desktop homes for rollback.
    ".local/share/hermes"
    ".local/share/hermes-desktop"
  ];

  home.activation.agentConfigurationCheckout = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD ${lib.getExe agentConfigurationCheckout}
  '';

  # Preload OpenCode with my API keys
  programs.opencode.apiKeys = ./apikeys-env.age;

  # Preload mmx-cli with my API keys
  programs.mmx-cli.apiKeys = ./apikeys-env.age;

  # Preload pi with my API keys and watch the downloads task drop zones.
  programs.pi-coding-agent = {
    apiKeys = ./apikeys-env.age;
    taskDropZones.enable = true;
  };

  programs.hermes.apiKeys = ./apikeys-env.age;

  # Self-hosted webapps running from my kit desktop
  xdg = lib.optionalAttrs config.desktop.enable {
    desktopEntries = config.lib.chromium.mkWebApp {
      name = "OpenCode";
      url = "https://opencode-jon.kit";
      icon =
        pkgs.writeText "icon.svg"
        # html
        ''
          <svg width='300' height='300' viewBox='0 0 300 300' fill='none' xmlns='http://www.w3.org/2000/svg'><g transform='translate(30, 0)'><g clip-path='url(#clip0_1401_86283)'><mask id='mask0_1401_86283' style='mask-type:luminance' maskUnits='userSpaceOnUse' x='0' y='0' width='240' height='300'><path d='M240 0H0V300H240V0Z' fill='white'/></mask><g mask='url(#mask0_1401_86283)'><path d='M180 240H60V120H180V240Z' fill='#4B4646'/><path d='M180 60H60V240H180V60ZM240 300H0V0H240V300Z' fill='#F1ECEC'/></g></g></g><defs><clipPath id='clip0_1401_86283'><rect width='240' height='300' fill='white'/></clipPath></defs></svg>
        '';
    };
  };
}
