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
  if [[ "${target}" == "$(hostname)" ]]; then
    # https://github.com/NixOS/nixpkgs/issues/195777#issuecomment-1324378856
    # Commented this out because it's messing with Hyprland
    # task "sudo systemctl restart systemd-udev-trigger.service" 
    task "sudo nixos-rebuild --flake ${dir}#${target} ${action}"
  else
    task "nixos-rebuild --build-host ${USER}@${target}.$(domainname) --target-host ${USER}@${target}.$(domainname) --flake ${dir}#${target} --use-remote-sudo ${action}"
  fi
done
