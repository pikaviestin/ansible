# docker.pikaviestin.fi on podman

Status: **cut over 2026-11-14.** Docker is stopped and disabled on the host;
its containers are kept for an emergency rollback.

## Layout

- `uumas.podman.podman` installs podman; `roles/podman_services` runs each
  service as Quadlet units through `uumas.podman.service`:
  authentik (+ valkey, worker), cinny, element, jitsi (web + prosody/jicofo/jvb).
- One host caddy (`uumas.general.caddy` / `uumas.general.vhost`) proxies to
  ports published on localhost:

  | Domain | Port |
  |---|---|
  | login.pikaviestin.fi | 9000 |
  | cinny.pikaviestin.fi | 8081 |
  | chat.pikaviestin.fi | 8082 (container listens on 8080: the image's unprivileged nginx can't bind :80 under podman) |
  | jitsi.pikaviestin.fi | 8083 |
  | jarkkaa.fi | 4000 |

- Mobilizon is still a compose project in `/etc/docker/compose/docker-mobilizon`,
  run with `docker compose` against `/run/podman/podman.sock`; a
  `docker-compose.override.yml` publishes it on `127.0.0.1:4000`.
- Authentik's worker has no container socket, so only the embedded outpost works.

```bash
ansible-playbook -D playbooks/podman-containers.yml
```

## Migration tooling

- `playbooks/podman-prep.yml` snapshots docker state and backs up appdata and
  the mobilizon directory to `/opt/podman-migration/<timestamp>/` (root-only,
  contains secrets). The mobilizon postgres datadir in it was copied live.
- `playbooks/podman-cutover.yml` pre-pulls images (`--tags prepull`), stops and
  disables docker, resets the `FORWARD DROP` policy docker leaves behind (it
  blocks podman container egress under nftables), then runs
  `playbooks/podman-containers.yml`.

## Rollback

The Ansible docker setup has been removed; rollback restarts the docker
containers still on the host.

```bash
systemctl stop caddy authentik authentik-worker authentik-redis cinny element jitsi jitsi-prosody jitsi-jicofo jitsi-jvb
```

```bash
DOCKER_HOST=unix:///run/podman/podman.sock docker compose -f /etc/docker/compose/docker-mobilizon/docker-compose.yml down
```

```bash
rm /etc/docker/compose/docker-mobilizon/docker-compose.override.yml
```

```bash
systemctl enable --now docker.socket docker.service
```

Traefik's container comes back with docker and needs ports 80/443, so caddy
must stay stopped.

## Follow-ups

- Port mobilizon into `uumas.podman.service` (needs its `.env` secrets in vault).
- Purge docker-ce and its containers once a rollback is no longer wanted;
  `docker volume prune` first removes the 133 dangling volumes.
