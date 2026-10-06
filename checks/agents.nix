{
  flake,
  pkgs,
  perSystem,
  ...
}: let
  lib = pkgs.lib;
  retired = ["agentConfigurationCheckout" "piAgentConfiguration" "openCodeAgentConfiguration" "hermesAgentConfiguration"];
  checkHost = host: let
    cfg = flake.nixosConfigurations.${host}.config.home-manager.users.jon;
    directories = map (entry:
      if builtins.isString entry
      then entry
      else entry.directory)
    cfg.persist.storage.directories;
    command = lib.findFirst (package: lib.getName package == "agents") (throw "Missing agents command") cfg.home.packages;
    checkout = lib.head cfg.systemd.user.services.agents-checkout.Service.ExecStart;
    stylix = pkgs.writeText "${host}-pi-stylix-activation" cfg.home.activation.piStylixTheme.data;
    herdr = pkgs.writeText "${host}-pi-herdr-activation" cfg.home.activation.piHerdrIntegration.data;
    activation = lib.concatMapStringsSep "\n" (entry: entry.data) (builtins.attrValues cfg.home.activation);
  in
    assert cfg.programs.agents.enable && cfg.programs.claude-code.enable && cfg.programs.pi-coding-agent.enable;
    assert cfg.programs.claude-code.package == perSystem.agents.claude-code;
    assert cfg.programs.claude-code.finalPackage == perSystem.agents.claude-code;
    assert lib.elem perSystem.agents.claude-code cfg.home.packages;
    assert lib.all (path: lib.elem path directories) [".agents" ".claude"];
    assert lib.elem ".claude.json" cfg.persist.storage.files;
    assert !(cfg.home.sessionVariables ? CLAUDE_CONFIG_DIR);
    assert lib.all (name: !(builtins.hasAttr name cfg.home.activation)) retired;
    assert !(lib.hasInfix ".agents/" activation);
    assert cfg.home.activation.piStylixTheme.after == ["writeBoundary"];
    assert cfg.home.activation.piHerdrIntegration.after == ["writeBoundary"];
    assert lib.all (file: !(lib.hasInfix ".claude" file.target || lib.hasInfix ".agents/" file.target)) (builtins.attrValues cfg.home.file);
    assert cfg.systemd.user.services.agents-checkout.Service.Type == "exec";
    assert cfg.systemd.user.services.agents-checkout.Service.Restart == "on-failure"; ''
      echo "Checking ${host} agents installation and independent integrations"
      python3 ${../modules/home/default/options/agents/test.py} \
        ${checkout} ${lib.getExe command} ${stylix} ${herdr}
      home=$(mktemp -d)
      env -i HOME="$home" PATH=${lib.makeBinPath [pkgs.coreutils]} \
        ${perSystem.agents.claude-code}/bin/claude --version
      rm -rf -- "$home"
    '';
in
  pkgs.runCommand "agents-home-manager-check" {
    nativeBuildInputs = with pkgs; [bash coreutils git python3];
  } ''
    ${lib.concatMapStringsSep "\n" checkHost ["kit" "cog"]}
    touch "$out"
  ''
