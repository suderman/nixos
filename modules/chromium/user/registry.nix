{ lib, ... }: let 

  registry = {
    alby = "iokeahhehimjnekafflcihljlcjccdbe";
    auto-tab-discard-suspend = "jhnleheckmknfcgijgkadoemagpecfol";
    built-with = "dapjbgnjinbpoindlpdmhochffioedbn";
    chromium-web-store = "https://github.com/NeverDecaf/chromium-web-store/releases/download/v1.5.4.3/Chromium.Web.Store.crx";
    dark-reader = "eimadpbcbfnmbkopoojfekhnkhdbieeh";
    fake-data = "gchcfdihakkhjgfmokemfeembfokkajj";
    floccus-bookmarks-sync = "fnaicdffflnofjppbagibeoednhnbjhg";
    global-speed = "jpbjcnkcffbooppibceonlgknpkniiff";
    i-still-dont-care-about-cookies = "edibdbjcniadpccecjdfdjjppcpchdlm";
    one-password = "aeblfdkhhhdcdjpifhhbdiojplfjncoa";
    return-youtube-dislike = "gebbhagfogifgggkldgodflihgfeippi";
    sponsorblock = "mnjggcdmjocbbbhaepdhchncahnbgone";
    stylus = "clngdbkpkpeebahjckkjfobafhncgmne";
    tampermonkey = "dhdgffkkebhmkfjojejmpbldmpobfkfo";
    ublock-origin = "cjpalhdlnbpafiamejdnhcphjbkeiagm";
    ublock-origin-lite = "ddkjiahejlhfcafbddmgiahcphecmpfh";
  };

in {
  options.programs.chromium.registry = lib.mkOption {
    type = lib.types.anything; 
    readOnly = true; 
    default = registry;
  };
}
