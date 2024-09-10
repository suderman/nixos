{ lib, this, adoptopenjdk-icedtea-web }: this.lib.mkShellScript {

  name = "isy";
  inputs = [ adoptopenjdk-icedtea-web ];

  text = '' 
    # echo $ISY_BASIC_AUTH | base64 -d | cut -d':' -f2 | wl-copy
    javaws http://${this.networks.home.isy}/admin.jnlp
  '';

}
