{
  osConfig,
  lib,
  ...
}: {
  options.networking = lib.mkOption {
    type = lib.types.anything;
    default = {
      inherit
        (osConfig.networking)
        address
        domain
        hostName
        ;
    };
  };
}
