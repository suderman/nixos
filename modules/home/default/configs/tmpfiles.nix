# Wrapper for systemd.user.tmpfiles.rules for my own sanity
{
  osConfig,
  config,
  lib,
  ...
}: let
  cfg = config.tmpfiles;
  inherit (lib) mkOption types unique;
  inherit (osConfig.tmpfiles.lib) toMode toText trim;
  inherit (config.home) homeDirectory username;
in {
  options.tmpfiles = {
    directories = mkOption {
      type = with types; listOf (either str attrs);
      default = [];
    };

    files = mkOption {
      type = with types; listOf (either str attrs);
      default = [];
    };

    symlinks = mkOption {
      type = with types; listOf (either str attrs);
      default = [];
    };
  };

  # Add these paths to list found in systemd.user.tmpfiles.rules
  config.systemd.user.tmpfiles.rules =
    (
      # tmpfiles.directories = ["foo-dir"];
      # d /home/jon/foo-dir 0755 jon users - -
      # tmpfiles.directories = [{ target = "bar-dir"; mode = 775; source = "/etc/default"; }];
      # C+ /home/jon/bar-dir 0775 me users - /etc/default
      map (x: let
        directory =
          if builtins.isAttrs x
          then x // {target = "${homeDirectory}/${toString (x.target or "target")}";}
          else {target = "${homeDirectory}/${x}";};
        rulesFor = {
          target,
          mode ? "0775",
          user ? username,
          group ? "users",
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
        rulesFor directory) (unique cfg.directories)
    )
    ++ (
      # tmpfiles.files { target = "foobar"; text = "Hello world!"; }];
      # f+ /home/jon/foobar 0775 jon users - "Hello world!"
      # tmpfiles.files { target = "foobaz"; mode = 600; source = config.age.secrets.baz.path; }];
      # C+ /home/jon/foobaz 0600 jon users -  /run/user/1000/agenix/baz
      map (x: let
        file =
          if builtins.isAttrs x
          then x // {target = "${homeDirectory}/${toString (x.target or "target")}";}
          else {target = "${homeDirectory}/${x}";};
        rulesFor = {
          target,
          mode ? "0775",
          user ? username,
          group ? "users",
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
        rulesFor file) (unique cfg.files)
    )
    ++ (
      # tmpfiles.symlinks [{ target = "foobarlink"; source = "/etc/foobar"; }];
      # L+ /home/jon/foobarlink - - - - /etc/foobarlink
      map (x: let
        symlink =
          if builtins.isAttrs x
          then x // {target = "${homeDirectory}/${toString (x.target or "target")}";}
          else {target = "${homeDirectory}/${x}";};
        rulesFor = {
          target,
          source ? "/dev/null",
          ...
        }:
          trim ''
            L+ ${toString target} - - - - ${toString source}
          '';
      in
        rulesFor symlink) (unique cfg.symlinks)
    );
}
