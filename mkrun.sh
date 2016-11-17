#!/bin/bash

if [[ $# -lt 3 ]]; then
    echo "Illegal number of parameters."
    echo "Usage: $0 cloud_slot params_file mkcloud target"
    echo "i.e. $0 7 cloud7-ha-openvswitch all_noreboot"
    exit 1
fi

### unset switches to prevent surprises
#unset qa_crowbarsetup
unset TESTHEAD
unset hacloud
unset OWNAUTOMATION

# allocated cloud
allocated_cloud=$1
shift

# params file
. $1
shift

# targets
while (( "$#" )); do
    MKCLOUDTARGET="$MKCLOUDTARGET $1"
    shift
done

export user_keyfile=/root/manual.abel/id_rsa.pub
exec &> >(while IFS= read -r line; do echo "$(date +'%Y-%m-%d %H:%M:%S.%N') $line"; done | tee -a "g${allocated_cloud}/mkcloud.`date +%Y%m%d-%H%M`.log")


###############################

. /root/cloud.d/runtestn ${allocated_cloud}


echo "Source: $cloudsource"
if test -n "$upgrade_cloudsource"; then
    echo "Upgrading to: $upgrade_cloudsource"
fi
if test -n "$TESTHEAD"; then
    echo "Using staging: yes"
else
    echo "Using staging: no"
fi
echo "mkcloud target: $MKCLOUDTARGET"

echo

if test -n "$qa_crowbarsetup"; then
    echo "You cannot define qa_crowbarsetup variable anymore"
    exit 1
fi

if test -n "${OWNAUTOMATION:-1}"; then
    echo "Using custom mkcloud and qa_crowbarsetup: yes"
else
    echo "Using custom mkcloud and qa_crowbarsetup: no"
fi

if test -n "$install_chef_suse_override" -a -e "$install_chef_suse_override"; then
    echo "Using custom install-chef-suse.sh: yes"
else
    echo "Using custom install-chef-suse.sh: no"
fi

echo

echo "Number of nodes: ${nodenumber:-2}"
if test -n "$want_sles12"; then
    echo "Using SLES12 nodes: yes"
else
    echo "Using SLES12 nodes: no"
fi

echo

echo "Virtualization: ${libvirt_type:-kvm}"
echo "Neutron mechanism driver: ${networkingplugin:-openvswitch}"
echo "Neutron default type: ${networkingmode:-gre (openvswitch) / vlan (linuxbridge)}"
if test "$want_swift" == "1"; then
    echo "Using swift: yes"
else
    echo "Using swift: no"
fi
if test "$want_ceph" == 1 -a "$want_swift" != 1 -a ${nodenumber:-2} -ge 3; then
    echo "Using ceph: yes"
else
    echo "Using ceph: no"
fi

if test "$tempestoptions" == "-t"; then
    echo "Tempest options: full"
elif test "$tempestoptions" == "-t -s"; then
    echo "Tempest options: smoketest"
else
    echo "Tempest options: $tempestoptions"
fi

echo

if test -n "$OWNAUTOMATION"; then
    pushd /root/manual.abel/automation
    git pull
    popd

    pushd /root/manual.abel/g${allocated_cloud}
    exec /root/manual.abel/automation/scripts/mkcloud $MKCLOUDTARGET
    popd
else
    echo "OWNAUTOMATION=0 not supported for now"
    exit 1
    #exec mkcloud $MKCLOUDTARGET
fi
