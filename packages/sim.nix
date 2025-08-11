{
  pkgs,
  perSystem,
  ...
}:
perSystem.self.mkScript {
  name = "sim";
  path = [
    perSystem.self.default
    perSystem.self.derive
    pkgs.age
    pkgs.gum
    pkgs.passh
    pkgs.qemu
  ];

  text = let
    disks = map toString [1 2 3 4];

    qemu-system = toString (
      [
        "qemu-system-x86_64"
        "-enable-kvm" # kernel-based virtual machine
        "-m 6144" # 6GB of RAM
        "-cpu host" # use host CPU model
        "-smp 4" # 4 CPU cores
        # "-display sdl,gl=on" # Simple DirectMedia Layer, OpenGL acceleration
        "-device virtio-vga-gl"
        "-display gtk,gl=on"
        # "-device AC97"
        # "-device virtio-gpu-pci" # fake GPU
        # "-device virtio-keyboard-pci " # fake keyboard
        # "-device virtio-mouse-pci" # fake mouse
        # "-device virtio-net-pci,netdev=net0" # fake network interface
        "-device ich9-intel-hda,id=snd0 -device hda-output" # fake speaker
        "-device virtio-tablet-pci"
        # "-device qemu-xhci -device usb-tablet"
        "-nic user,hostfwd=tcp::2222-:22,hostfwd=tcp::12345-:12345,hostfwd=tcp::4443-:443" # forward ports
      ]
      ++ (map (n:
        toString [
          "-device virtio-blk-pci,drive=disk${n},serial=${n}"
          "-drive file=hosts/sim/disk${n}.img,format=qcow2,if=none,id=disk${n}"
        ])
      disks)
    );

    qemu-img = builtins.concatStringsSep "\n" (map (n:
      toString [
        "[[ -e hosts/sim/disk${n}.img ]] ||"
        "qemu-img create -f qcow2 hosts/sim/disk${n}.img 100G"
      ])
    disks);
  in
    # bash
    ''
      # Pretty output
      gum_warn() { gum style --foreground=196 "✖ Error: $*" && exit 1; }
      gum_info() { gum style --foreground=29 "➜ $*"; }
      gum_show() { gum style --foreground=177 "    $*"; }

      # If PRJ_ROOT is set, change to that directory
      [[ -n "$PRJ_ROOT" ]] && cd "$PRJ_ROOT"

      # Ensure key exists and identity unlocked
      [[ ! -f hex.age ]] && gum_warn "./hex.age missing"
      [[ ! -f /tmp/id_age ]] && gum_warn "Age identity locked"

      # Derive ssh private key
      age -d -i /tmp/id_age <hex.age |
        derive hex sim |
        derive ssh > hosts/sim/ssh_host_ed25519_key &&
        chmod 600 hosts/sim/ssh_host_ed25519_key

      # Set path to ssh private key in env variable
      export NIX_SSHOPTS="-p 2222 -i hosts/sim/ssh_host_ed25519_key"

      # Ensure disk images exist
      ${qemu-img}

      # Dispatch
      case "''${1-}" in

        up | u)
          if [[ ''${2-} == "iso" ]]; then
            ${qemu-system} -boot d -cdrom $(nixos iso path)
          else
            ${qemu-system}
          fi
          ;;

        rebuild | r)
          if [[ ''${2-} == "boot" ]]; then
            nixos-rebuild --target-host root@localhost --flake .#sim boot
          else
            nixos-rebuild --target-host root@localhost --flake .#sim switch
          fi
          ;;

        ssh | s)
          if [[ ''${2-} == "iso" ]]; then
            passh -p x ssh $NIX_SSHOPTS root@localhost
          else
            ssh $NIX_SSHOPTS root@localhost
          fi
          ;;

        help | *)
          echo "Usage: sim COMMAND"
          echo
          echo "  up [iso]"
          echo "  rebuild [boot]"
          echo "  ssh [iso]"
          echo "  help"
          ;;
      esac
    '';
}
