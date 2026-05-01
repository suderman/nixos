{
  config,
  lib,
  ...
}: {
  # Lingered users can have their systemd user manager (`user@UID.service`)
  # started during boot before Home Manager has finished activating that user's
  # generation. That can leave user services starting from stale/incomplete HM
  # state.
  #
  # Order the `user@.service` template after all Home Manager activation services
  # so user managers start only after HM has installed the current user units/files.
  # Secret consumers should still run as user services ordered after agenix.service;
  # this only fixes the HM-vs-user-manager boot race.
  systemd.services."user@" = let
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
