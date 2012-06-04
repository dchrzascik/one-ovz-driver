#!/usr/bin/env ruby


def print_info(name, value)
    value = "0" if value.nil? or value.to_s.strip.empty?
    puts "#{name}=#{value}"
end

# OpenVZ specific parameters:

# cpu unit is a number calculated by OpenVZ with the help of the special algorithm 
# Current CPU utilization (CURRENT_CPU_UTIL) show the total cpu current utilisation (in units) assigned to currently running containers and the host system processess 

# (NODE_CPU_POWER)power of the node is a cpu power of all cpus available on the host mesured in the same units

# if the CURRENT_CPU_UTIL < NODE_CPU_POWER it means that the node is under utilized and the containers can receive more cpu that they have guaranree to receive (if no cpu_limit for the containers is set) 
# if CURRENT_CPU_UTIL > NODE_CPU_POWER, node is overcommited: the node promised more cpu units than the power of the Hardware Node. In this case, the containers might receive less power that they had been guaranted to receive



input, output = IO.pipe
pid = fork {
    # child
    $stdout.reopen output
    input.close
    exec '/usr/sbin/vzcpucheck'
}
# parent
output.close

vzcpucheck_text= input.read.split(/\n/)

$current_util = vzcpucheck_text[0].split(/:/)[1].strip
$node_power = vzcpucheck_text[1].split(/:/)[1].strip

Process.waitpid(pid)
	
print_info("NODE_CPU_POWER",$node_power)
print_info("CURRENT_CPU_UTIL",$current_util)
