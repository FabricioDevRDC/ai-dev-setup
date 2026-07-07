#!/usr/bin/env bash
# RDC-OS 2.0 — model routing resolver
# Reads templates/model-routing.json and stamps each installed command's
# frontmatter `model:` from its declared work TIER, for the active provider.
#
# This is the mechanism behind Fix #1 (model independence): commands carry a
# semantic tier (mechanical/execution/reasoning), never a hardcoded model.
# Changing model or provider = edit model-routing.json + re-run, not a rewrite.
#
# Usage:
#   apply_model_routing [provider]      # provider defaults to $MODEL_PROVIDER or the map's default_provider

source "$(dirname "${BASH_SOURCE[0]}")/colors.sh" 2>/dev/null || true

apply_model_routing() {
  local script_dir routing commands_dir provider
  script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
  routing="$script_dir/templates/model-routing.json"
  commands_dir="$HOME/.claude/commands"

  if ! command -v jq &>/dev/null; then
    warn "jq not found — skipping model routing (commands keep their current model)."
    return 0
  fi
  [[ -f "$routing" ]] || { warn "model-routing.json missing — skipping."; return 0; }

  # provider precedence: arg > $MODEL_PROVIDER > map default
  provider="${1:-${MODEL_PROVIDER:-$(jq -r '.default_provider' "$routing")}}"

  step "Applying model routing (provider: $provider)"

  local applied=0
  # iterate command -> tier from the map
  while IFS=$'\t' read -r cmd tier; do
    local file="$commands_dir/$cmd.md"
    [[ -f "$file" ]] || continue

    local model
    model=$(jq -r --arg t "$tier" --arg p "$provider" '.tiers[$t][$p] // empty' "$routing")
    if [[ -z "$model" ]]; then
      warn "  $cmd: no model for tier '$tier' + provider '$provider' — left unchanged"
      continue
    fi

    # Rewrite (or insert) the `model:` line inside the leading frontmatter block.
    # Keep the `tier:` line as the source of truth; model is derived.
    if head -1 "$file" | grep -q '^---'; then
      # has frontmatter — replace the model: line, ensure a tier: line exists
      awk -v model="$model" -v tier="$tier" '
        NR==1 && $0=="---" { print; infm=1; seenmodel=0; seentier=0; next }
        infm && /^model:/  { print "model: " model; seenmodel=1; next }
        infm && /^tier:/   { print "tier: " tier;  seentier=1;  next }
        infm && $0=="---" {
          if (!seentier) print "tier: " tier
          if (!seenmodel) print "model: " model
          infm=0; print; next
        }
        { print }
      ' "$file" > "$file.tmp" && mv "$file.tmp" "$file"
    else
      # no frontmatter — prepend one
      { printf -- "---\ntier: %s\nmodel: %s\n---\n\n" "$tier" "$model"; cat "$file"; } > "$file.tmp" && mv "$file.tmp" "$file"
    fi
    ((applied++))
  done < <(jq -r '.command_tiers | to_entries[] | "\(.key)\t\(.value)"' "$routing")

  ok "Model routing applied to $applied command(s) for provider '$provider'"
  info "Change provider/model in templates/model-routing.json, then: ./install.sh --route [provider]"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  apply_model_routing "$@"
fi
