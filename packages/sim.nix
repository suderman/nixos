{ pkgs, perSystem, ... }: perSystem.self.mkScript {

  path = [ 
    perSystem.self.iso 
    pkgs.passh
    pkgs.qemu
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
      
    qemu-img = builtins.concatStringsSep "\n" (map (n: toString [
      "[[ -e hosts/sim/disk${n}.img ]] ||"
      "qemu-img create -f qcow2 hosts/sim/disk${n}.img 20G"
    ]) disks);

  in ''
    [[ -z "''${PRJ_ROOT-}" ]] || cd $PRJ_ROOT
    case "''${1-}" in
      up | u)
        ${qemu-img}
        if [[ ''${2-} == "iso" ]]; then
          ${qemu-system} -boot d -cdrom $(iso path)
        else
          ${qemu-system}
        fi
        ;;
      ssh | s)
        if [[ ''${2-} == "iso" ]]; then
          passh -p x ssh root@localhost -p2222
        else
          ssh ''${2-$USER}@localhost -p2222
        fi
        ;;
      help | *)
        echo "Usage: sim COMMAND"
        echo
        echo "  up [iso]"
        echo "  ssh [iso]"
        echo "  help"
        ;;
    esac
  '';

}
