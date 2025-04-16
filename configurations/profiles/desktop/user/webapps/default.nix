{ config, lib, ... }: let

  inherit (lib) mkMerge;
  inherit (config.programs.chromium.lib) mkWebApp;

in { 
  xdg.desktopEntries = mkMerge (map mkWebApp [

    {
      name = "Gmail";
      icon = ./gmail.svg;
      url = "https://mail.google.com/";
      profile = "work";
    }

    {
      name = "Google Calendar";
      icon = ./calendar.svg;
      url = "https://calendar.google.com/";
      profile = "work";
    }

    {
      name = "Google Analytics";
      icon = ./analytics.svg;
      url = "https://analytics.google.com/";
      profile = "team";
    }

    {
      name = "Google Meet";
      icon = ./meet.svg;
      url = "https://meet.google.com/";
      profile = "work";
    }

    {
      name = "Slack";
      icon = ./slack.svg;
      url = "https://nonfictionstudios.slack.com/";
      profile = "work";
    }

    {
      name = "Harvest";
      icon = ./harvest.png;
      url = "https://nonfictionstudios.harvestapp.com/";
      profile = "work";
    }

    {
      name = "Asana";
      icon = ./asana.png;
      url = "https://app.asana.com/";
      profile = "work";
    }

  ]);
}
