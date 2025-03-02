{ lib, this }: this.lib.mkShellScript {
  name = "sv";
  text = ./sv.sh;
}
