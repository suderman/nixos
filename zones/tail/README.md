# Tailscale network

`default.nix` is the source of truth for these addresses.

- `100.99.91.44` 2021 Framework Laptop - NixOS
  ([cog](https://github.com/suderman/nixos/tree/main/hosts/cog))
- `100.69.75.29` 2009 Mac Pro - NixOS
  ([eve](https://github.com/suderman/nixos/tree/main/hosts/eve))
- `100.122.127.88` 2009 Mac Pro - NixOS
  ([pow](https://github.com/suderman/nixos/tree/main/hosts/pow))
- `100.97.117.105` 2013 Intel NUC - NixOS
  ([hub](https://github.com/suderman/nixos/tree/main/hosts/hub))
- `100.67.76.42` 2024 FormD T1 Desktop - NixOS
  ([kit](https://github.com/suderman/nixos/tree/main/hosts/kit))
- `100.76.94.96` 2018 Thinkpad T480s - NixOS
  ([wit](https://github.com/suderman/nixos/tree/main/hosts/wit))
- `100.93.245.77` 2020 MacBook Air - macOS
- `100.73.89.6` Pixel 10 Pro - GrapheneOS (`gem`)

## VPN Configuration

<details>
<summary><b>Subnet routes</b></summary>

|     | https://login.tailscale.com/admin/machines |
| --- | ------------------------------------------ |
| hub | `10.1.0.0/16`                              |
| eve | `10.2.0.0/16`                              |

</details>

<details>
<summary><b>DNS</b></summary>

|                    | https://login.tailscale.com/admin/dns |
| ------------------ | ------------------------------------- |
| Override local DNS | `Yes`                                 |
| Global nameservers | `100.97.117.105` _(hub)_              |
| Global nameservers | `100.69.75.29` _(eve)_                |

</details>
