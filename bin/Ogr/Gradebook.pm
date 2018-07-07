package Ogr::Gradebook;

use strict;
use warnings qw( all );

use Ogr::Utils qw( pretty_round );

use Data::Dumper;
use Text::CSV_XS;
use Switch;

sub new
{
	my ( $class, @args ) = @_;

	if ((scalar @args) ne 3)
	{
		die "Gradebook requires an input/output path\n";
	}

	my $self =
	{
		files  =>
		{
			in => $args[0],
			out => $args[1],
			db => $args[2]
		},
		gradebook => undef
	};

	bless $self, $class;

	return $self;
}

sub build
{
	my ( $self ) = @_;

	$self->_load_csv();
	$self->_parse_csv();

	$self->_load_idents();
	$self->to_html();
}

sub to_html()
{
	my ( $self ) = @_;

	my $html = '';

	my $t = "\t";
	my $n = "\n";

	my $gradebook = $self->{gradebook};
	my $headers = $gradebook->{headers};

	my $colw = $#$headers;
	my $colspan = $colw + 1 + 2;

	$html .= "<table class='gradebook'>$n";
	$html .= "$t<tr class='title'>$n";
	$html .= "$t$t<th colspan=$colspan>$gradebook->{title}->[0]</th>$n";
	$html .= "$t</tr>$n";

	$html .= "$t<tr class='due'>$n";
	$html .= "$t$t<td></td>$n";

	my $duedates = $gradebook->{due};
	my $outof = $gradebook->{outof};

	# DUE
	for (0 .. $colw)
	{
		$html .= "$t$t<td title='$outof->[$_]'>" .
			"$duedates->[$_]</td>$n";
	}
	$html .= "$t$t<td></td>$n";
	$html .= "$t</tr>$n";

	$html .= "$t<tr class='headers'>$n";
	$html .= "$t$t<th>ident</th>$n";
	for (0 .. $colw)
	{
		my $worth = pretty_round($outof->[$_], $gradebook->{points});
		$html .= "$t$t<th title='$outof->[$_] ($worth)'>$headers->[$_]</th>$n";
	}
	$html .= "$t$t<th>%</th>$n";
	$html .= "$t</tr>$n";

	my %students = %{ $gradebook->{students} };

	my (@sorted, %lut);
	my %idents = %{ $self->{identities} };

	foreach my $key (keys %students)
	{
		my $ident = $idents{$key}[0];

		push @sorted, $ident;
		$lut{$ident} = $key;
	}

	@sorted = sort @sorted;

	my $i = 0;
	foreach (@sorted)
	{
		my $ident = $_;
		my $onid = $lut{$ident};

		my $avatar = $idents{$onid}->[1];
		my $text = $idents{$onid}->[2];

		my $class = ($i & 1) ? 'even' : 'odd';

		$html .= "$t<tr class='$class'>$n";
		$html .= "$t$t<td title='$text'>$ident $avatar</td>$n";

		my $student = $students{$onid};
		my $points = $student->{points};
		my $grades = $student->{grades};
		for (0 .. $colw)
		{
			$html .= "$t$t<td title='$grades->[$_]'>$points->[$_]</td>$n";
		}

		$html .= "$t$t<td title='grade'>$student->{grade}</td>$n";
		$html .= "$t</tr>$n";

		$i++;
	}

	$html .= "</table>\n";

	my $out = $self->{files}->{out};
	open my $fh, '>', $out or die "Could not open $out\n";
	print $fh $html;
	close $fh;
}

sub _load_csv
{
	my ( $self ) = shift;

	my $csv = Text::CSV_XS->new({
		sep_char => qq|\t|
	});

	my @settings = < title headers due outof mute >;

	open(my $fh, '<', $self->{files}{in});
	while (my $row = $csv->getline($fh))
	{
		my @cols = @$row;
		my $colw = scalar @cols;

		if ($colw le 1)
		{
			next;
		}

		my $field = shift @cols;
		my $is_setting = ($field ~~ @settings);

		my @trimmed;

		foreach (@cols)
		{
			if ($_ ne '')
			{
				push @trimmed, $_;
			}
		}

		if ($is_setting)
		{
			$self->{gradebook}{$field} = \@trimmed;
		}
		else
		{
			shift @cols;

			$self->{gradebook}{'students'}{$field} =
			{
				grade  => 100.0,
				points => \@trimmed,
				grades => undef
			};
		}
	}

	close($fh);
}

sub _parse_csv
{
	my ( $self ) = shift;

	my $gradebook = $self->{gradebook};
	if (defined($gradebook) eq 0)
	{
		die "Gradebook not defined\n";
	}

	my $headers = $gradebook->{headers};
	my $outof = $gradebook->{outof};
	my $duedates = $gradebook->{due};
	my $mute = $gradebook->{mute};

	if ((defined($headers) eq 0) ||
		(defined($outof) eq 0) ||
		(defined($duedates) eq 0) ||
		(defined($mute) eq 0))
	{
		die "Gradebook missing required field (headers, outof, due)\n";
	}

	my $colw = $#$headers;

	if (($colw ^ $#$outof) ||
		($colw ^ $#$duedates) ||
		($colw ^ $#$mute))
	{
		die "Assignment rows (headers, outof, due) misaligned\n";
	}

	# TOTAL -- Maximum points possible in class
	my $points = 0.0;
	for (0 .. $colw)
	{
		$points += $outof->[$_];
	}
	$gradebook->{points} = $points;

	# AVERAGE -- Average score per assignment
	@{ $gradebook->{'average'} } = (0) x ($colw + 1);

	# GRADE, GRADES -- Percentage earned total, per assignment
	# AVERAGE - Average per assignment
	my @n = (0) x ($colw + 1);
	while (my ($k, $v) = each $gradebook->{'students'})
	{
		my $points = $v->{'points'};

		if ($colw ^ $#$points)
		{
			die "Assignment rows (headers, outof, due) misaligned for $k: " .
				"expected $colw\n";
		}

		my $total = 0;
		my $total_outof = 0;
		for (0 .. $colw)
		{
			my $point = $points->[$_];
			my $grade = '-';

			if (($mute->[$_] eq 'n') &&
				($point ne '-'))
			{
				$grade = pretty_round($point, $outof->[$_]);
				$total += $point;
				$total_outof += $outof->[$_];

				$gradebook->{'average'}->[$_] += $point;
				$n[$_]++;
			}

			$v->{'grades'}->[$_] = $grade;
		}

		if ($total_outof eq 0)
		{
			$total_outof = 1;
		}

		$v->{'grade'} = int(10000 * $total / $total_outof) / 100;
		$v->{'grade'} = pretty_round($total, $total_outof);
	}

	for (0 .. $colw)
	{
		my $average = '-';

		if ($n[$_] ne 0)
		{
			my $total = $gradebook->{'average'}->[$_];
			my $div = $outof->[$_] * $n[$_];

			$average = pretty_round($total, $div);
		}

		$gradebook->{'average'}->[$_] = $average;
	}
}

sub _load_idents
{
	my ( $self ) = shift;

	my $path = $self->{files}->{db};

	my $handle = DBI->connect("dbi:SQLite:dbname=$path", "", "");

	my $query = $handle->prepare("SELECT * FROM students");
	$query->execute();
	my $row = $query->fetchall_arrayref({});
	$query->finish;
	$handle->disconnect();

	my %idents;

	for (@$row)
	{
		my $id = $_->{id};
		my $name = $_->{nick};
		if (defined($name) == 0)
		{
			$name = $_->{fprint};
		}

		my $emoji = $_->{emoji};
		my $text = $_->{text};

		$idents{$id} = [ $name, $emoji, $text ];
	}

	$self->{identities} = \%idents;
}

1;
