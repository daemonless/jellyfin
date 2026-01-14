# Jellyfin

The Free Software Media System on FreeBSD.

| | |
|---|---|
| **Port** | 8096 |
| **Registry** | `ghcr.io/daemonless/jellyfin` |
| **Source** | [https://github.com/jellyfin/jellyfin](https://github.com/jellyfin/jellyfin) |
| **Website** | [https://jellyfin.org/](https://jellyfin.org/) |

## Deployment

### Podman Compose

```yaml
services:
  jellyfin:
    image: ghcr.io/daemonless/jellyfin:latest
    container_name: jellyfin
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=UTC
    volumes:
      - /path/to/containers/jellyfin:/config
      - /path/to/path/to/cache:/cache
      - /path/to/path/to/tv:/tv
      - /path/to/path/to/movies:/movies
    ports:
      - 8096:8096
    annotations:
      org.freebsd.jail.allow.mlock: "true"
    restart: unless-stopped
```

### Podman CLI

```bash
podman run -d --name jellyfin \
  -p 8096:8096 \
  --annotation 'org.freebsd.jail.allow.mlock=true' \
  -e PUID=@PUID@ \
  -e PGID=@PGID@ \
  -e TZ=@TZ@ \
  -v /path/to/containers/jellyfin:/config \ 
  -v /path/to/path/to/cache:/cache \ 
  -v /path/to/path/to/tv:/tv \ 
  -v /path/to/path/to/movies:/movies \ 
  ghcr.io/daemonless/jellyfin:latest
```
Access at: `http://localhost:8096`

### Ansible

```yaml
- name: Deploy jellyfin
  containers.podman.podman_container:
    name: jellyfin
    image: ghcr.io/daemonless/jellyfin:latest
    state: started
    restart_policy: always
    env:
      PUID: "@PUID@"
      PGID: "@PGID@"
      TZ: "@TZ@"
    ports:
      - "8096:8096"
    volumes:
      - "/path/to/containers/jellyfin:/config"
      - "/path/to/path/to/cache:/cache"
      - "/path/to/path/to/tv:/tv"
      - "/path/to/path/to/movies:/movies"
    annotation:
      org.freebsd.jail.allow.mlock: "true"
```

## Configuration
### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `PUID` | `1000` | User ID for the application process |
| `PGID` | `1000` | Group ID for the application process |
| `TZ` | `UTC` | Timezone for the container |
### Volumes

| Path | Description |
|------|-------------|
| `/config` | Configuration directory |
| `/cache` | {'desc': 'Cache directory', 'optional': True} |
| `/tv` | {'desc': 'TV Series library', 'optional': True} |
| `/movies` | {'desc': 'Movie library', 'optional': True} |
### Ports

| Port | Protocol | Description |
|------|----------|-------------|
| `8096` | TCP | Web UI |

## Notes

- **User:** `bsd` (UID/GID set via PUID/PGID)
- **Base:** Built on `ghcr.io/daemonless/base` (FreeBSD)
- **.NET App:** Requires `--annotation 'org.freebsd.jail.allow.mlock=true'` and a [patched ocijail](https://daemonless.io/guides/ocijail-patch).