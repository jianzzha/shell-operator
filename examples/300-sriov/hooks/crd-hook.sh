#!/usr/bin/env bash

if [[ $1 == "--config" ]] ; then
  cat <<EOF
{
  "configVersion":"v1",
  "kubernetes":[{
    "apiVersion": "sriov.redhat.com/v1",
    "kind": "VirtualFunction",
    "executeHookOnEvent":["Added","Deleted","Modified"]
  }]
}
EOF
else
  type=$(jq -r '.[0].type' ${BINDING_CONTEXT_PATH})
  if [[ $type == "Synchronization" ]] ; then
      echo "########################## Synchronization" 
      exit 0
  fi

  if [[ $type == "Event" ]] ; then
    echo "########################## Event"
    numvfs=$(jq -r '.[0].object.spec.numvfs' ${BINDING_CONTEXT_PATH})
    pci=$(jq -r '.[0].object.spec.pci' ${BINDING_CONTEXT_PATH})
    echo "########################## numvfs=${numvfs}, pci=${pci}"
  fi
fi
