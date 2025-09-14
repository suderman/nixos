{...}: {
  nixpkgs.overlays = [
    (_final: prev: let
      wayland = {rofi-unwrapped = prev.rofi-wayland-unwrapped;};
    in {
      # Rofi plugins
      rofi-blezz = prev.rofi-blezz.override wayland;
      rofi-calc = prev.rofi-calc.override wayland;
      rofi-file-browser = prev.rofi-file-browser.override wayland;
      rofi-menugen = prev.rofi-menugen.override wayland;
      rofi-obsidian = prev.rofi-obsidian.override wayland;
      rofi-power-menu = prev.rofi-power-menu.override wayland;
      rofi-pulse-select = prev.rofi-pulse-select.override wayland;
      rofi-screenshot = prev.rofi-screenshot.override wayland;
      rofi-top = prev.rofi-top.override wayland;
      rofi-vpn = prev.rofi-vpn.override wayland;
    })
  ];
}
