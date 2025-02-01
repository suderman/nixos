{ config, lib, pkgs, profiles, ... }: {

  # Import all *.nix files in this directory
  imports = lib.ls ./. ++ [
    profiles.desktop # gui apps on all my desktops
    profiles.image-editing # graphics apps 
    profiles.video-editing # davinci resolve and others
  ];

  # Enable email/calendars/contacts
  accounts.enable = true;

  # Enhance btop with GPU support
  programs.btop = {
    package = pkgs.btop.overrideAttrs (prev: rec {
      cmakeFlags = (prev.cmakeFlags or []) ++ [
        "GPU_SUPPORT=true"
      ];
    });
  };

}
