{ lib, this, docker }: this.lib.mkShellScript {
  name = "docker-nvidia-smi";
  inputs = [ docker ];
  text = ''
    docker run --rm --gpus all nvidia/cuda:12.5.0-base-ubuntu22.04 nvidia-smi
  '';
}
