# programs.starship.enable = true;
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.programs.starship;
  inherit (lib) mkIf;
in {
  programs.starship = mkIf cfg.enable {
    enableBashIntegration = true;
    enableZshIntegration = true;
    package = pkgs.starship;
    settings = {
      format = "$directory$git_branch$git_metrics$nix_shell$package$character";
      right_format = "$username$hostname";
      add_newline = false;
      line_break.disabled = true;
      directory = {
        format = "[ $path]($style) ";
        style = "cyan ";
        truncate_to_repo = true;
      };
      character = {
        success_symbol = "[❯](purple)";
        error_symbol = "[❯](red)";
        vimcmd_symbol = "[❮](green)";
      };
      git_branch = {
        symbol = "[](bold purple)";
        format = "$symbol[$branch]($style) ";
        style = "purple";
      };
      git_metrics = {
        disabled = false;
        added_style = "bold yellow";
        deleted_style = "bold red";
      };
      nix_shell = {
        symbol = "[󱄅 ](bold blue)";
        format = "$symbol[$name]($style) ";
        style = "blue";
      };
      package.format = "[$version](bold green) ";
      username = {
        format = "[$user]($style)";
        style_user = "8";
        style_root = "red bold";
        show_always = true;
      };
      hostname = {
        format = "[@$hostname]($style)";
        style = "8";
        ssh_only = false;
      };
    };
  };
}
