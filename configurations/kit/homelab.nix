{ config, lib, pkgs, ... }: { 

  # Experiments
  systemd.user.services.foobar = {
    description = "Foobar NixOS";
    after = [ "graphical-session.target" ];
    requires = [ "graphical-session.target" ];
    wantedBy = [ "default.target" ];
    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = "yes";
    };
    environment = {
      FOO = "bar";
    };
    path = with pkgs; [ coreutils ];
    script = ''
      touch /tmp/foobar.txt
      date >> /tmp/foobar.txt
    '';
  };

  file."/etc/foo" = { type = "dir"; };
  file."/etc/foo/bar" = { text = "Hello world!"; mode = 665; user = 913; };
  file."/etc/foo/symlink" = { type = "link"; source = /etc/foo/bar; };
  file."/etc/foo/resolv" = { type = "file"; mode = 775; user = "jon"; group = "users"; source = /etc/resolv.conf; };
  file."/etc/foo/srv" = { type = "dir"; source = /srv; };


  # Stable Diffusion
  services.traefik.proxy.sd = "http://127.0.0.1:7860";
  services.traefik.proxy."sd.suderman.org" = {
    url = "http://127.0.0.1:7860";
    public = false;
  };


  services.silverbullet.enable = true;

}
