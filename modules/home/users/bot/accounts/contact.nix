{
  config,
  lib,
  ...
}: let
  account = "contacts";
in {
  config = lib.mkIf config.accounts.enable {
    # bind-mounted from /mnt/main/storage/home/jon/.local/share
    accounts.contact.basePath = ".local/share";

    accounts.contact.accounts.${account} = {
      local = {
        type = "filesystem";
        fileExt = ".vcf";
      };

      khard = {
        enable = true;
        addressbooks = ["Personal" "Shared"];
      };
    };

    programs.khard.enable = true;
  };
}
