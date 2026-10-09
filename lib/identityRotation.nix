# Fleet-wide identity rotation phase from secrets/rotation/state.json.
# While rotating, every host holds and trusts both key generations; the switch
# phase selects the next generation.
{lib, ...}: let
  inherit (builtins.fromJSON (builtins.readFile ../secrets/rotation/state.json)) phase;
in
  assert lib.assertOneOf "identity rotation phase" phase ["idle" "prepare" "switch"]; rec {
    inherit phase;
    active = phase != "idle";
    useNext = phase == "switch";

    nextPath = path: path + ".next";

    keyFiles = paths:
      paths ++ lib.optionals active (map nextPath paths);
  }
