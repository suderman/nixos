# https://github.com/sumnerevans/home-manager-config/blob/master/pkgs/beeper-desktop.nix
{ lib, fetchurl, appimageTools }:
appimageTools.wrapType2 rec {
  name = "beeper";
  version = "3.75.16";

  src = fetchurl {
    # url = "https://download.beeper.com/linux/appImage/x64";
    url = "https://download.todesktop.com/2003241lzgn20jd/beeper-${version}.AppImage";
    sha256 = "sha256-0upeew7iCZUqT93r6ZCBiGjzQun9DjyI6w+TDTLrIMo=";
  };

  extraInstallCommands =
    let
      appimageContents = appimageTools.extractType2 { inherit name src; };
      installIcon = size: ''
        install -m 444 -D ${appimageContents}/usr/share/icons/hicolor/${size}x${size}/apps/${name}.png \
          $out/share/icons/hicolor/${size}x${size}/apps/${name}.png
      '';
    in
    ''
      install -Dm444 ${appimageContents}/${name}.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/${name}.desktop \
        --replace 'Exec=AppRun --no-sandbox' 'Exec=${name} --ozone-platform-hint=auto --enable-features=WaylandWindowDecorations'
      ${lib.concatMapStringsSep "\n" installIcon (map toString [16 32 48 64 128 256 512 1024 ])}
    '';

  meta = with lib; {
    homepage = "https://www.beeper.com/";
    description = "Unified chat app";
    longDescription = ''
      A single app to chat on iMessage, WhatsApp, and 13 other networks. You
      can search, prioritize, and mute messages. And with a unified inbox,
      you'll never miss a message again.
    '';
    license = licenses.unfree;
    platforms = [ "x86_64-linux" ];
    maintainers = with maintainers; [ sumnerevans ];
  };
}
