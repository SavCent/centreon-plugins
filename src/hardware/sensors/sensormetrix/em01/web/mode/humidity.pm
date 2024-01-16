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

package hardware::sensors::sensormetrix::em01::web::mode::humidity;

use base qw(centreon::plugins::mode);

use strict;
use warnings;
use centreon::plugins::http;

sub new {
    my ($class, %options) = @_;
    my $self = $class->SUPER::new(package => __PACKAGE__, %options);
    bless $self, $class;

    $options{options}->add_options(arguments => {
        "hostname:s"        => { name => 'hostname' },
        "port:s"            => { name => 'port', },
        "proto:s"           => { name => 'proto' },
        "urlpath:s"         => { name => 'url_path', default => "/index.htm?em" },
        "credentials"       => { name => 'credentials' },
        "basic"             => { name => 'basic' },
        "username:s"        => { name => 'username' },
        "password:s"        => { name => 'password' },
        "warning:s"         => { name => 'warning' },
        "critical:s"        => { name => 'critical' },
        "timeout:s"         => { name => 'timeout' },
    });
    $self->{http} = centreon::plugins::http->new(%options);
    return $self;
}

sub check_options {
    my ($self, %options) = @_;
    $self->SUPER::init(%options);

    if (($self->{perfdata}->threshold_validate(label => 'warning', value => $self->{option_results}->{warning})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong warning threshold '" . $self->{option_results}->{warning} . "'.");
        $self->{output}->option_exit();
    }
    if (($self->{perfdata}->threshold_validate(label => 'critical', value => $self->{option_results}->{critical})) == 0) {
        $self->{output}->add_option_msg(short_msg => "Wrong critical threshold '" . $self->{option_results}->{critical} . "'.");
        $self->{output}->option_exit();
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

sub run {
    my ($self, %options) = @_;
        
    my $webcontent = $self->{http}->request();
    my $humidity;

    if ($webcontent !~ /<body>(.*)<\/body>/msi || $1 !~ /HU:\s*([0-9\.]+)/i) {
        $self->{output}->add_option_msg(short_msg => "Could not find humidity information.");
        $self->{output}->option_exit();
    }
    $humidity = $1;
    $humidity = '0' . $humidity if ($humidity =~ /^\./);

    my $exit = $self->{perfdata}->threshold_check(value => $humidity, threshold => [ { label => 'critical', 'exit_litteral' => 'critical' }, { label => 'warning', exit_litteral => 'warning' } ]);
    
    $self->{output}->output_add(severity => $exit,
                                short_msg => sprintf("Humidity: %.2f %%", $humidity));
    $self->{output}->perfdata_add(label => "humidity", unit => '%',
                                  value => sprintf("%.2f", $humidity),
                                  warning => $self->{perfdata}->get_perfdata_for_output(label => 'warning'),
                                  critical => $self->{perfdata}->get_perfdata_for_output(label => 'critical'),
                                  );

    $self->{output}->display();
    $self->{output}->exit();

}

1;

__END__

=head1 MODE

Check sensor Humidity.

=over 8

=item B<--hostname>

IP Addr/FQDN of the web server host

=item B<--port>

Port used by Apache

=item B<--proto>

Specify https if needed

=item B<--urlpath>

Set path to get server-status page in auto mode (default: '/index.htm?em')

=item B<--credentials>

Specify this option if you access server-status page with authentication

=item B<--username>

Specify the username for authentication (mandatory if --credentials is specified)

=item B<--password>

Specify the password for authentication (mandatory if --credentials is specified)

=item B<--basic>

Specify this option if you access server-status page over basic authentication and don't want a '401 UNAUTHORIZED' error to be logged on your web server.

Specify this option if you access server-status page over hidden basic authentication or you'll get a '404 NOT FOUND' error.

(use with --credentials)

=item B<--timeout>

Threshold for HTTP timeout

=item B<--warning>

Warning Threshold for Humidity

=item B<--critical>

Critical Threshold for Humidity

=back

=cut
