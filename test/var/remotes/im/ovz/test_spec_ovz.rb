#!/usr/bin/env ruby

require 'spec_ovz'
require "test/unit"

module OpenNebula
	class IMOpenVZTest < Test::Unit::TestCase
	
		def test_parse_cpu_power
			text  = File.read("tests/resources/vzcpucheck.txt")
			current_cpu_utilization, node_cpu_power = IMOpenVZParser.parse_cpu_power(text)
			assert_equal "4000", current_cpu_utilization
			assert_equal "109946", node_cpu_power
		end

		def test_parse_memcheck
			text  = File.read("tests/resources/vzmemcheck.txt")
			alloc_util, alloc_commit, alloc_limit = IMOpenVZParser.parse_memcheck(text)
			assert_equal "1.95", alloc_util
			assert_equal "3922547387167512.00", alloc_commit
			assert_equal "3922547387167512.00", alloc_limit
		end

		def test_cpu_power
			assert_nothing_raised do
				puts IMOpenVZDriver.print
			end
		end	
	end
end
