{ flake, inputs, ... }: let

  # Module args with lib included
  inherit (inputs.nixpkgs) lib;
  args = { inherit flake inputs lib; };

in rec {

  # Bash script helpers
  helpers = ./helpers.sh;

}
