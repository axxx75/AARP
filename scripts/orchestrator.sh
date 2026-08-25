#!/usr/bin/env bash
set -euo pipefail

# Colori per il terminale
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# ------------------------------------------------------------------------------
# CONFIGURATION & TARGET REPOSITORY
# ------------------------------------------------------------------------------
AARP_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd -P)"
TARGET_SPEC=""
REVIEW_DIR_OVERRIDE=""

usage() {
    cat <<'EOF'
Usage: bash scripts/orchestrator.sh [--target PATH_OR_GIT_URL] [--review-dir PATH]

Review a local checkout or clone a Git repository without copying AARP into it.

Options:
  --target PATH_OR_GIT_URL  Local checkout or Git URL to review.
  --review-dir PATH         Directory for the clone, reports, and logs.
  -h, --help                Show this help.

With no --target, the legacy in-place workflow is used and the repository
containing this script is reviewed.
EOF
}

while (($# > 0)); do
    case "$1" in
        --target|--repository|--repo)
            if (($# < 2)); then
                echo "Missing value for $1." >&2
                usage >&2
                exit 2
            fi
            TARGET_SPEC="$2"
            shift 2
            ;;
        --review-dir)
            if (($# < 2)); then
                echo "Missing value for --review-dir." >&2
                usage >&2
                exit 2
            fi
            REVIEW_DIR_OVERRIDE="$2"
            shift 2
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        --)
            shift
            if (($# > 0)); then
                echo "Unexpected positional argument: $1" >&2
                usage >&2
                exit 2
            fi
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage >&2
            exit 2
            ;;
    esac
done

is_remote_target() {
    local source="$1"
    case "$source" in
        http://*|https://*|ssh://*|git://*|git@*:*|file://*)
            return 0
            ;;
    esac

    [[ "$source" =~ ^([^/:[:space:]]+@)?[^/:[:space:]]+:.+ ]]
}

target_slug() {
    local source="$1"
    local name="${source##*/}"
    name="${name%.git}"
    name="${name:-repository}"
    printf '%s' "$name" | tr -cs '[:alnum:]._-' '-' | sed 's/^-*//; s/-*$//'
}

target_hash() {
    printf '%s' "$1" | cksum | awk '{print $1}'
}

canonical_path() {
    local input_path="$1"
    local normalized_path
    local existing_path
    local component
    local joined
    local -a input_parts=()
    local -a normalized_parts=()
    local -a missing_parts=()

    if [[ "$input_path" != /* ]]; then
        input_path="$PWD/$input_path"
    fi

    IFS=/ read -r -a input_parts <<< "$input_path"
    for component in "${input_parts[@]}"; do
        case "$component" in
            ""|.)
                ;;
            ..)
                if ((${#normalized_parts[@]} > 0)); then
                    normalized_parts=("${normalized_parts[@]:0:${#normalized_parts[@]} - 1}")
                fi
                ;;
            *)
                normalized_parts+=("$component")
                ;;
        esac
    done

    if ((${#normalized_parts[@]} == 0)); then
        normalized_path="/"
    else
        joined="$(IFS=/; printf '%s' "${normalized_parts[*]}")"
        normalized_path="/${joined}"
    fi

    while [[ ! -d "$normalized_path" ]]; do
        missing_parts=("$(basename "$normalized_path")" "${missing_parts[@]}")
        normalized_path="$(dirname "$normalized_path")"
    done

    existing_path="$(cd -P "$normalized_path" && pwd)"
    for component in "${missing_parts[@]}"; do
        existing_path="${existing_path}/${component}"
    done
    printf '%s\n' "$existing_path"
}

path_is_within() {
    local candidate="$1"
    local parent="$2"
    [[ "$candidate" == "$parent" || "$candidate" == "$parent/"* ]]
}

if [[ -z "$TARGET_SPEC" ]]; then
    TARGET_DIR="$AARP_DIR"
    REVIEW_DIR="$AARP_DIR"
    REPORTS_DIR="$TARGET_DIR"
    AUDIT_DIR="$TARGET_DIR"
else
    if is_remote_target "$TARGET_SPEC"; then
        TARGET_KIND="git-source"
        TARGET_SOURCE="$TARGET_SPEC"
    elif [[ -d "$TARGET_SPEC" ]] &&
        [[ "$(git -C "$TARGET_SPEC" rev-parse --is-bare-repository 2>/dev/null || true)" == "true" ]]; then
        TARGET_KIND="git-source"
        TARGET_SOURCE="$(cd "$TARGET_SPEC" && pwd -P)"
    else
        if [[ ! -d "$TARGET_SPEC" ]]; then
            echo "Target directory not found: ${TARGET_SPEC}" >&2
            exit 1
        fi
        TARGET_KIND="local-checkout"
        TARGET_DIR="$(git -C "$TARGET_SPEC" rev-parse --show-toplevel 2>/dev/null)" ||
            { echo "Target directory is not a Git repository: ${TARGET_SPEC}" >&2; exit 1; }
        TARGET_DIR="$(canonical_path "$TARGET_DIR")"
        TARGET_SOURCE="$TARGET_DIR"
    fi

    TARGET_SLUG="$(target_slug "$TARGET_SOURCE")"
    TARGET_KEY="$(target_hash "${TARGET_KIND}:${TARGET_SOURCE}")"
    if [[ -n "$REVIEW_DIR_OVERRIDE" ]]; then
        REVIEW_DIR="$(canonical_path "$REVIEW_DIR_OVERRIDE")"
    else
        REVIEW_DIR="$(canonical_path "${AARP_DIR}/reviews/${TARGET_SLUG}-${TARGET_KEY}")"
    fi

    if [[ "$TARGET_KIND" == "local-checkout" ]] && path_is_within "$REVIEW_DIR" "$TARGET_DIR"; then
        echo "Review directory must be outside the local target repository: ${REVIEW_DIR}" >&2
        exit 1
    fi
    mkdir -p "$REVIEW_DIR"

    REVIEW_TARGET_MARKER="${REVIEW_DIR}/.aarp-target-key"
    if [[ -f "$REVIEW_TARGET_MARKER" ]] &&
        [[ "$(cat "$REVIEW_TARGET_MARKER")" != "${TARGET_KIND}:${TARGET_KEY}" ]]; then
        echo "Review directory belongs to a different target: ${REVIEW_DIR}" >&2
        exit 1
    fi

    if [[ "$TARGET_KIND" == "git-source" ]]; then
        TARGET_DIR="${REVIEW_DIR}/repository"
        if [[ -e "$TARGET_DIR" ]]; then
            if ! git -C "$TARGET_DIR" rev-parse --show-toplevel >/dev/null 2>&1; then
                echo -e "${RED:-}Review checkout already exists but is not a Git repository: ${TARGET_DIR}${NC:-}" >&2
                exit 1
            fi
            ORIGIN_URL="$(git -C "$TARGET_DIR" remote get-url origin 2>/dev/null || true)"
            if [[ "$ORIGIN_URL" != "$TARGET_SOURCE" ]]; then
                echo -e "${RED:-}Review checkout already exists for a different origin: ${TARGET_DIR}${NC:-}" >&2
                exit 1
            fi
            echo "Reusing existing review checkout: ${TARGET_DIR}"
        else
            echo "Cloning target repository into: ${TARGET_DIR}"
            git clone "$TARGET_SOURCE" "$TARGET_DIR"
        fi
    fi

    REPORTS_DIR="${REVIEW_DIR}/reports"
    mkdir -p "$REPORTS_DIR"

    printf '%s\n' "${TARGET_KIND}:${TARGET_KEY}" > "$REVIEW_TARGET_MARKER"

    # Audit a disposable snapshot so phases 1–3 do not operate in the target
    # checkout. The original target is used only after phase 4 is authorized.
    AUDIT_DIR="${REVIEW_DIR}/source"
    if [[ -e "$AUDIT_DIR" && ! -d "$AUDIT_DIR" ]]; then
        echo "Audit snapshot path is not a directory: ${AUDIT_DIR}" >&2
        exit 1
    fi
    if [[ ! -d "$AUDIT_DIR" ]]; then
        mkdir -p "$AUDIT_DIR"
        tar -C "$TARGET_DIR" --exclude=.git -cf - . | tar -xf - -C "$AUDIT_DIR"
    fi
fi

LOGS_DIR="${REVIEW_DIR}/logs"
mkdir -p "$REPORTS_DIR" "$LOGS_DIR"

CLAUDE_DIR="${AARP_DIR}/.openclaude"
PROMPTS_DIR="${CLAUDE_DIR}/prompts"
TEMPLATES_DIR="${CLAUDE_DIR}/templates"
CONTEXT_TEMPLATE="${TEMPLATES_DIR}/PROJECT_CONTEXT.template.md"
UX_TEMPLATE="${TEMPLATES_DIR}/AUDIT_UX_PERF.template.md"
SECURITY_TEMPLATE="${TEMPLATES_DIR}/AUDIT_APPSEC.template.md"
DATABASE_TEMPLATE="${TEMPLATES_DIR}/AUDIT_DATABASE.template.md"
ROADMAP_TEMPLATE="${TEMPLATES_DIR}/ROADMAP.template.md"

CONTEXT_REPORT="${REPORTS_DIR}/PROJECT_CONTEXT.md"
UX_REPORT="${REPORTS_DIR}/AUDIT_UX_UI.md"
SECURITY_REPORT="${REPORTS_DIR}/AUDIT_SECURITY.md"
DATABASE_REPORT="${REPORTS_DIR}/AUDIT_DB.md"
ROADMAP_REPORT="${REPORTS_DIR}/ROADMAP.md"

# ------------------------------------------------------------------------------
# OPTIMIZATION & CONTEXT CONFIGURATION
# ------------------------------------------------------------------------------

# Inietta la mappatura esatta della context window per evitare fallback conservativi
export CLAUDE_CODE_OPENAI_CONTEXT_WINDOWS='{
  "thinkingmachines/inkling:free": 262144,
  "cohere/north-mini-code:free": 256000,
  "google/gemma-2-9b-it:free": 131072,
  "qwen/qwen-2.5-coder-32b-instruct:free": 131072,
  "anthropic/claude-3.5-sonnet": 200000,
  "deepseek/deepseek-r1": 163840,
  "google/gemini-2.5-flash": 1048576
}'

# Massimizza i token di output generabili per evitare troncatura dei report
export CLAUDE_CODE_OPENAI_MAX_OUTPUT_TOKENS='{
  "thinkingmachines/inkling:free": 8192,
  "cohere/north-mini-code:free": 4096,
  "anthropic/claude-3.5-sonnet": 8192,
  "deepseek/deepseek-r1": 8192,
  "google/gemini-2.5-flash": 8192
}'

# Parametri di stabilità e performance
export OPENAI_TEMPERATURE=0.2
export OPENROUTER_TIMEOUT=300
export OPENROUTER_MAX_RETRIES=3
export NODE_NO_WARNINGS=1
export DISABLE_TELEMETRY=1
export CLAUDE_CODE_DISABLE_BANNER=1

#MODEL_GENERAL="${MODEL_GENERAL:-anthropic/claude-sonnet-5}"
#MODEL_REASONING="${MODEL_REASONING:-deepseek/deepseek-v4-pro}"

#MODEL_GENERAL="${MODEL_GENERAL:-anthropic/claude-3.5-sonnet}"
#MODEL_REASONING="${MODEL_REASONING:-deepseek/deepseek-r1}"

#MODEL_GENERAL="${MODEL_GENERAL:-thinkingmachines/inkling:free}"
#MODEL_REASONING="${MODEL_REASONING:-cohere/north-mini-code:free}"

MODEL_GENERAL="${MODEL_GENERAL:-google/gemini-2.5-flash}"
MODEL_REASONING="${MODEL_REASONING:-google/gemini-2.5-flash}"
# ------------------------------------------------------------------------------
# -START AARP PIPELINE
# ------------------------------------------------------------------------------

echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}   AI MULTI-AGENT ORCHESTRATOR (STATEFUL / RESUME) ${NC}"
echo -e "${CYAN}   AARP Framework: ${AARP_DIR}${NC}"
echo -e "${CYAN}   Target Repository: ${TARGET_DIR}${NC}"
echo -e "${CYAN}   Review Artifacts: ${REPORTS_DIR}${NC}"
echo -e "${CYAN}====================================================${NC}"

# Validazione alberatura e dei template
if [ ! -d "$PROMPTS_DIR" ]; then
  echo -e "${RED}Errore Critico: Directory prompt non trovata in: ${PROMPTS_DIR}${NC}"
  exit 1
fi

for required_file in \
    "$CONTEXT_TEMPLATE" \
    "$UX_TEMPLATE" \
    "$SECURITY_TEMPLATE" \
    "$DATABASE_TEMPLATE" \
    "$ROADMAP_TEMPLATE"; do
    if [ ! -f "$required_file" ]; then
        echo -e "${RED}Errore Critico: Template richiesto non trovato: ${required_file}${NC}"
        exit 1
    fi
done

source "${AARP_DIR}/scripts/report_validation.sh"

# Agents inspect the isolated audit snapshot, while framework files remain in
# AARP_DIR and the target checkout remains untouched until phase 4 is approved.
cd "$AUDIT_DIR"

# ------------------------------------------------------------------------------
# FASE 1: Context Mapping (Architect Agent)
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}[FASE 1/4] Context Mapping...${NC}"

if validate_report "$CONTEXT_REPORT" "PROJECT_CONTEXT.md" "$CONTEXT_TEMPLATE" \
    "# Project Context & Architectural Blueprint" \
    "## 1. Tech Stack & Core Services" \
    "## 2. Architecture & Data Flow" \
    "## 3. Critical Path, Blind Spots & Technical Debt"; then
    echo -e "${GREEN}✓ [SKIP] PROJECT_CONTEXT.md già presente. Ripresa dallo stato salvato.${NC}"
else
    echo -e "${CYAN}--> Spawning Architect Agent (${MODEL_GENERAL})...${NC}"

        echo "Esamina l'intera alberatura dello snapshot del repository target, i file di configurazione e la struttura. Leggi il template allegato ${CONTEXT_TEMPLATE}, usalo come struttura obbligatoria, sostituisci tutti i placeholder con informazioni verificate e genera il report completo in ${CONTEXT_REPORT}. Non creare o modificare file del framework AARP o del repository target. Se esiste già un report incompleto, sovrascrivilo con il report completo." | \
        openclaude --print --dangerously-skip-permissions --model "$MODEL_GENERAL" \
            --file "${PROMPTS_DIR}/mapping.md" \
            --file "$CONTEXT_TEMPLATE" \
	    --add-dir "$AARP_DIR" --add-dir "$REVIEW_DIR"

    validate_report "$CONTEXT_REPORT" "PROJECT_CONTEXT.md" "$CONTEXT_TEMPLATE" \
        "# Project Context & Architectural Blueprint" \
        "## 1. Tech Stack & Core Services" \
        "## 2. Architecture & Data Flow" \
        "## 3. Critical Path, Blind Spots & Technical Debt" || exit 1
    echo -e "${GREEN}✓ FASE 1 Completata: PROJECT_CONTEXT.md generato.${NC}"
fi

# ------------------------------------------------------------------------------
# FASE 2: Deep Audit (Specialist Agents in Parallel)
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}[FASE 2/4] Spawning Specialists Parallels Agents...${NC}"
pids=()

# 2.1 Audit UX/UI
if validate_report "$UX_REPORT" "AUDIT_UX_UI.md" "$UX_TEMPLATE" \
    "# UX/UI & Front-End Performance Audit Report:" \
    "## Executive UX & Performance Summary" \
    "## Detailed Findings & Accessibility Audit" \
    "## Verification Checklist"; then
    echo -e "${GREEN}✓ [SKIP] AUDIT_UX_UI.md già presente.${NC}"
else
    echo -e "${CYAN}--> Launching UX/UI Agent (${MODEL_GENERAL})...${NC}"
    (
        echo "Leggi ${CONTEXT_REPORT} e i componenti UI dello snapshot del repository target. Leggi il template allegato ${UX_TEMPLATE}, usalo come struttura obbligatoria, sostituisci i placeholder e salva il report completo in ${UX_REPORT}. Non creare o modificare file del framework AARP o del repository target." | \
        openclaude --print --dangerously-skip-permissions --model "$MODEL_GENERAL" \
            --file "${PROMPTS_DIR}/ux-ui.md" \
            --file "$UX_TEMPLATE" \
	    --add-dir "$AARP_DIR" --add-dir "$REVIEW_DIR"
        validate_report "$UX_REPORT" "AUDIT_UX_UI.md" "$UX_TEMPLATE" \
            "# UX/UI & Front-End Performance Audit Report:" \
            "## Executive UX & Performance Summary" \
            "## Detailed Findings & Accessibility Audit" \
            "## Verification Checklist"
    ) > "${LOGS_DIR}/audit_ux.log" 2>&1 &
    pids+=($!)
fi

# 2.2 Audit Security
if validate_report "$SECURITY_REPORT" "AUDIT_SECURITY.md" "$SECURITY_TEMPLATE" \
    "# AppSec Audit Report:" \
    "## Executive Security Summary" \
    "## Detailed Vulnerability Findings" \
    "## Security Verification & Next Steps"; then
    echo -e "${GREEN}✓ [SKIP] AUDIT_SECURITY.md già presente.${NC}"
else
    echo -e "${CYAN}--> Launching Security Agent (${MODEL_REASONING})...${NC}"
    (
        echo "Leggi ${CONTEXT_REPORT} e le rotte/controller backend dello snapshot del repository target. Leggi il template AppSec allegato ${SECURITY_TEMPLATE}, usalo come struttura obbligatoria, sostituisci i placeholder e salva il report completo in ${SECURITY_REPORT}. Non creare o modificare file del framework AARP o del repository target." | \
        openclaude --print --dangerously-skip-permissions --model "$MODEL_REASONING" \
            --file "${PROMPTS_DIR}/security.md" \
            --file "$SECURITY_TEMPLATE" \
	    --add-dir "$AARP_DIR" --add-dir "$REVIEW_DIR"
        validate_report "$SECURITY_REPORT" "AUDIT_SECURITY.md" "$SECURITY_TEMPLATE" \
            "# AppSec Audit Report:" \
            "## Executive Security Summary" \
            "## Detailed Vulnerability Findings" \
            "## Security Verification & Next Steps"
    ) > "${LOGS_DIR}/audit_sec.log" 2>&1 &
    pids+=($!)
fi

# 2.3 Audit DB & Storage
if validate_report "$DATABASE_REPORT" "AUDIT_DB.md" "$DATABASE_TEMPLATE" \
    "# Database & Storage Audit Report:" \
    "## Executive Database Summary" \
    "## Detailed Performance & Storage Findings" \
    "## Verification Checklist"; then
    echo -e "${GREEN}✓ [SKIP] AUDIT_DB.md già presente.${NC}"
else
    echo -e "${CYAN}--> Launching DB Agent (${MODEL_REASONING})...${NC}"
    (
        echo "Leggi ${CONTEXT_REPORT} e gli schemi DB dello snapshot del repository target. Leggi il template allegato ${DATABASE_TEMPLATE}, usalo come struttura obbligatoria, sostituisci i placeholder e salva il report completo in ${DATABASE_REPORT}. Non limitarti a descrivere un report esistente: aggiorna direttamente il file. Se trovi finding DB, calcola la tabella Executive dai finding dettagliati: ogni riga P0/P1/P2 deve riportare i conteggi per categoria e il totale, e la somma dei totali deve coincidere con il numero di finding. Mantieni tutti zero solo se non esistono finding e spiega esplicitamente il perimetro senza database. Non creare o modificare file del framework AARP o del repository target." | \
        openclaude --print --dangerously-skip-permissions --model "$MODEL_REASONING" \
            --file "${PROMPTS_DIR}/db-specialist.md" \
            --file "$DATABASE_TEMPLATE" \
	    --add-dir "$AARP_DIR" --add-dir "$REVIEW_DIR"
        validate_report "$DATABASE_REPORT" "AUDIT_DB.md" "$DATABASE_TEMPLATE" \
            "# Database & Storage Audit Report:" \
            "## Executive Database Summary" \
            "## Detailed Performance & Storage Findings" \
            "## Verification Checklist"
    ) > "${LOGS_DIR}/audit_db.log" 2>&1 &
    pids+=($!)
fi

# Sincronizzazione dei job lanciati in questa esecuzione
if [ ${#pids[@]} -gt 0 ]; then
    echo -e "${YELLOW}In attesa del completamento degli agenti attivi (${#pids[@]})...${NC}"
    for pid in "${pids[@]}"; do
        wait "$pid" || { echo -e "${RED}Errore durante l'esecuzione dell'agente PID $pid. Controlla i log in ${LOGS_DIR}${NC}"; exit 1; }
    done
fi

echo -e "\n${YELLOW}[FASE 2] Completata: Tutti i report di settore sono stati generati.${NC}"

# ------------------------------------------------------------------------------
# FASE 3: Sintesi e Backlog (Engineering Director Agent)
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}[FASE 3/4] Sintesi e Generazione Roadmap...${NC}"

if validate_report "$ROADMAP_REPORT" "ROADMAP.md" "$ROADMAP_TEMPLATE" \
    "# Target Release:" \
    "## 🚨 P0 Priority — Critical Blockers & Vulnerabilities" \
    "## ⚡ P1 Priority — Core Features & Architecture Improvements" \
    "## 🛠️ P2 Priority — Code Optimizations & Tech Debt" \
    "## 📊 Status Tracking Checklist"; then
    echo -e "${GREEN}✓ [SKIP] ROADMAP.md già presente.${NC}"
else
    echo -e "${CYAN}--> Spawning Engineering Director Agent (${MODEL_GENERAL})...${NC}"
    echo "Agisci come Engineering Director. Leggi ${CONTEXT_REPORT}, ${UX_REPORT}, ${SECURITY_REPORT} e ${DATABASE_REPORT}. Leggi il template allegato ${ROADMAP_TEMPLATE}, usalo come struttura obbligatoria, sostituisci i placeholder e sintetizza tutti i rilievi nel report ${ROADMAP_REPORT}, dividendo i task in P0 (Bloccanti/Sicurezza), P1 (Architettura) e P2 (Debito tecnico). Per ciascun task specifica: Ruolo, File interessati, Impatto ed Effort (XS/S/M/L). Non creare o modificare file del framework AARP o del repository target." | \
    openclaude --print --dangerously-skip-permissions --model "$MODEL_GENERAL" --file "$ROADMAP_TEMPLATE" --add-dir "$AARP_DIR" --add-dir "$REVIEW_DIR"

    validate_report "$ROADMAP_REPORT" "ROADMAP.md" "$ROADMAP_TEMPLATE" \
        "# Target Release:" \
        "## 🚨 P0 Priority — Critical Blockers & Vulnerabilities" \
        "## ⚡ P1 Priority — Core Features & Architecture Improvements" \
        "## 🛠️ P2 Priority — Code Optimizations & Tech Debt" \
        "## 📊 Status Tracking Checklist" || exit 1
    echo -e "${GREEN}✓ FASE 3 Completata: ROADMAP.md generata.${NC}"
fi

# ------------------------------------------------------------------------------
# HUMAN-IN-THE-LOOP CHECKPOINT
# ------------------------------------------------------------------------------
echo -e "\n${CYAN}====================================================${NC}"
echo -e "${YELLOW}   PAUSA OPERATIVA: HUMAN-IN-THE-LOOP CHECKPOINT    ${NC}"
echo -e "${CYAN}====================================================${NC}"
echo -e "Tutti i report e la ROADMAP.md sono pronti."
echo -e "Ispeziona ${GREEN}${ROADMAP_REPORT}${NC} prima di procedere con le remediation.\n"

read -p "Vuoi autorizzare la Fase 4 per la risoluzione progressiva della ROADMAP? (s/N): " confirm

if [[ "$confirm" != "s" && "$confirm" != "S" ]]; then
  echo -e "${YELLOW}Orchestrazione messa in pausa. Puoi rilanciare il comando in qualsiasi momento per riprendere dal checkpoint.${NC}"
  exit 0
fi

# ------------------------------------------------------------------------------
# FASE 4: Remediation Tasks (Optional Trigger)
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}[FASE 4/4] Ciclo Interattivo Remediation...${NC}"

MAIN_BRANCH="release/v2.0.0"
source "${AARP_DIR}/scripts/roadmap_helpers.sh"
TARGET_PREPARED=false
SKIPPED_TASK_IDS=()


while true; do
    SKIPPED_TASKS_CSV="$(IFS=,; printf '%s' "${SKIPPED_TASK_IDS[*]}")"
    TASK_PREVIEW="$(roadmap_next_task_preview "$SKIPPED_TASKS_CSV" || true)"
    if [[ -z "$TASK_PREVIEW" ]]; then
        if ((${#SKIPPED_TASK_IDS[@]} > 0)); then
            echo -e "${YELLOW}Nessun altro task disponibile in questa esecuzione. Task saltati: ${SKIPPED_TASK_IDS[*]}. Rilanciare per riprenderli.${NC}"
        else
            echo -e "${GREEN}Nessun task P0/P1/P2 aperto nella ROADMAP.md. Fase 4 completata.${NC}"
        fi
        break
    fi

    TASK_ID="$(roadmap_task_id_from_preview "$TASK_PREVIEW" || true)"
    TASK_PRIORITY="$(roadmap_task_priority_from_id "$TASK_ID" || true)"
    TASK_BRANCH_PREFIX="$(roadmap_task_branch_prefix "$TASK_PRIORITY" || true)"
    if [[ -z "$TASK_ID" || -z "$TASK_PRIORITY" || -z "$TASK_BRANCH_PREFIX" ]]; then
        echo -e "${RED}Impossibile identificare priorità, task o branch nella ROADMAP.md; remediation sospesa.${NC}" >&2
        break
    fi

    echo -e "\n${CYAN}----------------------------------------------------${NC}"
    echo -e "${YELLOW}Prossima remediation ${TASK_PRIORITY} individuata:${NC}"
    echo -e "${TASK_PREVIEW}"
    if ! read -r -p "Azione per ${TASK_ID}: [s]ì / [skip] / [exit] (default: exit): " task_action; then
        task_action="exit"
    fi
    case "${task_action,,}" in
        s|si|sì|y|yes)
            ;;
        skip|k)
            SKIPPED_TASK_IDS+=("$TASK_ID")
            echo -e "${YELLOW}${TASK_ID} saltato per questa esecuzione; ROADMAP.md resta invariata.${NC}"
            continue
            ;;
        exit|e|"")
            echo -e "${YELLOW}Orchestrazione interrotta. ${TASK_ID} verrà riproposto al prossimo avvio.${NC}"
            break
            ;;
        *)
            echo -e "${YELLOW}Scelta non riconosciuta: usare s, skip oppure exit.${NC}"
            continue
            ;;
    esac

    # Keep the previewed roadmap even when the legacy in-place workflow checks
    # out a branch that contains a different ROADMAP.md version.
    ROADMAP_BACKUP="$(mktemp)"
    cp "$ROADMAP_REPORT" "$ROADMAP_BACKUP"

    # The target is writable only after both human approvals.
    if [[ "$TARGET_PREPARED" == false ]]; then
        if ! cd "$TARGET_DIR"; then
            cp "$ROADMAP_BACKUP" "$ROADMAP_REPORT"
            rm -f "$ROADMAP_BACKUP"
            echo -e "${RED}Impossibile accedere al repository target; ROADMAP.md ripristinata.${NC}" >&2
            exit 1
        fi
        git config user.name >/dev/null 2>&1 ||
            git config user.name "AARP AI Agent"
        git config user.email >/dev/null 2>&1 ||
            git config user.email "agent@aarp.ai"
        if ! git checkout "$MAIN_BRANCH" >/dev/null 2>&1; then
            cp "$ROADMAP_BACKUP" "$ROADMAP_REPORT"
            rm -f "$ROADMAP_BACKUP"
            echo -e "${RED}Impossibile passare al branch ${MAIN_BRANCH}; ROADMAP.md ripristinata.${NC}" >&2
            exit 1
        fi
        TARGET_PREPARED=true
    fi

    echo -e "${CYAN}--> Invocazione Agent per ${TASK_ID} (${TASK_PRIORITY})...${NC}"

    # La roadmap viene aggiornata deterministicamente dall'orchestratore dopo
    # il merge; l'agente deve limitarsi alla remediation e al commit.
    if ! echo "Leggi ${ROADMAP_REPORT}. Esegui esclusivamente il task ${TASK_ID} (${TASK_PRIORITY}) appena confermato. Crea il branch ${TASK_BRANCH_PREFIX}<task-name> corrispondente nel repository target, applica la fix o implementa il cambiamento richiesto e fai il git commit. Non modificare ${ROADMAP_REPORT} e non modificare file del framework AARP." | \
        openclaude --print --dangerously-skip-permissions --model "$MODEL_GENERAL" --add-dir "$AARP_DIR" --add-dir "$REVIEW_DIR"; then
        cp "$ROADMAP_BACKUP" "$ROADMAP_REPORT"
        rm -f "$ROADMAP_BACKUP"
        echo -e "${RED}Errore durante la remediation di ${TASK_ID}; ROADMAP.md ripristinata.${NC}" >&2
        exit 1
    fi

    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)

    # L'agente deve rimanere sul prefisso coerente con la priorità confermata.
    if [[ "$CURRENT_BRANCH" == "${TASK_BRANCH_PREFIX}"* ]]; then
        echo -e "\n${GREEN}✓ Task completato sul branch: ${CURRENT_BRANCH}${NC}"

        if ! read -r -p "Vuoi pubblicare '$CURRENT_BRANCH' per testarlo prima del merge? (s/N): " do_task_push; then
            do_task_push="n"
        fi
        if [[ "$do_task_push" == "s" || "$do_task_push" == "S" ]]; then
            echo -e "${CYAN}--> Esecuzione git push origin $CURRENT_BRANCH...${NC}"
            if ! git push --set-upstream origin "$CURRENT_BRANCH"; then
                cp "$ROADMAP_BACKUP" "$ROADMAP_REPORT"
                rm -f "$ROADMAP_BACKUP"
                echo -e "${RED}Push del branch task fallito; ${ROADMAP_REPORT} resta invariata.${NC}" >&2
                exit 1
            fi
            echo -e "${GREEN}✓ Branch ${CURRENT_BRANCH} pubblicato per il test.${NC}"
        else
            echo -e "${YELLOW}Branch task non pubblicato; puoi comunque procedere con il merge locale.${NC}"
        fi

        if ! read -r -p "Vuoi fare il MERGE automatico di '$CURRENT_BRANCH' su '$MAIN_BRANCH'? (S/n): " do_merge; then
            do_merge="n"
        fi
        if [[ "$do_merge" != "n" && "$do_merge" != "N" ]]; then
            if ! git checkout "$MAIN_BRANCH"; then
                cp "$ROADMAP_BACKUP" "$ROADMAP_REPORT"
                rm -f "$ROADMAP_BACKUP"
                echo -e "${RED}Impossibile passare al branch ${MAIN_BRANCH}; ROADMAP.md ripristinata.${NC}" >&2
                exit 1
            fi
            if ! git merge "$CURRENT_BRANCH" --no-ff -m "Merge branch '$CURRENT_BRANCH' into $MAIN_BRANCH"; then
                cp "$ROADMAP_BACKUP" "$ROADMAP_REPORT"
                rm -f "$ROADMAP_BACKUP"
                echo -e "${RED}Merge fallito; ROADMAP.md ripristinata.${NC}" >&2
                exit 1
            fi
            cp "$ROADMAP_BACKUP" "$ROADMAP_REPORT"
            if ! mark_roadmap_task_merged "$TASK_ID"; then
                rm -f "$ROADMAP_BACKUP"
                echo -e "${RED}Merge completato, ma non è stato possibile aggiornare ${ROADMAP_REPORT} per ${TASK_ID}.${NC}" >&2
                exit 1
            fi
            rm -f "$ROADMAP_BACKUP"
            echo -e "${GREEN}✓ Merge completato su $MAIN_BRANCH${NC}"
            echo -e "${GREEN}✓ ${TASK_ID} marcato come Merged in ${ROADMAP_REPORT}${NC}"
        else
            cp "$ROADMAP_BACKUP" "$ROADMAP_REPORT"
            rm -f "$ROADMAP_BACKUP"
            echo -e "${YELLOW}Merge rifiutato; ${ROADMAP_REPORT} resta invariata. Il branch ${CURRENT_BRANCH} resta disponibile per il test o il rollback.${NC}"
            break
        fi

        read -p "Vuoi fare il PUSH su GitHub ($MAIN_BRANCH) per testare sul server di test? (s/N): " do_push
        if [[ "$do_push" == "s" || "$do_push" == "S" ]]; then
            echo -e "${CYAN}--> Esecuzione git push origin $MAIN_BRANCH...${NC}"
            git push origin "$MAIN_BRANCH"
            echo -e "${GREEN}✓ Push completato con successo! Il codice è ora online sul repository Remote.${NC}"
        fi
    else
        cp "$ROADMAP_BACKUP" "$ROADMAP_REPORT"
        rm -f "$ROADMAP_BACKUP"
        echo -e "${YELLOW}Nessun branch ${TASK_BRANCH_PREFIX} creato. Verificare la remediation di ${TASK_ID}; roadmap invariata.${NC}"
    fi
done
