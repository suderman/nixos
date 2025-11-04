{
  config,
  lib,
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

        bind browser h "exit"
        bind browser j "next-entry"
        bind browser k "previous-entry"
        bind browser l "select-entry"
        # bind browser d "detach-file"

        macro index dd "<delete-message><previous-entry>" "Delete message"
        macro index <Space> "<tag-message><previous-entry>" "Tag message"
        macro index F "<flag-message><previous-entry>" "Flag message"

        bind index D "delete-message"
        bind index N "toggle-new"
        # bind index F "flag-message"
        bind index w "sync-mailbox"

        bind pager <Up> previous-line   # scroll up
        bind pager <Down> next-line     # scroll down
      '';

    localStorePath = [".config/neomutt/binds"];
  };
}
