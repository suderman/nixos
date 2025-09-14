# WeChip W3 Air Mouse
# https://www.amazon.ca/gp/product/B081CTNB5W/
{
  ids = ["25a7:0124"];
  settings =
    {
      main = {
        # Assign tab to capslock key, and use as custom modifier
        capslock = "overloadt2(nav, tab, 200)";

        # Assign super to leftalt key
        leftalt = "layer(super)";

        # Assign alt to compose key
        compose = "layer(alt)";

        # Homepage/back button
        # Short press is super (default is back), long press is oneshot super (default is homepage)
        back = "layer(super)";
        homepage = "oneshot(super)";
      };
    }
    // import ./all.nix;
}
