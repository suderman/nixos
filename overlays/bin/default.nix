# Personal scripts
{ self, super, this, ... }: builtins.listToAttrs (
  map (dir: { 
    name = "${dir}";
    value = super.callPackage ./${dir} {};
  }) (this.lib.ls { path = ./.; full = false; })
)
