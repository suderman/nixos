{
  lib,
  flake,
  ...
}: {
  imports = [
    flake.homeModules.default
    flake.homeModules.desktop.hyprland
    flake.homeModules.users.june
  ];

  # A small desktop on the dummy plug, whichever port it is in, fits in a
  # window on Jon's screen.
  wayland.windowManager.hyprland.lua.monitors = [
    {
      output = "";
      mode = "1920x1080@60";
      position = "0x0";
      scale = "1";
    }
  ];

  # Reached remotely and always on: never lock or blank the screen.
  services.hypridle.enable = lib.mkForce false;

  # Browser fallback for devices without Moonlight
  services.wayvnc.enable = true;

  # Jon's org, media, and profile folders
  services.syncthing.enable = true;

  # Workers, each harness logged in by Jon on this desktop
  programs.agents.enable = true;
  programs.antigravity-cli.enable = true;
  programs.claude-code.enable = true;
  programs.codex.enable = true;
  programs.opencode.enable = true;
  programs.pi-coding-agent.enable = true;
  programs.herdr.enable = true;
  programs.june.accounts.enable = true;
}
