{
  config,
  lib,
  ...
}: {
  home = lib.mkIf config.programs.neomutt.enable {
    file.".config/neomutt/4-pager".text =
      # sh
      ''
        unbind pager h
        unbind pager j
        unbind pager k
        unbind pager l

        macro pager h "<exit>:source ~/.config/neomutt/3-attach\n" "Attach"
        bind pager j "next-line"
        bind pager k "previous-line"
        bind pager l "next-line"
      '';

    localStorePath = [".config/neomutt/4-pager"];
  };
}
