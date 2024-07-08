#!/usr/bin/env bash
set -x

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
  echo -e "ZWIFT_USERNAME=\nZWIFT_PASSWORD=" > $CREDENTIALS
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
  --name=zwift-$USER \
  --hostname=$(hostname) \
  --env-file=$CREDENTIALS \
  --device=$DEVICE \
  -e NVIDIA_DRIVER_CAPABILITIES=all \
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
