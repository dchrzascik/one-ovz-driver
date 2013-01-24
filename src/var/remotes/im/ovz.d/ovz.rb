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

$: << "#{File.dirname(__FILE__)}/../../"

require 'lib/parsers/im'

module OpenNebula

  class IMBaseDriver
    @@free_cmd = "free -k"
    @@cpu_info_cmd = "cat /proc/cpuinfo"
    @@top_cmd = "top -bin1" # b- batch mode, i - ignore idle and zombie, n1 - probe one time
    @@net_dev_cmd = "cat /proc/net/dev"

    # Prints system state information( cpu, memory, bandwith)
    def self.print
      free_text = `#{@@free_cmd}`
      total_memory, used_memory, free_memory = IMBaseParser.memory_info(free_text)
      puts "TOTALMEMORY=#{total_memory}"
      puts "USEDMEMORY=#{used_memory}"
      puts "FREEMEMORY=#{free_memory}"
      cpu_info_text = `#{@@cpu_info_cmd}`
      top_bin1_text = `#{@@top_cmd}`
      free_cpu, used_cpu, cpu_speed, total_cpu = IMBaseParser.cpu_info(cpu_info_text, top_bin1_text)
      puts "FREECPU=#{free_cpu}"
      puts "USEDCPU=#{used_cpu}"
      puts "TOTALCPU=#{total_cpu}"
      puts "CPUSPEED=#{cpu_speed}"
      proc_net_dev_text = `#{@@net_dev_cmd}`
      netrx, nettx = IMBaseParser.in_out_bandwith(proc_net_dev_text)
      puts "NETRX=#{netrx}"
      puts "NETTX=#{nettx}"
    end
  end
end


if __FILE__ == $0
  OpenNebula::IMBaseDriver.print
end
