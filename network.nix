rec {

  # Reverse proxies
  cog = tail.cog;
  lux = home.lux;
  hub = home.hub;
  eve = work.eve;
  sol = tail.sol;

  # Home network - Unifi Controller
  home = {
    logos  = "10.1.0.1"; # USG 3P
    ethos  = "10.1.0.2"; # US 8 150W
    pathos = "10.1.0.3"; # nanoHD
    hub    = "10.1.0.4";
    lux    = "10.1.0.5";
    rig    = "10.1.0.6";
    cog    = "10.1.0.7";
  };

  # Work network - ASUS RT-AC66U
  work = {
    rt  = "10.2.0.1";
    eve = "10.2.0.2";
    pom = "10.2.0.3";
    cog = "10.2.0.20";
  };

  # VPN - Tailscale
  tail = {
    hub = "100.115.119.94";
    lux = "100.90.63.125";
    cog = "100.86.99.137";
    eve = "100.88.52.75";
    sol = "100.69.160.76";
  };

}
