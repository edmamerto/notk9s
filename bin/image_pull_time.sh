#!/bin/bash

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

print_image_pull_times() {
  local NAMESPACE="$1"
  local PREFIX_FILTER="$2"

  echo "🐳 Estimating image pull times in namespace: $NAMESPACE"
  [[ -n "$PREFIX_FILTER" ]] && echo "📦 Filtering by prefix: $PREFIX_FILTER"

  printf "\n%-70s %-20s\n" "POD NAME" "PULL TIME (s)"
  printf "%0.s-" {1..90}
  echo ""

  total_pods=0
  total_pull=0

  for pod in $(kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}'); do
    if [[ -n "$PREFIX_FILTER" && "$pod" != ${PREFIX_FILTER}* ]]; then
      continue
    fi

    SCHEDULED=$(kubectl get pod "$pod" -n "$NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="PodScheduled")].lastTransitionTime}')
    STARTED=$(kubectl get pod "$pod" -n "$NAMESPACE" -o jsonpath='{.status.containerStatuses[0].state.running.startedAt}')

    if [[ -z "$SCHEDULED" || -z "$STARTED" ]]; then
      continue
    fi

    SCHEDULED_SEC=$(date -jf "%Y-%m-%dT%H:%M:%SZ" "$SCHEDULED" +%s 2>/dev/null)
    STARTED_SEC=$(date -jf "%Y-%m-%dT%H:%M:%SZ" "$STARTED" +%s 2>/dev/null)

    if [[ -n "$SCHEDULED_SEC" && -n "$STARTED_SEC" && $STARTED_SEC -ge $SCHEDULED_SEC ]]; then
      DELAY=$((STARTED_SEC - SCHEDULED_SEC))

      if (( DELAY < 5 )); then
        COLOR=$GREEN
      elif (( DELAY < 30 )); then
        COLOR=$YELLOW
      else
        COLOR=$RED
      fi

      printf "%-70s ${COLOR}%-20s${NC}\n" "$pod" "$DELAY"
      ((total_pods++))
      ((total_pull+=DELAY))
    fi
  done

  echo ""
  echo "📊 Summary:"
  echo "-----------"
  echo "Pods analyzed:    $total_pods"
  echo "Total pull time:  $total_pull seconds"
  if (( total_pods > 0 )); then
    avg_pull=$(echo "scale=2; $total_pull / $total_pods" | bc)
    echo "Average pull time: $avg_pull seconds"
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

  print_image_pull_times "$NAMESPACE" "$PREFIX"
fi
