# INFO8995 Final Assignment – Troubleshooting Log

This log captures the issues encountered while standing up the Django CRM stack with Docker/Compose, TrueNAS NFS storage, and Cloudflared ingress, plus how each was investigated and resolved.

## Environment snapshot

- App: Django CRM (Django + mysqlclient)
- Containers: crm (Django), db (MySQL), adminer
- Base image: python:3.13-alpine for crm
- DB: MySQL (we recommend pinning to `mysql:8`)
- Storage: TrueNAS NFS for MySQL data volume
- Ingress: Cloudflare Tunnel (cloudflared) with oauth2-proxy

---

## 1) mysqlclient failed: missing libmariadb.so.3 on Alpine

- Symptom
  - `ImportError: libmariadb.so.3: cannot open shared object file` when running Django with `mysqlclient` on Alpine.
- Likely root cause
  - Alpine needs the runtime package `mariadb-connector-c` available at runtime; only having `-dev` during build is insufficient.
- What we tried
  - Installed `mariadb-connector-c-dev`, `gcc`, `musl-dev` to build `mysqlclient`.
  - Initially removed too many packages post-build which also removed the runtime lib.
- Final fix
  - Ensure runtime lib stays installed:
    - Keep `mariadb-connector-c` (runtime) installed permanently.
    - Use a temporary `.build-deps` group only for compilers/headers, then `apk del .build-deps`.
- Status: Resolved
  - `import MySQLdb` works inside the container; migrations run.

---

## 2) Duplicate columns during migrations (e.g., `signature_id` already exists)

- Symptom
  - Running migrations/setupdata failed with errors like duplicate column/index.
- Likely root cause
  - A previous DB state existed in the persistent volume from an earlier schema, causing conflicts.
- What we tried
  - Re-ran migrations; inspected migration history.
- Final fix
  - Reset the MySQL data volume (remove/drop the named volume or drop the DB) and re-run migrations.
  - Then ran `python manage.py setupdata`.
- Status: Resolved
  - Setup completed and printed superuser credentials.

---

## 3) Superuser creation failures (manage.py setupdata)

- Symptom
  - `docker compose exec crm python manage.py setupdata` failed during earlier runs.
- Likely root cause
  - Same underlying DB schema issues as above; the command depends on clean, migrated DB.
- Final fix
  - After resetting the DB volume and re-running migrations, `setupdata` succeeded.
  - Credentials output (as shown in logs at the time):
    - Username: `IamSUPER`
    - Password: `X99MQcYW`
    - Email: `super@example.com`
- Status: Resolved

---

## 4) Cloudflared ingress “Not found” and NXDOMAIN

- Symptoms
  - Accessing `https://codespace.premchanderj.me/…` returned oauth2-proxy pages or “Not found”.
  - `dev-codespace.premchanderj.me` returned NXDOMAIN initially.
- Likely root cause
  - Tunnel ingress mapped `codespace.premchanderj.me` → `http://localhost:4180` (oauth2-proxy).
  - No upstream from oauth2-proxy to the app port (8080), and `dev-codespace` DNS route wasn’t created yet.
- What we tried
  - Validated local service on 8080 with curl.
  - Added both hostnames to Django `ALLOWED_HOSTS` and `CSRF_TRUSTED_ORIGINS` in `settings.py`.
  - Kept two ingress rules:
    - `codespace.premchanderj.me` → `http://localhost:4180`
    - `dev-codespace.premchanderj.me` → `http://localhost:8080`
- Final fix options
  1) Create tunnel DNS route and use `dev-codespace` for direct app access:
     - `cloudflared tunnel route dns <TUNNEL_ID> dev-codespace.premchanderj.me`
     - `sudo systemctl restart cloudflared`
     - `cloudflared tunnel ingress validate`
  2) Or, keep only `codespace.premchanderj.me` and configure oauth2-proxy to upstream to `http://localhost:8080`.
- Status: Partially resolved/pending verification
  - Config is correct; ensure DNS route exists and tunnel is restarted. Then verify:
    - `https://dev-codespace.premchanderj.me/en/456-admin/`
    - `https://dev-codespace.premchanderj.me/en/123/`

---

## 5) Django host/CSRF configuration

- Symptom
  - CSRF/Host validation errors or unexpected 400s when accessing via external hostnames.
- Cause
  - Missing hosts/origins in Django settings.
- Fix
  - Added to `settings.py`:
    - `ALLOWED_HOSTS += ["codespace.premchanderj.me", "dev-codespace.premchanderj.me"]`
    - `CSRF_TRUSTED_ORIGINS += ["https://codespace.premchanderj.me", "https://dev-codespace.premchanderj.me"]`
  - Rebuild/restart the app container if needed.
- Status: Resolved

---

## 6) NFS volume mount and permissions (TrueNAS)

- Symptoms
  - `chmod`/permission errors on NFS path; inability to reach TrueNAS NFS from Windows Docker host.
- Likely root causes
  - Client host not on same network / routing to TrueNAS.
  - NFS export options (Maproot) and dataset permissions not allowing required access.
  - Compose NFS `driver_opts` not correctly quoted/indented.
- What we tried
  - Recommended TrueNAS NFS export:
    - Maproot User: `root`, Group: `wheel` (or appropriate UID/GID mapping).
    - Restrict Networks/Hosts to intended Docker host.
    - Ensure dataset permits MySQL to write.
  - Compose volume config (example):

    ```yaml
    volumes:
      mysql_db_data:
        driver: local
        driver_opts:
          type: nfs
          o: "addr=10.172.27.9,nolock,soft,rw,proto=tcp,vers=3"
          device: ":/mnt/mysql-data"
    ```

  - Note: Docker Desktop on Windows couldn’t reach `10.172.27.9` without proper network/VPN; testing proceeded on an Ubuntu host.
- Status: Pending validation on the final target host
  - Works when the Docker host can reach the NFS server and export perms are correct.

---

## 7) Compose YAML pitfalls (quoting/indentation)

- Symptom
  - `docker compose` parse errors around `driver_opts`.
- Cause
  - Unquoted `o:` string and/or wrong indentation under `driver_opts`.
- Fix
  - Quote `o:` and ensure proper indentation as shown above.
- Status: Resolved

---

## 8) MySQL image version compatibility

- Observation
  - Using latest MySQL led to unexpected behavior in some environments.
- Recommendation
  - Pin DB image: `image: mysql:8` for stability with `mysqlclient` and existing migrations.
- Status: Recommended best practice (implement in Compose)

---

## Verification checklist

- Local app health:
  - `curl -I http://localhost:8080/en/456-admin/` returns 302 to login.
  - `curl -I http://localhost:8080/en/123/` returns 301 → 200.
- Cloudflared ingress:
  - DNS routes exist for both hostnames; `cloudflared tunnel ingress validate` passes.
  - `https://dev-codespace.premchanderj.me/en/456-admin/` reaches Django login.
- Persistent storage:
  - DB data persists across container restarts; NFS dataset shows MySQL files.

---

## Open items / next steps

- Confirm the Cloudflared DNS route for `dev-codespace` and test HTTPS endpoints.
- If using oauth2-proxy only, set its upstream to `http://localhost:8080`.
- Finalize CI/CD pipeline (build and push image to your registry on push).
- Generate Helm chart via Kompose and deploy to a K8s cluster; document values.
