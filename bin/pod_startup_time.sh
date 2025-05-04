#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_pod_startup_times() {
  local NAMESPACE="$1"
  local PREFIX_FILTER="$2"

  echo "🚀 Measuring pod startup times in namespace: $NAMESPACE"
  [[ -n "$PREFIX_FILTER" ]] && echo "🔍 Filtering by prefix: $PREFIX_FILTER"

  # Header
  printf "\n%-70s %-20s\n" "POD NAME" "STARTUP TIME (s)"
  printf "%0.s-" {1..90}
  echo ""

  total_pods=0
  total_delay=0

  for pod in $(kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}'); do
    if [[ -n "$PREFIX_FILTER" && "$pod" != ${PREFIX_FILTER}* ]]; then
      continue
    fi

    SCHEDULED=$(kubectl get pod "$pod" -n "$NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="PodScheduled")].lastTransitionTime}')
    READY=$(kubectl get pod "$pod" -n "$NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="Ready")].lastTransitionTime}')

    if [[ -z "$SCHEDULED" || -z "$READY" ]]; then
      continue
    fi

    SCHEDULED_SEC=$(date -jf "%Y-%m-%dT%H:%M:%SZ" "$SCHEDULED" +%s 2>/dev/null)
    READY_SEC=$(date -jf "%Y-%m-%dT%H:%M:%SZ" "$READY" +%s 2>/dev/null)

    if [[ -n "$SCHEDULED_SEC" && -n "$READY_SEC" ]]; then
      DELAY=$((READY_SEC - SCHEDULED_SEC))

      # Adjusted thresholds
      if (( DELAY < 60 )); then
        COLOR=$GREEN
      elif (( DELAY < 120 )); then
        COLOR=$YELLOW
      else
        COLOR=$RED
      fi

      printf "%-70s ${COLOR}%-20s${NC}\n" "$pod" "$DELAY"
      ((total_pods++))
      ((total_delay+=DELAY))
    fi
  done

  echo ""
  echo "📊 Summary:"
  echo "-----------"
  echo "Pods analyzed:    $total_pods"
  echo "Total delay (s):  $total_delay"
  if (( total_pods > 0 )); then
    avg_delay=$(echo "scale=2; $total_delay / $total_pods" | bc)
    echo "Average delay (s): $avg_delay"
  fi
}

# Caller block – only runs if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [[ -z "$1" ]]; then
    echo "❌ Usage: $0 <namespace> [optional_pod_prefix]"
    exit 1
  fi

  NAMESPACE="$1"
  PREFIX="$2"

  print_pod_startup_times "$NAMESPACE" "$PREFIX"
fi