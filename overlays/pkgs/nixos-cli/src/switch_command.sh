task -d 'nixos-rebuild switch --flake /etc/nixos#'$(hostname)
sudo nixos-rebuild switch --flake /etc/nixos#$(hostname)
