{
  lib,
  config,
  pkgs,
  ...
}: let
  cfg = config.services.hermes-agent;
  inherit
    (config.lib.hermes-agent)
    agentNames
    clientAgents
    dataDir
    localClientAgents
    ;

  knownAgentCase =
    lib.concatMapStringsSep "\n" (
      name:
      # bash
      ''
        ${name})
          return 0
          ;;
      ''
    )
    clientAgents;

  profileListCommand =
    if clientAgents == []
    then "exit 0"
    else "printf '%s\\n' '${lib.concatStringsSep "\n" clientAgents}'\nexit 0";

  profileInfoCase =
    lib.concatMapStringsSep "\n" (
      name: let
        agent = cfg.agents.${name};
        isLocal = builtins.elem name localClientAgents;
        infoLines =
          [
            "name: ${name}"
            "mode: ${
              if isLocal
              then "local"
              else "ssh"
            }"
          ]
          ++ lib.optionals isLocal [
            "home: ${dataDir}/${name}"
            "config: ${dataDir}/${name}/config.yaml"
            "skin: ${dataDir}/${name}/skins/${name}.yaml"
            "honcho: ${dataDir}/${name}/honcho.json"
          ]
          ++ lib.optionals (!isLocal) [
            "ssh_target: ${agent.client}.home"
            "ssh_command: ${name}"
          ];
        infoCommand = lib.concatMapStringsSep "\n" (line: "printf '%s\\n' '${line}'") infoLines;
      in
        # bash
        ''
          ${name})
            ${infoCommand}
            exit 0
            ;;
        ''
    )
    clientAgents;

  profileHelpCommand = lib.concatStringsSep "\n" [
    "printf '%s\\n' 'Managed Hermes profiles:'"
    "printf '%s\\n' '  list              List configured runnable agents'"
    "printf '%s\\n' '  show <name>       Show managed agent details'"
    "printf '%s\\n' '  info <name>       Show managed agent details'"
    "printf '%s\\n' ''"
    "printf '%s\\n' 'Unsupported upstream profile mutations in this setup:'"
    "printf '%s\\n' '  use create delete alias rename export import install update'"
    "printf '%s\\n' ''"
    "printf '%s\\n' 'Use delegation with:'"
    "printf '%s\\n' '  hermes -p <agent> ...'"
    "printf '%s\\n' '  hermes --profile <agent> ...'"
    "printf '%s\\n' '  hermes --profile=<agent> ...'"
    "exit 0"
  ];

  missingProfileCommand = lib.concatStringsSep "\n" [
    "printf '%s\\n' 'No Hermes agent/profile selected.' >&2"
    "printf '%s\\n' '' >&2"
    "printf '%s\\n' 'Use one of:' >&2"
    "printf '%s\\n' '  hermes -p <agent> ...' >&2"
    "printf '%s\\n' '  hermes --profile <agent> ...' >&2"
    "printf '%s\\n' '  hermes --profile=<agent> ...' >&2"
    "exit 2"
  ];

  hermesShim = pkgs.self.mkScript {
    name = "hermes";
    text = lib.concatStringsSep "\n" [
      "export SSL_CERT_FILE=\"/etc/ssl/certs/ca-bundle.crt\""
      "export REQUESTS_CA_BUNDLE=\"/etc/ssl/certs/ca-bundle.crt\""
      "export HERMES_KANBAN_HOME=\"${dataDir}\""
      ""
      "set -a"
      "[[ -f \"${dataDir}/.env\" ]] && . \"${dataDir}/.env\""
      "set +a"
      ""
      "known_agent() {"
      "  case \"$1\" in"
      knownAgentCase
      "    *)"
      "      return 1"
      "      ;;"
      "  esac"
      "}"
      ""
      "require_known_agent() {"
      "  local agent=\"$1\""
      "  if ! known_agent \"$agent\"; then"
      "    echo \"Unknown Hermes agent/profile: $agent\" >&2"
      "    exit 127"
      "  fi"
      "}"
      ""
      "handle_profile_command() {"
      "  local sub=\"\${1:-}\""
      "  shift || true"
      ""
      "  case \"$sub\" in"
      "    \"\"|help|-h|--help)"
      profileHelpCommand
      "      ;;"
      "    list)"
      profileListCommand
      "      ;;"
      "    show|info)"
      "      local agent=\"\${1:-}\""
      "      if [[ -z \"$agent\" ]]; then"
      "        echo \"Missing Hermes agent/profile for 'hermes profile $sub'\" >&2"
      "        exit 2"
      "      fi"
      "      require_known_agent \"$agent\""
      "      case \"$agent\" in"
      profileInfoCase
      "        *)"
      "          echo \"Unknown Hermes agent/profile: $agent\" >&2"
      "          exit 127"
      "          ;;"
      "      esac"
      "      ;;"
      "    use|create|delete|alias|rename|export|import|install|update)"
      "      echo \"'hermes profile $sub' is not supported in this managed setup. Use Nix-managed agents and pass --profile/-p at runtime.\" >&2"
      "      exit 2"
      "      ;;"
      "    *)"
      "      echo \"Unknown or unsupported hermes profile subcommand: $sub\" >&2"
      "      exit 2"
      "      ;;"
      "  esac"
      "}"
      ""
      "if [[ \"\${1:-}\" == \"profile\" ]]; then"
      "  shift"
      "  handle_profile_command \"$@\""
      "fi"
      ""
      "agent=\"\""
      "args=()"
      "while (($#)); do"
      "  case \"$1\" in"
      "    -p|--profile)"
      "      if (($# < 2)); then"
      "        echo \"Missing Hermes agent/profile after $1\" >&2"
      "        exit 2"
      "      fi"
      "      agent=\"$2\""
      "      shift 2"
      "      ;;"
      "    --profile=*)"
      "      agent=\"\${1#--profile=}\""
      "      shift"
      "      ;;"
      "    *)"
      "      args+=(\"$1\")"
      "      shift"
      "      ;;"
      "  esac"
      "done"
      "set -- \"\${args[@]}\""
      ""
      "if [[ -n \"$agent\" ]]; then"
      "  require_known_agent \"$agent\""
      "  export HERMES_TUI=0"
      "  exec \"${config.home.profileDirectory}/bin/$agent\" \"$@\""
      "fi"
      ""
      "case \"\${1:-}\" in"
      "  \"\"|-h|--help|help|--version|-V)"
      "    exec \"${cfg.package}/bin/hermes\" \"$@\""
      "    ;;"
      "  *)"
      missingProfileCommand
      "    ;;"
      "esac"
      ""
    ];
  };
in {
  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !(builtins.elem "hermes" agentNames);
        message = "services.hermes-agent.agents cannot include 'hermes'; that binary name is reserved for the profile shim.";
      }
      {
        assertion =
          lib.all (
            name: let
              agent = cfg.agents.${name};
            in
              !(agent.gateway && builtins.isString agent.client)
          )
          agentNames;
        message = "services.hermes-agent.agents.<name>.gateway cannot be combined with a string client SSH alias.";
      }
    ];

    home.activation.hermes-agent-shim = lib.hm.dag.entryAfter ["writeBoundary"] ''
      $DRY_RUN_CMD mkdir -p "${config.home.homeDirectory}/bin"
      $DRY_RUN_CMD ln -sfn "${hermesShim}/bin/hermes" "${config.home.homeDirectory}/bin/hermes"
    '';

    home.packages = [hermesShim];
  };
}
