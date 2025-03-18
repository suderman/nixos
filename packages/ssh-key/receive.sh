# Ensure public key exists
has ./ssh_host_ed25519_key.pub \
  || error "$(pwd)/ssh_host_ed25519_key.pub missing"

# Open port for netcat (if running as root)
[[ "$(id -u)" == "0" ]] \
  && iptables -A INPUT -p tcp --dport 12345 -j ACCEPT

# Make and switch to tmp directory to receive key
dir=$(pwd) tmp=$(pwd)/tmp
mkdir -p $tmp && cd $tmp

# Copy existing public key to tmp dir
cp -f $dir/ssh_host_ed25519_key.pub $tmp/ssh_host_ed25519_key.pub

# Demonstrate command to enter on client
host="$(cat ssh_host_ed25519_key.pub | cut -d' ' -f3 | cut -d'@' -f1)"
info "ssh-key send ${host:-$(hostname)} $(ipaddr lan)"

# Loop until private key validated
while true; do

  # Wait for private key to be received over netcat
  nc -l -N 12345 > $tmp/ssh_host_ed25519_key

  if ssh-key verify; then
    mv $tmp/ssh_host_ed25519_key $dir/ssh_host_ed25519_key
    chmod 600 $dir/ssh_host_ed25519_key
    cd $dir && rm -rf $tmp
    info "Success: VALID ed25519 key received"
    break
  else
    warn "Error: INVALID ed25519 key received"
  fi

  sleep 1

done
