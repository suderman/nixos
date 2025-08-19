{ config, lib, ... }: {

  # Extend accounts options
  options.accounts.enable = lib.options.mkEnableOption "accounts"; 

}
