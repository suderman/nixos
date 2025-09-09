{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) attrValues filterAttrs hasAttr map;
  mdpPort = 6600; # default port for mpd control
  httpPort = 8600; # default port for http streaming
  # snapPort = 1704; # default port for snapcast server stream
in {
  # Check for home-manager (not-root) configurations
  networking.firewall =
    if ! hasAttr "home-manager" config
    then {}
    else {
      # Open firewall for user mpd service
      allowedTCPPorts = let
        # find all home-manager users with mpd enabled
        users = filterAttrs (_: user: (user.services.mpd.enable == true)) config.home-manager.users;

        # [ 0 1 2 ... ]
        offsets = map (user: user.home.offset) (attrValues users);

        # [ 6600 6601 6602 ... ]
        mdpPorts = map (offset: mdpPort + offset) offsets;

        # [ 8600 8601 8602 ... ]
        httpPorts = map (offset: httpPort + offset) offsets;
        # # [ 1704 1705 1706 ... ]
        # snapPorts = map (offset: snapPort + offset) offsets;
        # ctrlPorts = map (offset: snapPort + 1 + offset) offsets;
        # in mdpPorts ++ httpPorts ++ snapPorts ++ ctrlPorts;
      in
        mdpPorts ++ httpPorts;
    };

  services.snapserver = {
    enable = false;
    openFirewall = true;
    http = {
      enable = true;
      listenAddress = "0.0.0.0";
      docRoot = "${pkgs.snapcast}/share/snapserver/snapweb/";
    };

    # streams.mpd = {
    #   type = "pipe";
    #   location = "/tmp/snap.fifo";
    #   sampleFormat = "44100:16:2";
    #   codec = "pcm";
    # };

    codec = "flac";
    streams.mpd = {
      type = "pipe";
      location = "/run/snapserver/pipe";
      query = {
        codec = "pcm";
        sampleformat = "44100:16:2";
      };
    };

    # streams.mpd = {
    #   type = "pipe";
    #   location = "/run/snapserver/mpd";
    #   sampleFormat = "44100:16:2";
    #   codec = "opus";
    # };

    # streams.snapinfo = {
    #   type = "pipe";
    #   location = "/run/snapserver/snapfifo";
    #   query = {
    #     sampleformat = "48000:16:2";
    #     codec = "flac";
    #     mode = "create";
    #   };
    # };
  };
}
