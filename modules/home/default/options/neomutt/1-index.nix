{
  config,
  lib,
  ...
}: {
  home = lib.mkIf config.programs.neomutt.enable {
    file.".config/neomutt/1-index".text =
      # sh
      ''
        unbind index h
        unbind index j
        unbind index k
        unbind index l

        macro index h ":set sidebar_visible=yes\n:source ~/.config/neomutt/0-sidebar\n" "Sidebar"
        bind index j "next-entry"
        bind index k "previous-entry"
        macro index l "<display-message>:source ~/.config/neomutt/2-pager\n" "Pager"
        color sidebar_divider brightblack black
      '';

    localStorePath = [".config/neomutt/1-index"];
  };
}
