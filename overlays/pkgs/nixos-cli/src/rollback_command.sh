local dir="/etc/nixos"

# List all NixOS configurations, skipping bootstrap
function configurations {
  nix flake show --json $dir | jq -r '.nixosConfigurations | keys[] | select(. != "bootstrap")' | xargs
}

# Choose from list of configurations, including [all] to deploy to full list 
local targets="$(ask "$(configurations) [all]" "${args[target]-$(hostname)}")"
[[ "$targets" == "[all]" ]] && targets="$(configurations)"

# Default action is switch configuration, but boot and test are available
local action="switch"
if [[ "${args[--boot]}" == "1" ]]; then
  action="boot"
elif [[ "${args[--test]}" == "1" ]]; then
  action="test"
fi

# nixos-rebuild on all selected targets
for target in $targets; do
  task "nixos-rebuild --target-host root@${target}.$(hostname -d) --flake ${dir}#${target} --rollback ${action}"
done
