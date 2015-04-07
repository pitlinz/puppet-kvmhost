/**
 * class to install network time server
 */
class kvmhost::tools::ntp(
    $timeservers = [
        '0.debian.pool.ntp.org',
		'1.debian.pool.ntp.org',
		'2.debian.pool.ntp.org',
		'3.debian.pool.ntp.org',
    ],
    $restrictions = [
        '192.168.0.0 netmask 255.255.0.0'
    ],
	$broadcast = "",
){

}
