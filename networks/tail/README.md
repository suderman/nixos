# Tailscale network

- `100.115.119.94` 2013 Intel NUC - NixOS 24.05 ([hub](https://github.com/suderman/nixos/tree/main/configurations/hub))
- `100.88.52.75` 2009 Mac Pro - NixOS 24.05 ([eve](https://github.com/suderman/nixos/tree/main/configurations/eve))
- `100.69.160.76` Linode Nanode 1 GB - NixOS 24.05 ([sol](https://github.com/suderman/nixos/tree/main/configurations/sol))
- `100.118.135.148` 2018 Thinkpad T480s - NixOS 24.05 ([wit](https://github.com/suderman/nixos/tree/main/configurations/wit))
- `100.122.127.88` 2009 Mac Pro - NixOS Unstable ([pod](https://github.com/suderman/nixos/tree/main/configurations/pod))
- `100.86.99.137` 2021 Framework Laptop - NixOS Unstable ([cog](https://github.com/suderman/nixos/tree/main/configurations/cog))
- `100.110.44.15` 2024 FormD T1 Desktop - NixOS Unstable ([kit](https://github.com/suderman/nixos/tree/main/configurations/kit))

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
| Global nameservers | `100.88.52.75` _(eve)_                |
| Global nameservers | `100.69.160.76` _(sol)_               |

</details>
