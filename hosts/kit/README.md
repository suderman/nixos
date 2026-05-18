# kit 🎮

<table>
  <tr>
    <td>
      <img alt="kit" width="200" src="https://suderman.github.io/assets/nixos/hosts/kit.png" />
    </td>
    <td>
      <ul>
          <li>FormD T1 v2.1 ITX case <a target="_blank" href="https://formdt1.com/">↗️</a></li>
          <li>ASRock Z790 PG-ITX/TB4 motherboard <a target="_blank" href="https://pg.asrock.com/mb/Intel/Z790%20PG-ITXTB4/index.asp">↗️</a></li>
          <li>Corsair SF750 PSU <a target="_blank" href="https://www.corsair.com/us/en/p/psu/CP-9020186-NA/sf-series-sf750-750-watt-80-plus-platinum-certified-high-performance-sfx-psu-cp-9020186-na">↗️</a></li>
          <li>Intel Core i7-14700K CPU <a target="_blank" href="https://www.amazon.ca/dp/B0CGJ41C9W">↗️</a></li>
          <li>MasterLiquid 240 Atmos liquid cooler <a target="_blank" href="https://www.coolermaster.com/en-global/products/masterliquid-240-atmos/">↗️</a></li>
          <li>Asus ProArt RTX 4070 Ti SUPER 16GB GPU <a target="_blank" href="https://www.asus.com/ca-en/motherboards-components/graphics-cards/proart/proart-rtx4070tis-o16g/">↗️</a></li>
          <li>32GB G.Skill Ripjaws S5 DDR5-6400 CL32 memory (x2) <a target="_blank" href="https://www.amazon.ca/dp/B0C1TL9CT9">↗️</a></li>
          <li>2TB WD_Black SN850X NVMe storage (x2) <a target="_blank" href="https://www.amazon.ca/dp/B0B7CMZ3QH">↗️</a></li>
          <li>2TB Crucial T500 NVMe storage <a target="_blank" href="https://www.amazon.ca/dp/B0CK2TC9XQ">↗️</a></li>
          <li>Acer XB273K V3bmiiprx 27" UHD 4K display <a target="_blank" href="https://www.amazon.ca/gp/product/B0CQPHJ32Y/">↗️</a></li>
          <li>Happy Hacking Keyboard Professional 2, black <a target="_blank" href="https://hhkeyboard.us/hhkb/pro-classic/sku/cg01000-296401">↗️</a></li>
          <li>Keychron M6 1K Wireless Mouse <a target="_blank" href="https://www.keychron.com/products/keychron-m6-wireless-mouse">↗️</a></li>
      </ul>
    </td>
  </tr>
</table>

Custom build sitting on my home office desk. Great for coding, video editing, AI experiements and gaming.
Powered by [Hyprland](https://hypr.land/)!

Thankfully I purchased & assembled this rig before storage and memory prices went insane.

## Matrix notes

- Well-known: `curl -i https://matrix.kit/.well-known/matrix/client`
- Confirm JSON includes `"io.element.e2ee": { "force_disable": true }`
- Confirm `Access-Control-Allow-Origin: *`
- Confirm Synapse eval/config has `encryption_enabled_by_default_for_room_type = "off"`
- Create a fresh room or DM and verify there is no `m.room.encryption`; abandon/recreate any existing encrypted rooms or DMs
- Android/GrapheneOS Element and Element X may not fully honor the Element well-known override; if they still force encrypted DMs, use unencrypted rooms or a client/admin/bot flow that creates non-E2EE rooms
