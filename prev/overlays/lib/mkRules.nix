# this.lib.mkRules
{ pkgs, lib, this }: let

  inherit (builtins) attrNames stringLength;
  inherit (lib) forEach mkOption types removePrefix removeSuffix;
  inherit (this.lib) toMode trim;

  # Use systemd tmpfiles rules to create files, directories, symlinks and permissions changes
  # https://www.freedesktop.org/software/systemd/man/latest/tmpfiles.d.html
  rules = {

    # file "/etc/foobar" { mode = "0775"; user = "me"; group = "users"; text = "Hello world!"; };
    # f+ /etc/foobar 0775 me users - Hello world!
    # file "/etc/foo-resolv" { mode = "0775"; user = "me"; group = "users"; source = "/etc/resolv.conf"; };
    # C+ /etc/foo-resolv - - - - /etc/resolv.conf
    # z  /etc/foo-resolv 0775 me users - -
    file = path: { mode ? "0775", user ? "root", group ? user, source ? "-", text ? "-", ... }: 
      trim ( if source != "-" then ''
        C+ ${path} - - - - ${source}
        z  ${path} ${mode} ${user} ${group} - -
      '' else ( if text != "-" then ''
        f+ ${path} ${mode} ${user} ${group} - ${text}
      '' else '' 
        f ${path} ${mode} ${user} ${group} -
      ''
      ) );

    # dir "/etc/foo-dir" { mode = "0775"; user = "me"; group = "users"; };
    # d /etc/foobaz 0755 me users - -
    # dir "/etc/foo-dir" { mode = "0775"; user = "me"; group = "users"; source = "/etc/default };
    # C+ /etc/foo-default - - - - /etc/default
    # Z  /etc/foo-default 0775 me users - -
    dir = path: { mode ? "0775", user ? "root", group ? user, source ? "-", ... }:
      trim ( if source != "-" then ''
        C+ ${path} - - - - ${source}
        Z  ${path} ${mode} ${user} ${group} - -
      '' else ''
        d ${path} ${mode} ${user} ${group} - -
      '' );

    # mode "/etc/foobar" { mode = "0775"; user = "me"; group = "users; };
    # Z /etc/foobar 0755 me users -
    mode = path: { mode ? "-", user ? "-", group ? user, ... }: 
      trim ''
        Z ${path} ${mode} ${user} ${group} - -
      '';

    # link "/etc/foobarlink" { source = "/etc/foobar"; };
    # L+ /etc/foobar - - - - /etc/foobarlink
    link = path: { source ? "/dev/null", ... }: 
      trim ''
        L+ ${path} - - - - ${source}
      '';

  };

# Convert attr set into list of rules: 
in file: forEach (attrNames file) (path: 

  # Default rule type is "file"
  let attrs = file."${path}";
      type = ( if attrs ? type then attrs.type else "file" );

  # Build specified rule type
  in rules."${type}" path ( {}
    // ( if attrs ? mode then { mode = toMode attrs.mode; } else {} )
    // ( if attrs ? user then { user = toString attrs.user; } else {} )
    // ( if attrs ? group then { group = toString attrs.group; } else {} )
    // ( if attrs ? source then { source = toString attrs.source; } else {} )
    // ( if attrs ? text then { text = toString attrs.text; } else {} )
  )

)
