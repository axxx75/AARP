#!/usr/bin/env bash
set -euo pipefail

# ------------------------------------------------------------------------------
# CONFIGURAZIONE AMBIENTE & PARAMETRI AVANZATI
# ------------------------------------------------------------------------------
export OPENCLAUDE_PROVIDER="openrouter"
export CLAUDE_CODE_OPENAI_CONTEXT_WINDOWS='{"thinkingmachines/inkling:free": 262144, "cohere/north-mini-code:free": 256000}'
export CLAUDE_CODE_OPENAI_MAX_OUTPUT_TOKENS='{"thinkingmachines/inkling:free": 8192, "cohere/north-mini-code:free": 4096}'

export OPENAI_TEMPERATURE=0.2
export OPENROUTER_TIMEOUT=300
export OPENROUTER_MAX_RETRIES=3
export NODE_NO_WARNINGS=1
export DISABLE_TELEMETRY=1

#MODEL_REASONING="${MODEL_REASONING:-google/gemini-2.5-flash}"
MODEL_REASONING="${MODEL_REASONING:-cohere/north-mini-code:free}"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOGS_DIR="${PROJECT_DIR}/logs"

mkdir -p "$LOGS_DIR"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${CYAN}====================================================${NC}"
echo -e "${CYAN}   AI REGRESSION DEBUGGER & AUTO-REMEDY             ${NC}"
echo -e "${CYAN}   Project Root: ${PROJECT_DIR}${NC}"
echo -e "${CYAN}====================================================${NC}"

# Assicura identità Git
git config user.name "SANForge AI Agent" >/dev/null 2>&1 || true
git config user.email "agent@sanforge.ai" >/dev/null 2>&1 || true

# ------------------------------------------------------------------------------
# INPUT ERRORE E PREPARAZIONE DIFF RECENTI
# ------------------------------------------------------------------------------
ERROR_INPUT="${1:-}"
if [ -z "$ERROR_INPUT" ]; then
    echo -e "${YELLOW}Incolla la descrizione dell'errore / test fallito (premi Ctrl+D al termine):${NC}"
    ERROR_INPUT=$(cat)
fi

if [ -z "$ERROR_INPUT" ]; then
    echo -e "${RED}Nessun errore fornito. Interruzione.${NC}"
    exit 1
fi

# Salva il patch nella directory di progetto per garantire i permessi
GIT_DIFF_FILE="${LOGS_DIR}/recent_commits.patch"
git log -p -n 3 > "$GIT_DIFF_FILE"

PROMPT_TEXT="È stato riscontrato un fallimento nei test o un errore a runtime a seguito delle recenti modifiche.

DESCRIZIONE ERRORE / TEST NEGATIVO:
$ERROR_INPUT

ISTRUZIONI:
1. Analizza i diff forniti nel file allegato recent_commits.patch per individuare quale commit o riga ha introdotto la regressione.
2. Presenta prima un piano sintetico di risoluzione.
3. Applica direttamente la correzione sui file sorgente coinvolti (es. db_manager.py).
4. Esegui il commit delle modifiche con messaggio 'fix(regression): <dettaglio_errore>'."

# ------------------------------------------------------------------------------
# ESECUZIONE DIRETTA AGENTE
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}[REGRESSION RECOVERY] Avvio analisi ed esecuzione agente...${NC}\n"

EXTRA_FILES=()
[ -f "${PROJECT_DIR}/PROJECT_CONTEXT.md" ] && EXTRA_FILES+=(--file "${PROJECT_DIR}/PROJECT_CONTEXT.md")
[ -f "${PROJECT_DIR}/ROADMAP.md" ]         && EXTRA_FILES+=(--file "${PROJECT_DIR}/ROADMAP.md")
[ -f "$GIT_DIFF_FILE" ]                     && EXTRA_FILES+=(--file "$GIT_DIFF_FILE")

echo "$PROMPT_TEXT" | openclaude --dangerously-skip-permissions --model "$MODEL_REASONING" "${EXTRA_FILES[@]}"

echo -e "\n${GREEN}✓ Procedura di ripristino completata. Stato repository:${NC}"
git status -s
