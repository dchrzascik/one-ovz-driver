#!/bin/bash

# -------------------------------------------------------------------------- #
# Copyright 2002-2011, OpenNebula Project Leads (OpenNebula.org)             #
#                                                                            #
# Licensed under the Apache License, Version 2.0 (the "License"); you may    #
# not use this file except in compliance with the License. You may obtain    #
# a copy of the License at                                                   #
#                                                                            #
# http://www.apache.org/licenses/LICENSE-2.0                                 #
#                                                                            #
# Unless required by applicable law or agreed to in writing, software        #
# distributed under the License is distributed on an "AS IS" BASIS,          #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.   #
# See the License for the specific language governing permissions and        #
# limitations under the License.                                             #
#--------------------------------------------------------------------------- #

# CPU
if [ -f /proc/cpuinfo ]; then
  cpuinfo=`cat /proc/cpuinfo`
  ncpus=$(echo "$cpuinfo"|grep processor|wc -l)
  total_cpu=$(($ncpus*100))
  cpu_speed=$(echo "$cpuinfo"|grep "cpu MHz"|sort -u|sed s/[^0-9.]//g)
  cpu_speed=`printf "%.2f" $cpu_speed`
  free_cpu=`top -bin1| grep "Cpu"|cut -d ',' -f4|sed s/[^0-9.]//g`
  free_cpu=`echo "$free_cpu*$ncpus"|bc`
  used_cpu=`echo "$total_cpu - $free_cpu"|bc`
  used_cpu=`printf "%.2f" $used_cpu`
fi

# MEMORY
mem_info=`free -k`
total_memory=`echo $mem_info|awk '{print $8}'`
free_memory=`echo $mem_info|awk '{print $17}'`
used_memory=$(($total_memory - $free_memory))


# NETWORK
if [ -f /proc/net/dev ]; then
  net_info=`cat /proc/net/dev`
  netrx=$(echo "$net_info"|grep eth0|cut -d: -f2|awk {'print $1'})
  nettx=$(echo "$net_info"|grep eth0|cut -d: -f2|awk {'print $9'})
fi

# Print output
echo "HYPERVISOR=ovz"

echo "TOTALCPU=$total_cpu"
echo "CPUSPEED=$cpu_speed"

echo "TOTALMEMORY=$total_memory"
echo "USEDMEMORY=$used_memory"
echo "FREEMEMORY=$free_memory"

echo "FREECPU=$free_cpu"
echo "USEDCPU=$used_cpu"

echo "NETRX=$netrx"
echo "NETTX=$nettx"

