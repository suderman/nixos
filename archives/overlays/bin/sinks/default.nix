{ lib, this, pulseaudio, silver-searcher, fuzzel }: this.lib.mkShellScript {
  name = "sinks";
  inputs = [ pulseaudio silver-searcher fuzzel ];
  text = ./sinks.sh;
}
