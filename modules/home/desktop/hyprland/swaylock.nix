{lib, ...}: {
  programs.swaylock = {
    enable = true;
    settings = {
      color = lib.mkDefault "000000";
      font = lib.mkDefault "monospace";
      line-color = lib.mkDefault "000000";
      ring-color = lib.mkDefault "ffffff70";
      indicator-radius = 150;
      indicator-thickness = 30;
      show-failed-attempts = true;
      ignore-empty-password = true;
    };
  };
}
