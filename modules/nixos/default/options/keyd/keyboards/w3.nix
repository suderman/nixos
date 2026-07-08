# WeChip W3 Air Mouse
# https://www.amazon.ca/gp/product/B081CTNB5W/
{
  ids = ["25a7:0124"];
  settings = {
    main = {
      # Assign tab to capslock key, and use as custom modifier
      capslock = "overloadt2(fn, tab, 200)";

      # Assign super to leftalt key
      leftalt = "overload(super, f14)";

      # Assign alt to compose key
      compose = "overload(alt, f13)";

      # Homepage/back button
      # Short press is super (default is back), long press is oneshot super (default is homepage)
      back = "overload(super, f14)";
      homepage = "overload(super, f14)";
    };
  };
}
