{pkgs, ...}: {
  # Telegram
  home.packages = [pkgs.tdesktop];

  # iMessage
  programs.bluebubbles.enable = true;

  # Slack
  programs.slack.enable = true;
}
