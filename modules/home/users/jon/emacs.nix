{
  config,
  pkgs,
  ...
}: {
  programs.emacs = {
    enable = true;
    package = pkgs.emacs-pgtk;
  };
  services.emacs = {
    package = config.programs.emacs.package;
    extraOptions = [
      "--init-directory"
      "~/.config/emacs"
    ];
  };
  home.activation.emacs-install = {
    after = ["link-ssh-id"];
    before = [];
    data = ''
      echo 1
    '';
  };
}
