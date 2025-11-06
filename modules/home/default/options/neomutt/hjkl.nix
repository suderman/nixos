{
  config,
  lib,
  ...
}: let
  cfg = config.programs.neomutt;
  hjkl = i: ".config/neomutt/hjkl-${toString i}";
  source = i: ":source ~/${hjkl i}\\n";
in {
  home = lib.mkIf cfg.enable {
    file."${hjkl 0}".text =
      # sh
      ''
        # vim: set ft=neomuttrc:
        # hjkl-0 sidebar

        # Brighten sidebar's divider to white
        color sidebar_divider brightwhite default

        # Furthest back in navigation
        bind index h sidebar-prev

        # Next mailbox
        bind index j sidebar-next

        # Previous mailbox
        bind index k sidebar-prev

        # Open mailbox, restore control to index
        macro index l "<sidebar-open>${source 1}" "Index"

        # Reset search
        source ~/.config/neomutt/search-0
      '';

    file."${hjkl 1}".text =
      # sh
      ''
        # vim: set ft=neomuttrc:
        # hjkl-0 index

        # Darken sidebar's divider to black
        color sidebar_divider brightblack black

        # Back to sidebar
        macro index h ":set sidebar_visible=yes\n${source 0}" "Sidebar"

        # Next email
        bind index j "next-entry"

        # Previous email
        bind index k "previous-entry"

        # Open current email in pager
        macro index l "<display-message>${source 2}" "Pager"

        # Reset search
        source ~/.config/neomutt/search-0
      '';

    file."${hjkl 2}".text =
      # sh
      ''
        # vim: set ft=neomuttrc:
        # hjkl-2 pager

        # Back to index
        macro pager h "<exit>${source 1}" "Index"

        # Next line in email
        bind pager j "next-line"

        # Previous line in email
        bind pager k "previous-line"

        # Open email's attachments
        macro pager l "<view-attachments>${source 3}" "Attach"

        # Reset search
        source ~/.config/neomutt/search-0
      '';

    file."${hjkl 3}".text =
      # sh
      ''
        # vim: set ft=neomuttrc:
        # hjkl-3 attach

        # Back to email pager
        macro attach h "<exit>${source 2}" "Pager"

        # Next attachment
        bind attach j "next-line"

        # Previous attachment
        bind attach k "previous-line"

        # Open attachment in pager
        macro attach l "<view-attach>${source 4}" "Attach Pager"

        # Reset search
        source ~/.config/neomutt/search-0
      '';

    file."${hjkl 4}".text =
      # sh
      ''
        # vim: set ft=neomuttrc:
        # hjkl-4 pager

        # Back to email's attachments
        macro pager h "<exit>${source 3}" "Attach"

        # Next line in attachment
        bind pager j "next-line"

        # Previous line in attachment
        bind pager k "previous-line"

        # Furthest forward in navigation
        bind pager l "next-line"

        # Reset search
        source ~/.config/neomutt/search-0
      '';

    localStorePath = [
      (hjkl 0)
      (hjkl 1)
      (hjkl 2)
      (hjkl 3)
      (hjkl 4)
    ];
  };
}
