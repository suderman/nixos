{
  pkgs,
  perSystem,
  ...
}:
pkgs.runCommand "camofox-browser-check" {
  nativeBuildInputs = [pkgs.python3];
} ''
  python3 ${../packages/camofox-browser/test.py} ${perSystem.self.camofox-browser}/bin/camofox-browser
  touch "$out"
''
