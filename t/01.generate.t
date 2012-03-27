use strict;
use Test::More;
plan( tests => 1 );

use Nagios::Object::EC2;

my $access_key = $ENV{AMAZON_ACCESS_KEY_ID};
my $secret_key = $ENV{AMAZON_SECRET_ACCESS_KEY}; 
my $end_point  = $ENV{EC2_URL};

unless ($access_key && $secret_key && $end_point) {
   fail("environment value is not set"); 
}

my $ec2_object = Nagios::Object::EC2->new(
    access_key => $access_key, 
    secret_key => $secret_key,
    endpoint   => $end_point, 
);

$ec2_object->generate('./t/template', './t/objects');

is(1, 1);

1;
