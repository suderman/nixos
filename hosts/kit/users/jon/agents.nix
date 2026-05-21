_: {
  services.hermes-agent = {
    enable = true;
    matrix.enable = true;

    # Agents and their configuration overrides
    agents = {
      june.gateway = true;
      pax.gateway = true;
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
