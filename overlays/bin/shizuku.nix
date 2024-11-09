{ lib, this, android-tools }: this.lib.mkShellScript {

  name = "shizuku";
  inputs = [ android-tools ];
  text = "adb shell sh /storage/emulated/0/Android/data/moe.shizuku.privileged.api/start.sh";

}

