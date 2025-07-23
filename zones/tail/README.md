# Tailscale network

- `100.86.99.137` 2021 Framework Laptop - NixOS 25.05
  ([cog](https://github.com/suderman/nixos/tree/main/configurations/cog))
- `100.111.105.128` 2009 Mac Pro - NixOS 25.05
  ([eve](https://github.com/suderman/nixos/tree/main/configurations/eve))
- `100.122.127.88` 2009 Mac Pro - NixOS 25.05
  ([fit](https://github.com/suderman/nixos/tree/main/configurations/fit))
- `100.115.119.94` 2013 Intel NUC - NixOS 25.05
  ([hub](https://github.com/suderman/nixos/tree/main/configurations/hub))
- `100.110.44.15` 2024 FormD T1 Desktop - NixOS 25.05
  ([kit](https://github.com/suderman/nixos/tree/main/configurations/kit))
- `100.69.160.76` Linode Nanode 1 GB - NixOS 24.11
  ([sol](https://github.com/suderman/nixos/tree/main/configurations/sol))
- `100.118.135.148` 2018 Thinkpad T480s - NixOS
  25.05([wit](https://github.com/suderman/nixos/tree/main/configurations/wit))

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
| Global nameservers | `100.115.119.94` _(hub)_              |
| Global nameservers | ~~`100.111.105.128` _(eve)_~~         |
| Global nameservers | ~~`100.69.160.76` _(sol)_~~           |

</details>
