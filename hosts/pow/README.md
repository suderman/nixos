<table>
  <tr>
    <td>
      <img alt="pow" width="200" src="https://github.com/user-attachments/assets/7e505c94-d9bb-4e55-977b-5f46e1170bd2" />
    </td>
  <td>
    <h1>pow</h1>
    <ul>
      <li>2009 Mac Pro 4,1 (flashed to 5,1)</li>
      <li>Two 2.93GHz Quad-Core Intel Xeon</li>
      <li>40GB DDR3-1066</li>
      <li>Crucial MX500 1TB 3D NAND SATA 2.5 SSD</li>
      <li>Seagate IronWolf 12TB NAS Internal Hard Drive HDD (x2)</li>
      <li>AMD Radeon RX 580 Series</li>
    </ul>
  </td>
  </tr>
</table>

Home gym computer to run [Zwift](https://github.com/netbrain/zwift/), and play
music & movies during workouts.

Also, 4 drive bays are handy for home backups!

## Screenshots
![screenshot1](https://github.com/user-attachments/assets/a6bc06cd-0af9-4d35-814d-003b114e40de)
![screenshot2](https://github.com/user-attachments/assets/8edbb866-f9f1-4425-a2d4-21fe14e8a159)

## Install Notes

This ancient beast has no concept of selecting a startup disk at boot. The RX 580 won't display anything during boot and even with a supported Mac GPU, the startup manager won't display my NixOS volumes as a selectable choice. To force it to boot from a USB drive, there must be no bootable interal drives installed. This means any destination SSD must be pre-wiped (or at least its boot partition sabotaged) when attempting to boot from a USB ISO.
