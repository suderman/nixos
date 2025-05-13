# Wrapper for systemd.tmpfiles.rules for my own sanity
{ config, lib, ... }: let

  cfg = config.tmpfiles;
  inherit (builtins) isString head match stringLength;
  inherit (lib) mkOption types;

  # Convert 3-digit mode (ie: 775) to 4-digit mode (ie: 0775) by padding a zero
  toMode = mode: let mode' = toString mode; in if stringLength mode' == 3 then "0${mode'}" else mode'; 

  # Trim whitespace from beginning and end of string
  trim = str: let m = match "[[:space:]]*(.*[^[:space:]])[[:space:]]*" str; in
    if m == null then
      if str == "" || match "[[:space:]]*" str != null
      then "" else str
    else
      head m;

in {

  # Add "tmpfiles" options
  options.tmpfiles = let option = mkOption { type = types.listOf types.anything; default = []; }; in {
    directories = option; files = option; symlinks = option; 
  };

  # Add these paths to list found in systemd.tmpfiles.rules 
  config.systemd.tmpfiles.rules = (

    # tmpfiles.directories = [{ target = "/etc/foo-dir"; mode = "0775"; user = "jon"; group = "users"; }];
    # d /etc/foobaz 0755 jon users - -
    # data.directories = [{ target = "/etc/foo-dir"; mode = "0775"; user = "jon"; group = "users"; source = "/etc/default"; }];
    # C+ /etc/foo-default - - - - /etc/default
    # Z  /etc/foo-default 0775 me users - -
    map (x: let 
      directory = if isString x then { target = x; } else x;  
      rulesFor = { target, mode ? "0775", user ? "root", group ? user, source ? "-", ... }:
        trim ( if (toString source) != "-" then ''
          C+ ${toString target} - - - - ${toString source}
          Z  ${toString target} ${toMode mode} ${toString user} ${toString group} - -
        '' else ''
          d ${toString target} ${toMode mode} ${toString user} ${toString group} - -
        '' );
    in rulesFor directory) cfg.directories

  ) ++ (

    # tmpfiles.files { target = "/etc/foobar"; mode = "0775"; user = "jon"; group = "users"; text = "Hello world!"; }];
    # f+ /etc/foobar 0775 jon users - Hello world!
    # data.files { target = "/etc/foo-resolv"; mode = "0775"; user = "jon"; group = "users"; source = "/etc/resolv.conf"; }];
    # C+ /etc/foo-resolv - - - - /etc/resolv.conf
    # z  /etc/foo-resolv 0775 jon users - -
    map (x: let 
      file = if isString x then { target = x; } else x;  
      rulesFor = { target, mode ? "0775", user ? "root", group ? user, source ? "-", text ? "-", ... }:
        trim ( if toString(source) != "-" then ''
          C+ ${toString target} - - - - ${toString source}
          z  ${toString target} ${toMode mode} ${toString user} ${toString group} - -
        '' else ( if text != "-" then ''
          f+ ${toString target} ${toMode mode} ${toString user} ${toString group} - ${toString text}
        '' else '' 
          f ${toString target} ${toMode mode} ${toString user} ${toString group} -
        '' 
        ) );
    in rulesFor file) cfg.files

  ) ++ (

    # tmpfiles.symlinks [{ target = "/etc/foobarlink"; source = "/etc/foobar"; }];
    # L+ /etc/foobar - - - - /etc/foobarlink
    map (x: let 
      symlink = if isString x then { target = x; } else x;  
      rulesFor = { target, source ? "/dev/null", ... }:
        trim ''
          L+ ${toString target} - - - - ${toString source}
        '';
    in rulesFor symlink) cfg.symlinks

  );

}
