package Range::ArrayIter;

# DATE
# VERSION

use strict;
use warnings;

use Exporter qw(import);
our @EXPORT_OK = qw(range_arrayiter);

my $re_num = qr/\A[+-]?[0-9]+(\.[0-9]+)?\z/;

sub range_arrayiter($$;$) : lvalue {
    my ($start, $end, $step) = @_;

    tie my @ary, 'Range::ArrayIter::Tie', $start, $end, $step;
    \@ary;
}

package # hide from PAUSE
    Range::ArrayIter::Tie;

sub TIEARRAY {
    my $class = shift;
    my ($start, $end, $step) = @_;
    $step //= 1;

    my $self = {
        start => $start,
        end   => $end,
        step  => $step,

        _ended => 0,
        _len   => 0,
        _cur   => $start,
        _buf   => [],
    };

    if ($start =~ $re_num && $end =~ $re_num) {
        $self->{_num}   = 1;
        $self->{_ended}++ if $start > $end;
    } else {
        die "Cannot specify step != 1 for non-numeric range" if $step != 1;
        $self->{_ended}++ if $start gt $end;
    }
    bless $self, $class;
}

sub _next {
    my $self = shift;

    if ($self->{_num}) {
        $self->{_ended}++ if $self->{_cur} > $self->{end};
        return if $self->{_ended};
        push @{ $self->{_buf} }, $self->{_cur};
        $self->{_cur} += $self->{step};
    } else {
        return if $self->{_ended};
        $self->{_ended}++ if $self->{_cur} ge $self->{end};
        push @{ $self->{_buf} }, $self->{_cur}++;
    }
}

sub FETCHSIZE {
    my $self = shift;
    $self->_next;
    $self->{_len} + @{ $self->{_buf} };
}

sub FETCH {
    my $self = shift;
    $self->_next;
    if (@{ $self->{_buf} }) {
        $self->{_len}++;
        shift @{ $self->{_buf} };
    } else {
        undef;
    }
}

1;
#ABSTRACT: Generate a tied-array iterator for range

=for Pod::Coverage .+

=head1 SYNOPSIS

  use Range::ArrayIter qw(range_arrayiter);

  my $iter = range_arrayiter(1, 10);
  for (@$iter) { ... } # 1, 2, 3, 4, 5, 6, 7, 8, 9, 10

You can add step:

 my $iter = range_arrayiter(1, 10, 2); # 1, 3, 5, 7, 9

Anything that can be incremented by Perl is game:

  $iter = range_arrayiter("a", "e"); # a, b, c, d, e


=head1 DESCRIPTION

B<PROOF OF CONCEPT.>

This module offers a tied-array-based iterator that you can use using for()
loop. It's most probably useful as a proof of concept only.


=head1 FUNCTIONS

=head2 range_arrayiter($start, $end) => arrayref


=head1 SEE ALSO

L<Range::Iter>

=cut
