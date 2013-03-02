#!/bin/bash

#   Copyright 2012 Tim Ellis
#   CTO: PalominoDB
#   The Palomino Cluster Tool
#
#   Licensed under the Apache License, Version 2.0 (the "License");
#   you may not use this file except in compliance with the License.
#   You may obtain a copy of the License at
#
#       http://www.apache.org/licenses/LICENSE-2.0
#
#   Unless required by applicable law or agreed to in writing, software
#   distributed under the License is distributed on an "AS IS" BASIS,
#   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#   See the License for the specific language governing permissions and
#   limitations under the License.

# TODO: Convert this to a playbook as well. Ansible supports playbooks-of-playbooks

# doesn't need to run as root
if [ $USER == "root" ] ; then
	echo "This script does NOT need to be run as root (probably). If you disagree, edit the script"
	echo "and remove the code that quits when you're root. Exiting abnormally."
	echo ""
	exit 255
fi


# check input is a clusterName
clusterName=$1
if [ "xxx$clusterName" == "xxx" ] ; then
	echo " E Usage: $0 <clusterName>"
	echo " E Currently configured clusters:"
	find /etc/palomino -mindepth 1 -type d -printf "%f\n" | awk '{print " - "$_}'
	exit 255
fi
ansibleHosts="/etc/ansible/$clusterName.ini"


# Sanity Check Overall Configuration
echo " - Checking configuration."
echo "   Ensuring minimum sane NameNode, HMaster, Zookeeper Nodes, DataNodes, and RegionServers defined."

NameNodes=`awk '/\[.+\]/{m=0};NF && m{t++};/\[NameNodes\]/{m=1} END{print t+0}' $ansibleHosts`
if [ $NameNodes -ne 1 ] ; then echo "There must be one entry in [NameNodes] section in $ansibleHosts - found $NameNodes" ; exit 255 ; fi


HMasters=`awk '/\[.+\]/{m=0};NF && m{t++};/\[HMasters\]/{m=1} END{print t+0}' $ansibleHosts`
if [ $HMasters -ne 1 ] ; then echo "There must be one entry in [HMasters] section in $ansibleHosts - found $HMasters" ; exit 255 ; fi

ZooKeepers=`awk '/\[.+\]/{m=0};NF && m{t++};/\[ZooKeepers\]/{m=1} END{print t+0}' $ansibleHosts`
if [ $ZooKeepers -lt 1 ] ; then echo "There must be 1 (or more, preferably odd) entries in [ZooKeepers] section in $ansibleHosts - found $ZooKeepers" ; exit 255 ; fi

RegionServers=`awk '/\[.+\]/{m=0};NF && m{t++};/\[RegionServers\]/{m=1} END{print t+0}' $ansibleHosts`
if [ $RegionServers -lt 2 ] ; then echo "There must be 4 (or more) entries in [RegionServers] section in $ansibleHosts - found $RegionServers" ; exit 255 ; fi


# run the playbooks
./lib-WrapPlaybooks.sh $clusterName BaseSaneSystem
./lib-WrapPlaybooks.sh $clusterName Hadoop
./lib-WrapPlaybooks.sh $clusterName HBase

