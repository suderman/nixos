# perSystem.self.mkDesktopItem {}
{ pkgs, perSystem, ... }: let

  inherit (builtins) baseNameOf toString length;
  inherit (perSystem.self) mkScript;
  inherit (pkgs) lib stdenv makeDesktopItem copyDesktopItems;
  inherit (lib) concatStringsSep init splitString;

  toIcon = path: let 
    f = baseNameOf (toString path); n = splitString "." f;
  in if length n > 1 then concatStringsSep "." (init n) else f;
    
in { name ? "script", title ? name, icon ? null, ...}@args:

  let script = mkScript args; 
      desktopItem = {
        inherit name;
        exec = name;
        icon = if isNull icon then name else toIcon icon;
        desktopName = title;
        comment = "";
        categories = [];
      };

  in stdenv.mkDerivation {
      inherit name;
      version = "1.0";
      nativeBuildInputs = [ copyDesktopItems ];
      desktopItems = [ (makeDesktopItem desktopItem) ];
      installPhase = ''
        mkdir -p $out/bin
        cp ${script}/bin/${name} $out/bin/${name}
        mkdir -p $out/share/icons/hicolor/64x64/apps
      '';
        # install -Dm644 ${desktopItem.icon} $out/share/icons/hicolor/64x64/apps/${desktopItem.icon}.png
      meta = with lib; {
        mainProgram = name;
        description = desktopItem.comment or "";
        license     = licenses.mit;
        platforms   = platforms.all;
      };
    }
