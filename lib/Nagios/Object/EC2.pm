package Nagios::Object::EC2;

use warnings;
use strict;
use Carp;

use version; our $VERSION = qv('0.0.1');

use Exporter::Lite;
our @EXPORT = qw/generate/;

use IO::File;
use VM::EC2;
use Text::Xslate qw(mark_raw);

sub new {
    my $class = shift;

    my %args = @_;

    my $self = {
        -access_key  => $args{access_key}, 
        -secret_key  => $args{secret_key},
        -endpoint    => $args{endpoint},
        -print_error => 1
    };
    bless $self, $class;
 
    return $self;
}

sub generate {
    my $self = shift;

    my ($template_dir, $objects_dir) = @_;
    unless ( -d $template_dir && -d $objects_dir) {
        warn "$template_dir or $objects_dir is not found";
    }

    my $ec2 = VM::EC2->new(
        -access_key  => $self->{-access_key}, 
        -secret_key  => $self->{-secret_key},
        -endpoint    => $self->{-endpoint},
        -print_error => 1
    );

    my $members;
    my $hosts;

    my @instances = $ec2->describe_instances();
    for my $i (@instances) {
        next unless ($i->current_status eq 'running');
        
        my $dns  = $i->dnsName;
        my $addr = $i->privateIpAddress;

        next unless ($i->tagSet->{Role});
        my @roles = split /:/, $i->tagSet->{Role};
        foreach my $role (@roles) {
            unless ($members->{$role}) {
                $members->{$role} = $dns;
            }
            else {
                $members->{$role} .= ",$dns";
            }
                
            $hosts->{$role} = [] unless ($hosts->{$role});
            my $host = {
                name => $dns,
                address => $addr
            };
            unshift $hosts->{$role}, $host;
        }
    }

    for my $role (keys $members) {
        my $template_file = "$template_dir/$role.template";
        unless (-f $template_file) {
            warn "$template_file is not found. Please create $template_file";
            next;
        }

        my $object_file = "$objects_dir/$role.cfg";
        my $fh = IO::File->new( "> $object_file" )
            or die "Could not create filehandle: $!";
        print "generates $object_file\n";

        my $tx = Text::Xslate->new();
        my %vars = (
            members => $members->{$role},
            hosts   => $hosts->{$role},
        );
        print $fh $tx->render($template_file, \%vars);
    }

}

1;
__END__

=head1 NAME

Nagios::Object::EC2 - nagios object file generator for Amazon EC2


=head1 VERSION

version 0.0.1 beta


=head1 SYNOPSIS

    use Nagios::Object::EC2;
    
    my $ec2_object = Nagios::Object::EC2->new(
        access_key => $ENV{AMAZON_ACCESS_KEY_ID}, 
        secret_key => $ENV{AMAZON_SECRET_ACCESS_KEY},
        endpoint   => $ENV{EC2_URL}, 
    );
    
    $ec2_object->generate($template_dir, $objects_dir);
    
=head1 DESCRIPTION

Generates nagios object files (*.cfg) in $objects_dir with template files (*.template) in $template_dir ;

Before using this module, you should assign "Role" tag to your ec2 instances.
Format of "Role" tag is like these:

    k=Role, v=base
    k=Role, v=base:web
    k=Role, v=base:db

Separated by ':' if you want to assign multiple roles.

=head1 METHODS 

=over 4

=item new($args)

Create a new configuration object.

=item generate($template_dir, $objects_dir)

Generate new nagios object files from template.

Example of template file: base.template

    define hostgroup {
        hostgroup_name base 
        alias base 
        members <: $members :>
    }

    : for $hosts -> $host {
    define host {
        use generic-host
        host_name <: $host.name :> 
        alias base 
        address <: $host.address :> 
        max_check_attempts 10
        contact_groups admins
    }
    : }

    define service {
        use generic-service
        hostgroup_name base 
        service_description SSH
        check_command check_ssh!22
    }

=back

=head1 AUTHOR

Takumi SAKAMOTO  C<< <takumi.saka@gmail.com> >>


=head1 LICENCE AND COPYRIGHT

Copyright (c) 2012, Takumi SAKAMOTO C<< <takumi.saka@gmail.com> >>. All rights reserved.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself. See L<perlartistic>.


=head1 DISCLAIMER OF WARRANTY

BECAUSE THIS SOFTWARE IS LICENSED FREE OF CHARGE, THERE IS NO WARRANTY
FOR THE SOFTWARE, TO THE EXTENT PERMITTED BY APPLICABLE LAW. EXCEPT WHEN
OTHERWISE STATED IN WRITING THE COPYRIGHT HOLDERS AND/OR OTHER PARTIES
PROVIDE THE SOFTWARE "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
EXPRESSED OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE. THE
ENTIRE RISK AS TO THE QUALITY AND PERFORMANCE OF THE SOFTWARE IS WITH
YOU. SHOULD THE SOFTWARE PROVE DEFECTIVE, YOU ASSUME THE COST OF ALL
NECESSARY SERVICING, REPAIR, OR CORRECTION.

IN NO EVENT UNLESS REQUIRED BY APPLICABLE LAW OR AGREED TO IN WRITING
WILL ANY COPYRIGHT HOLDER, OR ANY OTHER PARTY WHO MAY MODIFY AND/OR
REDISTRIBUTE THE SOFTWARE AS PERMITTED BY THE ABOVE LICENCE, BE
LIABLE TO YOU FOR DAMAGES, INCLUDING ANY GENERAL, SPECIAL, INCIDENTAL,
OR CONSEQUENTIAL DAMAGES ARISING OUT OF THE USE OR INABILITY TO USE
THE SOFTWARE (INCLUDING BUT NOT LIMITED TO LOSS OF DATA OR DATA BEING
RENDERED INACCURATE OR LOSSES SUSTAINED BY YOU OR THIRD PARTIES OR A
FAILURE OF THE SOFTWARE TO OPERATE WITH ANY OTHER SOFTWARE), EVEN IF
SUCH HOLDER OR OTHER PARTY HAS BEEN ADVISED OF THE POSSIBILITY OF
SUCH DAMAGES.
