{
  config,
  lib,
  ...
}: {
  home = lib.mkIf config.programs.neomutt.enable {
    file.".config/neomutt/3-attach".text =
      # sh
      ''
        unbind attach h
        unbind attach j
        unbind attach k
        unbind attach l

        macro attach h "<exit>:source ~/.config/neomutt/2-pager\n" "Pager"
        bind attach j "next-line"
        bind attach k "previous-line"
        macro attach l "<view-attach>:source ~/.config/neomutt/4-pager\n" "Attach Pager"
      '';

    localStorePath = [".config/neomutt/3-attach"];
  };
}
