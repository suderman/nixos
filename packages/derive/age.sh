# Exit if standard input is missing
[[ -z "$input" ]] && exit 0

# Use derive ssh (this package) to generate ssh key from input
ssh="$(echo "$input" | $0 ssh)"
[[ -z "$ssh" ]] && exit 0

# Use https://github.com/Mic92/ssh-to-age to generate age from ssh key
age="$(echo "$ssh" | ssh-to-age -private-key)"
[[ -z "$age" ]] && exit 0

# Use derive public (this package) to generate formatted identity and output
echo "# imported from: $(echo "$ssh" | $0 public)"
echo "# public key: $(echo "$age" | $0 public)"
echo "$age"
