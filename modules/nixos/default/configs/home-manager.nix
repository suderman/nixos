{
  config,
  lib,
  ...
}: {
  # Home Manager writes into these directories during activation. Wait for their
  # persistent bind mounts, or those writes will be hidden when mounts appear.
  systemd.services = lib.mkMerge [
    (lib.mapAttrs'
      (username: user:
        lib.nameValuePair "home-manager-${username}" {
          unitConfig.RequiresMountsFor =
            (lib.mapAttrsToList
              (_: directory: "${user.home.homeDirectory}/${directory.path}")
              (lib.filterAttrs (_: directory: directory.enable && directory.sync && directory.persist != null) (user.home.directories or {})))
            ++ lib.optionals (user.programs.hermes.enable or false) ["${user.home.homeDirectory}/.hermes"];
        })
      (config.home-manager.users or {}))

    # Lingered users can have their systemd user manager (`user@UID.service`)
    # started during boot before Home Manager has finished activating that user's
    # generation. That can leave user services starting from stale/incomplete HM
    # state.
    #
    # Order the `user@.service` template after all Home Manager activation services
    # so user managers start only after HM has installed the current user units/files.
    # Secret consumers should still run as user services ordered after agenix.service;
    # this only fixes the HM-vs-user-manager boot race.
    {
      "user@" = let
        homeManagerServices =
          lib.mapAttrsToList
          (username: _: "home-manager-${username}.service")
          (config.home-manager.users or {});
      in
        lib.mkIf (homeManagerServices != []) {
          wants = lib.mkAfter homeManagerServices;
          after = lib.mkAfter homeManagerServices;
        };
    }
  ];
}
