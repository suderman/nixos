FLAKE := $(shell hostname)

all: switch

# if sudo, switch_host; else, switch_home
switch:
	@if [ "$(shell id -u)" = 0 ]; then make --no-print-directory switch_host; else make --no-print-directory switch_home; fi

# rebuild the whole system with nixos-rebuild
switch_host:
	nixos-rebuild switch --flake '$(PWD)#$(FLAKE)'

# rebuild the home directory with home-manager
switch_home:
	home-manager switch --extra-experimental-features 'nix-command flakes' --flake '$(PWD)#$(FLAKE)'

update:
	nix flake update

install_home_manager:
	nix --extra-experimental-features 'nix-command flakes' build --no-link .#homeConfigurations.$(FLAKE).activationPackage
	"$$(nix --extra-experimental-features 'nix-command flakes' path-info .#homeConfigurations.$(FLAKE).activationPackage)"/activate
