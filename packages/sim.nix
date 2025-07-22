{ pkgs, perSystem, flake, ... }: perSystem.self.mkScript {

  path = [ 
    perSystem.self.derive 
    perSystem.self.iso 
    pkgs.passh
    pkgs.qemu
    pkgs.age
  ];

  name = "sim";

  text = let
    disks = map toString [ 1 2 3 4 ];

    qemu-system = toString ([ "qemu-system-x86_64"
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
    ] ++ (map (n: toString [ 
      "-device virtio-blk-pci,drive=disk${n},serial=${n}"
      "-drive file=hosts/sim/disk${n}.img,format=qcow2,if=none,id=disk${n}"
    ]) disks));

    # qemu-system-x86_64 -enable-kvm -m 8G -smp 4 -device virtio-vga-gl -display gtk,gl=on -device AC97 -nic user,hostfwd=tcp::2222-:22,hostfwd=tcp::12345-:12345,hostfwd=tcp::4443-:443 -device virtio-blk-pci,drive=disk1,serial=1 -drive file=hosts/sim/disk1.img,format=qcow2,if=none,id=disk1 -device virtio-blk-pci,drive=disk2,serial=2 -drive file=hosts/sim/disk2.img,format=qcow2,if=none,id=disk2 -device virtio-blk-pci,drive=disk3,serial=3 -drive file=hosts/sim/disk3.img,format=qcow2,if=none,id=disk3 -device virtio-blk-pci,drive=disk4,serial=4 -drive file=hosts/sim/disk4.img,format=qcow2,if=none,id=disk4

    qemu-img = builtins.concatStringsSep "\n" (map (n: toString [
      "[[ -e hosts/sim/disk${n}.img ]] ||"
      "qemu-img create -f qcow2 hosts/sim/disk${n}.img 100G"
    ]) disks);

    derive-ssh = toString [
      "cat hex.age |"
      "age -d -i /tmp/id_age |"
      "derive hex sim |"
      "derive ssh > hosts/sim/ssh_host_ed25519_key &&"
      "chmod 600 hosts/sim/ssh_host_ed25519_key"
    ];

  in 
    # bash
    ''
    source ${flake.lib.bash}
    [[ -z "''${PRJ_ROOT-}" ]] || cd $PRJ_ROOT
    [[ ! -f hex.age ]] && error "./hex.age missing"
    [[ ! -f /tmp/id_age ]] && error "Age identity locked"

    export NIX_SSHOPTS="-p 2222 -i hosts/sim/ssh_host_ed25519_key"
    ${derive-ssh}
    ${qemu-img}

    case "''${1-}" in

      up | u)
        if [[ ''${2-} == "iso" ]]; then
          ${qemu-system} -boot d -cdrom $(iso path)
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
