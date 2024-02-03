rec {

  # Reverse proxies
  cog = tail.cog;
  lux = home.lux;
  hub = home.hub;
  rig = home.rig;
  eve = work.eve;
  sol = tail.sol;
  wit = tail.wit;

  # Home network: Unifi Controller
  home = {
    logos    = "10.1.0.1"; # USG 3P
    ethos    = "10.1.0.2"; # US 8 150W
    pathos   = "10.1.0.3"; # nanoHD
    hub      = "10.1.0.4";
    lux      = "10.1.0.5";
    rig      = "10.1.0.6";
    isy      = "10.1.0.8";
    cog      = "10.1.0.20";
    cog-wifi = "10.1.0.21";
  };

  # Work network: ASUS RT-AC66U
  work = {
    rt       = "10.2.0.1";
    eve      = "10.2.0.2";
    pom      = "10.2.0.3";
    cog      = "10.2.0.20";
    cog-wifi = "10.2.0.21";
  };

  # VPN: Tailscale
  tail = {
    hub      = "100.115.119.94";
    lux      = "100.90.63.125";
    rig      = "100.122.127.88";
    cog      = "100.86.99.137";
    wit      = "100.118.135.148";
    eve      = "100.88.52.75";
    sol      = "100.69.160.76";
    pxl      = "100.101.42.9";
    gemini   = "100.92.80.11";
    agate    = "100.119.189.110";
  };

}
