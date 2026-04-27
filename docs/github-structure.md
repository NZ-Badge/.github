# GitHub Structure

## Objective

Pubblicare NZ Badge su GitHub mantenendo separati i cicli di rilascio di webapp, firmware e
hardware, senza introdurre il costo operativo dei submodule finche' non serve davvero.

## Recommended Topology

### GitHub Organization

Nome consigliato:

- `nz-badge`

Alternative accettabili:

- `nzbadge`

La soluzione migliore e' usare una Organization, non un account personale, per separare ownership,
permessi e crescita futura del progetto.

### Repositories

| Repository | Tipo | Contenuto |
| --- | --- | --- |
| `nz-badge` | meta-repo | documentazione di insieme, bootstrap workspace, roadmap, issue trasversali |
| `nz-badge-webapp` | applicativo | dashboard admin, backend API, database, OTA, integrazioni |
| `nz-badge-reader-station` | firmware | reader ESP32-S3, attendance queue offline, provisioning |
| `nz-badge-writer-station` | firmware | writer ESP32-S3, protocollo WebSerial, card operations |
| `nz-badge-hardware` | hardware | schemi, PCB, Gerber, enclosure 3D |

## Important Constraint

Se `nz-badge` viene creato come repository Git nella root del workspace, non deve contenere i
repository figli come cartelle tracciate, altrimenti Git li registrera' come repository embedded o
gitlink.

Approccio corretto:

- il meta-repo contiene solo i file della root come `README.md`, `docs/`, `scripts/`, `.github/`
- le working copy locali di `app`, `hardware` e `firmware/*` restano non tracciate nel meta-repo
- `.gitignore` del meta-repo ignora esplicitamente le directory dei repository figli

## Local Workspace Layout

Layout consigliato sul filesystem:

```text
nz_badge/
  README.md
  docs/
  scripts/
  app/                        # clone di nz-badge-webapp
  hardware/                   # clone di nz-badge-hardware
  firmware/
    reader-station/           # clone di nz-badge-reader-station
    writer-station/           # clone di nz-badge-writer-station
```

Questo layout mantiene i path locali che hai gia' usato nella documentazione, ma evita di legare i
repo tra loro a livello Git.

## Suggested Repository Settings

Impostazioni consigliate per tutti i repository:

- default branch: `main`
- branch protection su `main`
- squash merge abilitato
- merge commit disabilitato se vuoi storia piu' pulita
- template `README`, `LICENSE`, `.editorconfig`, `.gitignore` per ogni repo
- topic GitHub coerenti: `nfc`, `rfid`, `esp32`, `attendance`, `webserial`

## Suggested Ownership

Team GitHub suggeriti:

- `platform`: accesso a `nz-badge` e `nz-badge-webapp`
- `firmware`: accesso a `nz-badge-reader-station` e `nz-badge-writer-station`
- `hardware`: accesso a `nz-badge-hardware`
- `maintainers`: admin su tutti i repository

## Recommended Rollout Order

1. Crea la Organization `nz-badge`.
2. Pubblica i quattro repository di prodotto.
3. Crea il meta-repo `nz-badge`.
4. Copia in `nz-badge` la documentazione root e gli script di bootstrap.
5. Aggiorna i link del meta-repo ai repository GitHub reali.
6. Imposta branch protection, topics e permessi team.

## When To Adopt Submodules

Passa ai submodule solo se emerge un requisito reale di version pinning cross-repo, per esempio:

- build CI che devono usare revisioni esatte e coordinate
- release bundle dove il commit di ogni sottoprogetto va congelato
- demo environment che devono essere ricostruibili byte-for-byte

Finche' non hai quel bisogno, il costo operativo dei submodule e' superiore al beneficio.
