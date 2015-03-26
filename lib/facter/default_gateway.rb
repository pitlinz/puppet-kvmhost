Facter.add('default_gateway') do
  confine :kernel => 'Linux'
  setcode do
    Facter::Core::Execution.exec("/sbin/route -n | /bin/grep ^0 | /usr/bin/cut -b 17-32 | /usr/bin/tr  -d '[[:space:]]'")
  end
end