{ flake, config, lib, ... }: {

  imports = [
    flake.homeModules.common
  ];

  programs.chromium = {
    enable = true;
    unpackedExtensions = {
      alby = "iokeahhehimjnekafflcihljlcjccdbe";
      dark-reader = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
      fake-data = "gchcfdihakkhjgfmokemfeembfokkajj";
      global-speed = "jpbjcnkcffbooppibceonlgknpkniiff";
      i-still-dont-care-about-cookies = "edibdbjcniadpccecjdfdjjppcpchdlm";
      one-password = "aeblfdkhhhdcdjpifhhbdiojplfjncoa";
      sponsorblock = "mnjggcdmjocbbbhaepdhchncahnbgone";
      tampermonkey = "dhdgffkkebhmkfjojejmpbldmpobfkfo";
      ublock-origin = "cjpalhdlnbpafiamejdnhcphjbkeiagm";
      ublock-origin-lite = "ddkjiahejlhfcafbddmgiahcphecmpfh";
    };
  };

}
