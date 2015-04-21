/**
 * define a class to add a package only if not defined
 *
 */
define kvmhost::tools::checkpackage(
    $ensure = installed,
) {
    if !defined(Package[$name]) {
        package{"${name}":
            ensure => $ensure,
		}
    }
}
