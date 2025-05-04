#!/bin/bash

# Colors
GREEN='\033[0;32m'   # New
BLUE='\033[1;34m'    # Reused
NC='\033[0m'

print_node_reuse() {
  local NAMESPACE="$1"
  local PREFIX_FILTER="$2"

  echo "🔍 Checking node reuse in namespace: $NAMESPACE"
  [[ -n "$PREFIX_FILTER" ]] && echo "📦 Filtering by prefix: $PREFIX_FILTER"

  printf "\n%-70s %-10s\n" "POD NAME" "STATUS"
  printf "%0.s-" {1..85}
  echo ""

  total_pods=0
  reused=0
  new_nodes=0

  for POD in $(kubectl get pods -n "$NAMESPACE" -o jsonpath='{.items[*].metadata.name}'); do
    if [[ -n "$PREFIX_FILTER" && "$POD" != ${PREFIX_FILTER}* ]]; then
      continue
    fi

    NODE_NAME=$(kubectl get pod "$POD" -n "$NAMESPACE" -o jsonpath='{.spec.nodeName}')
    if [[ -z "$NODE_NAME" ]]; then
      printf "%-70s %-10s\n" "$POD" "${BLUE}Pending${NC}"
      continue
    fi

    NODE_CREATED=$(kubectl get node "$NODE_NAME" -o jsonpath='{.metadata.creationTimestamp}')
    SCHEDULED_TIME=$(kubectl get pod "$POD" -n "$NAMESPACE" -o jsonpath='{.status.conditions[?(@.type=="PodScheduled")].lastTransitionTime}')

    NODE_CREATED_SEC=$(date -jf "%Y-%m-%dT%H:%M:%SZ" "$NODE_CREATED" +%s 2>/dev/null)
    SCHEDULED_TIME_SEC=$(date -jf "%Y-%m-%dT%H:%M:%SZ" "$SCHEDULED_TIME" +%s 2>/dev/null)

    if [[ -z "$NODE_CREATED_SEC" || -z "$SCHEDULED_TIME_SEC" ]]; then
      continue
    fi

    ((total_pods++))
    if (( NODE_CREATED_SEC + 5 >= SCHEDULED_TIME_SEC )); then
      STATUS="${GREEN}🆕 New${NC}"
      ((new_nodes++))
    else
      STATUS="${BLUE}♻️ Reused${NC}"
      ((reused++))
    fi

    printf "%-70s %-10b\n" "$POD" "$STATUS"
  done

  echo ""
  echo "📊 Summary:"
  echo "-----------"
  echo "Pods analyzed:     $total_pods"
  echo "New nodes:         $new_nodes"
  echo "Reused nodes:      $reused"
}

# Caller block – only runs if not sourced
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [[ -z "$1" ]]; then
    echo "❌ Usage: $0 <namespace> [optional_pod_prefix]"
    exit 1
  fi

  NAMESPACE="$1"
  PREFIX="$2"

  print_node_reuse "$NAMESPACE" "$PREFIX"
fi
