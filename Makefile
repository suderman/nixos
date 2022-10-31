all: switch

# if sudo, switch_host; else, switch_home
switch:
	@[ "$(shell id -u)" = 0 ] && make --no-print-directory switch_host || make --no-print-directory switch_home

# rebuild the whole system with nixos-rebuild
switch_host:
	nixos-rebuild switch --flake '.'

# rebuild the home directory with home-manager
switch_home:
	home-manager switch --flake '.#me'

update:
	nix flake update

install_home_manager:
	nix build --no-link .#homeConfigurations.me.activationPackage
	"$$(nix path-info .#homeConfigurations.me.activationPackage)"/activate
