#!/usr/bin/env ruby

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

class IMBaseDriver
	
	@@free_cmd = "free -k"
	@@cpu_info_cmd = "cat /proc/cpuinfo"
	@@top_cmd = "top -bin1" # b- batch mode, i - ignore idle and zombie, n1 - probe one time
	@@net_dev_cmd = "cat /proc/net/dev"

	# Prints system state information( cpu, memory, bandwith)
	def self.print
		free_text  = `#{@@free_cmd}`		
		total_memory, used_memory, free_memory = IMBaseParser.memory_info(free_text)
	    	puts "TOTAL_MEMORY=#{total_memory}"
	    	puts "USED_MEMORY=#{used_memory}"
	    	puts "FREE_MEMORY=#{free_memory}"
		cpu_info_text = `#{@@cpu_info_cmd}`	
		top_bin1_text  = `#{@@top_cmd}`	
		free_cpu, used_cpu, cpu_speed = IMBaseParser.cpu_info(cpu_info_text, top_bin1_text)
		puts "FREE_CPU=#{free_cpu}"
		puts "USED_CPU=#{used_cpu}"

		puts "CPU_SPEED=#{cpu_speed}"
		proc_net_dev_text = `#{@@net_dev_cmd}`	
		netrx, nettx  = IMBaseParser.in_out_bandwith(proc_net_dev_text)
		puts "NETRX=#{netrx}"
		puts "NETTX=#{nettx}"
	end
end

# This class provides a convinient way of getting interesting system state
# information out of provided system files/ commands outputs
class IMBaseParser

	# Gathers information about memory on the machine
	#
	# * *Args* :
	# - +free_text+ -> output of the free -l command	
	# * *Returns* :
	# - total_memory, used_memory, free_memory parameters of system described by args as strings
	def self.memory_info(free_text)
		total_memory = free_text.grep(/Mem:?/)[0].split()[1]
		used_memory, free_memory=free_text.grep(/buffers\/cache?/)[0].split().slice(2,2)
		return total_memory.strip, used_memory.strip, free_memory.strip
	end

	# Gathers information about cpu on the machine
	#
	# * *Args* :
	# - +cpu_info_text+ -> content of the /proc/cpuinfo file
	# - +top_bin1_text+ -> output of the top -bin1. b- batch mode, i - ignore idle and zombie, n1 - probe one time
	# * *Returns* :
	# - free_cpu, used_cpu, speed_cpu parameters of system described by args as strings
	def self.cpu_info(cpu_info_text, top_bin1_text)
		# learn how many virtual processors are they
		# each processor in this file appear as a single line in a format: processor: processor_id
		ncpus = cpu_info_text.grep(/processor?/).count
		total_cpu=ncpus*100
		# cpu speed - is always equal for each core, so read the first one
		cpu_speed = cpu_info_text.grep(/cpu MHz?/)[0].split(":")[1].strip
		free_cpu, used_cpu = nil, nil
		idle = top_bin1_text.grep(/^Cpu?/)[0].split(':')[1].split(',').grep(/.%id/)[0].split('%')[0]
		free_cpu = idle.to_f * total_cpu.to_f / 100
		used_cpu = total_cpu.to_f - free_cpu
		return free_cpu.to_s, used_cpu.to_s, cpu_speed.to_s
	end

	# Gathers information about in and out bandwith 
	#
	# * *Args* :
	# - +proc_net_dev_text+ -> content of the /proc/net/dev file
	# - +loopback_names_prefix+ ->  prefix of the names of loopback interfaces, default is /lo/
	# * *Returns* :
	# - netrx - in bandwith, nettr - out bandwith
	def self.in_out_bandwith(proc_net_dev_text, loopback_names_prefix = "lo")
		# sum in and put used bandwith on all interface except of one loopback
		# interface with a default name matching ^loopback_names_prefix (FIXME?)
		# drop first 2 lines of net_text file - headers
		netrx, nettx = 0, 0
		proc_net_dev_text.split(/\n/).drop(2).each{|line|
		    unless line.match("^ *#{loopback_names_prefix}")
			arr = line.split(":")[1].split(" ")
			netrx += arr[0].to_i()
			nettx += arr[8].to_i()
		    end
		}
		return netrx.to_s, nettx.to_s 
	end
end

if __FILE__ == $0
	IMBaseDriver.print
end
