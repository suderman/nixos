{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.accounts.enable {
    # Contacts are stored at ~/.local/share/contacts
    persist.storage.directories = [".local/share/contacts"];
    accounts.contact.basePath = ".local/share";
    accounts.contact.accounts."contacts" = {
      remote = {
        userName = "suderman@fastmail.com";
        passwordCommand = ["cat" config.age.secrets.fastmail.path];
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
      khard.enable = true;
    };

    # DAV sync
    programs.vdirsyncer.enable = true;
    services.vdirsyncer.enable = true;

    # Address book
    programs.khard.enable = true;
    xdg.configFile."khard/khard.conf".text = let
      path = "${config.home.homeDirectory}/.local/share/contacts";
    in
      lib.mkForce ''
        [addressbooks]
        [[personal]]
        path = ${path}/Personal/
        [[shared]]
        path = ${path}/Shared/

        [general]
        default_action=list
        editor=nvim, -i, NONE

        [contact table]
        display=formatted_name
        preferred_email_address_type=pref, work, home
        preferred_phone_number_type=pref, cell, home

        [vcard]
        private_objects=Jabber, Skype, Twitter
      '';
  };
}
