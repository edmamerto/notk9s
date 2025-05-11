#!/bin/bash

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/bin"
RECOMMENDED_GUM_VERSION="0.16.0"

check_gum_version() {
  if ! command -v gum &>/dev/null; then
    echo -e "❌ \033[0;31mgum is not installed.\033[0m"
    echo -e "🔧 Install it with: \033[0;33mbrew install gum\033[0m"
    exit 1
  fi

  CURRENT_VERSION=$(gum --version | awk '{print $3}')
  if [[ "$CURRENT_VERSION" != "$RECOMMENDED_GUM_VERSION" ]]; then
    echo -e "⚠️  \033[0;33mYou're using gum version $CURRENT_VERSION.\033[0m"
    echo -e "🔁 Recommended version: \033[1;32m$RECOMMENDED_GUM_VERSION\033[0m"
    echo -e "📦 To install it manually (if needed):"
    echo -e "   \033[0;36mexport PATH=\"/opt/homebrew/opt/gum@0.16.0/bin:\$PATH\"\033[0m"
  fi
}

print_help() {
  gum style --foreground 35 "📖 notk9s CLI Help"
  echo ""
  echo "Usage: $0 <command> <namespace> [pod_prefix]"
  echo ""
  gum style --foreground 33 "Commands:"
  echo "  scheduling-delay     Time from pod creation to being scheduled"
  echo "  startup-delay        Time from scheduled to ready"
  echo "  image-pull           Time spent pulling container image"
  echo "  node-reuse           Check if pod used a new or reused node"
  echo "  restart-reason       Show restart reasons for pods"
  echo "  pending-reason       Show why pods are stuck in Pending"
  echo ""
  gum style --foreground 240 "🔧 TIP: Run without arguments to launch interactive mode"
  echo ""
}

show_menu() {
  TOOL=$(gum choose --limit=1 --header="📦 Choose a notk9s tool:" \
    "scheduling-delay: Time from pod creation to being scheduled" \
    "startup-delay: Time from scheduled to ready" \
    "image-pull: Time spent pulling container image" \
    "node-reuse: Check if pod used a new or reused node" \
    "restart-reason: Show restart reasons for pods" \
    "pending-reason: Show why pods are stuck in Pending" \
  | cut -d':' -f1)

  [[ -z "$TOOL" ]] && gum style --foreground 196 "❌ No tool selected. Exiting." && exit 1

  NAMESPACE=$(gum input --placeholder "Enter namespace (required)" --prompt.foreground="33")
  [[ -z "$NAMESPACE" ]] && gum style --foreground 196 "❌ Namespace is required. Exiting." && exit 1

  PREFIX=$(gum input --placeholder "Optional pod prefix (press Enter to skip)" --prompt.foreground="240")

  case "$TOOL" in
    scheduling-delay) SCRIPT="pod_scheduling_time.sh" ;;
    startup-delay)    SCRIPT="pod_startup_time.sh" ;;
    image-pull)       SCRIPT="image_pull_time.sh" ;;
    node-reuse)       SCRIPT="node_reuse_check.sh" ;;
    restart-reason)   SCRIPT="restart_reason_analyzer.sh" ;;
    pending-reason)   SCRIPT="pending_reason_analyzer.sh" ;;
    *) 
      gum style --foreground 196 "❌ Invalid selection."
      exit 1
      ;;
  esac

  bash "$SCRIPT_DIR/$SCRIPT" "$NAMESPACE" "$PREFIX"
}

# ✅ Validate gum is available (non-fatal if mismatched version)
check_gum_version

# 📘 Help mode
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "help" ]]; then
  print_help
  exit 0
fi

# 🧪 Interactive mode
if [[ $# -eq 0 ]]; then
  show_menu
  exit 0
fi

# 🚀 CLI mode
COMMAND=$1
NAMESPACE=$2
PREFIX=$3

if [[ -z "$NAMESPACE" ]]; then
  gum style --foreground 196 "❌ Namespace is required for CLI mode."
  gum style --foreground 240 "Run with --help for usage info."
  exit 1
fi

case $COMMAND in
  scheduling-delay)
    bash "$SCRIPT_DIR/pod_scheduling_time.sh" "$NAMESPACE" "$PREFIX"
    ;;
  startup-delay)
    bash "$SCRIPT_DIR/pod_startup_time.sh" "$NAMESPACE" "$PREFIX"
    ;;
  image-pull)
    bash "$SCRIPT_DIR/image_pull_time.sh" "$NAMESPACE" "$PREFIX"
    ;;
  node-reuse)
    bash "$SCRIPT_DIR/node_reuse_check.sh" "$NAMESPACE" "$PREFIX"
    ;;
  restart-reason)
    bash "$SCRIPT_DIR/restart_reason_analyzer.sh" "$NAMESPACE" "$PREFIX"
    ;;
  pending-reason)
    bash "$SCRIPT_DIR/pending_reason_analyzer.sh" "$NAMESPACE" "$PREFIX"
    ;;
  *)
    gum style --foreground 196 "❌ Unknown command: $COMMAND"
    gum style --foreground 240 "Run with --help for usage info."
    ;;
esac
