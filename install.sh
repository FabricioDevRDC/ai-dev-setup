#!/usr/bin/env bash
# ai-dev-setup — Automated developer environment setup
# https://github.com/FabricioDevRDC/ai-dev-setup
#
# Usage:
#   ./install.sh              Full interactive setup
#   ./install.sh --check      Check dependencies only
#   ./install.sh --commands   Install/update Claude commands only
#   ./install.sh --hooks      Install git hooks only (for current repo)
#   ./install.sh --configure  Re-run configuration wizard
#   ./install.sh --update     Pull latest and reinstall commands

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/lib/colors.sh"

# ─── Banner ────────────────────────────────────────────────────────────────────

print_banner() {
  echo ""
  echo -e "${BOLD}${CYAN}"
  echo "  ┌─────────────────────────────────────────┐"
  echo "  │         ai-dev-setup  v2.0.0            │"
  echo "  │   AI-powered developer environment      │"
  echo "  │  github.com/FabricioDevRDC/ai-dev-setup  │"
  echo "  └─────────────────────────────────────────┘"
  echo -e "${NC}"
}

# ─── Hook installer ────────────────────────────────────────────────────────────

install_hooks() {
  local target="${1:-local}"   # "local" or "global"

  step "Installing git hooks ($target)"

  if [[ "$target" == "global" ]]; then
    local hooks_dir="$HOME/.git-hooks"
    mkdir -p "$hooks_dir"
    git config --global core.hooksPath "$hooks_dir"
    local dest="$hooks_dir"
    info "Global hooks path set to $hooks_dir"
  else
    # Check we're inside a git repo
    if ! git rev-parse --git-dir &>/dev/null; then
      warn "Not inside a git repository — skipping local hook installation."
      warn "cd into your project first, then run: ./install.sh --hooks"
      return 1
    fi
    local dest
    dest="$(git rev-parse --git-dir)/hooks"
  fi

  for hook in "$SCRIPT_DIR/hooks/"*; do
    local name
    name=$(basename "$hook")
    cp "$hook" "$dest/$name"
    chmod +x "$dest/$name"
    ok "Hook installed: $name → $dest/$name"
  done
}

# ─── CLAUDE.md generator ───────────────────────────────────────────────────────

generate_claude_md() {
  source "$HOME/.dev-setup-config" 2>/dev/null || true

  if [[ ! -f "CLAUDE.md" ]]; then
    step "Generating CLAUDE.md"

    local project_name
    project_name=$(basename "$(pwd)")
    local branch_pattern="${BRANCH_PATTERN:-{username}/{ticket}/{description}}"

    sed \
      -e "s/{{PROJECT_NAME}}/$project_name/g" \
      -e "s/{{PROJECT_DESCRIPTION}}/Add project description here./g" \
      -e "s/{{LANGUAGE}}/Python/g" \
      -e "s/{{FRAMEWORK}}/Flask/g" \
      -e "s/{{CI_CD}}/GitHub Actions/g" \
      -e "s/{{CLOUD}}/AWS/g" \
      -e "s|{{BRANCH_PATTERN}}|$branch_pattern|g" \
      "$SCRIPT_DIR/templates/CLAUDE.md.template" > CLAUDE.md

    ok "CLAUDE.md created in $(pwd)"
  else
    dim "      CLAUDE.md already exists — skipping."
  fi
}

# ─── Apply git config ──────────────────────────────────────────────────────────

apply_git_config() {
  source "$HOME/.dev-setup-config" 2>/dev/null || true

  step "Applying git configuration"

  [[ -n "$GIT_NAME" ]]  && git config --global user.name  "$GIT_NAME"  && ok "user.name  = $GIT_NAME"
  [[ -n "$GIT_EMAIL" ]] && git config --global user.email "$GIT_EMAIL" && ok "user.email = $GIT_EMAIL"

  # Sensible global defaults
  git config --global push.default current
  git config --global pull.rebase false
  git config --global init.defaultBranch main
  git config --global core.autocrlf input
  git config --global rebase.autoStash true
  ok "Global git defaults applied"
}

# ─── Full setup ────────────────────────────────────────────────────────────────

full_setup() {
  source "$SCRIPT_DIR/lib/check-deps.sh"
  source "$SCRIPT_DIR/lib/configure.sh"
  source "$SCRIPT_DIR/lib/install-commands.sh"

  print_banner

  # 1. Check dependencies
  run_checks || {
    echo ""
    fail "Fix missing required tools above, then re-run setup."
    exit 1
  }

  # 2. Configure
  run_configure
  source "$HOME/.dev-setup-config"

  # 3. Apply git config
  apply_git_config

  # 4. Install Claude commands
  if [[ "$INSTALL_COMMANDS" == "true" ]]; then
    install_commands
  fi

  # 5. Install git hooks
  if [[ "$INSTALL_HOOKS_GLOBAL" == "true" ]]; then
    install_hooks "global"
  else
    info "Hooks not installed globally."
    info "To install hooks in a specific project: cd <project> && $SCRIPT_DIR/install.sh --hooks"
  fi

  # 6. Done
  echo ""
  echo -e "${BOLD}${GREEN}  ✓  Setup complete!${NC}"
  echo ""
  echo -e "  ${CYAN}Next steps:${NC}"
  echo -e "  ${DIM}1. Open a new terminal for changes to take effect${NC}"
  echo -e "  ${DIM}2. Run 'claude' in any project to start Claude Code${NC}"
  if command -v "${AI_EDITOR:-windsurf}" &>/dev/null; then
    echo -e "  ${DIM}3. Open your project in ${AI_EDITOR}: ${AI_EDITOR} .${NC}"
  fi
  echo -e "  ${DIM}4. Try a command: /review-comment <PR>  or  /risk-assessment <TICKET>${NC}"
  echo ""
  echo -e "  ${DIM}Config saved to: ~/.dev-setup-config${NC}"
  echo -e "  ${DIM}Commands in:    ~/.claude/commands/${NC}"
  echo ""
}

# ─── Entry point ───────────────────────────────────────────────────────────────

case "${1:-}" in
  --check)
    source "$SCRIPT_DIR/lib/check-deps.sh"
    print_banner
    run_checks
    ;;
  --commands)
    source "$SCRIPT_DIR/lib/install-commands.sh"
    print_banner
    install_commands
    ;;
  --hooks)
    print_banner
    install_hooks "local"
    ;;
  --configure)
    source "$SCRIPT_DIR/lib/configure.sh"
    print_banner
    run_configure
    apply_git_config
    ;;
  --update)
    print_banner
    step "Updating ai-dev-setup"
    git pull origin main
    source "$SCRIPT_DIR/lib/install-commands.sh"
    install_commands
    ok "Updated to latest version."
    ;;
  --claude-md)
    generate_claude_md
    ;;
  *)
    full_setup
    ;;
esac
