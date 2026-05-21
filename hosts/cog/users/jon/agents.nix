_: {
  services.hermes-agent = {
    enable = true;
    matrix.enable = true;

    # Agents and their configuration overrides
    agents = {
      cid.gateway = true;
      june.client = "kit";
      pax.client = "kit";
      dot.client = "gem";
    };
  };

  # Ensure uvx is available for mcp servers
  toolchains.python.enable = true;
}
