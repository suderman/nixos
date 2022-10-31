HOSTNAME := $(shell hostname)

all: switch

# if sudo, switch_host; else, switch_home
switch:
	@if [ "$(shell id -u)" = 0 ]; then make --no-print-directory switch_host; else make --no-print-directory switch_home; fi

# rebuild the whole system with nixos-rebuild
switch_host:
	nixos-rebuild switch --flake '$(PWD)#$(HOSTNAME)'

# rebuild the home directory with home-manager
switch_home:
	home-manager switch --flake '$(PWD)#me'

update:
	nix flake update

install_home_manager:
	nix build --no-link .#homeConfigurations.me.activationPackage
	"$$(nix path-info .#homeConfigurations.me.activationPackage)"/activate
