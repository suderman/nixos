{pkgs, ...}: {
  home.packages = with pkgs; [
    audacity
    imagemagick # animate compare composite conjure convert display identify import magick magick-script mogrify montage stream
    inkscape-with-extensions
  ];

  programs.gimp.enable = true;

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
}
