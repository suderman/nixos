{
  pkgs,
  perSystem,
  ...
}:
perSystem.self.mkScript {
  name = "shizuku";
  path = [pkgs.android-tools];
  text = "adb shell sh /storage/emulated/0/Android/data/moe.shizuku.privileged.api/start.sh";
}
