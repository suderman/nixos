{ pkgs, perSystem, ... }: perSystem.self.mkScript {

  path = [ perSystem.self.iso ];
  name = "sim";

  text = let
    disks = [ "1" "2" "3" "4" ];

    qemu-system = toString ([ "qemu-system-x86_64"
      "-enable-kvm" # kernel-based virtual machine
      "-m 6144" # 6GB of RAM
      "-cpu host" # use host CPU model
      "-smp 4" # 4 CPU cores
      "-display sdl,gl=on" # Simple DirectMedia Layer, OpenGL acceleration
      "-device virtio-gpu-pci" # fake GPU
      "-device virtio-keyboard-pci " # fake keyboard
      "-device virtio-mouse-pci" # fake mouse
      # "-device virtio-net-pci,netdev=net0" # fake network interface
      "-device ich9-intel-hda,id=snd0 -device hda-output" # fake speaker
      "-nic user,hostfwd=tcp::2222-:22,hostfwd=tcp::12345-:12345" # forward ports
    ] ++ (map (n: toString [ 
      "-device virtio-blk-pci,drive=disk${n},serial=${n}"
      "-drive file=hosts/sim/disk${n}.img,format=qcow2,if=none,id=disk${n}"
    ]) disks));
      
    qemu-img = builtins.concatStringsSep "\n" (map (n: ''
      [[ -e hosts/sim/disk${n}.img ]] ||
      qemu-img create -f qcow2 hosts/sim/disk${n}.img 20G
    '') disks);

  in ''
    [[ -z "''${PRJ_ROOT-}" ]] || cd $PRJ_ROOT
    case "''${1-}" in

      disks | d)
        ${qemu-img}
        ;;

      iso | i)
        $0 disks
        ${qemu-system} -boot d -cdrom $(iso path)
        ;;

      up | u)
        $0 disks
        ${qemu-system}
        ;;

      help | *)
        echo "Usage: sim COMMAND"
        echo
        echo "  disks"
        echo "  iso"
        echo "  up"
        echo "  help"
        ;;

    esac
    echo
  '';

}
