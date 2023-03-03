local dir=/etc/nixos/overlays/pkgs/nixos-cli
local bashly="docker run --rm -it --user $(id -u):$(id -g) --volume $dir:/app dannyben/bashly"
task -d "cd $dir && bashly generate"
(cd $dir && $bashly generate)
