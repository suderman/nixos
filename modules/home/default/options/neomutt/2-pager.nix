{
  config,
  lib,
  ...
}: {
  home = lib.mkIf config.programs.neomutt.enable {
    file.".config/neomutt/2-pager".text =
      # sh
      ''
        unbind pager h
        unbind pager j
        unbind pager k
        unbind pager l

        macro pager h "<exit>:source ~/.config/neomutt/1-index\n" "Index"
        bind pager j "next-line"
        bind pager k "previous-line"
        macro pager l "<view-attachments>:source ~/.config/neomutt/3-attach\n" "Attach"
      '';

    localStorePath = [".config/neomutt/2-pager"];
  };
}
