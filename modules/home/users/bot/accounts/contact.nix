{
  config,
  lib,
  pkgs,
  ...
}: let
  account = "contacts";
in {
  config = lib.mkIf config.accounts.enable {
    # Contacts are stored at ~/.local/share/contacts
    persist.storage.directories = [".local/share/${account}"];
    accounts.contact.basePath = ".local/share";
    accounts.contact.accounts.${account} = {
      remote = {
        userName = "suderman@fastmail.com";
        passwordCommand = ["/run/current-system/sw/bin/cat" config.age.secrets.fastmail-dav.path];
        url = "https://carddav.fastmail.com/";
        type = "carddav";
      };
      local = {
        type = "filesystem";
        fileExt = ".vcf";
      };
      vdirsyncer = {
        enable = true;
        collections = [
          ["Personal" "Default" "Personal"] # default address book
          ["Shared" "masteruser_autoyk908y8@fastmail.com.Shared" "Shared"]
        ];
        conflictResolution = "remote wins";
      };
      khard = {
        enable = true;
        addressbooks = ["Personal" "Shared"];
      };
    };

    # DAV sync
    programs.vdirsyncer.enable = true;
    services.vdirsyncer.enable = true;

    # Put this contacts account on vdirsyncer's radar
    systemd.user.services.vdirsyncer.Service.ExecStart = lib.mkBefore [
      (
        pkgs.self.mkScript {
          path = [pkgs.vdirsyncer];
          text = "yes | vdirsyncer discover contacts_${account} || true";
        }
      )
    ];

    # Address book CLI
    programs.khard.enable = true;
  };
}
