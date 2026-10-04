{...}: let
  mount = mountpoint: {
    inherit mountpoint;
    mountOptions = ["compress=zstd" "noatime" "discard=async"];
  };
in {
  disko.devices.disk.system = {
    type = "disk";
    # Linode final and installer profiles must both map the raw system disk here.
    device = "/dev/sda";
    content = {
      type = "gpt";
      partitions = {
        bios = {
          size = "1M";
          type = "EF02";
          priority = 1;
        };
        boot = {
          size = "1G";
          priority = 2;
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/boot";
          };
        };
        swap = {
          size = "2G";
          priority = 3;
          content = {type = "swap";};
        };
        main = {
          size = "100%";
          priority = 4;
          content =
            mount "/mnt/main"
            // {
              type = "btrfs";
              extraArgs = ["-fL" "main"];
              subvolumes = {
                root = mount "/";
                nix = mount "/nix";
                storage = {};
                scratch = {};
                snapshots = {};
              };
            };
        };
      };
    };
  };
}
