# https://github.com/netbrain/zwift/blob/master/zwift.sh
{ lib, this, docker, xorg }: let

  # https://hub.docker.com/r/netbrain/zwift
  image = "docker.io/netbrain/zwift";
  tag = "latest";

in this.lib.mkShellScript {

  name = "zwift";
  inputs = [ docker xorg.xhost ];

  text = ''
    set -x

    # Check for updated container image
    docker pull ${image}:${tag}

    # Check for proprietary nvidia driver and set correct device to use
    if [[ -f "/proc/driver/nvidia/version" ]]; then
      VGA_DEVICE_FLAG="--gpus all"
    else
      VGA_DEVICE_FLAG="--device /dev/dri:/dev/dri"
    fi

    # Create user volume
    DATA_DIR="$HOME/.local/share/zwift"
    mkdir -p $DATA_DIR

    # Create example credentials to auto-login
    echo -e "ZWIFT_USERNAME=username\nZWIFT_PASSWORD=password" \
      > $DATA_DIR/.zwift-credentials-example 

    # Start the zwift container
    CONTAINER=$(docker run -d --rm --privileged --name="zwift" \
      --env="DISPLAY" $VGA_DEVICE_FLAG \
      -v /tmp/.X11-unix:/tmp/.X11-unix \
      -v /run/user/$UID/pulse:/run/user/1000/pulse \
      -v $DATA_DIR:/home/user/Zwift \
      ${image}:${tag})

    # Allow container to connect to X
    xhost +local:$(docker inspect --format='{{ .Config.Hostname }}' $CONTAINER)
  '';

}
