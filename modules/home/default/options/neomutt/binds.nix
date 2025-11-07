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

        # bind pager,index d noop
        # bind pager,index dd delete-message

        # Mail & Reply
        bind index \Cm list-reply # Doesn't work currently

        # Threads
        bind browser,pager,index N search-opposite
        # bind pager,index dT delete-thread
        # bind pager,index dt delete-subthread
        bind pager,index gh next-thread
        bind pager,index gH previous-thread
        bind index za collapse-thread
        bind index zA collapse-all # Missing :folddisable/

        # -----

        # Arrow keys mirror vim's hjkl keys
        macro index,pager,attach,browser <Left> ":push h\n"
        macro index,pager,attach,browser <Down> ":push j\n"
        macro index,pager,attach,browser <Up> ":push k\n"
        macro index,pager,attach,browser <Right> ":push l\n"

        # Toggle sidebar with B
        bind index,pager B sidebar-toggle-visible

        # Toggle unread with U
        bind index U toggle-new

        # Tag (multi-select) with Spacebar
        bind pager,index <Space> tag-thread

        # # Delete with D
        # bind pager,index D delete-message

        # [c] is prefix for compose mail
        bind pager c noop
        macro index,pager,attach c "echo '[c]ompose, [r]eply, reply-[a]ll, [f]orward, [d]raft'"

        # [c] is prefix for compose mail
        bind index,pager c noop

        # Compose new email
        bind index,pager cm mail
        bind index,pager cc mail

        # Compose reply to email
        bind index,pager cr reply

        # Compose reply-all to email
        bind index,pager ca group-reply

        # Compose forward of email
        bind index,pager cf forward-message

        # Compose draft of email
        bind index,pager cd recall-message

        # View raw message with Z
        bind index,pager Z view-raw-message

        bind browser h exit
        bind browser j next-entry
        bind browser k previous-entry
        bind browser l select-entry
        bind browser K exit

        # Archive/unarchive email with e
        folder-hook . \
          'macro index,pager e ":set confirmappend=no\n<save-message>+Archive\n:set confirmappend=yes\n" "Archive email"'
        folder-hook Archive \
          'macro index,pager e ":set confirmappend=no\n<save-message>+Inbox\n:set confirmappend=yes\n" "Unarchive email"'

        # Delete/undelete email with d
        folder-hook . \
          bind index,pager d delete-message
        folder-hook Trash \
          'macro index,pager d ":set confirmappend=no\n<save-message>+Inbox\n:set confirmappend=yes\n" "Undelete email"'

        # Delete/undelete spam with dm
        folder-hook . \
          'macro index,pager D ":set confirmappend=no\n<save-message>+Spam\n:set confirmappend=yes\n" "Delete spam"'
        folder-hook Spam \
          'macro index,pager D ":set confirmappend=no\n<save-message>+Inbox\n:set confirmappend=yes\n" "Not spam"'

        # Jump to mailbox with gi ga gd gs gm gt
        macro index,pager gi "<change-folder>+Inbox\n" "Go to Inbox"
        macro index,pager ga "<change-folder>+Archive\n" "Go to Archive"
        macro index,pager gd "<change-folder>+Drafts\n" "Go to Drafts"
        macro index,pager gs "<change-folder>+Sent\n" "Go to Sent"
        macro index,pager gS "<change-folder>+Spam\n" "Go to Spam"
        macro index,pager gt "<change-folder>+Trash\n" "Go to Trash"

        # List mailboxes with K
        macro index,pager K "<change-folder>?" "List mailboxes"

        # View URLs in message with L
        macro index,pager L "<pipe-message>${pkgs.urlscan}/bin/urlscan<enter><exit>";

        # Write changes to mailbox with w
        bind index w "sync-mailbox"

        set query_command="${pkgs.notmuch-addrlookup}/bin/notmuch-addrlookup --mutt '%s'"

        # Search using notmuch with S
        macro index S \
          "<enter-command>set my_old_pipe_decode=\$pipe_decode my_old_wait_key=\$wait_key nopipe_decode nowait_key<enter>\
          <shell-escape>${pkgs.notmuch-mutt}/bin/notmuch-mutt -r --prompt search<enter>\
          <change-folder-readonly>`echo ''${XDG_CACHE_HOME:-$HOME/.cache}/notmuch/mutt/results`<enter>\
          <enter-command>set pipe_decode=\$my_old_pipe_decode wait_key=\$my_old_wait_key<enter>" \
                "notmuch: search mail"

        # Select all (tag) with Ctrl-a
        macro index \Ca "<tag-pattern>.<enter>" "Select all"

        # Limit tagged with F (Filter)
        macro index F "<limit>~T<enter><untag-pattern>.<enter>" "Limit tagged"

        # Limit pattern with f (filter)
        bind index f limit
      '';

    localStorePath = [".config/neomutt/binds"];
  };
}
