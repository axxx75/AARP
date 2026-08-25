#!/usr/bin/env bash

roadmap_next_task_preview() {
    local skipped_ids="${1:-}"

    awk -v skipped_ids="$skipped_ids" '
        function task_id_from_text(text, normalized) {
            normalized = text
            gsub(/\*\*/, "", normalized)
            if (match(normalized, /TASK-P[012][-A-Za-z0-9_]+/)) {
                return substr(normalized, RSTART, RLENGTH)
            }
            return ""
        }

        function is_skipped(task_id, count, ids, i) {
            if (skipped_ids == "") {
                return 0
            }
            count = split(skipped_ids, ids, ",")
            for (i = 1; i <= count; i++) {
                if (ids[i] == task_id) {
                    return 1
                }
            }
            return 0
        }

        function task_priority_from_text(text, normalized, id) {
            id = task_id_from_text(text)
            if (id == "") {
                return -1
            }
            normalized = id
            if (normalized ~ /TASK-P0-/) return 0
            if (normalized ~ /TASK-P1-/) return 1
            if (normalized ~ /TASK-P2-/) return 2
            return -1
        }

        function is_unresolved_task() {
            return $0 ~ /^[[:space:]]*-[[:space:]]*\[[[:space:]]\]/ &&
                task_priority_from_text($0) >= 0
        }

        /^## / {
            capture_priority = -1
            in_p0 = ($0 ~ /P0/)
            in_p1 = ($0 ~ /P1/)
            in_p2 = ($0 ~ /P2/)
            in_status = ($0 ~ /Status Tracking/ || $0 ~ /Checklist/)
            if (in_p0) {
                section_priority = 0
            } else if (in_p1) {
                section_priority = 1
            } else if (in_p2) {
                section_priority = 2
            } else {
                section_priority = -1
            }
            next
        }

        capture_priority >= 0 {
            if ($0 ~ /^---/ || $0 ~ /^[[:space:]]*-[[:space:]]*\[/ ||
                $0 ~ /^\|/) {
                capture_priority = -1
            } else if (candidate_effort[capture_priority] == "" &&
                $0 ~ /[Ee]ffort/) {
                candidate_effort[capture_priority] = $0
            }
        }

        is_unresolved_task() && section_priority >= 0 {
            priority = task_priority_from_text($0)
            task_id = task_id_from_text($0)
            if (candidate_line[priority] == "" && !is_skipped(task_id)) {
                candidate_line[priority] = $0
                candidate_id[priority] = task_id_from_text($0)
                capture_priority = priority
            }
            next
        }

        in_status && /^\|/ && /TASK-P[012][-A-Za-z0-9_]+/ &&
            $0 ~ /[Pp]ending|[Ii]n-[Pp]rogress|[Rr]eview/ {
            priority = task_priority_from_text($0)
            task_id = task_id_from_text($0)
            if (priority >= 0 && candidate_line[priority] == "" &&
                !is_skipped(task_id)) {
                candidate_line[priority] = $0
                candidate_id[priority] = task_id
            }
        }

        END {
            for (priority = 0; priority <= 2; priority++) {
                if (candidate_line[priority] != "") {
                    print candidate_line[priority]
                    if (candidate_effort[priority] != "") {
                        print candidate_effort[priority]
                    }
                    exit 0
                }
            }
            exit 1
        }
    ' "$ROADMAP_REPORT"
}

roadmap_task_id_from_preview() {
    printf '%s\n' "$1" | grep -oE 'TASK-P[012][-A-Za-z0-9_]+' | head -n 1
}

roadmap_task_priority_from_id() {
    case "$1" in
        TASK-P0-*) printf 'P0\n' ;;
        TASK-P1-*) printf 'P1\n' ;;
        TASK-P2-*) printf 'P2\n' ;;
        *) return 1 ;;
    esac
}

roadmap_task_branch_prefix() {
    case "$1" in
        P0) printf 'fix/p0-\n' ;;
        P1) printf 'feat/p1-\n' ;;
        P2) printf 'refactor/p2-\n' ;;
        *) return 1 ;;
    esac
}

mark_roadmap_task_merged() {
    local task_id="$1"
    local temp_path="${ROADMAP_REPORT}.tmp.$$"

    if [[ ! -f "$ROADMAP_REPORT" ]]; then
        return 1
    fi

    if ! awk -v task_id="$task_id" '
        function task_id_from_text(text, normalized) {
            normalized = text
            gsub(/\*\*/, "", normalized)
            if (match(normalized, /TASK-P[012][-A-Za-z0-9_]+/)) {
                return substr(normalized, RSTART, RLENGTH)
            }
            return ""
        }

        {
            if ($0 ~ /^[[:space:]]*-[[:space:]]*\[[[:space:]]\]/ &&
                task_id_from_text($0) == task_id) {
                found = 1
                sub(/\[[[:space:]]\]/, "[x]")
            }

            if ($0 ~ /^\|/) {
                cell_count = split($0, cells, "|")
                if (cell_count > 2 && task_id_from_text(cells[2]) == task_id) {
                    found = 1
                    for (i = 2; i < cell_count; i++) {
                        if (cells[i] ~ /[Pp]ending|[Ii]n-[Pp]rogress|[Rr]eview/) {
                            cells[i] = " Merged "
                            rebuilt = ""
                            for (j = 1; j <= cell_count; j++) {
                                rebuilt = rebuilt cells[j]
                                if (j < cell_count) {
                                    rebuilt = rebuilt "|"
                                }
                            }
                            $0 = rebuilt
                            break
                        }
                    }
                }
            }
            print
        }

        END {
            if (!found) {
                exit 1
            }
        }
    ' "$ROADMAP_REPORT" > "$temp_path"; then
        rm -f "$temp_path"
        return 1
    fi

    mv "$temp_path" "$ROADMAP_REPORT"
}