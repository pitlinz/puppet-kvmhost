require 'resolv'
 
module Puppet::Parser::Functions
	newfunction(:get_ip_addr, :type => :rvalue) do |args|
		# Super sexy regex to match valid IPs
		ip_addr_re = /\b(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\b/
		hostname = args[0].strip
		if hostname =~ ip_addr_re then return hostname end
		begin
			Resolv::DNS.open { |dns| return dns.getaddress hostname }
			rescue Resolv::ResolvError
			return ''
		end
	end
end
