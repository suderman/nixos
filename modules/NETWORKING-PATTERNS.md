# Networking patterns

This repo's networking model is built from `zones/`, `flake.networking`,
Blocky DNS, Traefik routing, a custom internal CA, and Tailscale reachability.

## `zones/` is both data and ops documentation

- `zones/*/default.nix` is the machine-readable source of IP data.
- `zones/*/README.md` is mostly for human router/admin instructions: DHCP,
  static routes, DNS settings, Tailscale admin notes, and CA install steps.
- `zones/default.nix` defines the shared internal CA certificate path and the
  public domain name (`domainName`).

Treat the `default.nix` files as the executable source of truth. Treat the
READMEs as runbooks for manually keeping routers and clients aligned.

## `flake.networking`

`lib/networking.nix` imports all zone data and exports:

- `flake.networking.zones.<zone>`: raw zone IP maps
- `flake.networking.ca`: `zones/ca.crt`
- `flake.networking.domainName`: currently `suderman.org`
- `flake.networking.records`: flattened hostname-to-IP mappings

`flake.networking.records` contains both:

- zone-based names like `hub.home`, `eve.work`, `kit.tail`
- per-host primary records like `hub`, `eve`, `kit`, chosen from each host's
  `networking.domain`

## Host networking conventions

`modules/nixos/default/configs/networking.nix` derives host metadata from the
zone map:

- `networking.hostName` comes from the `hosts/<name>` directory
- `networking.domain` selects the host's primary zone/address
- `networking.address` becomes that primary IP
- `networking.addresses` includes loopback plus all known addresses whose names
  start with the host name
- `networking.hostNames` includes all matching DNS names for the host

Practical rule: when you change a host's main network identity, update its
`networking.domain` and the matching zone data.

## Blocky is the internal DNS layer

Blocky is what makes internal URLs resolve.

From `modules/nixos/default/options/blocky/default.nix`:

- hosts using Blocky point `networking.nameservers` to `127.0.0.1`
- `services.blocky.records` folds together Traefik-derived records from all
  NixOS configurations
- `customDNS.mapping = flake.networking.records // cfg.records`

So Blocky resolves both:

- base hostnames from `zones/`
- service hostnames discovered from Traefik configs across the flake

By default Blocky is private: firewall rules only allow DNS/API access from
loopback, RFC1918 ranges, docker ranges, and Tailscale (`100.64.0.0/10`).

## Traefik is the service naming and routing layer

`services.traefik.proxy` is the main high-level entrypoint for reverse proxies.
The Traefik module derives routers, services, middlewares, certificates, and
DNS-facing hostnames from that shorthand.

### Hostname rules

From `modules/nixos/default/options/traefik/lib.nix`:

- a bare name like `jellyfin` becomes `jellyfin.<current-host>`
- explicit hostnames stay as written
- URLs are parsed to extract their hostnames

### Internal vs external

Traefik treats a hostname as internal if it:

- is the current host name
- ends with `.<current-host>`
- ends with `.${flake.networking.domainName}`
- or is explicitly listed in `services.traefik.extraInternalHostNames`

Otherwise it is treated as external.

### Private vs public

- private hostnames get the `local` middleware automatically
- `local` is an IP allowlist for local, RFC1918, docker, and Tailscale ranges
- public hostnames do not get that middleware by default
- external hostnames default to public unless explicitly overridden

### Helper API

Other modules are expected to compose with Traefik via:

- `services.traefik.proxy`
- `services.traefik.lib.mkLabels` for OCI containers
- `services.traefik.lib.mkAlias` for alias hostnames

Avoid rebuilding the routing logic manually when these helpers already express
the intended conventions.

## Certificates: internal CA vs Let's Encrypt

This repo uses two certificate paths:

- internal hostnames get certs signed by the custom CA in `zones/ca.crt`
- external hostnames get Let's Encrypt certs via Cloudflare DNS challenge

`modules/nixos/default/options/traefik/default.nix` generates internal certs in
an activation script using the decrypted CA key from agenix.

The intended internal HTTPS model is:

- Blocky resolves `jellyfin.lux` / `hass.hub` / `syncthing-jon.kit`
- Traefik routes those hostnames to the right backend
- Traefik serves an internally trusted cert
- clients trust it because the custom CA has been installed once

`services.traefik.caPort` can expose `ca.crt` for easy client installation.

## Tailscale is the reachability layer

`zones/tail` tracks Tailscale IPs and admin-side subnet/DNS notes.

Tailscale is what makes the private DNS + private HTTPS model usable across
devices outside the local LAN. The common path is:

- Tailscale provides reachability to the target host or subnet
- Blocky resolves the internal hostname
- Traefik terminates HTTPS and forwards to the backend
- the custom CA makes the certificate trusted

Without Tailscale or equivalent routing, internal names may resolve but not be
reachable from outside the LAN.

## User-level services

`modules/nixos/default/options/traefik/users.nix` integrates Home Manager users
into the hostname model.

- each user gets extra internal names like `<user>.<host>`
- Traefik also routes `*.${user}.${host}` to the user's per-user backend port
- those backend ports are based on `21000 + home.portOffset`

This is why user-scoped URLs like `syncthing-jon.kit` fit naturally into the
same DNS + Traefik + CA system.

## Practical authoring rules

- If you add a new host or change a host's primary network, update `zones/*` and
  the host's `networking.domain` together.
- If you add a new internal web service, prefer exposing it through
  `services.traefik.proxy` or Traefik labels instead of inventing ad-hoc hostnames.
- If a service should resolve internally, make sure it ends up in Traefik so
  Blocky can see it.
- If a service should only be reachable privately, keep it on an internal name
  and let the `local` middleware protect it.
- If a service should be public, use an external hostname and let Traefik manage
  Cloudflare DNS + Let's Encrypt.
