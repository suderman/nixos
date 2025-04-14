{ config, lib, ... }: let

  inherit (lib) mkMerge;
  inherit (config.programs.chromium.lib) mkWebApp;

in { 
  xdg.desktopEntries = mkMerge (map mkWebApp [

    {
      name = "Gmail";
      icon = ./gmail.svg;
      url = "https://mail.google.com/";
    }

    {
      name = "Google Calendar";
      icon = ./calendar.svg;
      url = "https://calendar.google.com/";
    }

    {
      name = "Google Analytics";
      icon = ./analytics.svg;
      url = "https://analytics.google.com/";
    }

    {
      name = "Google Meet";
      icon = ./meet.svg;
      url = "https://meet.google.com/";
    }

    {
      name = "Slack";
      icon = ./slack.svg;
      url = "https://nonfictionstudios.slack.com/";
    }

    {
      name = "Harvest";
      icon = ./harvest.png;
      url = "https://nonfictionstudios.harvestapp.com/";
    }

    {
      name = "Asana";
      icon = ./asana.png;
      url = "https://app.asana.com/";
    }

  ]);
}
