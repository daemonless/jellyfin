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
      - /path/to/containers/jellyfin/cache:/cache # optional
      - /path/to/media:/media
    ports:
      - 8096:8096
    restart: unless-stopped
```

### Podman CLI

```bash
podman run -d --name jellyfin \
  -p 8096:8096 \
  -e PUID=@PUID@ \
  -e PGID=@PGID@ \
  -e TZ=@TZ@ \
  -v /path/to/containers/jellyfin:/config \ 
  -v /path/to/containers/jellyfin/cache:/cache \  # optional
  -v /path/to/media:/media \ 
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
      PUID: "1000"
      PGID: "1000"
      TZ: "UTC"
    ports:
      - "8096:8096"
    volumes:
      - "/path/to/containers/jellyfin:/config"
      - "/path/to/containers/jellyfin/cache:/cache" # optional
      - "/path/to/media:/media"
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
| `/cache` | Cache directory (Optional) |
| `/media` | Media library |

### Ports

| Port | Protocol | Description |
|------|----------|-------------|
| `8096` | TCP | Web UI |

## Notes

- **User:** `bsd` (UID/GID set via PUID/PGID)
- **Base:** Built on `ghcr.io/daemonless/base` (FreeBSD)