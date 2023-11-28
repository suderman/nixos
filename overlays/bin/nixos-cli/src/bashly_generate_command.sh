local dir=/etc/nixos/overlays/bin/nixos-cli
local bashly="docker run --rm -it --user $(id -u):$(id -g) --volume $dir:/app dannyben/bashly"
show "cd $dir && bashly generate"
(cd $dir && $bashly generate)
