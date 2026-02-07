{
  lib,
  pkgs,
  ...
}: {
  # List packages installed in system profile
  environment.systemPackages = with pkgs; [
    arp-scan # arp-fingerprint arp-scan get-iab get-oui
    curl # curl curl-config wcurl
    dig # arpaname ddns-confgen delv dig dnssec-cds dnssec-dsfromkey dnssec-importkey dnssec-keyfromlabel dnssec-keygen dnssec-ksr dnssec-revoke dnssec-settime dnssec-signzone dnssec-verify host mdig named named-checkconf named-checkzone named-compilezone named-journalprint named-rrchecker nsec3hash nslookup nsupdate rndc rndc-confgen tsig-keygen
    gnumake # make
    gnutar # tar
    home-manager
    inetutils # dnsdomainname ftp hostname ifconfig logger ping ping6 rcp rexec rlogin rsh talk telnet tftp traceroute whois
    libarchive # bsdcat bsdcpio bsdtar bsdunzip
    lsof
    mtr # mtr mtr-packet
    nmap # ncat nmap nping
    p7zip # 7z 7za 7zr
    pciutils # lspci pcilmr setpci
    rsync # rsync rsync-ssl
    sysstat # cifsiostat iostat mpstat pidstat sadf sar tapestat
    unzip # funzip unzip unzipsfx zipgrep zipinfo
    usbutils # lsusb lsusb.py usb-devices usbhid-dump usbreset
    zip # zip zipcloak zipnote zipsplit
    btop # process viewer
  ];

  # Default enable these common modules for all hosts
  programs = {
    git.enable = lib.mkDefault true;
    mosh.enable = lib.mkDefault true;
    rust-motd.enable = lib.mkDefault true;
    tmux.enable = lib.mkDefault true;
    zsh.enable = lib.mkDefault true;
  };
}
