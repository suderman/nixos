# Home network

- `10.1.0.1` Unifi Router - USG 3P
- `10.1.0.2` Unifi Switch - US 8 150W
- `10.1.0.3` Unifi Access Point - nanoHD
- `10.1.0.4` 2013 Intel NUC - NixOS 23.11 ([hub](https://github.com/suderman/nixos/tree/main/configurations/hub))
- `10.1.0.5` 2021 Intel NUC - NixOS 23.11 ([lux](https://github.com/suderman/nixos/tree/main/configurations/lux))
- `10.1.0.7` 2009 Mac Pro - NixOS 23.11 ([pod](https://github.com/suderman/nixos/tree/main/configurations/pod))
- `10.1.0.8` Universal Devices - ISY-944i

## Router Configuration

<details>
<summary><b>Unifi Devices</b></summary>

|               | https://10.1.0.4:8443/manage/default/devices |
| ------------- | ----------------------------------------------------- |
| Unifi Devices |  _(see below)_                                        |
  
| Name   | Device    | Static IP | Subnet Mask   | Gateway  | Preferred DNS |
| ------ | --------- | --------- | ------------- | -------- | ------------- |
| logos  | USG 3P    | 10.1.0.1  | -             | -        | -             |
| ethos  | US 8 150W | 10.1.0.2  | 255.255.255.0 | 10.1.0.1 | 8.8.8.8       |
| pathos | nanoHD    | 10.1.0.3  | 255.255.255.0 | 10.1.0.1 | 8.8.8.8       |

</details>

<details>
<summary><b>Client Devices</b></summary>
  
|                  | https://10.1.0.4:8443/manage/default/clients                                                       |
| ---------------- | -------------------------------------------------------------------------------------------------- |
| Fixed IP Address | [networks/home/default.nix](https://github.com/suderman/nixos/tree/main/networks/home/default.nix) |

</details>

<details>
<summary><b>Settings: Networks</b></summary>
  
|                 | https://10.1.0.4:8443/manage/default/settings/networks |
| --------------- | ------------------------------------------------------ |
| Network Name    | `home`                                                 |
| Host Address    | `10.1.0.1`                                             |
| Netmask         | `/16`                                                  |
| IGMP Snooping   | `Off`                                                  |
| Multicast DNS   | `On`                                                   |
| DHCP Mode       | `DHCP Server`                                          |
| DHCP Range      | `10.1.0.1` to `10.1.255.254`                           |
| Default Gateway | `Auto`                                                 |
| DNS Server      | `10.1.0.4`                                             |
| Domain Name     | `home`                                                 |

</details>

<details>
<summary><b>Settings: Routing</b></summary>

|               | https://10.1.0.4:8443/manage/default/settings/routing |
| ------------- | ----------------------------------------------------- |
| Static Routes |  _(see below)_                                        |
  
| Name | Distance | Destination Network | Type     | Next Hop |
| ---- | -------- | ------------------- | -------- | -------- |
| tail | 5        | 100.64.0.0/10       | Next Hop | 10.1.0.4 |
| work | 2        | 10.2.0.0/16         | Next Hop | 10.1.0.4 |
| star | 3        | 10.3.0.0/16         | Next Hop | 10.1.0.4 |

</details>
