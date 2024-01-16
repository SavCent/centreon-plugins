#
# Copyright 2024 Centreon (http://www.centreon.com/)
#
# Centreon is a full-fledged industry-strength solution that meets
# the needs in IT infrastructure and application monitoring for
# service performance.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package hardware::devices::camera::hanwha::snmp::mode::hardware;

use base qw(centreon::plugins::templates::hardware);

use strict;
use warnings;

sub set_system {
    my ($self, %options) = @_;

    $self->{cb_hook2} = 'snmp_execute';    
    $self->{thresholds} = {
        service => [
            ['low', 'OK'],
            ['high', 'CRITICAL']
        ],
        sdcard => [
            ['normal', 'OK'],
            ['fail', 'CRITICAL']
        ]
    };
    
    $self->{components_path} = 'hardware::devices::camera::hanwha::snmp::mode::components';
    $self->{components_module} = ['service', 'sdcard'];
}

sub snmp_execute {
    my ($self, %options) = @_;

    $self->{snmp} = $options{snmp};
    my $oid_nwCam = '.1.3.6.1.4.1.36849.1.2';
    $self->{results} = $self->{snmp}->get_multiple_table(oids => [ { oid => $oid_nwCam } ]);
}

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options, force_new_perfdata => 1, no_performance => 1, no_absent => 1);
    bless $self, $class;

    $options{options}->add_options(arguments => {});

    return $self;
}

1;

__END__

=head1 MODE

Check hardware.

=over 8

=item B<--component>

Which component to check (default: '.*').
Can be: 'service', 'sdcard'.

=item B<--filter>

Exclude some parts (comma separated list)
You can also exclude items from specific instances: --filter=instance,relayOutput1

=item B<--no-component>

Define the expected status if no components are found (default: critical).

=item B<--threshold-overload>

Use this option to override the status returned by the plugin when the status label matches a regular expression (syntax: section,[instance,]status,regexp).
Example: --threshold-overload='service,relayOutpu1,OK,high'

=back

=cut
