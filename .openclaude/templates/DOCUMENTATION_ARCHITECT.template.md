# Documentation Architect Output Contract

> **ISTRUZIONI PER L'AGENTE DOCUMENTATION ARCHITECT:**> Questo file definisce la struttura OBBLIGATORIA e il livello di dettaglio richiesto per i 4 documenti di output.>>
 **REGOLE TASSATIVE:**
@ 1. NON lasciare testo di istruzione, parentesi quadre `[...]`, segnaposto, `TODO` o `TBD`.
A 2. Genera SEMPRE i diagrammi Mermaid sintatticamente validi per ogni documento dove richiesto.
A 3. Traduci ogni concetto in prosa tecnica ricca, accompagnata da tabelle esaustive, schemi e snippet di codice reali.
A4. Ogni documento DEVE terminare con la sezione `## Evidence Classification`.

<!-- ========================================== -->
<!-- FILE 1: ARCHITECTURE.md                    -->
<!-- ========================================== -->

# FILE OUTPUT: ARCHITECTURE.md

# Architecture & System Design Reference

## Executive Summary & System Vision
[Descrizione narrativa e approfondita del sistema: qual è il problema di business o tecnico che risolve, quali sono i principi architetturali chiave (es. Event-Driven, Microservizi, Monolite modulare, Domain-Driven Design) e le caratteristiche distintive trovate nel codice.]

## High-Level Architecture
[Descrizione dettagliata dell'architettura generale.]

 ```mermaid
graph TD

    %% Esempio di diagramma dei componenti. Genera il diagramma reale basato sul codice.
    Client[Client / User Interface] --> API[API Gateway / Ingress]
    API --> Controller[Application Core / Business Logic]
    Controller --> DB([database / Persistence)]
    Controller --> Queue[Message Queue / Event Bus]
    Controller --> ExtService[External Services]
```J

### Component Breakdown
|Componente | ResponsabilitÀ Principale | Modulo/Package nel Codice | Tecnologie / Framework |
|C:--- | :--- | :--- | :--- |
|[some_component] | [Descrizione dettagliata delle responsabilitÀ] | `[path/to/module]` | [Linguaggio/Libreria] |

## Data Flow & Lifecycle
[Spiegazione narrativa di come un'operazione tipica attraversa il sistema dall'ingresso alla persistenza o risposta.]

```mermaid
sequenceDiagram
    autonumber
    actor User
    participant Entry as EntryPoint/API
    participant Core as Core Service
    participant Data as Data Layer

    User->>Entry: Triggers Action
    Entry->>Core: Process Request & Validate
    Core->>Data: Read/Write State
    Data-->>Core: Return Entity/Result
    Core-->>Entry: Return DTO
    Entry-->>User: Response Payload
```J

## Data Persistence & Domain Schemas
[Spiegazione dettagliata del modello dei dati, entità ORM, strutture NoSQL o file di stato usati dal sistema.]

erDiagram
    %% Genera il diagramma Entity-Relationship reale rilevato dalle migrazioni, ORM o classi DTO
    ENTITY_A ||--o{ ENTITY_B : "relazione"
    ENTITY_A {
        string id PK
        string status
    }
    ENTITY_B {
        string id PK
        string entity_a_id FK
    }

### Key Data Entities
[Per ogni entità chiave, illustra campi, tipi, vincoli e significato applicativo in forma di tabella.]

## Technical Patterns & Architectural Decisions
[Pattern Name, es. Repository Pattern / Circuit Breaker]: [Descrizione di dove e come è stato implementato nel codice, citando le classi o i moduli responsabili.]

[Pattern Name, es. Middleware Chain]: [Dettagli sull'adozione e impatto architetturale.]

## Security & Isolation Architecture
[Analisi di come il sistema gestisce autenticazione, autorizzazione, cifratura dati, comunicazione inter-nodo e isolamento delle risorse.]

## Evidence Classification
Categoria				Dettagli Architetturali Verificati
Verified				[Elementi confermati direttamente da codice sorgente, import, o config.]
Inferred				[Deduzioni logiche basate su convenzioni di naming o pattern standard.]
Unverified / Absent		[Aspetti architetturali attesi ma non trovati nel repository.]

<!-- ===================================== -->
<!-- FILE 2: ADMIN_GUIDE.md                -->
<!-- ===================================== -->
# FILE OUTPUT: ADMIN_GUIDE.md

# Operations & Administration Guide

## System Requirements & Prerequisites
- **Runtime:** [es. Node.js 18+, Python 3.11+, Go 1.21+]
- **Dipendenze Esterne:** [es. PostgreSQL 15, Redis 7, RabbitMQ]
- **Risorse Hardware Minime Consigliate:** [CPU, RAM, Storage stimati in base ai profile di esecuzione trovati.]

## Infrastructure Deployment Workflow

```mermaid
flowchart LR
    A[Env-vironment Setup] --> B[Configuration / Env Vars]
    B --> C[Database Migrations]
    C --> D[Service Startup]
    D --> E[Healthcheck Verification]

### Deployment Execution Steps
[Fornisci le procedure esatte di deployment trovate nei file Dockerfile, docker-compose, Helm Chart, Makefile o script di installazione.]

## Environment Configuration Reference
[Tabella completa e dettagliata di TUTTE le variabili d'ambiente e parametri di configurazione scoperti nel codice.]
Variabile / Key, Tipo,	Valore Default,	Obbligatorio?,	Descrizione e Impatto

## Day-2 Operations & Monitoring

### Health Checks & Diagnostics
 - Endpoint / Method: [yes. GET /health or CLI ping]
 - Criteri di Rilevamento: [Cosa controlla esattamente l'healthcheck: DB connection, cache, disco.]

### Logging Architecture
 - Formato Log: [es. JSON strutturato, plaintext, Syslog]
 - Livelli supportati: [DEBUG, INFO, WARN, ERROR]
 - Log Rilevanti per il Tracing: [Log key identificativi trovati nel codice]

## Troubleshooting & Common Failure Modes
flowchart TD
   Issue[Rilevato Errore / Anomalia] --> CheckLog{Analisi Log}
   CheckLog -->|Error Code X| ActionA[Azione Correttiva A]
   CheckLog -->|Connection Refused| ActionB[Azione Correttiva B]

###Failure Matrix
Sintomo / Error Message |	Causa Radice Probabile	| Procedura di Risoluzione

## Evidence Classification
Categoria				Dettagli Architetturali Verificati
Verified				[Variabili, script di deploy e logiche di error handling trovate nel codice.]
Inferred				[Stime di requisiti di sistema basati sulle dipendenze]
Unverified / Absent		[Procedure operative non presenti (es. backup/restore assenti)]



