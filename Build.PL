use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Nagios::Object::EC2',
    license             => 'perl',
    dist_author         => 'Takumi SAKAMOTO <takumi.saka@gmail.com>',
    dist_version_from   => 'lib/Nagios/Object/EC2.pm',
    requires => {
        'Test::More' => 0,
        'version'    => 0,
    },
    add_to_cleanup      => [ 'Nagios-Object-EC2-*' ],
);

$builder->create_build_script();
