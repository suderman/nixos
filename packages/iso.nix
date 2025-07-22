{
  pkgs,
  perSystem,
  ...
}:
perSystem.self.mkScript {
  path = [
    pkgs.gawk
    pkgs.gum
    pkgs.util-linux
  ];

  name = "iso";

  text =
    # bash
    ''
      [[ -z "''${PRJ_ROOT-}" ]] || cd $PRJ_ROOT
      case "''${1-}" in

        path | p)
          shopt -s nullglob
          files=(result/iso/nixos*.iso)
          shopt -u nullglob
          if [[ ''${#files[@]} -gt 0 ]]; then
            readlink -f "''${files[0]}"
          else
            echo ""
          fi
          ;;

        build | b)
          nix build .#nixosConfigurations.iso.config.system.build.isoImage
          ;;

        flash | f)
          echo "Detecting USB drives..."
          usb_devices=$(lsblk -dpno NAME,SIZE,MODEL,TRAN | grep -i usb || true)

          if [[ -z "$usb_devices" ]]; then
            echo "No USB drives detected."
            exit 1
          fi

          # Select USB device
          usb_selection=$(echo "$usb_devices" | gum choose --header "Select USB drive to flash the ISO to")
          device=$(echo "$usb_selection" | awk '{print $1}')

          iso_path="$($0 path)"
          if [[ -z "$iso_path" ]]; then
            $0 build
            iso_path="$($0 path)"
          fi

          # Final confirmation
          echo "You are about to write:"
          echo "  ISO file : $iso_path"
          echo "  To device: $device"
          echo
          gum confirm "Are you sure? This will erase all data on $device." || exit 1

          # Run dd
          echo "Flashing ISO to $device..."
          sudo dd if="$iso_path" of="$device" bs=4M status=progress oflag=sync

          echo "Done. ISO flashed to $device."
          ;;

        help | *)
          echo "Usage: iso ARG"
          echo
          echo "  path"
          echo "  build"
          echo "  flash"
          echo "  help"
          ;;

      esac
    '';
}
