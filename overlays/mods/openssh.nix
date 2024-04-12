{ final, prev, ... }: 

# # Enable support for DSA keys
# # https://github.com/NixOS/nixpkgs/commit/6ee4b8c8bf815567f7d0fa131576d2b8c0a18167
# prev.openssh.override {
#   dsaKeysSupport = true;
# }

# Takes too long to override openssh. EVERYTHING has to be compiled as a result.
prev.openssh
