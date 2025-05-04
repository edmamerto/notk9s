#!/bin/bash

# Colors
GREEN='\033[0;32m'
BLUE='\033[1;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/bin"

print_help() {
  echo -e "${GREEN}📖 notk9s CLI Help${NC}"
  echo -e "Usage: $0 <command> <namespace> [pod_prefix]\n"
  echo -e "${BLUE}Commands:${NC}"
  echo -e "  ${YELLOW}scheduling-delay${NC}     Time from pod creation to being scheduled"
  echo -e "  ${YELLOW}startup-delay${NC}        Time from scheduled to ready"
  echo -e "  ${YELLOW}image-pull${NC}           Time spent pulling container image"
  echo -e "  ${YELLOW}node-reuse${NC}           Check if pod used a new or reused node"
  echo -e "  ${YELLOW}restart-reason${NC}       Show restart reasons for pods"
  echo ""
  echo -e "${RED}🔧 TIP:${NC} Run ${YELLOW}'$0'${NC} with ${YELLOW}no arguments${NC} to launch ${BLUE}interactive mode${NC}!"
  echo ""
}

show_menu() {
  echo -e "${GREEN}📦 Welcome to notk9s!${NC}"
  echo -e "${BLUE}Choose a tool:${NC}"
  echo -e "${BLUE}1)${NC} Scheduling Delay"
  echo -e "${BLUE}2)${NC} Startup Delay"
  echo -e "${BLUE}3)${NC} Image Pull Time"
  echo -e "${BLUE}4)${NC} Node Reuse Check"
  echo -e "${BLUE}5)${NC} Restart Reason Analyzer"
  echo ""

  echo -ne "${YELLOW}Enter number: ${NC}"
  read TOOL_NUM

  while [[ -z "$NAMESPACE" ]]; do
    echo -ne "${YELLOW}Enter namespace (required): ${NC}"
    read NAMESPACE
  done

  echo -ne "${YELLOW}Optional pod prefix (press Enter to skip): ${NC}"
  read PREFIX
  echo ""

  case $TOOL_NUM in
    1) bash "$SCRIPT_DIR/pod_scheduling_time.sh" "$NAMESPACE" "$PREFIX" ;;
    2) bash "$SCRIPT_DIR/pod_startup_time.sh" "$NAMESPACE" "$PREFIX" ;;
    3) bash "$SCRIPT_DIR/image_pull_time.sh" "$NAMESPACE" "$PREFIX" ;;
    4) bash "$SCRIPT_DIR/node_reuse_check.sh" "$NAMESPACE" "$PREFIX" ;;
    5) bash "$SCRIPT_DIR/restart_reason_analyzer.sh" "$NAMESPACE" "$PREFIX" ;;
    *) echo -e "${RED}❌ Invalid selection.${NC}" ;;
  esac
}

# Show help if requested
if [[ "$1" == "--help" || "$1" == "-h" || "$1" == "help" ]]; then
  print_help
  exit 0
fi

# Interactive mode
if [[ $# -eq 0 ]]; then
  show_menu
  exit 0
fi

# CLI mode
COMMAND=$1
NAMESPACE=$2
PREFIX=$3

if [[ -z "$NAMESPACE" ]]; then
  echo -e "${RED}❌ Namespace is required for CLI mode.${NC}"
  echo -e "${YELLOW}Run with --help for usage info.${NC}"
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
  *)
    echo -e "${RED}❌ Unknown command: $COMMAND${NC}"
    echo -e "${YELLOW}Run with --help for usage info.${NC}"
    ;;
esac
