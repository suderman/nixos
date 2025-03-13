# Exit if standard input is missing
input="$(cat)"
[[ -z "$input" ]] && exit 0

# Use to-ssh (this flake) to generate ssh key from input
# ssh="$(echo "$input" | to-ssh)"
ssh="$(echo "$input" | bash -c "$0 ssh")"
[[ -z "$ssh" ]] && exit 0

# Use https://github.com/Mic92/ssh-to-age to generate age from ssh key
age="$(echo "$ssh" | ssh-to-age -private-key)"
[[ -z "$age" ]] && exit 0

# Use to-public (this flake) to generate formatted identity and output
# echo "# imported from: $(echo "$ssh" | to-public)"
# echo "# public key: $(echo "$age" | to-public)"
# echo "$age"
echo "# imported from: $(echo "$ssh" | bash -c "$0 public")"
echo "# public key: $(echo "$age" | bash -c "$0 public")"
echo "$age"
