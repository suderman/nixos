{
  config,
  lib,
  ...
}: let
  cfg = config.services.keyd;
  inherit (lib) mkOption removePrefix removeSuffix replaceStrings toLower types;

  # Create window class name from hyprland string to what keyd-application-mapper makes:
  # 427 def normalize_class(s):
  # 423   return re.sub('[^A-Za-z0-9]+', '-', s).strip('-').lower()
  mkClass = str: let
    invalid = ["." "_" "/" "(" ")" "$" "<" ">" "[" "]" ":"];
    repeats = ["-------" "------" "-----" "----" "---" "--"];
    hyphens = map (_: "-");
    strValidated = replaceStrings invalid (hyphens invalid) str;
    strShortened = replaceStrings repeats (hyphens repeats) strValidated;
    strTrimmed = removeSuffix "-" (removePrefix "-" strShortened);
  in
    toLower strTrimmed;
in {
  options.services.keyd.lib = mkOption {
    type = types.anything;
    readOnly = true;
    default = {inherit mkClass;};
  };
}
