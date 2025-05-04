#!/bin/bash

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
NC='\033[0m'

# Extract just the clean reason (e.g. FailedScheduling)
extract_reason() {
  local warn_line="$1"
  echo "$warn_line" | awk '{print $2}'
}

# Optional: add color + emoji based on reason type
color_reason() {
  case "$1" in
    FailedScheduling) echo -e "${YELLOW}🗓️  $1${NC}" ;;
    ImagePullBackOff|ErrImagePull) echo -e "${RED}🐳  $1${NC}" ;;
    CreateContainerConfigError) echo -e "${RED}⚙️  $1${NC}" ;;
    CrashLoopBackOff) echo -e "${RED}💥 $1${NC}" ;;
    *) echo -e "${BLUE}❓ $1${NC}" ;;
  esac
}

print_pending_reasons() {
  local NAMESPACE="$1"
  local PREFIX_FILTER="$2"

  echo -e "${BLUE}🔍 Analyzing pending pods in namespace:${NC} $NAMESPACE"
  [[ -n "$PREFIX_FILTER" ]] && echo -e "${BLUE}📦 Filtering by prefix:${NC} $PREFIX_FILTER"

  printf "\n%-60s %-22s %-s\n" "POD NAME" "REASON" "MESSAGE"
  printf "%0.s-" {1..120}
  echo ""

  TMP_REASONS_FILE=$(mktemp)
  total_pending=0

  for POD in $(kubectl get pods -n "$NAMESPACE" --field-selector=status.phase=Pending -o jsonpath='{.items[*].metadata.name}'); do
    if [[ -n "$PREFIX_FILTER" && "$POD" != ${PREFIX_FILTER}* ]]; then
      continue
    fi

    WARN_LINE=$(kubectl describe pod "$POD" -n "$NAMESPACE" 2>/dev/null | grep -m 1 "Warning")
    RAW_REASON=$(extract_reason "$WARN_LINE")
    REASON=$(color_reason "$RAW_REASON")

    RAW_MESSAGE=$(echo "$WARN_LINE" | cut -d' ' -f3-)
    MESSAGE=$(echo "$RAW_MESSAGE" | cut -c1-60)

    printf "%-60s %-22s %-s\n" "$POD" "$REASON" "$MESSAGE"

    echo "$RAW_REASON" >> "$TMP_REASONS_FILE"
    total_pending=$((total_pending + 1))
  done

  echo ""
  echo -e "${BLUE}📊 Summary:${NC}"
  echo "-----------"
  echo "Pending pods analyzed: $total_pending"
  sort "$TMP_REASONS_FILE" | uniq -c | sort -nr

  rm -f "$TMP_REASONS_FILE"
}

# Entry point
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [[ -z "$1" ]]; then
    echo -e "${RED}❌ Usage:${NC} $0 <namespace> [optional_pod_prefix]"
    exit 1
  fi

  NAMESPACE="$1"
  PREFIX="$2"

  print_pending_reasons "$NAMESPACE" "$PREFIX"
fi
