# lux

Intel NUC Panther Canyon PAHi7 With 11th Gen Core Processors i7 1165G7 RNUC11PAHi70001 Mini PC Barebone System

- Intel Core i7-1165G7
- Intel Iris Xe Graphics
- Memory Types DDR4-3200 1.2V SO-DIMM
- Max Memory Size (dependent on memory type) 64GB
- Thunderbolt Ports

## Installation video

I recorded my initial installation of this server to help out forgetful future-me:

<https://www.youtube.com/watch?v=Uoii8733sIo>

## Setup

```bash
# Authenticate Tailscale (maybe skip accept-routes as it messed with local routing?)
# https://github.com/tailscale/tailscale/issues/1227
sudo tailscale up --accept-routes 
```

