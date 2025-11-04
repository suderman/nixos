{
  config,
  lib,
  ...
}: let
  cfg = config.programs.neomutt;
  search = bool: ".config/neomutt/search-${toString bool}";
  source = bool: ":source ~/${search bool}\\n";
in {
  home = lib.mkIf cfg.enable {
    file."${search 0}".text =
      # sh
      ''
        # vim: set ft=neomuttrc:
        # search-0

        # Default behaviour is navigate entries with n/p
        bind index,pager,attach,browser n next-entry
        bind index,pager,attach,browser p previous-entry

        # Search with /
        macro index,pager,attach,browser / "${source 1}<search>" "Search"
      '';

    file."${search 1}".text =
      # sh
      ''
        # vim: set ft=neomuttrc:
        # search-1

        # Navigate search results with n/p
        bind index,pager,attach,browser n search-next
        bind index,pager,attach,browser p search-opposite

        # Cancel search mode with <Space>
        macro index,pager,attach,browser / "${source 0}:echo '󰈉 Search OFF'\n" "Cancel search"
      '';

    localStorePath = [
      (search 0)
      (search 1)
    ];
  };
}
