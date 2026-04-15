{
  config,
  pkgs,
  ...
}: {
  # Preload OpenCode with my API keys
  programs.opencode.apiKeys = ./apikeys-env.age;

  # Preload mmx-cli with my API keys
  programs.mmx-cli.apiKeys = ./apikeys-env.age;

  # Self-hosted webapps running from my kit desktop
  xdg = config.desktop {
    desktopEntries =
      (config.lib.chromium.mkWebApp {
        name = "OpenCode";
        url = "https://code.suderman.org";
        icon =
          pkgs.writeText "icon.svg"
          # html
          ''
            <svg width='300' height='300' viewBox='0 0 300 300' fill='none' xmlns='http://www.w3.org/2000/svg'><g transform='translate(30, 0)'><g clip-path='url(#clip0_1401_86283)'><mask id='mask0_1401_86283' style='mask-type:luminance' maskUnits='userSpaceOnUse' x='0' y='0' width='240' height='300'><path d='M240 0H0V300H240V0Z' fill='white'/></mask><g mask='url(#mask0_1401_86283)'><path d='M180 240H60V120H180V240Z' fill='#4B4646'/><path d='M180 60H60V240H180V60ZM240 300H0V0H240V300Z' fill='#F1ECEC'/></g></g></g><defs><clipPath id='clip0_1401_86283'><rect width='240' height='300' fill='white'/></clipPath></defs></svg>
          '';
      })
      // (config.lib.chromium.mkWebApp {
        name = "OpenClaw";
        url = "https://claw.suderman.org";
        icon =
          pkgs.writeText "icon.svg"
          # html
          ''
            <svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" aria-label="Pixel lobster" viewBox="0 0 16 16"><path fill="none" d="M0 0h16v16H0z"/><g fill="#3a0a0d"><path d="M1 5h1v3H1zM2 4h1v1H2zM2 8h1v1H2zM3 3h1v1H3zM3 9h1v1H3zM4 2h1v1H4zM4 10h1v1H4zM5 2h6v1H5zM11 2h1v1h-1zM12 3h1v1h-1zM12 9h1v1h-1zM13 4h1v1h-1zM13 8h1v1h-1zM14 5h1v3h-1zM5 11h6v1H5zM4 12h1v1H4zM11 12h1v1h-1zM3 13h1v1H3zM12 13h1v1h-1zM5 14h6v1H5z"/></g><g fill="#ff4f40"><path d="M5 3h6v1H5zM4 4h8v1H4zM3 5h10v1H3zM3 6h10v1H3zM3 7h10v1H3zM4 8h8v1H4zM5 9h6v1H5zM5 12h6v1H5zM6 13h4v1H6z"/></g><g fill="#ff775f"><path d="M1 6h2v1H1zM2 5h1v1H2zM2 7h1v1H2zM13 6h2v1h-2zM13 5h1v1h-1zM13 7h1v1h-1z"/></g><g fill="#081016"><path d="M6 5h1v1H6zM9 5h1v1H9z"/></g><g fill="#f5fbff"><path d="M6 4h1v1H6zM9 4h1v1H9z"/></g></svg>
          '';
      });
  };
}
