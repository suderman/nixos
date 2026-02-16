# Assume "docker" available system-wide
# including in "path" doesn't seem to work with nvidia-flavour
{
  pkgs,
  perSystem,
  ...
}:
perSystem.self.mkApplication {
  name = "zwift";
  path = [pkgs.hostname];
  text =
    # bash
    ''
      # https://hub.docker.com/r/netbrain/zwift
      IMAGE="docker.io/netbrain/zwift"
      TAG="latest"

      # Check for updated container image
      docker pull $IMAGE:$TAG

      # Create user volume
      DATA_DIR="$HOME/.local/share/zwift"
      mkdir -p $DATA_DIR

      # Create credentials file for auto-login
      CREDENTIALS="$DATA_DIR/.zwift-credentials"
      if [[ ! -f $CREDENTIALS ]]; then
        echo -e "ZWIFT_USERNAME=\nZWIFT_PASSWORD=" >$CREDENTIALS
      fi

      # Get user and group ids
      ZWIFT_UID=$(id -u $USER)
      ZWIFT_GID=$(id -g $USER)

      # Check for proprietary nvidia driver and set correct device to use
      if [[ -f "/proc/driver/nvidia/version" ]]; then
        DEVICE="nvidia.com/gpu=all"
      else
        DEVICE="/dev/dri:/dev/dri"
      fi

      # Run container
      docker run --rm \
        --privileged \
        --network=bridge \
        --dns=8.8.8.8 \
        --dns=1.1.1.1 \
        --name=zwift \
        --hostname=$(hostname) \
        --env-file=$CREDENTIALS \
        --security-opt label=disable \
        --device=$DEVICE \
        -e NVIDIA_DRIVER_CAPABILITIES=all \
        -e CONTAINER_TOOL=docker \
        -e WINE_EXPERIMENTAL_WAYLAND=0 \
        -e DISPLAY=:0 \
        -e PULSE_SERVER=/run/user/$ZWIFT_UID/pulse/native \
        -e DBUS_SESSION_BUS_ADDRESS=unix:path=/run/user/$ZWIFT_UID/bus \
        -e ZWIFT_UID \
        -e ZWIFT_GID \
        -v $DATA_DIR:/home/user/.wine/drive_c/users/user/Documents/Zwift \
        -v /run/user/$ZWIFT_UID/pulse:/run/user/$ZWIFT_UID/pulse \
        -v /run/user/$ZWIFT_UID/bus:/run/user/$ZWIFT_UID/bus \
        -v /tmp/.X11-unix:/tmp/.X11-unix \
        $IMAGE:$TAG
    '';
  desktopName = "Zwift";
  icon = pkgs.writeText "zwift.svg" ''
    <?xml version="1.0" encoding="UTF-8"?>
    <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 3000 3000">
      <path fill="#ED7522" d="M2642 2433c0,257 -209,466 -467,466l-1717 0c-249,0 -451,-199 -458,-447l0 -23c4,-136 67,-228 67,-228l714 -1167 -315 0c-253,0 -459,-202 -466,-454l0 -25c7,-249 208,-449 457,-454l2543 0 -1141 1865 316 0c258,0 467,209 467,467z"/>
    </svg>
  '';
}
