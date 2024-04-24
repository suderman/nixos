{ lib, ... }: let inherit (lib) mkDefault; in {

  windowrulev2 = [

    # forbid windows from maximizing/fullscreening themselves
    "suppressevent maximize, class:.*"
    "suppressevent fullscreen, class:.*"

  ];

}
