#!/bin/bash

print_restart_reasons() {
  local NAMESPACE="$1"
  local PREFIX_FILTER="$2"

  echo "🔁 Analyzing pod restarts in namespace: $NAMESPACE"
  [[ -n "$PREFIX_FILTER" ]] && echo "📦 Filtering by prefix: $PREFIX_FILTER"

  printf "\n%-50s %-20s %-15s %-25s\n" "POD NAME" "CONTAINER" "RESTARTS" "REASON"
  printf "%0.s-" {1..115}
  echo ""

  total_pods=0
  total_restarts=0
  restarted_pods=0

  POD_LIST=$(kubectl get pods -n "$NAMESPACE" -o json)

  echo "$POD_LIST" | jq -c '.items[]' | while read -r pod_json; do
    POD_NAME=$(echo "$pod_json" | jq -r '.metadata.name')

    if [[ -n "$PREFIX_FILTER" && "$POD_NAME" != ${PREFIX_FILTER}* ]]; then
      continue
    fi

    CONTAINER_STATUSES=$(echo "$pod_json" | jq '.status.containerStatuses // []')
    HAS_RESTART=$(echo "$CONTAINER_STATUSES" | jq '[.[] | select(.restartCount > 0)] | length')

    if (( HAS_RESTART == 0 )); then
      continue
    fi

    for CONTAINER in $(echo "$CONTAINER_STATUSES" | jq -r '.[].name'); do
      STATUS=$(echo "$CONTAINER_STATUSES" | jq -r --arg name "$CONTAINER" '.[] | select(.name == $name)')
      RESTARTS=$(echo "$STATUS" | jq -r '.restartCount')

      if (( RESTARTS > 0 )); then
        REASON=$(echo "$STATUS" | jq -r '.lastState.terminated.reason // "Unknown"')
        printf "%-50s %-20s %-15s %-25s\n" "$POD_NAME" "$CONTAINER" "$RESTARTS" "$REASON"
        ((total_restarts+=RESTARTS))
        ((restarted_pods++))
      fi
    done

    ((total_pods++))
  done

  echo ""
  echo "📊 Summary:"
  echo "-----------"
  echo "Total pods analyzed:     $total_pods"
  echo "Pods with restarts:      $restarted_pods"
  echo "Total restarts:          $total_restarts"
}

# Caller
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  if [[ -z "$1" ]]; then
    echo "❌ Usage: $0 <namespace> [optional_pod_prefix]"
    exit 1
  fi

  NAMESPACE="$1"
  PREFIX="$2"

  print_restart_reasons "$NAMESPACE" "$PREFIX"
fi
