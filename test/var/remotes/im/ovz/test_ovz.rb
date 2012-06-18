#!/usr/bin/env ruby

require 'ovz'
require "test/unit"

module OpenNebula
	class IMBaseParserTest < Test::Unit::TestCase
	
		def test_memory_info
			free_text  = File.read("tests/resources/free.txt")
			total_memory, used_memory, free_memory = IMBaseParser.memory_info(free_text)
			assert_equal "498572", total_memory
			assert_equal "239880",used_memory
			assert_equal "258692",free_memory
		end

		def test_cpu_info
			cpu_info_text = File.read("tests/resources/cpuinfo.txt")	
			top_bin1_text  = File.read("tests/resources/top_bin1.txt")
			free_cpu, used_cpu, cpu_speed = IMBaseParser.cpu_info(cpu_info_text, top_bin1_text)
			assert_equal "88.2", free_cpu
			assert_equal "11.8", used_cpu
			assert_equal "2198.917", cpu_speed
		end

		def test_in_out_bandwith
			proc_net_dev_text = File.read("tests/resources/proc_net_dev.txt")		
			netrx, nettx  = IMBaseParser.in_out_bandwith(proc_net_dev_text)
			assert_equal "48291381", netrx
			assert_equal "11168834", nettx
		end

		def test_print
			assert_nothing_raised do
				puts IMBaseDriver.print
			end
		end	
	end
end
