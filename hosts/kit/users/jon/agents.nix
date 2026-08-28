_: {
  services.hermes-agent = {
    enable = true;
    gateway.enable = true;
    dashboard.enable = true;

    # Agents and their configuration overrides
    agents = {
      june = {
        client = true;
        homeAssistant = true;
      };
      pax.client = true;
      cid.client = "cog";
      dot.client = "gem";
    };
  };

  # Ensure uvx is available for mcp servers
  toolchains.python.enable = true;

  services.camofox-browser = {
    enable = true;
    enableVnc = true;
  };
}
