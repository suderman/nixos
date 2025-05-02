# perSystem.self.mkDesktopItem {}
{ pkgs, perSystem, ... }: let

  inherit (builtins) isPath toString removeAttrs;
  inherit (pkgs) lib stdenv makeDesktopItem copyDesktopItems;
    
in args@{ name ? "application", desktopName ? name, icon ? null, pname ? name, version ? "1.0", ... }:

  let 
    script = perSystem.self.mkScript (removeAttrs args [ "desktopName" "icon" "pname" "version" ]); 
    desktopItem = (removeAttrs args [ "text" "path" "env" "pname" "version" ]) // {
      inherit name desktopName;
      exec = "${script}/bin/${pname}";
      icon = if isPath icon then toString icon else icon;
    };

  in stdenv.mkDerivation {
    inherit pname version;
    nativeBuildInputs = [ copyDesktopItems ];
    desktopItems = [ (makeDesktopItem desktopItem) ];
    unpackPhase = "true";
    installPhase = ''
      runHook preInstall
      mkdir -p $out/bin
      cp ${script}/bin/${pname} $out/bin/${pname}
      runHook postInstall
    '';
    meta = with lib; {
      mainProgram = pname;
      description = desktopItem.comment or "";
      license     = licenses.mit;
      platforms   = platforms.all;
    };
  }
