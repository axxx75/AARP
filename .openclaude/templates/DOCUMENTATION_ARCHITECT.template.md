# AARP DOCUMENTATION ARCHITECT - TEMPLATE CONTRACT

> **ISTRUZIONI PER L'AGENTE DOCUMENTATION ARCHITECT:**
> Questo file definisce la struttura OBBLIGATORIA e il livello di dettaglio richiesto per i 4 documenti di output.
> 
> **REGOLE TASSATIVE:**
> 1. NON lasciare testo di istruzione, parentesi quadre `[...]`, segnaposto, `TODO` o `TBD`.
> 2. Genera SEMPRE i diagrammi Mermaid sintatticamente validi per ogni documento dove richiesto.
> 3. Traduci ogni concetto in prosa tecnica ricca, accompagnata da tabelle esaustive, schemi e snippet di codice reali.
> 4. Ogni documento DEVE terminare con la sezione `## Evidence Classification`.

---

<!-- ===================================== -->
<!-- FILE 1: ARCHITECTURE.md               -->
<!-- ===================================== -->

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
    Controller --> DB[(Database / Persistence)]
    Controller --> Queue[Message Queue / Event Bus]
    Controller --> ExtService[External Services]


Component Breakdown
Componente
Responsabilità Principale
Modulo/Package nel Codice
Tecnologie / Framework
[some_component]
[Descrizione dettagliata delle responsabilità]
[path/to/module]
[Linguaggio/Libreria]

Data Flow & Lifecycle
[Spiegazione narrativa di come un'operazione tipica attraversa il sistema dall'ingresso alla persistenza o risposta.]



Snippet di codice
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


Data Persistence & Domain Schemas
[Spiegazione dettagliata del modello dei dati, entità ORM, strutture NoSQL o file di stato usati dal sistema.]



Snippet di codice
erDiagram
    ENTITY_A ||--o{ ENTITY_B : "relazione"
    ENTITY_A {
        string id PK
        string status
    }
    ENTITY_B {
        string id PK
        string entity_a_id FK
    }


Key Data Entities
[Per ogni entità chiave, illustra campi, tipi, vincoli e significato applicativo in forma di tabella.]
Technical Patterns & Architectural Decisions
[Pattern Name, es. Repository Pattern / Circuit Breaker]: [Descrizione di dove e come è stato implementato nel codice, citando le classi o i moduli responsabili.]
[Pattern Name, es. Middleware Chain]: [Dettagli sull'adozione e impatto architetturale.]
Security & Isolation Architecture
[Analisi di come il sistema gestisce autenticazione, autorizzazione, cifratura dati, comunicazione inter-nodo e isolamento delle risorse.]
Evidence Classification
Categoria
Dettagli Architetturali Verificati
Verified
[Elementi confermati direttamente da codice sorgente, import, o config.]
Inferred
[Deduzioni logiche basate su convenzioni di naming o pattern standard.]
Unverified / Absent
[Aspetti architetturali attesi ma non trovati nel repository.]

FILE OUTPUT: ADMIN_GUIDE.md
Operations & Administration Guide
System Requirements & Prerequisites
Runtime: [es. Node.js 18+, Python 3.11+, Go 1.21+]
Dipendenze Esterne: [es. PostgreSQL 15, Redis 7, RabbitMQ]
Risorse Hardware Minime Consigliate: [CPU, RAM, Storage stimati in base ai profile di esecuzione trovati.]
Infrastructure Deployment Workflow



Snippet di codice
flowchart LR
    A[Env-vironment Setup] --> B[Configuration / Env Vars]
    B --> C[Database Migrations]
    C --> D[Service Startup]
    D --> E[Healthcheck Verification]


Deployment Execution Steps
[Fornisci le procedure esatte di deployment trovate nei file Dockerfile, docker-compose, Helm Chart, Makefile o script di installazione.]
Environment Configuration Reference
[Tabella completa e dettagliata di TUTTE le variabili d'ambiente e parametri di configurazione scoperti nel codice.]
Variabile / Key
Tipo
Valore Default
Obbligatorio?
Descrizione e Impatto
name_var
String
``
Sì
[description]

Day-2 Operations & Monitoring
Health Checks & Diagnostics
Endpoint / Method: [yes. GET /health or CLI ping]
Criteri di Rilevamento: [Cosa controlla esattamente l'healthcheck: DB connection, cache, disco.]
Logging Architecture
Formato Log: [es. JSON strutturato, plaintext, Syslog]
Livelli supportati: [DEBUG, INFO, WARN, ERROR]
Log Rilevanti per il Tracing: [Log key identificativi trovati nel codice]
Troubleshooting & Common Failure Modes



Snippet di codice
flowchart TD
    Issue[Rilevato Errore / Anomalia] --> CheckLog{Analisi Log}
    CheckLog -->|Error Code X| ActionA[Azione Correttiva A]
    CheckLog -->|Connection Refused| ActionB[Azione Correttiva B]


Failure Matrix
Sintomo / Error Message
Causa Radice Probabile
Procedura di Risoluzione
[Messaggio errore reale nel codice]
[Condizione che lo scattata]
[Passi da eseguire per ripristinare il servizio]

Evidence Classification
Categoria
Dettagli Operativi Verificati
Verified
[Variabili, script di deploy e logiche di error handling trovate nel codice.]
Inferred
[Stime di requisiti di sistema basati sulle dipendenze.]
Unverified / Absent
[Procedure operative non presenti (es. backup/restore assenti).]

FILE OUTPUT: USER_GUIDE.md
User & Functional Workflow Guide
Domain Concepts & Glossary
[Termine / Dominio 1]: [Spiegazione dettagliata del concetto nel contesto del prodotto.]
[Termine / Dominio 2]: [Spiegazione dettagliata.]
Core User Journeys & Workflow Overview



Snippet di codice
stateDiagram-v2
    [*] --> Init: Avvio Operazione / Interfaccia
    Init --> Processing: Invio Input / Dati
    Processing --> Success: Esito Positivo
    Processing --> Error: Fallimento / Validazione 
    Error --> Processing: Correggi Input
    Success --> [*]


Detailed Feature Walkthroughs
1. [Nome Macro-Funzionalità / Feature Key]
Descrizione: [Spiegazione narrativa e approfondita di cosa fa questa funzionalità, quali problemi dell'utente risolve e quali componenti attiva.]
Workflow Passaggio-Passaggio:
Prerequisiti: [Stato iniziale richiesto]
Azione dell'utente: [Input fornito, bottone premuto o comando CLI lanciato]
Elaborazione di Sistema: [Cosa succede internamente]
Risultato Atteso: [Cosa vede o riceve l'utente]
Edge Cases, Limits & Behavioral Rules
Validazioni Stringenti: [Descrivi i limiti di input trovati nei validatori del codice (es. max size file, regex, vincoli di lunghezza).]
Comportamento in caso di Timeout o Errori: [Cosa succede dal punto di vista dell'utente se un servizio downstream fallisce.]
Evidence Classification
Categoria
Dettagli Funzionali Verificati
Verified
[Funzionalità, regole di validazione e flussi confermati da codice e test.]
Inferred
[Intent utente dedotto dalle interfacce o dalle rotte.]
Unverified / Absent
[Funzionalità o interfacce utente non presenti nel repository.]

FILE OUTPUT: API_REF.md
Interface & API Reference Specifications
Overview & Authentication Mechanism
Tipo Interfaccia: [REST API / gRPC / WebSocket / CLI Tool / Nessuna interfaccia esterna]
Autenticazione: [es. Bearer Token JWT, API Key, MTLS, Nessuna]
Base URL / Endpoint Root: [yes. /api/v1 o sintassi CLI]
Endpoints / Commands Specification



Snippet di codice
flowchart LR
    Client -->|Headers + Auth| Endpoint[API Endpoint / CLI Command]
    Endpoint -->|200 OK| Response[Payload Risposta]
    Endpoint -->|4xx / 5xx| ErrorResponse[Error Schema]


[METHOD] /path/to/endpoint (o command-name per CLI)
Descrizione: [Spiegazione dettagliata dell'endpoint o comando.]
Request Parameters / Payload
Parametro
Posizione (Query/Body/Header/Arg)
Tipo
Obbligatorio?
Descrizione
field_name
Body
String
Sì
[Descrizione del campo]

Example Request



HTTP
POST /api/v1/resource HTTP/1.1
Host: api.example.com
Authorization: Bearer <token>
Content-Type: application/json

{
  "field_name": "example_value"
}


Example Response (200 OK)



JSON
{
  "status": "success",
  "data": {
    "id": "12345",
    "field_name": "example_value"
  }
}


Error Responses
HTTP Code / Status
Motivo
Body di Esempio
400 Bad Request
Validazione fallita
{\n "error": "Invalid field_name"\n}
401 Unauthorized
Token assente o scaduto
{ "error": "Unauthorized" }

Non-API / Embedded Interface Note
(Compilare questa sezione SE NON sono state trovate API HTTP/CLI esterne)
Qualora il sintassate sia una libreria interna, un worker batch o un job schedulato senza API esposte, spiegare in dettaglio l'interfaccia di programmazione interna (es. Metodi pubblici esposti dalle classi principali, Event listener o firme dei parametri dei job).
Evidence Classification
Categoria
Dettagli Interfaccia Verificati
Verified
[Rotte, controller, schemi OpenAPI o parser CLI trovati nel codice.]
Inferred
[Esempi di payload costruiti dai test unitari o integration test.]
Unverified / Absent
[Integrazioni o metodi API non documentati nel codice.]
EOF
