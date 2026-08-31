# Follow-up work

These changes need an explicit decision or staged migration. They are not part
of routine cleanup.

- [ ] Upgrade PostgreSQL 14 with backups, service-specific migration checks,
      and rollback instructions.
- [ ] Remove Kit's `foobar` service and any confirmed scratch configuration.
- [ ] Move unchanged `system.stateVersion` and `home.stateVersion` values to
      their host and user boundaries.
- [ ] Migrate impermanence to systemd initrd and test the root wipe in `sim`
      before changing physical hosts.
- [ ] Stage automatic upgrades through validated revisions or a server-first
      rollout.
- [ ] Migrate Lux from Gitea to Forgejo with a tested backup and rollback path.
- [ ] Extract repeated boot-loader or backup-destination policy only where it
      removes real duplication.
- [ ] Add statix, deadnix, shellcheck, and CI after deciding which CI service
      should run the checks.
- [ ] Re-enable Nix dirty-tree warnings if the extra local warning is useful.
- [ ] Consider host roles only if the shared service baseline causes recurring
      deployment problems.

## Completed

- [x] Keep PostgreSQL on localhost, close port 5432 in the firewall, and remove
      Immich's obsolete Docker-network access rule. Current services use Unix
      sockets; local TCP remains available for Grafana and FreshRSS.
