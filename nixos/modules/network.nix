{ ... }: {

  persist.dirs = [
    "/var/lib/bluetooth"                      # bluetooth connections
    "/etc/NetworkManager/system-connections"  # wifi connections
  ];

}
