# CLIProxyAPI's official model catalog, pinned, with gpt-6.1-terra added to the paid Codex tiers.
# OpenAI released it on 2026-10-26, before router-for-me/models listed it. Remove this file and
# the models.catalog default in default.nix once the official catalog has it, so refreshes resume.
{
  fetchurl,
  runCommand,
  jq,
}: let
  official = fetchurl {
    url = "https://raw.githubusercontent.com/router-for-me/models/6e82c3999c895ef83ca9087e6944008658fabe78/models.json";
    hash = "sha256-Q67SZb39ElF/R9sTqAJUKMuE4gFCWKwFrOBqASCKGyg=";
  };
in
  runCommand "cliproxyapi-models.json" {nativeBuildInputs = [jq];} ''
    jq '
      def terra: (map(select(.id == "gpt-6.1-sol")) | first) + {
        id: "gpt-6.1-terra",
        created: 1793001600,
        display_name: "GPT 6.1 Terra",
        description: "Fast, lower-cost model for computer use and visual reasoning.",
        thinking: {levels: ["none", "low", "medium", "high", "xhigh", "max"]}
      };
      reduce ("codex-team", "codex-plus", "codex-pro") as $tier (.;
        if any(.[$tier][]; .id == "gpt-6.1-terra") then . else .[$tier] += [.[$tier] | terra] end)
    ' ${official} > $out
  ''
