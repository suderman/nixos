{
  config,
  lib,
  ...
}: {
  home = lib.mkIf config.programs.neomutt.enable {
    file.".config/neomutt/formats".text =
      # sh
      ''
        set forward_format = "Fwd: %s"

        set date_format = "%d.%m.%Y %H:%M"

        set index_format=" %zs %zc %zt %{!%d %b} . %-28.28L  %?M?(%1M)&  ? %?X?&·? %s"

        set pager_format=" %n %zc  %T %s%*  %{!%d %b · %H:%M} %?X?  %X ? %P  "

        set status_format = " %f%?r? %r?  󰻩 %m %?n? 󰇮 %n ?  %?d?  %d ?%?t?  %t ?%?F?  %F? %> %?p?   %p ?"

        set folder_format = "   %t%N %f %> %-5.5s"

        set attach_format = " %u%D%t%I  %T%d %> [%.7m/%.10M, %.6e%<C?, %C>]  %-5.5s "

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

    localStorePath = [".config/neomutt/formats"];
  };
}
