{pkgs, ...}: {
  programs.obs-studio = with pkgs; {
    enable = true;
    package = obs-studio;
    plugins = with obs-studio-plugins; [
      # droidcam-obs
      # obs-backgroundremoval
      obs-pipewire-audio-capture
      # wlrobs
    ];
  };

  # Persist scenes, profiles, and plugin settings
  persist.storage.directories = [".config/obs-studio"];
}
