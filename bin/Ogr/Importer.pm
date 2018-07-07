#
# Ogr - The anonymous, static, gradebook generator.
#
# Copyright 2018 Harlan J. Waldrop <harlan@ieee.org>
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     https://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

package Ogr::Importer;

use strict;
use warnings qw( all );

use JSON;
use Switch;

use constant CANVAS => 0;

use constant BASE_URL_CANVAS => 'https://canvas.instructure.com/api/v1/courses';

sub new
{
	my ( $class, $from, $path ) = @_;

	my $type = -1;

	switch ($from)
	{
		case 'canvas' { $type = CANVAS; }
		default:
			die "Import type '$from' is not supported\n";
	}

	my $token = `cat $path | tr -d '\n'`;

	my $self = {
		class => undef,
		section => undef,

		logins => undef,

		type => $type,
		token => $token
	};

	bless $self, $class;

	return $self;
}

sub build
{
	my ( $self ) = @_;

	switch ($self->{type})
	{
		case CANVAS { $self->build_canvas(); }
		default { die "Could not build with type '$self->{type}'\n" };
	}

	my $result = {
		class => $self->{class},
		section => $self->{section},
		logins => $self->{logins}
	};

	# onid | fprint | emoji | text | nick | class | section

	return $result;
}

sub build_canvas()
{
	my $self = shift;

	my @params = (
		'enrollment_state=active',
		'enrollment_type=ta',
		'include=session');

	my $url = BASE_URL_CANVAS . '?' . join('&', @params) .
		"&access_token=$self->{token}";

	my $curl = `curl -s '$url'`;

	my $json = decode_json($curl);

	my $i = 0;
	my (@ids, @codes);

	print "Course Listings:\n";
	for (@$json)
	{
		print "[$i]\t=> { COURSE: $_->{course_code},\n\t\tID: $_->{id} }\n";
		push @ids, $_->{id};
		push @codes, $_->{course_code};
		++$i;
	}

	my $max = $#$json;

	print "Enter the index for the course: ";

	my $choice = int(<STDIN>);

	if ($choice gt $max)
	{
		die "Out of bounds\n";
	}

	$url = BASE_URL_CANVAS . "/$ids[$choice]/students?access_token=$self->{token}";
	$curl = `curl -s '$url'`;
	$json = decode_json($curl);

	my ($name, @code) = $codes[$choice] =~ /([a-z0-9 ]+)\(([a-z]{2,4})_([0-9]{3})_([0-9]{3})_[a-z0-9]+\)/i;
	my $fullcode = join('_', @code);

	my @logins;
	for (@$json)
	{
		push @logins, $_->{login_id};
	}

	$self->{class} = $code[0] . $code[1];
	$self->{section} = $code[2];
	$self->{logins} = \@logins;
}

1;
