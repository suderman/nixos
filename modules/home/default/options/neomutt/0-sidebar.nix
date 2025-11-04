{
  config,
  lib,
  ...
}: {
  home = lib.mkIf config.programs.neomutt.enable {
    file.".config/neomutt/0-sidebar".text =
      # sh
      ''
        unbind index h
        unbind index j
        unbind index k
        unbind index l

        bind index h sidebar-prev
        bind index j sidebar-next
        bind index k sidebar-prev
        macro index l "<sidebar-open>:source ~/.config/neomutt/1-index\n" "Index"
        color sidebar_divider brightwhite default
      '';

    localStorePath = [".config/neomutt/0-sidebar"];
  };
}
