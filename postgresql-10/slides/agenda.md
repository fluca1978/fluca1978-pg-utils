# Introduzione ai database relazionali
- Scenari di utilizzo e introduzione ai sistemi relazionali
- Il linguaggio SQL di base: ```INSERT, UPDATE, DELETE, SELECT```
- Tabelle e viste: definire i dati e gestirli
- Vincoli sui dati: chiavi primarie, condizioni di validità
- Relazioni fra tabelle, vincoli di integrità referenziale
- Reagire per mantenere i dati coerenti: triggers e stored procedures
- Cenni a sistemi NOSQL, CAP, Column-Store


# PostgreSQL: primi passi
- Introduzione al progetto (storia, cultura, risorse, funzionalità)
- Concetti di base (cluster, utenti, permessi, ecc.)
- Installazione di un cluster PostgreSQL
  - installazione da pacchetto binario
  - configurazione della directory di lavoro del cluster (```initdb```)
  - configurazione delle connessioni esterne (```pg_hba.conf```)
  - connessione al cluster tramite ```psql``` (*template0*, *template1*)
  - creazione di utenti e database
- Connessione ad un database specifico
  - utilizzare ```psql```
  - definire tabelle, viste, ruoli, e popolare il database
  - modificare lo schema (cenni)
- Backup e Restore
  - backup logico *testuale* con ```pg_dump```
  - restore manuale con ```psql``` o ```pg_restore```

# PostgreSQL: Server Side Programming (1)
- Transazioni: livelli di isolamento
- Stored Procedures: creare funzioni in linguaggio *plpgsql*
- Triggers: agganciare le funzioni agli eventi

# PostgreSQL: Server Side Programming (2)
- Usare il proprio linguaggio di programmazione preferito direttamente dentro a PostgreSQL (esempi)
- Background workers (esempi)
- Estendere PostgreSQL con le estensioni

# PostgreSQL: Replica
- Replication: concetti e terminologia, l'uso dei WAL
- Point in Time Recovery (esempi)
- Log Shipping Replication (esempi)
- Streaming Replication (esempi)
- Logical Replication (esempi)

-
