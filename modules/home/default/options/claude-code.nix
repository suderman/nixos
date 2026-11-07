# programs.claude-code.enable = true;
{
  config,
  lib,
  perSystem,
  pkgs,
  ...
}: let
  cfg = config.programs.claude-code;

  directAccountWrapper = account:
    pkgs.self.mkScript {
      name = "claude-${account}";
      text =
        # bash
        ''
          unset ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY \
            CLAUDE_CODE_OAUTH_TOKEN \
            CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY ENABLE_CLAUDEAI_MCP_SERVERS \
            CLAUDE_CODE_USE_BEDROCK CLAUDE_CODE_USE_VERTEX CLAUDE_CODE_USE_FOUNDRY
          export CLAUDE_CONFIG_DIR="$HOME/.claude-${account}"
          export ANTHROPIC_MODEL=claude-opus-5-5

          exec ${lib.getExe cfg.package} "$@"
        '';
    };

  wrapper = pkgs.self.mkScript {
    name = "claude-pool";
    text =
      # bash
      ''
        set -a
        . ${lib.escapeShellArg cfg.environmentFile}
        set +a

        export ANTHROPIC_BASE_URL=https://cliproxyapi.kit
        export ANTHROPIC_AUTH_TOKEN="''${CLIPROXYAPI_API_KEY:?Missing CLIPROXYAPI_API_KEY in Claude environment file}"
        export ANTHROPIC_MODEL=claude-opus-5-5
        export CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY=1
        # Gateway auth otherwise loses the subscription's one-hour main cache default.
        export CLAUDE_CODE_PROMPT_CACHE_TTL="''${CLAUDE_CODE_PROMPT_CACHE_TTL:-1h}"
        export ENABLE_CLAUDEAI_MCP_SERVERS=false
        unset ANTHROPIC_API_KEY CLAUDE_CODE_OAUTH_TOKEN

        exec ${lib.getExe cfg.package} "$@"
      '';
  };
in {
  options.programs.claude-code.environmentFile = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    description = "Decrypted shell-compatible dotenv containing CLIPROXYAPI_API_KEY. Enables the CLIProxyAPI launcher when set.";
  };

  config = lib.mkIf cfg.enable {
    programs.claude-code.package = lib.mkDefault perSystem.agents.claude-code;

    # Keep settings and login state writable and owned by Claude and agents apply.
    persist.storage = {
      directories = [
        {
          directory = ".claude";
          mode = "0700";
        }
        {
          directory = ".claude-home";
          mode = "0700";
        }
        {
          directory = ".claude-work";
          mode = "0700";
        }
        {
          directory = ".local/state/claude";
          mode = "0700";
        }
      ];
      files = [".claude.json"];
    };

    # Home Manager owns the outer link; runtime owns the selected account.
    home.file.".local/bin/claude".source =
      config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/.local/state/claude/current";

    home.activation.claudeAccount = lib.hm.dag.entryAfter ["writeBoundary"] ''
      if [[ ! -e "$HOME/.local/state/claude/current" && ! -L "$HOME/.local/state/claude/current" ]]; then
        run install -d -m 0700 "$HOME/.local/state/claude"
        run ln -s "$HOME/.local/bin/claude-work" "$HOME/.local/state/claude/current"
      fi
    '';

    home.file.".local/bin/claude-pool" = lib.mkIf (cfg.environmentFile != null) {
      source = lib.getExe wrapper;
    };

    home.file.".local/bin/claude-home".source = lib.getExe (directAccountWrapper "home");
    home.file.".local/bin/claude-work".source = lib.getExe (directAccountWrapper "work");

    home.file.".local/bin/claude-toggle".source = lib.getExe (pkgs.self.mkScript {
      name = "claude-toggle";
      text =
        # bash
        ''
          if (( $# > 1 )); then
            echo 'Usage: claude-toggle [home|work|--status]' >&2
            exit 2
          fi
          case "''${1-}" in
            --help|-h)
              echo 'Usage: claude-toggle [home|work|--status]'
              echo 'No argument flips accounts. Affects new launches only; never logs in or moves sessions.'
              exit 0
              ;;
            ""|home|work|--status) ;;
            *) echo 'Usage: claude-toggle [home|work|--status]' >&2; exit 2 ;;
          esac

          selector="$HOME/.local/state/claude/current"
          if [[ -e "$selector" && ! -L "$selector" ]]; then
            echo "Not an account symlink: $selector" >&2
            exit 1
          fi
          case "$(readlink "$selector" 2>/dev/null || true)" in
            "$HOME/.local/bin/claude-home") current=home ;;
            "$HOME/.local/bin/claude-work"|"") current=work ;;
            *) echo "Unknown account symlink: $selector" >&2; exit 1 ;;
          esac
          case "''${1-}" in
            --status) printf '%s\n' "$current"; exit 0 ;;
            home|work) account="$1" ;;
            "")
              if [[ "$current" == home ]]; then account=work; else account=home; fi
              ;;
          esac

          install -d -m 0700 "''${selector%/*}"
          next="$selector.$$"
          trap 'rm -f -- "$next"' EXIT
          ln -s -- "$HOME/.local/bin/claude-$account" "$next"
          mv -Tf -- "$next" "$selector"
          printf '%s\n' "$account"
        '';
    });

    home.file.".local/bin/claude-quota".source = lib.getExe (pkgs.self.mkScript {
      name = "claude-quota";
      path = [pkgs.curl pkgs.jq];
      text =
        # bash
        ''
          if (( $# > 1 )); then
            echo 'Usage: claude-quota [--json]' >&2
            exit 2
          fi
          case "''${1-}" in
            --help|-h)
              echo 'Usage: claude-quota [--json]'
              echo 'Reads the shared two-minute snapshot, not live inference or management credentials.'
              echo 'Stale/error data is not evidence that an account has usable quota.'
              exit 0
              ;;
            ""|--json) ;;
            *) echo 'Usage: claude-quota [--json]' >&2; exit 2 ;;
          esac

          snapshot=$(curl --fail --silent --show-error --max-time 10 \
            https://cliproxyapi-quota.kit/quota.json | jq -e '
              now as $now | .error as $error |
              {fetched, error, accounts: [.accounts[] | select(.provider == "claude") |
                {label, fetched, error, windows,
                 ageSeconds: (if .fetched == null then null else [0, ($now - .fetched | floor)] | max end),
                 stale: ($error != "" or .error != "" or .fetched == null or $now - .fetched > 300),
                 proxyDisabled: .disabled, proxyUnavailable: .unavailable}]}
            ')
          if [[ "''${1-}" == --json ]]; then
            printf '%s\n' "$snapshot"
          else
            jq -r '
              def reset: if . == null then "unknown" else floor | strftime("%Y-%m-%d %H:%M UTC") end;
              (if .error != "" then "Snapshot error: \(.error)" else empty end),
              (if .accounts == [] then "No Claude accounts in snapshot." else empty end),
              (.accounts[] |
                "\(.label) (\(if .stale then "STALE" else "fresh" end), age \(.ageSeconds // "unknown")s)",
                (if .error != "" then "  Error: \(.error)" else empty end),
                (.windows[] | "  \(.name): \(.remaining)% remaining; resets \(.resetAt | reset)"))
            ' <<< "$snapshot"
          fi
        '';
    });

    home.file.".local/bin/claude-auto".source = lib.getExe (pkgs.self.mkScript {
      name = "claude-auto";
      text = let
        auto =
          pkgs.writeText "claude-auto.py"
          # python
          ''
            import json
            import math
            import os
            import subprocess
            import sys
            import time

            WRAPPERS = {
                "work": ("jon@nonfiction.ca", "${lib.getExe (directAccountWrapper "work")}"),
                "home": ("jon@suderman.net", "${lib.getExe (directAccountWrapper "home")}"),
            }

            def number(value):
                return type(value) in (int, float) and math.isfinite(value)

            def window(windows, name, now, duration, floor, minimum, grace, reserve):
                matches = [w for w in windows if w.get("name") == name]
                if len(matches) != 1:
                    raise ValueError(f"missing or duplicate {name} window")
                raw = matches[0]
                remaining, reset = raw.get("remaining"), raw.get("resetAt")
                if not number(remaining) or not 0 <= remaining <= 100:
                    raise ValueError(f"invalid {name} remaining quota")
                if reset is not None and (not number(reset) or reset <= now):
                    raise ValueError(f"{name} reset passed or invalid; await a new sample")
                # Unknown reset gets no urgency bonus or low-quota exception.
                left = duration if reset is None else min(duration, reset - now)
                if remaining < minimum and not (left <= grace and remaining >= reserve):
                    raise ValueError(f"{name} below {minimum}% and outside near-reset reserve")
                return {
                    "remaining": remaining,
                    "resetInSeconds": None if reset is None else round(left),
                    "pace": min(100, remaining * duration / max(left, floor)),
                }

            def candidate(snapshot, account, now):
                label, _ = WRAPPERS[account]
                matches = [a for a in snapshot["accounts"] if a.get("label") == label]
                if len(matches) != 1:
                    raise ValueError("missing or duplicate account label")
                data = matches[0]
                fetched = data.get("fetched")
                if (data.get("stale") is not False or data.get("error") != ""
                        or not number(fetched) or not 0 <= now - fetched <= 300):
                    raise ValueError("quota is stale, failed or missing a valid timestamp")
                windows = data["windows"]
                five = window(windows, "5 hour", now, 18000, 1800, 10, 900, 2)
                week = window(windows, "Weekly", now, 604800, 86400, 5, 21600, 1)
                weekly = [week]
                if any(w.get("name") == "Opus weekly" for w in windows):
                    weekly.append(window(windows, "Opus weekly", now, 604800, 86400, 5, 21600, 1))
                # Harmonic weighting penalizes a weak window instead of hiding it in a sum.
                weekly_pace = min(w["pace"] for w in weekly)
                score = 1 / (0.65 / five["pace"] + 0.35 / weekly_pace)
                return {
                    "account": account, "eligible": True, "score": score,
                    "fiveHour": five, "weekly": weekly,
                }

            def main():
                args = sys.argv[1:]
                if args == ["--help"]:
                    print("Usage: claude-auto [--explain | -- CLAUDE_ARGS... | CLAUDE_ARGS...]")
                    print("Select a direct account once from fresh quota. --explain emits JSON without launching.")
                    return 0
                explain = args == ["--explain"]
                if args[:1] == ["--"]:
                    args = args[1:]
                try:
                    result = subprocess.run(
                        ["${config.home.file.".local/bin/claude-quota".source}", "--json"],
                        check=True, capture_output=True, text=True,
                    )
                    snapshot = json.loads(result.stdout)
                    if snapshot.get("error") != "" or not isinstance(snapshot.get("accounts"), list):
                        raise ValueError("snapshot has an error or invalid account list")
                    decisions = []
                    now = time.time()
                    for account in WRAPPERS:
                        try:
                            decisions.append(candidate(snapshot, account, now))
                        except (ValueError, KeyError, TypeError, AttributeError) as error:
                            decisions.append({"account": account, "eligible": False, "reason": str(error)})
                except (subprocess.CalledProcessError, OSError, ValueError, AttributeError):
                    print("claude-auto: cannot read a valid quota snapshot; no account launched", file=sys.stderr)
                    return 1
                eligible = [d for d in decisions if d["eligible"]]
                # Stable iteration breaks equal scores in favor of work, not snapshot order.
                chosen = max(eligible, key=lambda d: d["score"]) if eligible else None
                if explain:
                    print(json.dumps({"selected": chosen["account"] if chosen else None, "accounts": decisions}))
                if chosen is None:
                    reasons = "; ".join(d["account"] + ": " + d["reason"] for d in decisions)
                    print("claude-auto: no eligible account; " + reasons, file=sys.stderr)
                    return 1
                if explain:
                    return 0
                account = chosen["account"]
                print(f"claude-auto: {account} (score {chosen['score']:.1f})", file=sys.stderr)
                os.execv(WRAPPERS[account][1], ["claude-" + account, *args])

            if __name__ == "__main__":
                sys.exit(main())
          '';
      in
        # bash
        ''
          exec ${pkgs.python3}/bin/python3 ${auto} "$@"
        '';
    });

    home.file.".local/bin/claude-direct".source = lib.getExe (pkgs.self.mkScript {
      name = "claude-direct";
      text =
        # bash
        ''
          unset ANTHROPIC_BASE_URL ANTHROPIC_AUTH_TOKEN ANTHROPIC_API_KEY \
            CLAUDE_CODE_OAUTH_TOKEN ANTHROPIC_MODEL \
            CLAUDE_CODE_ENABLE_GATEWAY_MODEL_DISCOVERY ENABLE_CLAUDEAI_MCP_SERVERS

          exec ${lib.getExe cfg.package} "$@"
        '';
    });
  };
}
