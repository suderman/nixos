{config, ...}: {
  # Agent runtime files: kept across reboots, but not synced, snapshotted, or
  # in Git. project-org-tasks points agents here instead of ~/org.
  persist.scratch.directories = [".local/state/org-work"];

  # Her client and harness accounts. Her daemon stays in Jon's account on kit
  # until she moves to bot.
  programs.june = {
    enable = true;
    daemonHost = "jon@kit";
    # Her checkout runs in place of the pinned package once it is cloned.
    source = "${config.xdg.userDirs.extraConfig.SOURCE}/suderman/june";
    dataDir = "${config.xdg.userDirs.extraConfig.ORG}/june";
  };
}
