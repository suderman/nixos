# Work network

- `10.2.0.1` RT-AC66U - Asuswrt-Merlin 380.70
- `10.2.0.2` 2009 Mac Pro - NixOS 23.11 ([eve](https://github.com/suderman/nixos/tree/main/configurations/eve))
- `10.2.0.3` 2011 Mac Mini - macOS 10.13.6

## Router Configuration

<details>
<summary><b>LAN IP</b></summary>
  
|             | https://10.2.0.1:8443/Advanced_LAN_Content.asp |
|-------------|------------------------------------------------|
| Device Name | `rt`                                           |
| IP Address  | `10.2.0.1`                                     |
| Subnet Mask | `255.255.255.0`                                |

</details>

<details>
<summary><b>DHCP Server</b></summary>

|                                                         |    https://10.2.0.1:8443/Advanced_DHCP_Content.asp                                                 |
|---------------------------------------------------------|----------------------------------------------------------------------------------------------------|
| Enable the DHCP Server                                  | `Yes`                                                                                              |
| RT-AC66U's Domain Name                                  | `work`                                                                                             |
| IP Pool Starting Address                                | `10.2.0.2`                                                                                         |
| IP Pool Ending Address                                  | `10.2.0.254`                                                                                       |
| Default Gateway                                         | `10.2.0.1`                                                                                         |
| DNS Server 1                                            | `10.2.0.2`                                                                                         |
| Advertise router's IP in addition to user-specified DNS | `No`                                                                                               |
| Forward local domain queries to upstream DNS            | `No`                                                                                               |
| Enable Manual Assignment                                | `Yes`                                                                                              |
| Manually Assigned IP around the DHCP list               | [networks/work/default.nix](https://github.com/suderman/nixos/tree/main/networks/work/default.nix) |

</details>

<details>
<summary><b>Route</b></summary>

|                       | https://10.2.0.1:8443/Advanced_GWStaticRoute_Content.asp | 
|-----------------------|----------------------------------------------------------|
| Enable static routes  | `Yes`                                                    |

| Network/Host IP | Netmask       | Gateway  | Metric | Interface |
|-----------------|---------------|----------|--------|-----------|
| 100.64.0.0      | 255.192.0.0   | 10.2.0.2 |        | LAN       |
| 10.1.0.0        | 255.255.255.0 | 10.2.0.2 |        | LAN       |
| 10.3.0.0        | 255.255.255.0 | 10.2.0.2 |        | LAN       |

</details>

<details>
<summary><b>System</b></summary>

|                                                             | https://10.2.0.1:8443/Advanced_System_Content.asp                                                |
|-------------------------------------------------------------|--------------------------------------------------------------------------------------------------|
| Router Login Name                                           | `suderman`                                                                                       |
| Enable SSH                                                  | `LAN only`                                                                                       |
| SSH server port                                             | `22`                                                                                             |
| SSH Authentication key                                      | [secrets/keys/default.nix](https://github.com/suderman/nixos/blob/main/secrets/keys/default.nix) |
| Authentication Method                                       | `HTTPS`                                                                                          |
| HTTPS Lan port                                              | `8443`                                                                                           |

</details>

