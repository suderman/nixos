{ config, lib, pkgs, ... }: let

  cfg = config.services.keyd;
  inherit (lib) mkOption removePrefix removeSuffix replaceStrings toLower types;

  # Create window class name from hyprland string to what keyd-application-mapper makes:
  # 427 def normalize_class(s):
  # 423   return re.sub('[^A-Za-z0-9]+', '-', s).strip('-').lower()
  mkClass = str: let
    invalid = [ "." "_" "/" "(" ")" "$" "<" ">" "[" "]" ":" ];
    hyphens = map ( _: "-" ) invalid;
    v1 = replaceStrings invalid hyphens str;
    v2 = (removePrefix "-" (removePrefix "--" (removePrefix "---" (removePrefix "----" v1) ) )); 
    v3 = (removeSuffix "-" (removeSuffix "--" (removeSuffix "---" (removeSuffix "----" v2) ) )); 
  in toLower v3;

in {

  options.services.keyd.lib = mkOption {
    type = types.anything; 
    readOnly = true; 
    default = { inherit mkClass; };
  };

}
