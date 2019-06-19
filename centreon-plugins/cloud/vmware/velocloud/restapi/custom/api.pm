#
# Copyright 2019 Centreon (http://www.centreon.com/)
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

package cloud::vmware::velocloud::restapi::custom::api;

use strict;
use warnings;
use centreon::plugins::http;
use JSON::XS;

sub new {
    my ($class, %options) = @_;
    my $self  = {};
    bless $self, $class;

    if (!defined($options{output})) {
        print "Class Custom: Need to specify 'output' argument.\n";
        exit 3;
    }
    if (!defined($options{options})) {
        $options{output}->add_option_msg(short_msg => "Class Custom: Need to specify 'options' argument.");
        $options{output}->option_exit();
    }
    
    if (!defined($options{noptions})) {
        $options{options}->add_options(arguments => {                      
            "hostname:s"    => { name => 'hostname' },
            "port:s"        => { name => 'port' },
            "proto:s"       => { name => 'proto' },
            "username:s"    => { name => 'username' },
            "password:s"    => { name => 'password' },
            "operator-user" => { name => 'operator_user' },
            "api-path:s"    => { name => 'api_path' },
            "timeout:s"     => { name => 'timeout' },
        });
    }
    $options{options}->add_help(package => __PACKAGE__, sections => 'REST API OPTIONS', once => 1);

    $self->{output} = $options{output};
    $self->{mode} = $options{mode};
    $self->{http} = centreon::plugins::http->new(%options);
    
    return $self;
}

sub set_options {
    my ($self, %options) = @_;

    $self->{option_results} = $options{option_results};
}

sub set_defaults {
    my ($self, %options) = @_;

    foreach (keys %{$options{default}}) {
        if ($_ eq $self->{mode}) {
            for (my $i = 0; $i < scalar(@{$options{default}->{$_}}); $i++) {
                foreach my $opt (keys %{$options{default}->{$_}[$i]}) {
                    if (!defined($self->{option_results}->{$opt}[$i])) {
                        $self->{option_results}->{$opt}[$i] = $options{default}->{$_}[$i]->{$opt};
                    }
                }
            }
        }
    }
}

sub check_options {
    my ($self, %options) = @_;

    $self->{hostname} = (defined($self->{option_results}->{hostname})) ? $self->{option_results}->{hostname} : undef;
    $self->{proto} = (defined($self->{option_results}->{proto})) ? $self->{option_results}->{proto} : 'https';
    $self->{port} = (defined($self->{option_results}->{port})) ? $self->{option_results}->{port} : 443;
    $self->{username} = (defined($self->{option_results}->{username})) ? $self->{option_results}->{username} : undef;
    $self->{password} = (defined($self->{option_results}->{password})) ? $self->{option_results}->{password} : undef;
    $self->{api_path} = (defined($self->{option_results}->{api_path})) ? $self->{option_results}->{api_path} : '/portal/rest';
    $self->{timeout} = (defined($self->{option_results}->{timeout})) ? $self->{option_results}->{timeout} : 10;
 
    if (!defined($self->{hostname}) || $self->{hostname} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --hostname option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{username}) || $self->{username} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --username option.");
        $self->{output}->option_exit();
    }
    if (!defined($self->{password}) || $self->{password} eq '') {
        $self->{output}->add_option_msg(short_msg => "Need to specify --password option.");
        $self->{output}->option_exit();
    }

    return 0;
}

sub get_connection_infos {
    my ($self, %options) = @_;
    
    return $self->{hostname}  . '_' . $self->{http}->get_port();
}

sub build_options_for_httplib {
    my ($self, %options) = @_;

    $self->{option_results}->{hostname} = $self->{hostname};
    $self->{option_results}->{timeout} = $self->{timeout};
    $self->{option_results}->{port} = $self->{port};
    $self->{option_results}->{proto} = $self->{proto};
}

sub settings {
    my ($self, %options) = @_;

    $self->build_options_for_httplib();
    $self->{http}->add_header(key => 'Accept', value => 'application/json');
    $self->{http}->add_header(key => 'Content-Type', value => 'application/json');
    if (defined($self->{session_cookie})) {
        $self->{http}->add_header(key => 'Cookie', value => 'velocloud.session=' . $self->{session_cookie});
    }
    $self->{http}->set_options(%{$self->{option_results}});
}

sub get_session_cookie {
    my ($self, %options) = @_;
    
    my $form_post = { username => $self->{username}, password => $self->{password} };
    my $encoded;
    eval {
        $encoded = encode_json($form_post);
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot encode json request");
        $self->{output}->option_exit();
    }

    $self->settings();

    my $login_url = (defined($self->{option_results}->{operator_user})) ? '/login/operatorLogin' : '/login/enterpriseLogin';
    my $content = $self->{http}->request(
        method => 'POST',
        url_path => $self->{api_path} . $login_url,
        query_form_post => $encoded
    );
    my ($cookie) = $self->{http}->get_header(name => 'Set-Cookie');
    $cookie =~ /velocloud.message=(.*);/
    my $message = $1;
    $cookie =~ /velocloud.session=(.*);/
    my $session = $1;

    if (!defined($session)) {
        $self->{output}->add_option_msg(short_msg => "Cannot get session cookie: " . $message);
        $self->{output}->option_exit();
    }
    
    $self->{session_cookie} = $session;
}

sub get_entreprise_id {
    my ($self, %options) = @_;
    
    my $content = $self->{http}->request(
        method => 'POST',
        url_path => $self->{api_path} . '/enterprise/getEnterprise'
    );

    my $decoded;
    eval {
        $decoded = decode_json($content);
    };
    if ($@) {
        $self->{output}->output_add(long_msg => $content, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }
    
    $self->{entreprise_id} = $decoded->{id};
}

sub request_api {
    my ($self, %options) = @_;

    if (!defined($self->{session_cookie})) {
        $self->get_session_cookie();
    }

    $self->settings();

    if (!defined($self->{entreprise_id})) {
        $self->get_entreprise_id();
    }
    
    my $encoded_form_post;
    eval {
        $encoded_form_post = encode_json($options{query_form_post});
    };
    if ($@) {
        $self->{output}->add_option_msg(short_msg => "Cannot encode json request");
        $self->{output}->option_exit();
    }

    $self->{output}->output_add(long_msg => "URL: '" . $self->{proto} . '://' . $self->{hostname} . ':' .
        $self->{port} . $options{url_path} . "'", debug => 1);

    my $content = $self->{http}->request(
        method => $options{method},
        url_path => $options{url_path},
        query_form_post => $encoded_form_post,
        critical_status => '', warning_status => '', unknown_status => ''
    );

    my $decoded;
    eval {
        $decoded = decode_json($content);
    };
    if ($@) {
        $self->{output}->output_add(long_msg => $content, debug => 1);
        $self->{output}->add_option_msg(short_msg => "Cannot decode json response");
        $self->{output}->option_exit();
    }

    return $decoded;
}

sub list_edges {
    my ($self, %options) = @_;
    
    my $response = $self->request_api(
        method => 'POST',
        url_path => '/enterprise/getEnterpriseEdges',
        query_form_post => { enterpriseId => $self->{entreprise_id} }
    );
    
    return $response;
}

sub DESTROY {
    my $self = shift;

    if (defined($self->{session_cookie})) {
        $self->request_api(method => 'POST', url_path => $self->{api_path} . '/logout');
    }
}

1;

__END__

=head1 NAME

VMware VeloCloud Orchestrator REST API

=head1 SYNOPSIS

VMware VeloCloud Orchestrator Rest API custom mode

=head1 REST API OPTIONS

=over 8

=item B<--hostname>

VMware VeloCloud Orchestrator hostname.

=item B<--port>

Port used (Default: 443)

=item B<--proto>

Specify https if needed (Default: 'https')

=item B<--username>

VMware VeloCloud Orchestrator username.

=item B<--password>

VMware VeloCloud Orchestrator password.

=item B<--operator-user>

Set if the user is an operator.

=item B<--api-path>

API base url path (Default: '/portal/rest').

=item B<--timeout>

Set HTTP timeout in seconds (Default: '10').

=back

=head1 DESCRIPTION

B<custom>.

=cut
