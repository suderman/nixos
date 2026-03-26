{
  config,
  lib,
  ...
}: {
  config = lib.mkIf config.accounts.enable {
    # bind-mounted from /mnt/main/storage/home/jon/.local/share/mail
    accounts.email.maildirBasePath = ".local/share/mail";

    programs.notmuch = {
      enable = true;
      new.ignore = [
        ".uidvalidity"
        ".mbsyncstate"
        ".sync-if-1"
      ];
    };

    accounts.email.accounts.suderman = {
      primary = true;
      realName = "Jon Suderman";
      address = "jon@suderman.net";
      maildir.path = "suderman";
      notmuch.enable = true;
    };

    accounts.email.accounts.nonfiction = {
      realName = "Jon Suderman";
      address = "jon@nonfiction.ca";
      maildir.path = "nonfiction";
      notmuch.enable = true;
    };
  };
}
