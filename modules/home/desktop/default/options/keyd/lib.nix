{lib, ...}: let
  inherit (builtins) attrNames elemAt hasAttr listToAttrs map match;
  inherit (lib) removePrefix removeSuffix replaceStrings toLower;

  # Create window class names that match keyd-application-mapper:
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

  handAttrs = hand: keys:
    listToAttrs (map (key: {
        name = key;
        value = hand;
      })
      keys);

  # Only classified typing keys get home-row modifier aliases. Enter, escape,
  # and space are intentionally omitted.
  leftHandKeys =
    ["q" "w" "e" "r" "t"]
    ++ ["a" "s" "d" "f" "g"]
    ++ ["z" "x" "c" "v" "b"]
    ++ ["tab" "grave"]
    ++ ["1" "2" "3" "4" "5"];

  rightHandKeys =
    ["y" "u" "i" "o" "p"]
    ++ ["h" "j" "k" "l" "semicolon"]
    ++ ["n" "m" "comma" "dot" "slash"]
    ++ ["leftbrace" "rightbrace" "apostrophe" "backslash"]
    ++ ["minus" "equal"]
    ++ ["6" "7" "8" "9" "0"];

  keyHands = handAttrs "left" leftHandKeys // handAttrs "right" rightHandKeys;

  keyAliases = {
    "`" = "grave";
    "[" = "leftbrace";
    "]" = "rightbrace";
    ";" = "semicolon";
    "'" = "apostrophe";
    "," = "comma";
    "." = "dot";
    "/" = "slash";
    "\\" = "backslash";
    "-" = "minus";
    "=" = "equal";
  };

  normalizeKey = key:
    if hasAttr key keyAliases
    then keyAliases.${key}
    else key;

  handOfKey = key: let
    normalized = normalizeKey key;
  in
    if hasAttr normalized keyHands
    then keyHands.${normalized}
    else null;

  homeRowModifierLayers = {
    super = {
      left = "leftsuper";
      right = "rightsuper";
    };
    control = {
      left = "leftcontrol";
      right = "rightcontrol";
    };
    alt = {
      left = "leftalt";
      right = "rightalt";
    };
    shift = {
      left = "leftshift";
      right = "rightshift";
    };
  };

  oppositeLayer = modifier: hand:
    if hand == "left"
    then homeRowModifierLayers.${modifier}.right
    else if hand == "right"
    then homeRowModifierLayers.${modifier}.left
    else null;

  expandHomeRowModifierBinding = name: value: let
    parsed = match "([^.]*)\\.(.*)" name;
  in
    if parsed == null
    then {}
    else let
      modifier = elemAt parsed 0;
      key = elemAt parsed 1;
      hand = handOfKey key;
    in
      if !(hasAttr modifier homeRowModifierLayers) || hand == null
      then {}
      else {
        "${oppositeLayer modifier hand}.${key}" = value;
      };

  expandHomeRowModifierBindings = bindings: let
    generated = builtins.foldl' (
      acc: name: acc // expandHomeRowModifierBinding name bindings.${name}
    ) {} (attrNames bindings);
  in
    generated // bindings;

  expandHomeRowModifierRules = lib.mapAttrs (_: expandHomeRowModifierBindings);
in {
  lib.keyd = {
    inherit mkClass handOfKey expandHomeRowModifierBindings expandHomeRowModifierRules;
  };
}
