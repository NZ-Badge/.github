# NZ Badge

Sistema integrato per rilevare presenze tramite badge NFC/RFID, amministrare iscritti e corsi,
programmare card e gestire dispositivi ESP32-S3 distribuiti sul campo.

Il progetto e' composto da quattro aree distinte:

- una webapp che funge sia da dashboard operativa sia da backend API
- un firmware `reader-station` per lettura presenze online/offline
- un firmware `writer-station` per scrittura e diagnostica card via WebSerial
- un repository hardware con schemi, PCB e contenitori 3D

Questo README descrive la vista di insieme. Setup, API, pinout e dettagli operativi restano
documentati nei README specifici dei sottoprogetti.

Nel setup GitHub consigliato, questa root va trattata come meta-repository leggero di
coordinamento, non come contenitore dei repository figli tramite cartelle versionate.

## Problema Che Risolve

NZ Badge copre l'intero flusso di gestione badge per corsi o attivita' con iscritti:

- sincronizzazione o ricezione delle iscrizioni da un sistema esterno
- emissione e associazione di card RFID/NFC agli iscritti
- rilevazione presenze tramite reader dedicati
- raccolta e revisione delle presenze da dashboard amministrativa
- aggiornamento firmware dei reader e gestione operativa dei device

L'obiettivo non e' solo leggere un UID, ma tenere coerenti persone, card, dispositivi e storico
presenze in un unico sistema.

## Architettura

```text
Sistema esterno iscrizioni
          |
          v
   +------------------+
   |      Webapp      |
   | UI admin + API   |
   | DB + OTA         |
   +------------------+
      ^           ^
      |           |
      |           +-----------------------------+
      |                                         |
      |                                 Browser admin
      |                                         |
      |                                   Web Serial
      |                                         |
      |                                 +---------------+
      |                                 | Writer Station|
      |                                 +---------------+
      |
HTTP API + bearer token
      |
      v
+---------------+
| Reader Station|
+---------------+
      |
      v
 Badge NFC/RFID
```

## Componenti Del Sistema

### Webapp

La webapp e' il centro di integrazione principale. Gestisce:

- dashboard per operatori e amministratori
- anagrafica iscritti, corsi, card e presenze
- endpoint API usati dai reader
- workflow di scrittura card tramite browser e `writer-station`
- upload e attivazione firmware OTA per i reader
- sync e webhook verso il sistema esterno di enrollments

Nel workspace attuale il codice vive in [app/webapp](./app/webapp/README.md).

### Reader Station

`reader-station` e' un device ESP32-S3 con PN532, display, buzzer e feedback LED. Legge badge sul
campo, invia presenze alla webapp e continua a lavorare anche offline grazie a una coda locale che
viene flushata quando la connettivita' torna disponibile.

Nel workspace attuale il codice vive in [firmware/reader-station](./firmware/reader-station/README.md).

### Writer Station

`writer-station` e' un device ESP32-S3 collegato al browser via WebSerial. Non decide policy o
autorizzazioni: esegue operazioni hardware richieste dalla webapp, come scrittura MIFARE, lettura
UID e cancellazione card.

Nel workspace attuale il codice vive in [firmware/writer-station](./firmware/writer-station/README.md).

### Hardware

Il repository hardware raccoglie gli artefatti fisici del progetto:

- schema elettrico EasyEDA Pro
- PCB e Gerber di produzione
- modelli STL del contenitore

Lo stato attuale documenta soprattutto l'adattatore ESP32-S3 allineato al `reader-station`, mentre
per il writer le evidenze hardware presenti sono piu' parziali.

Nel workspace attuale il materiale vive in [hardware](./hardware/README.md).

## Flusso Operativo End-To-End

### 1. Provisioning e configurazione reader

Un reader nuovo o resettato entra in modalita' setup, riceve credenziali WiFi e parametri di
registrazione verso la webapp, poi riparte in modalita' operativa.

### 2. Gestione iscritti e card

La webapp mantiene iscritti, enrollments, card e regole di presenza. Quando serve emettere una
card, l'operatore usa una pagina admin che:

- richiede autorizzazione e parametri alla webapp
- apre la porta seriale del `writer-station` dal browser
- esegue scrittura o scansione della card
- conferma il risultato alla webapp

### 3. Rilevazione presenze

Quando un badge viene avvicinato a un reader:

1. il reader legge UID e timestamp locale
2. se online invia subito l'evento alla webapp
3. se offline mette l'evento in coda su filesystem locale
4. la webapp valida il device, collega la card all'iscritto e decide `entry` o `exit`
5. gli operatori vedono storico, anomalie e stato presenze in dashboard

### 4. Operativita' continua

La webapp espone health check, API di attendance e release firmware OTA. I reader controllano la
salute del backend, scaricano eventuali aggiornamenti e continuano a bufferizzare eventi se la rete
cade temporaneamente.

## Separazione Dei Repository

Il layout attuale e' un workspace condiviso, ma la separazione target e' questa:

| Repo logico | Path attuale | Responsabilita' |
| --- | --- | --- |
| Webapp | `app/webapp` | dashboard admin, backend API, database, OTA, integrazioni esterne |
| Reader firmware | `firmware/reader-station` | lettura badge, queue offline, provisioning, sync presenze |
| Writer firmware | `firmware/writer-station` | protocollo WebSerial e operazioni hardware su card |
| Hardware | `hardware` | schemi, PCB, Gerber, enclosure 3D |

Questa separazione aiuta a mantenere scope, release cycle e documentazione coerenti per team con
responsabilita' diverse.

## Struttura GitHub Consigliata

La struttura consigliata su GitHub e' una Organization dedicata, per esempio `nz-badge`, con questi
repository:

| Repository | Scopo |
| --- | --- |
| `nz-badge` | meta-repo: overview, architettura, roadmap, bootstrap workspace |
| `nz-badge-webapp` | dashboard admin, backend API, database, OTA, integrazioni esterne |
| `nz-badge-reader-station` | firmware reader ESP32-S3 |
| `nz-badge-writer-station` | firmware writer ESP32-S3 |
| `nz-badge-hardware` | schemi, PCB, Gerber, enclosure 3D |

Scelta raccomandata:

- niente submodule nella fase iniziale
- i repository applicativi restano indipendenti
- il meta-repo contiene solo documentazione e script di orchestrazione

Nota importante:

- se questa root viene inizializzata come repository Git, le directory figlie che sono gia'
  repository indipendenti non vanno committate dentro il meta-repo
- per evitare gitlink accidentali, il meta-repo deve ignorare `app`, `hardware` e i repository sotto
  `firmware`

La guida operativa completa e' in [docs/github-structure.md](./docs/github-structure.md).

## Mappa Rapida Dei Sottoprogetti

- [Webapp README](./app/webapp/README.md)
- [Reader Station README](./firmware/reader-station/README.md)
- [Writer Station README](./firmware/writer-station/README.md)
- [Hardware README](./hardware/README.md)

## Bootstrap Workspace

Per ricreare questo workspace da zero, il meta-repo include uno script che clona i repository
fratelli senza usare submodule:

```bash
./scripts/bootstrap-workspace.sh <github-org>
```

Esempio:

```bash
./scripts/bootstrap-workspace.sh nz-badge
```

Di default usa `git@github.com:<org>/...`. Per usare HTTPS:

```bash
GIT_BASE_URL="https://github.com/<org>" ./scripts/bootstrap-workspace.sh <org>
```

## Limiti E Confini Del Sistema

- La webapp e' il punto autorevole per autenticazione, autorizzazioni, persistenza e logica di business.
- Il writer non e' un sistema standalone di card management: esegue comandi della webapp via browser.
- Il reader e' progettato per resilienza operativa, non per operare come backend autonomo.
- Il repository hardware non contiene ancora tutto il necessario per descrivere in modo completo una board dedicata al writer.

## Quando Aprire I README Specifici

- Apri il README webapp per setup locale, variabili ambiente, database, endpoint e workflow admin.
- Apri il README reader per pinout, stati runtime, provisioning, OTA e console seriale.
- Apri il README writer per protocollo JSON/WebSerial, varianti PN532/RC522 e flussi di erase/write.
- Apri il README hardware per inventario artefatti, limiti dei file presenti e mappa pin verificata.
