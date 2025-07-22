{
  pkgs,
  perSystem,
  ...
}:
perSystem.self.mkScript {
  name = "docker-nvidia-smi";
  path = [pkgs.docker];
  text =
    # bash
    ''
      docker run --rm --device=nvidia.com/gpu=all nvidia/cuda:12.5.0-base-ubuntu22.04 nvidia-smi
    '';
}
