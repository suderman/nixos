show "nix build .#nixosConfigurations.$(hostname).config.system.build.toplevel --json | jq -r '.[].outputs | to_entries[].value' | cachix push suderman"
nix build .#nixosConfigurations.$(hostname).config.system.build.toplevel --json | jq -r '.[].outputs | to_entries[].value' | cachix push suderman
