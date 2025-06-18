{ config, pkgs, ... }: {

  home.packages = with pkgs; [ 
    slack # Slack chatroom
    tdesktop # Telegram messenger
  ];

  # iMessage
  programs.bluebubbles.enable = true;

}
