# Personal scripts
{ self, super, this, moduleDirNames, ... }: let in builtins.listToAttrs (
  builtins.map (dir: { 
    name = "${dir}";
    value = self.callPackage ./${dir} {};
  }) (moduleDirNames ./.)
)
