# pow 👟

<table>
  <tr>
    <td>
      <img alt="pow" width="200" src="https://suderman.github.io/assets/nixos/hosts/pow.png" />
    </td>
    <td>
      <ul>
        <li>2009 Mac Pro 4,1 (flashed to 5,1) <a target="_blank" href="https://support.apple.com/en-ca/112590">↗️</a></li>
        <li>Intel Xeon X5570 @ 3.06GHz x2</li>
        <li>AMD Sapphire NITRO+ RX 580 8GB GPU <a target="_blank" href="https://www.amazon.ca/dp/B071QX74F9">↗️</a></li>
        <li>8GB DDR3-1066 ECC Registered DIMM memory (x4)</li>
        <li>2GB DDR3-1066 ECC Registered DIMM memory (x4)</li>
        <li>1TB Crucial MX500 3D NAND 2.5" SSD storage <a target="_blank" href="https://www.amazon.ca/dp/B078211KBB?th=1">↗️</a></li>
        <li>12TB Seagate IronWolf 3.5" HDD storage (x2) <a target="_blank" href="https://www.amazon.ca/dp/B084ZTSMWF?th=1">↗️</a></li>
      </ul>
    </td>
  </tr>
</table>

Home gym computer to run [Zwift](https://github.com/netbrain/zwift/), and play
music & movies during workouts. Powered by [Hyprland](https://hypr.land/)!

Also, 4 drive bays are handy for home backups so I have two 12TB HDDs in a pool.

## Screenshots

![screenshot1](https://suderman.github.io/assets/nixos/hosts/pow1.png)
![screenshot2](https://suderman.github.io/assets/nixos/hosts/pow2.png)

## Install Notes

This ancient beast has no concept of selecting a startup disk at boot. The RX
580 won't display anything during boot and even with a supported Mac GPU, the
startup manager won't display my NixOS volumes as a selectable choice. To force
it to boot from a USB drive, there must be no bootable internal drives
installed. This means any destination SSD must be pre-wiped (or at least its
boot partition sabotaged) when attempting to boot from a USB
[ISO](https://github.com/suderman/nixos/tree/main/hosts/iso).
