# home row mods (to be merged with keyd main)
# lettermod(<layer>, <key>, <idle timeout>, <hold timeout>)*
#
# [⌘a][⌥s][⌃d][⇧f] _ _ [⇧f][⌃d][⌥s][⌘;]
{
  # [⌘] super is [a][;]
  a = "lettermod(meta, a, 200, 220)";
  semicolon = "lettermod(meta, ;, 200, 220)";

  # [⌥] alt is [s][l]
  s = "lettermod(alt, s, 200, 220)";
  l = "lettermod(alt, l, 200, 220)";

  # [⌃] ctrl is [d][k]
  d = "lettermod(control, d, 200, 220)";
  k = "lettermod(control, k, 200, 220)";

  # [⇧] shift is [f][j]
  f = "lettermod(shift, f, 200, 220)";
  j = "lettermod(shift, j, 200, 220)";

  # [✥] nav is [space]
  space = "lettermod(nav, space, 200, 220)";

  # [♫] media is [m]
  m = "lettermod(media, m, 200, 220)";

  # [Fn] function is [r][u]
  u = "lettermod(fn, u, 200, 220)";
  r = "lettermod(fn, r, 200, 220)";
}
