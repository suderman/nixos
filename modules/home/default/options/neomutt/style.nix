{
  config,
  lib,
  ...
}: {
  home = lib.mkIf config.programs.neomutt.enable {
    file.".config/neomutt/style".text =
      # sh
      ''
        # -- base16 colors --
        # color0  black
        # color8  black-light

        # color1  red
        # color9  red

        # color2  green
        # color10 green

        # color3  yellow
        # color11 yellow

        # color4  blue
        # color12 blue

        # color5  purple
        # color13 purple

        # color6  cyan
        # color14 cyan

        # color7  white
        # color15 white-dark

        # -- extended base16 --
        # color15 orange
        # color17 pink
        # color18 grey-dark
        # color19 grey-mid
        # color20 grey-light
        # color21 peach

        color header blue default ".*"
        color header brightmagenta default "^(From)"
        color header brightcyan default "^(Subject)"
        color header brightwhite default "^(CC|BCC)"

        mono bold bold
        mono underline underline
        mono indicator reverse
        mono error bold
        color normal default default
        color indicator brightblack cyan
        color sidebar_highlight brightblack cyan
        color sidebar_indicator brightblack cyan
        color sidebar_divider brightblack black
        color sidebar_flagged red black
        color sidebar_new cyan black
        color normal brightyellow default
        color error red default
        color tilde black default
        color message cyan default
        color markers red white
        color attachment white default
        color search brightmagenta default
        color status brightyellow black
        color hdrdefault brightgreen default
        color quoted green default
        color quoted1 blue default
        color quoted2 cyan default
        color quoted3 yellow default
        color quoted4 red default
        color quoted5 brightred default
        color signature brightgreen default
        color bold black default
        color underline black default
        color normal default default

        color body brightred default "[\-\.+_a-zA-Z0-9]+@[\-\.a-zA-Z0-9]+" # Email addresses
        color body brightblue default "(https?|ftp)://[\-\.,/%~_:?&=\#a-zA-Z0-9]+" # URL
        color body green default "\`[^\`]*\`" # Green text between ` and `
        color body brightblue default "^# \.*" # Headings as bold blue
        color body brightcyan default "^## \.*" # Subheadings as bold cyan
        color body brightgreen default "^### \.*" # Subsubheadings as bold green
        color body yellow default "^(\t| )*(-|\\*) \.*" # List items as yellow
        color body brightcyan default "[;:][-o][)/(|]" # emoticons
        color body brightcyan default "[;:][)(|]" # emoticons
        color body brightcyan default "[ ][*][^*]*[*][ ]?" # more emoticon?
        color body brightcyan default "[ ]?[*][^*]*[*][ ]" # more emoticon?
        color body red default "(BAD signature)"
        color body cyan default "(Good signature)"
        color body brightblack default "^gpg: Good signature .*"
        color body brightyellow default "^gpg: "
        color body brightyellow red "^gpg: BAD signature from.*"
        mono body bold "^gpg: Good signature"
        mono body bold "^gpg: BAD signature from.*"
        color body red default "([a-z][a-z0-9+-]*://(((([a-z0-9_.!~*'();:&=+$,-]|%[0-9a-f][0-9a-f])*@)?((([a-z0-9]([a-z0-9-]*[a-z0-9])?)\\.)*([a-z]([a-z0-9-]*[a-z0-9])?)\\.?|[0-9]+\\.[0-9]+\\.[0-9]+\\.[0-9]+)(:[0-9]+)?)|([a-z0-9_.!~*'()$,;:@&=+-]|%[0-9a-f][0-9a-f])+)(/([a-z0-9_.!~*'():@&=+$,-]|%[0-9a-f][0-9a-f])*(;([a-z0-9_.!~*'():@&=+$,-]|%[0-9a-f][0-9a-f])*)*(/([a-z0-9_.!~*'():@&=+$,-]|%[0-9a-f][0-9a-f])*(;([a-z0-9_.!~*'():@&=+$,-]|%[0-9a-f][0-9a-f])*)*)*)?(\\?([a-z0-9_.!~*'();/?:@&=+$,-]|%[0-9a-f][0-9a-f])*)?(#([a-z0-9_.!~*'();/?:@&=+$,-]|%[0-9a-f][0-9a-f])*)?|(www|ftp)\\.(([a-z0-9]([a-z0-9-]*[a-z0-9])?)\\.)*([a-z]([a-z0-9-]*[a-z0-9])?)\\.?(:[0-9]+)?(/([-a-z0-9_.!~*'():@&=+$,]|%[0-9a-f][0-9a-f])*(;([-a-z0-9_.!~*'():@&=+$,]|%[0-9a-f][0-9a-f])*)*(/([-a-z0-9_.!~*'():@&=+$,]|%[0-9a-f][0-9a-f])*(;([-a-z0-9_.!~*'():@&=+$,]|%[0-9a-f][0-9a-f])*)*)*)?(\\?([-a-z0-9_.!~*'();/?:@&=+$,]|%[0-9a-f][0-9a-f])*)?(#([-a-z0-9_.!~*'();/?:@&=+$,]|%[0-9a-f][0-9a-f])*)?)[^].,:;!)? \t\r\n<>\"]"

        # Default index colors:
        color index yellow default '.*'
        color index_author red default '.*'
        color index_number blue default
        color index_subject cyan default '.*'
        color index_flags color20 default
        color index_flags white default '~N'


        # For new mail:
        color index brightyellow black "~N"
        color index_author brightred black "~N"
        color index_subject brightcyan black "~N"

        # Tagged mail
        color index brightblack brightwhite '~T'
        color index_author brightblack brightwhite '~T'
        color index_number brightblack brightwhite '~T'
        color index_subject brightblack brightwhite '~T'
        color index_flags brightblack brightwhite '~T'

        # Trashed mail
        color index brightblack red '~D'
        color index_author brightblack red  '~D'
        color index_number brightblack red '~D'
        color index_subject brightblack red '~D'
        color index_flags brightblack red '~D'

        color progress black cyan

        #     󰀄 01:11  . Mary                · Today's email
        #     󰀄 Wed 05 . Alice               · Earlier this week
        #    󰀄 Oct 27 . Bob                 · RE: Last month's thread
        #     󰀄 Dec 14/24  . Larry           · Last year's email
        set date_format = "%d.%m.%Y %H:%M"
        set index_format=" %zs %zc %zt %<[y?%<[m?%<[d?%[%H:%M ]&%[%a %d]>&%[%b %d]>&%[%b %d/%y ]> . %-28.28L  %?M?(%1M)&  ? %?X?&·? %s"

        # =Inbox    󰻩 440  󰇮 9     4                                                           11
        set pager_format=" %n %zc  %T %s%*  %{!%d %b · %H:%M} %?X?  %X ? %P  "

        # Alex    󰀒 [immich-app/immich] Release v2.2.0                        30 Oct · 11:04  6% 
        set status_format = " %f%?r? %r?  󰻩 %m %?n? 󰇮 %n ?  %?d?  %d ?%?t?  %t ?%?F?  %F? %> %?p?   %p ?"

        #      Archive/                                                                            0K
        set folder_format = "   %t%N %f %> %-5.5s"

        # 󰶈 suderman/                                                                           113857
        set mailbox_folder_format = "%i %* %m"

        # I  └─><no description>                                     [text/html, quoted, utf-8]  66K
        set attach_format = " %u%D%t%I  %T%d %> [%.7m/%.10M, %.6e%<C?, %C>]  %-5.5s "

        # Prefix subject with Fwd:
        set forward_format = "Fwd: %s"

        # not me, me, me and others, carbon copied, from me, mailing list
        set to_chars="󰀒󰀄󰀎󰗦"

        # unchanged mailbox, changed, read only, attach mode
        set status_chars = " 󰌾"

        # signed/verified, encrypted, signed, has public key, no crypto
        ifdef crypt_chars set crypt_chars = " "

        # tagged,important,trash,trash-attachments,replied,old,new,old-thread,new-thread,read,
        set flag_chars = " 󰇮 󰇮  "

        set hidden_tags = "unread,draft,flagged,passed,replied,attachment,signed,encrypted"
        tag-transforms "replied" "↻ " "encrypted" "" "signed" "" "attachment" ""

        # The formats must start with 'G' and the entire sequence is case sensitive.
        tag-formats "replied" "GR" "encrypted" "GE" "signed" "GS" "attachment" "GA"

        color status white black
        color status green black '󰻩 '
        color status yellow black ' '
        color status red black ''
        color status brightblack blue '(.*)' 1
        color status blue black '.*()' 1
        color status black blue '\s* [0-9]+\s*'
        color status black yellow '\s* [0-9]+\s*'
        color status blue black '().* [0-9]+\s*' 1
        color status yellow black '()\s*\s*[0-9]+\s*' 1
        color status black yellow '\s*\s*[0-9]+\s*'
        color status blue yellow '() ([0-9]+%|all|end) \s*' 1
        color status black blue ' ([0-9]+%|all|end) \s*'
        color status yellow black '()\s*' 1
        color status default black ''

      '';

    localStorePath = [".config/neomutt/style"];
  };
}
