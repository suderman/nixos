# Wrapper for systemd.tmpfiles.rules for my own sanity
{
  config,
  lib,
  ...
}: let
  cfg = config.tmpfiles;
  inherit (builtins) isAttrs isString head match stringLength;
  inherit (lib) flatten mkOption types mapAttrsToList unique;
  users = config.home-manager.users or {};

  # Convert 3-digit mode (ie: 775) to 4-digit mode (ie: 0775) by padding a zero
  toMode = mode: let
    mode' = toString mode;
  in
    if stringLength mode' == 3
    then "0${mode'}"
    else mode';

  # Trim whitespace from beginning and end of string
  trim = str: let
    m = match "[[:space:]]*(.*[^[:space:]])[[:space:]]*" str;
  in
    if m == null
    then
      if str == "" || match "[[:space:]]*" str != null
      then ""
      else str
    else head m;

  # Escape backslashes, newlines and tabs for f+ rules
  toText = str:
    trim (builtins.replaceStrings ["\\" "\n" "\t"] ["\\\\" "\\n" "\\t"] (toString str));

  # Include tmpfiles rules found in home-manager users
  userRulesFor = kind:
    flatten (mapAttrsToList (
        _: user: let
          inherit (user.home) homeDirectory username;
          toRule = x: let
            rule =
              if isAttrs x
              then x
              else {};
            target =
              if isAttrs x
              then "${homeDirectory}/${toString (x.target or "target")}"
              else "${homeDirectory}/${toString x}";
          in
            rule
            // {
              inherit target;
              user = username;
              group = "users";
            };
        in
          map toRule (user.tmpfiles.${kind} or [])
      )
      users);

  userDirectories = userRulesFor "directories";
  userFiles = userRulesFor "files";
  userSymlinks = userRulesFor "symlinks";
in {
  # Add "tmpfiles" options
  options.tmpfiles = let
    option = mkOption {
      type = with types; listOf (either str attrs);
      default = [];
    };
  in {
    directories = option;
    files = option;
    symlinks = option;
  };

  # Add these paths to list found in systemd.tmpfiles.rules
  config.systemd.tmpfiles.rules =
    (
      # tmpfiles.directories = [{ target = "/etc/foo-dir"; mode = "0775"; user = "jon"; group = "users"; }];
      # d /etc/foobaz 0755 jon users - -
      # tmpfiles.directories = [{ target = "/etc/foo-dir"; mode = "0775"; user = "jon"; group = "users"; source = "/etc/default"; }];
      # C+ /etc/foo-default 0775 me users - /etc/default
      map (x: let
        directory =
          if isString x
          then {target = x;}
          else x;
        rulesFor = {
          target,
          mode ? "0775",
          user ? "root",
          group ? user,
          source ? "-",
          ...
        }:
          trim (
            if (toString source) != "-"
            then ''
              C+ ${toString target} ${toMode mode} ${toString user} ${toString group} - ${toString source}
            ''
            else ''
              d ${toString target} ${toMode mode} ${toString user} ${toString group} - -
            ''
          );
      in
        rulesFor directory) (unique (cfg.directories ++ userDirectories))
    )
    ++ (
      # tmpfiles.files { target = "/etc/foobar"; mode = "0775"; user = "jon"; group = "users"; text = "Hello world!"; }];
      # f+ /etc/foobar 0775 jon users - "Hello world!"
      # tmpfiles.files { target = "/etc/foo-resolv"; mode = "0775"; user = "jon"; group = "users"; source = "/etc/resolv.conf"; }];
      # C+ /etc/foo-resolv /etc/foo-resolv 0775 jon users - /etc/resolv.conf
      map (x: let
        file =
          if isString x
          then {target = x;}
          else x;
        rulesFor = {
          target,
          mode ? "0775",
          user ? "root",
          group ? user,
          source ? "-",
          text ? "-",
          ...
        }:
          trim (
            if toString source != "-"
            then ''
              C+ ${toString target} ${toMode mode} ${toString user} ${toString group} - ${toString source}
            ''
            else
              (
                if text != "-"
                then ''
                  f+ ${toString target} ${toMode mode} ${toString user} ${toString group} - ${toText text}
                ''
                else ''
                  f ${toString target} ${toMode mode} ${toString user} ${toString group} -
                ''
              )
          );
      in
        rulesFor file) (unique (cfg.files ++ userFiles))
    )
    ++ (
      # tmpfiles.symlinks [{ target = "/etc/foobarlink"; source = "/etc/foobar"; }];
      # L+ /etc/foobar - - - - /etc/foobarlink
      map (x: let
        symlink =
          if isString x
          then {target = x;}
          else x;
        rulesFor = {
          target,
          source ? "/dev/null",
          ...
        }:
          trim ''
            L+ ${toString target} - - - - ${toString source}
          '';
      in
        rulesFor symlink) (unique (cfg.symlinks ++ userSymlinks))
    );
}
