{ config, lib, pkgs, ...}: let

  inherit (lib) mkIf;
  cfg = config.vim.assistant.goose;

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

  options.vim = {
    assistant.goose.enable = lib.options.mkEnableOption "goose ai";
  };

  config.vim = mkIf cfg.enable {
    extraPlugins.goose = {
      inherit package;
      setup = ''
        require('goose').setup {};
      '';
    };
  };
}
