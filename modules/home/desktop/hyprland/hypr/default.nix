{
  flake,
  ...
}: {
  imports = flake.lib.ls ./.;

  # Keep a local Lua hook for quick experiments without regenerating Nix.
  persist.storage.directories = [".config/hypr/local"];
  tmpfiles.files = [".config/hypr/local/init.lua"];
}
