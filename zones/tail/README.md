# Tailscale network

- `100.99.91.44` 2021 Framework Laptop - NixOS
  ([cog](https://github.com/suderman/nixos/tree/main/hosts/cog))
- `100.69.75.29` 2009 Mac Pro - NixOS
  ([eve](https://github.com/suderman/nixos/tree/main/hosts/eve))
- `100.122.127.88` 2009 Mac Pro - NixOS
  ([fit](https://github.com/suderman/nixos/tree/main/hosts/fit))
- `100.115.119.94` 2013 Intel NUC - NixOS
  ([hub](https://github.com/suderman/nixos/tree/main/hosts/hub))
- `100.67.76.42` 2024 FormD T1 Desktop - NixOS
  ([kit](https://github.com/suderman/nixos/tree/main/hosts/kit))
- `100.118.135.148` 2018 Thinkpad T480s - NixOS
  25.05([wit](https://github.com/suderman/nixos/tree/main/hosts/wit))
- `100.93.245.77` 2020 MacBook Air - macOS

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
