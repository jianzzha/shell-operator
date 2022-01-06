#!/usr/bin/env bash

pci_dev_dir="/sys/bus/pci/devices"

unify_pci_addr () {
   if [[ $1 != 0000:* ]]; then
       echo "0000:$1"
   else
       echo $1
   fi
}

delete_vf () {
   current=$(cat ${pci_dev_dir}/${pci}/sriov_numvfs)
   if ((current > 0)); then
       echo "**** echo -n 0 > ${pci_dev_dir}/${pci}/sriov_numvfs"
       echo -n 0 > ${pci_dev_dir}/${pci}/sriov_numvfs
   fi
}

modify_vf () {
   current=$(cat ${pci_dev_dir}/${pci}/sriov_numvfs)
   if ((current != numvfs)); then
       delete_vf
       sleep 1
       echo "**** echo -n ${numvfs} > ${pci_dev_dir}/${pci}/sriov_numvfs"
       echo -n ${numvfs} > ${pci_dev_dir}/${pci}/sriov_numvfs
   fi
}

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
    pci=$(unify_pci_addr $pci)
    echo "########################## numvfs=${numvfs}, pci=${pci}"
    if [[ ! -e ${pci_dev_dir}/${pci} ]]; then
        echo "!!!!!!! not exist: ${pci_dev_dir}/${pci}"
        exit 0
    fi
    watchEvent=$(jq -r '.[0].watchEvent' ${BINDING_CONTEXT_PATH})
    if [[ "${watchEvent}" == "Modified" ]]; then
        echo "***** modify VF"
        modify_vf
    elif [[ "${watchEvent}" == "Deleted" ]]; then
        echo "***** delete VFs"
        delete_vf 
    elif [[ "${watchEvent}" == "Added" ]]; then
        echo "**** add VFs"
        modify_vf
    fi
  fi
fi
