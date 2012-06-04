#!/usr/bin/env ruby

# -------------------------------------------------------------------------- #
# Copyright 2002-2012, OpenNebula Project Leads (OpenNebula.org) #
# #
# Licensed under the Apache License, Version 2.0 (the "License"); you may #
# not use this file except in compliance with the License. You may obtain #
# a copy of the License at #
# #
# http://www.apache.org/licenses/LICENSE-2.0 #
# #
# Unless required by applicable law or agreed to in writing, software #
# distributed under the License is distributed on an "AS IS" BASIS, #
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. #
# See the License for the specific language governing permissions and #
# limitations under the License. #
#--------------------------------------------------------------------------- #

def print_info(name, value)
    value = "0" if value.nil? or value.to_s.strip.empty?
    puts "#{name}=#{value}"
end

# CPU

cpuinfo=`cat /proc/cpuinfo`
exit(-1) if $?.exitstatus != 0

# how many virtual processors are they?
# each processor in this file appear as a single line in a format: processor: processor_id
$ncpus = cpuinfo.grep(/processor/).count
# FIXME: why is it that way? copied from kvm..
$total_cpu=$ncpus*100

# cpu speed - is always equal for each core, so read the first one
$cpu_speed = cpuinfo.grep(/cpu MHz/).to_s().split(":")[1]

top_text=`top -bin1`
exit(-1) if $?.exitstatus != 0

top_text.gsub!(/^top.*^top.*?$/m, "") # Strip first top output

top_text.split(/\n/).each{|line|
    if line.match('^%?Cpu')
        line[7..-1].split(",").each{|elemento|
            temp = elemento.strip.split(/[% ]/)
            if temp[1]=="id"
            idle = temp[0]
            $free_cpu = idle.to_f * $total_cpu.to_f / 100
            $used_cpu = $total_cpu.to_f - $free_cpu
                break
            end

        }
    end
}

$total_memory = `free -k|grep "Mem:" | awk '{print $2}'`
tmp=`free -k|grep "buffers\/cache"|awk '{print $3 " " $4}'`.split

$used_memory=tmp[0]
$free_memory=tmp[1]

# get in/out used bandwith information

net_text=`cat /proc/net/dev`
exit(-1) if $?.exitstatus != 0

LOOPBACK_NAME = "lo"

netrx = 0
nettx = 0

# sum in and put used bandwith on all interface except of one loopback
# interface with a default name LOOPBACK_NAME
# drop first 2 lines of net_text file - headers
net_text.split(/\n/).drop(2).each{|line|
    unless line.match("^ *#{LOOPBACK_NAME }")
        arr = line.split(":")[1].split(" ")
        netrx += arr[0].to_i()
        nettx += arr[8].to_i()
    end
}

$netrx = netrx.to_s()
$nettx = nettx.to_s()


print_info("TOTALMEMORY",$total_memory)
print_info("USEDMEMORY",$used_memory)
print_info("FREEMEMORY",$free_memory)

print_info("FREECPU",$free_cpu)
print_info("USEDCPU",$used_cpu)

print_info("CPUSPEED",$cpu_speed)

print_info("NETRX",$netrx)
print_info("NETTX",$nettx)
