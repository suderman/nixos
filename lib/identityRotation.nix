{lib, ...}: state: let
  active = state.status == "active";

  targetState = category: name:
    state.targets.${category}.${name}
    or (throw "identity rotation target ${category}.${name} is missing");
in {
  inherit active state targetState;

  useNext = category: name: targetState category name == "next";

  select = category: name: current: next:
    if targetState category name == "next"
    then next
    else current;

  nextPath = path: path + ".next";

  keyFiles = paths:
    paths
    ++ lib.optionals active (map (path: path + ".next") paths);
}
