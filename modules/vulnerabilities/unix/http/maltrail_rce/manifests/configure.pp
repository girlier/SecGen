# Class: maltrail_rce::configure
# Configuration for vulnerable MalTrail
class maltrail_rce::configure {
  $secgen_parameters = secgen_functions::get_parameters($::base64_inputs_file)
  $user = $secgen_parameters['unix_username'][0]
  $leaked_filenames = $secgen_parameters['leaked_filenames']
  $strings_to_leak = $secgen_parameters['strings_to_leak']

  Exec { path => [ '/bin/', '/sbin/' , '/usr/bin/', '/usr/sbin/' ] }

  # Leak flag files to user's home directory for exploitation verification
  ::secgen_functions::leak_files { 'maltrail-flag-leak':
    storage_directory => "/home/${user}",
    leaked_filenames  => $leaked_filenames,
    strings_to_leak   => $strings_to_leak,
    owner             => $user,
    mode              => '0600',
    leaked_from       => 'maltrail_rce',
  }
}
