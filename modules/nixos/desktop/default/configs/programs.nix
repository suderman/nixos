{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs."stylix-theme-toggle";

  activate = pkgs.writeShellScriptBin "stylix-theme-activate" ''
    set -euo pipefail

    if [ "$#" -ne 0 ]; then
      printf 'usage: stylix-theme-activate\n' >&2
      exit 64
    fi

    light_profile=/nix/var/nix/profiles/system/specialisation/light
    light_switch="$light_profile/bin/switch-to-configuration"
    dark_switch=/nix/var/nix/profiles/system/bin/switch-to-configuration

    if [ ! -x "$light_switch" ]; then
      printf 'missing light specialisation: %s\n' "$light_switch" >&2
      exit 1
    fi

    current="$(${pkgs.coreutils}/bin/readlink -f /run/current-system)"
    light="$(${pkgs.coreutils}/bin/readlink -f "$light_profile")"

    if [ "$current" = "$light" ]; then
      exec "$dark_switch" switch
    fi

    exec "$light_switch" switch
  '';

  toggle = pkgs.writeShellScriptBin "stylix-theme-toggle" ''
    set -euo pipefail

    target_polarity() {
      local light_profile current light

      light_profile=/nix/var/nix/profiles/system/specialisation/light

      if [ ! -e "$light_profile" ]; then
        printf 'light\n'
        return 0
      fi

      current="$(${pkgs.coreutils}/bin/readlink -f /run/current-system)"
      light="$(${pkgs.coreutils}/bin/readlink -f "$light_profile")"

      if [ "$current" = "$light" ]; then
        printf 'dark\n'
      else
        printf 'light\n'
      fi
    }

    notify_theme_switch() {
      local target summary body

      target="$(target_polarity)"
      summary="Stylix theme"
      body="Switching to $target mode..."

      ${pkgs.libnotify}/bin/notify-send \
        --app-name=stylix-theme-toggle \
        --expire-time=3000 \
        "$summary" \
        "$body" \
        >/dev/null 2>&1 || true
    }

    refresh_emacs_theme() {
      local emacs emacsclient emacs_bin emacs_pkg theme_file ref candidate result

      emacs="$(command -v emacs || true)"
      emacsclient="$(command -v emacsclient || true)"

      if [ -z "$emacs" ] || [ -z "$emacsclient" ]; then
        return 0
      fi

      emacs_bin="$(${pkgs.coreutils}/bin/readlink -f "$emacs")"
      case "$emacs_bin" in
        */bin/emacs) emacs_pkg="''${emacs_bin%/bin/emacs}" ;;
        *) return 0 ;;
      esac

      theme_file=""
      while IFS= read -r ref; do
        candidate="$ref/share/emacs/site-lisp/base16-stylix-theme.el"
        if [ -r "$candidate" ]; then
          theme_file="$candidate"
          break
        fi
      done < <(${pkgs.nix}/bin/nix-store -q --references "$emacs_pkg" 2>/dev/null || true)

      if [ -z "$theme_file" ]; then
        return 0
      fi

      if ! result="$($emacsclient --eval "
        (let ((theme-file \"$theme_file\"))
          (mapc #'disable-theme custom-enabled-themes)
          (load-file theme-file)
          (setq base16-theme-256-color-source 'colors)
          (load-theme 'base16-stylix t))
      " 2>&1)"; then
        printf 'warning: could not refresh Emacs theme: %s\n' "$result" >&2
      fi
    }

    if [ "$#" -ne 0 ]; then
      printf 'usage: stylix-theme-toggle\n' >&2
      exit 64
    fi

    notify_theme_switch
    /run/wrappers/bin/sudo ${activate}/bin/stylix-theme-activate
    refresh_emacs_theme
  '';
in
  lib.mkMerge [
    {
      environment.systemPackages = with pkgs; [
        desktop-file-utils # desktop-file-edit desktop-file-install desktop-file-validate update-desktop-database
        hicolor-icon-theme # fallback icon theme
        shared-mime-info # update-mime-database
        wl-clipboard # wl-copy wl-paste
        xdg-user-dirs # xdg-user-dir xdg-user-dirs-update
        xdg-utils # xdg-desktop-icon xdg-desktop-menu xdg-email xdg-icon-resource xdg-mime xdg-open xdg-screensaver xdg-settings xdg-terminal
      ];

      # AirDrop alternative
      programs.localsend.enable = true;
    }

    (lib.mkIf cfg.enable {
      assertions = [
        {
          assertion = config.security.sudo.enable;
          message = "programs.stylix-theme-toggle requires security.sudo.enable.";
        }
      ];

      specialisation.light.configuration = {
        stylix.polarity = lib.mkForce "light";
        stylix.base16Scheme = lib.mkForce cfg.lightScheme;
      };

      environment.systemPackages = [toggle];

      security.sudo.extraConfig = lib.mkAfter ''
        %wheel ALL=(root) NOPASSWD: ${activate}/bin/stylix-theme-activate ""
      '';
    })
  ]
