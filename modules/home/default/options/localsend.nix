{
  osConfig,
  lib,
  ...
}: {
  config = lib.mkIf osConfig.programs.localsend.enable {
    persist.storage.directories = [".local/share/org.localsend.localsend_app"];
  };
}
