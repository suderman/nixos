{
  config,
  lib,
  pkgs,
  ...
}: {
  home = lib.mkIf config.programs.neomutt.enable {
    file.".config/neomutt/binds".text =
      # sh
      ''
        # Moving around
        bind attach,browser,index g noop
        bind attach,browser,index gg first-entry
        bind attach,browser,index G last-entry
        bind pager g noop
        bind pager gg top
        bind pager G bottom
        bind pager k previous-line
        bind pager j next-line

        # Scrolling
        bind attach,browser,pager,index \CF next-page
        bind attach,browser,pager,index \CB previous-page
        bind attach,browser,pager,index \Cu half-up
        bind attach,browser,pager,index \Cd half-down
        bind browser,pager \Ce next-line
        bind browser,pager \Cy previous-line
        bind index \Ce next-line
        bind index \Cy previous-line

        bind pager,index d noop
        bind pager,index dd delete-message

        # Mail & Reply
        bind index \Cm list-reply # Doesn't work currently

        # Threads
        bind browser,pager,index N search-opposite
        bind pager,index dT delete-thread
        bind pager,index dt delete-subthread
        bind pager,index gt next-thread
        bind pager,index gT previous-thread
        bind index za collapse-thread
        bind index zA collapse-all # Missing :folddisable/

        # -----

        # Search with / and browse results with C-n C-p
        bind index,pager,attach,browser / search
        bind index,pager,attach,browser \Cn search-next
        bind index,pager,attach,browser \Cp search-opposite

        # Navigate entries with n and p
        bind index,pager,attach,browser n next-entry
        bind index,pager,attach,browser p previous-entry

        # Toggle sidebar with B
        bind index,pager B sidebar-toggle-visible

        # Toggle unread with U
        bind index U toggle-new

        # Tag (multi-select) with Spacebar
        bind pager,index <Space> tag-entry

        # Delete with D
        bind pager,index D delete-message

        # Replay-all with a
        bind index,pager a group-reply

        # View raw message with Z
        bind index,pager Z view-raw-message

        bind browser h exit
        bind browser j next-entry
        bind browser k previous-entry
        bind browser l select-entry
        # bind browser d "detach-file"

        # Archive message with e
        macro index,pager e ":set confirmappend=no\\n<save-message>+Archive<enter>:set confirmappend=yes\\n";

        # View URLs in message with K
        macro pager K "<pipe-message>${pkgs.urlscan}/bin/urlscan<enter><exit>";

        # Write changes to mailbox with w
        bind index w "sync-mailbox"

        bind pager <Up> previous-line   # scroll up
        bind pager <Down> next-line     # scroll down
      '';

    localStorePath = [".config/neomutt/binds"];
  };
}
