# Wrapper script for zbarcam
{ pkgs, ... }: pkgs.writeScriptBin "qr" ''
  #!/usr/bin/env bash
  export PATH=${pkgs.lib.makeBinPath [ pkgs.zbar ]}:$PATH
  zbarcam --oneshot --raw --set "*.enable=0" --set "qrcode.enable=1"
  echo
''
