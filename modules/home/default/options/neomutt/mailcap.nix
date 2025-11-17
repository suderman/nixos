{
  config,
  lib,
  pkgs,
  ...
}: let
  mailcap = ".config/neomutt/mailcap";
in {
  config = lib.mkIf config.programs.neomutt.enable {
    home.file."${mailcap}".text =
      # sh
      ''
        text/plain; markdown %s; copiousoutput
        text/markdown; markdown %s; copiousoutput
        text/html; w3m -I %{charset} -T text/html; copiousoutput; nametemplate=%s.html
        text/calendar; mutt-ics; copiousoutput
        application/ics; mutt-ics; copiousoutput
        image/*; icat %s
        application/pdf; zathura '%s'; test=test -n "$DISPLAY"
        application/x-pdf; zathura '%s'; test=test -n "$DISPLAY"
        application/ics; importcal '%s'; test=test -n "$DISPLAY"
        text/calendar; importcal '%s'; test=test -n "$DISPLAY"
      '';
    home.localStorePath = [mailcap];
    programs.neomutt.settings.mailcap_path = "~/${mailcap}";

    home.packages = [
      (pkgs.self.mkScript {
        name = "markdown";
        path = [pkgs.python3Packages.html2text pkgs.glow];
        text = ''html2text "''${1-}" | glow -'';
      })
      (pkgs.self.mkScript {
        name = "icat";
        path = [pkgs.kitty];
        text =
          # bash
          ''
            kitty +kitten icat "$1"
            read -n 1 -s -r -p "Press any key to continue"
          '';
      })
      (pkgs.self.mkScript {
        name = "importcal";
        path = [pkgs.unstable.rofi pkgs.khal pkgs.dunst];
        text =
          # bash
          ''
            if [[ -f $1 ]]; then
              resp=$(echo -e "yes\nno" | rofi -i -only-match -dmenu -p "Would you like to add the event:" -mesg "`khal printics -f "{title} - {start-long} → {end-long} - {location}" $1 | tail -n +2`")

              if [[ "$resp" == "yes" ]]; then
                calendar=$(echo "`khal printcalendars`" | rofi -i -only-match -dmenu -p "Save to:")
                if [ -z "$calendar" ]; then
                  exit;
                fi
                khal import -a "$calendar" --batch $1 && \
                dunstify "Calendar" "Event added to $calendar";
              fi
            fi
          '';
      })
      pkgs.zathura
      pkgs.mutt-ics
      pkgs.w3m
    ];
  };
}
