{
  config,
  lib,
  flake,
  ...
}: {
  imports = flake.lib.ls ./.;

  # Source extra config at the end
  wayland.windowManager.hyprland.extraConfig = ''
    source = ~/.config/hypr/extra/hyprland.conf
  '';

  # Persist extra config
  persist.storage.directories = [".config/hypr/extra"];
  tmpfiles.files = [".config/hypr/extra/hyprland.conf"];

  # Use a real file for the hyprland config to ease real-time tinkering
  home.localStorePath = [".config/hypr/hyprland.conf"];

  # Temporarily pause autoreload during activation
  home.activation.localStoreHyprland = lib.hm.dag.entryBefore ["linkGeneration"] ''
    conf="${config.home.homeDirectory}/.config/hypr/hyprland.conf"
    if [ -L "$conf" ]; then
      echo "misc:disable_autoreload=true" >> "$conf" 2>/dev/null || true
    fi
  '';
}
