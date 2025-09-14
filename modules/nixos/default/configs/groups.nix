# GIDs 900-909 are custom shared groups in my flake
# UID/GIDs 910-999 are custom system users/groups in my flake
{config, ...}: {
  # Create secrets group
  ids.gids.secrets = 900;
  users.groups.secrets.gid = config.ids.gids.secrets;

  # Create media group
  ids.gids.media = 901;
  users.groups.media.gid = config.ids.gids.media;

  # Create photos group
  ids.gids.photos = 902;
  users.groups.photos.gid = config.ids.gids.photos;
}
