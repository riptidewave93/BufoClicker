package Bufo::Util::Time;
use strict;
use warnings;
use Bufo::Util::Number     ();
use Bufo::Util::Validation ();
use Bufo::Util::Deferred;

sub new {
    my ( $class, %args ) = @_;
    bless { now => $args{now} // sub { time() * 1000 }, %args }, $class;
}
sub getCurrentTime { $_[0]{now}->() }

sub calculateElapsedTime {
    my ( $self, $start, $end ) = @_;
    $end = $self->getCurrentTime unless defined $end;
    return 0
      unless Bufo::Util::Validation::isValidNumber($start)
      && Bufo::Util::Validation::isValidNumber($end);
    return $end > $start ? $end - $start : 0;
}

sub formatTimeAgo {
    my ( $self, $stamp, $reference ) = @_;
    return 'unknown time ago' unless Bufo::Util::Validation::isValidNumber($stamp);
    my $seconds =
      Bufo::Util::Number::_floor( $self->calculateElapsedTime( $stamp, $reference ) / 1000 );
    my ( $count, $unit ) = ( $seconds, 'second' );
    if ( $seconds >= 60 ) { $count = Bufo::Util::Number::_floor( $seconds / 60 ); $unit = 'minute' }
    if ( $seconds >= 3600 ) {
        $count = Bufo::Util::Number::_floor( $seconds / 3600 );
        $unit  = 'hour';
    }
    if ( $seconds >= 86400 ) {
        $count = Bufo::Util::Number::_floor( $seconds / 86400 );
        $unit  = 'day';
    }
    if ( $seconds >= 2592000 ) {
        $count = Bufo::Util::Number::_floor( $seconds / 2592000 );
        $unit  = 'month';
    }
    if ( $seconds >= 31104000 ) {
        $count = Bufo::Util::Number::_floor( $seconds / 31104000 );
        $unit  = 'year';
    }
    return "$count $unit" . ( $count == 1 ? '' : 's' ) . ' ago';
}

sub _schedule {
    my ( $self, $fn, $ms ) = @_;
    die "A timer schedule adapter is required\n" unless $self->{schedule};
    return $self->{schedule}->( $fn, $ms );
}

sub _cancel {
    my ( $self, $id ) = @_;
    die "A timer cancel adapter is required\n" unless $self->{cancel};
    $self->{cancel}->($id);
    return;
}

sub throttle {
    my ( $self, $fn, $delay ) = @_;
    my $last = 0;
    my $timer;
    return sub {
        my @args    = @_;
        my $now     = $self->getCurrentTime;
        my $elapsed = $now - $last;
        $self->_cancel($timer) if defined $timer;
        $timer = undef;
        if ( $elapsed >= $delay ) { $last = $now; $fn->(@args) }
        else {
            $timer =
              $self->_schedule( sub { $last = $self->getCurrentTime; $fn->(@args); $timer = undef },
                $delay - $elapsed );
        }
        return;
    };
}

sub debounce {
    my ( $self, $fn, $delay ) = @_;
    my $timer;
    return sub {
        my @args = @_;
        $self->_cancel($timer) if defined $timer;
        $timer = $self->_schedule( sub { $fn->(@args); $timer = undef }, $delay );
        return;
    }
}

sub calculateFPS {
    my ( $self, $delta ) = @_;
    return 0 unless Bufo::Util::Validation::isValidNumber($delta) && $delta > 0;
    return Bufo::Util::Number::roundTo( 1000 / $delta, 0 );
}

sub formatTimestamp {
    my ( $self, $stamp, $include ) = @_;
    $include = 1 unless defined $include;
    return 'Invalid date'
      unless Bufo::Util::Validation::isValidNumber($stamp) && abs($stamp) <= 8640000000000000;
    if ( $self->{format_date} ) {
        my $result = eval { $self->{format_date}->( $stamp, $include ) };
        return $@ ? 'Error formatting date' : $result;
    }
    my @date = localtime( $stamp / 1000 );
    return 'Invalid date' unless @date;
    my @months = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);
    my $result = "$months[$date[4]] $date[3], " . ( $date[5] + 1900 );
    if ($include) {
        my $hour = $date[2] % 12;
        $hour = 12 unless $hour;
        $result .=
          sprintf( ', %02d:%02d:%02d %s', $hour, $date[1], $date[0], $date[2] >= 12 ? 'PM' : 'AM' );
    }
    return $result;
}

sub delay {
    my ( $self, $ms ) = @_;
    my $deferred = Bufo::Util::Deferred->new;
    $self->_schedule( sub { $deferred->resolve(undef) }, $ms );
    return $deferred;
}

sub cancellableDelay {
    my ( $self, $ms ) = @_;
    my $deferred = Bufo::Util::Deferred->new;
    my $id       = $self->_schedule( sub { $deferred->resolve(undef) }, $ms );
    return { promise => $deferred, cancel => sub { $self->_cancel($id) } };
}
1;
