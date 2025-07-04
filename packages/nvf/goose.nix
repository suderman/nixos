{ lib, pkgs, ...}: let

  package = pkgs.vimUtils.buildVimPlugin rec {
    pname = "goose.nvim";
    version = "5a72d3b3f7a2a01d174100c8c294da8cd3a2aeeb";
    doCheck = false;
    src = pkgs.fetchFromGitHub {
      owner = "azorng";
      repo = pname;
      rev = version;
      sha256 = "sha256-jVWggPmdINFNVHJSCpbTZq8wKwGjldu6PNSkb7naiQE=";
    };
  };

in {

  vim.lazy.plugins."goose.nvim" = {
    inherit package;
    setupModule = "goose";
    setupOpts = {};
    after = "print('goose loaded')";
  };
}
