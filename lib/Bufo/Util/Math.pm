package Bufo::Util::Math;
use strict;
use warnings;
use Bufo::Util::Validation ();
use Bufo::Util::Number     ();

sub new {
    my ( $class, %args ) = @_;
    bless { random => $args{random} // sub { rand() } }, $class;
}

sub _valid {
    for (@_) { return 0 unless Bufo::Util::Validation::isValidNumber($_) }
    return 1;
}
sub _floor { Bufo::Util::Number::_floor( $_[0] ) }
sub _clamp { $_[0] < $_[1] ? $_[1] : $_[0] > $_[2] ? $_[2] : $_[0] }

sub randomInt {
    my ( $self, $min, $max ) = @_;
    $min = -_floor( -$min );
    $max = _floor($max);
    return _floor( $self->{random}->() * ( $max - $min + 1 ) ) + $min;
}

sub randomFloat {
    my ( $self, $min, $max, $digits ) = @_;
    return 0 unless _valid( $min, $max );
    return Bufo::Util::Number::roundTo( $self->{random}->() * ( $max - $min ) + $min,
        $digits // 2 );
}

sub mapRange {
    my ( $self, $v, $a, $b, $c, $d, $clamp ) = @_;
    return $c unless _valid( $v, $a, $b, $c, $d ) && $a != $b;
    my $r = ( $v - $a ) / ( $b - $a ) * ( $d - $c ) + $c;
    return $r if defined($clamp) && !$clamp;
    return $c < $d ? _clamp( $r, $c, $d ) : _clamp( $r, $d, $c );
}

sub inRange {
    my ( $self, $v, $a, $b ) = @_;
    return 0 unless _valid($v);
    ( $a, $b ) = ( $b, $a ) if $a > $b;
    return $v >= $a && $v <= $b ? 1 : 0;
}

sub lerp {
    my ( $self, $a, $b, $t ) = @_;
    return $a unless _valid( $a, $b, $t );
    $t = _clamp( $t, 0, 1 );
    return $a * ( 1 - $t ) + $b * $t;
}

sub inverseLerp {
    my ( $self, $a, $b, $v ) = @_;
    return 0 unless _valid( $a, $b, $v ) && $a != $b;
    return _clamp( ( $v - $a ) / ( $b - $a ), 0, 1 );
}

sub distance {
    my ( $self, $x, $y, $xx, $yy ) = @_;
    return 0 unless _valid( $x, $y, $xx, $yy );
    return sqrt( ( $xx - $x )**2 + ( $yy - $y )**2 );
}

sub angle {
    my ( $self, $x, $y, $xx, $yy ) = @_;
    return 0 unless _valid( $x, $y, $xx, $yy );
    return atan2( $yy - $y, $xx - $x );
}
sub toDegrees { my ( $self, $v ) = @_; return _valid($v) ? $v * 180 / ( 4 * atan2( 1, 1 ) ) : 0 }
sub toRadians { my ( $self, $v ) = @_; return _valid($v) ? $v * ( 4 * atan2( 1, 1 ) ) / 180 : 0 }

sub pointFromAngle {
    my ( $self, $x, $y, $a, $d ) = @_;
    return [ $x, $y ] unless _valid( $x, $y, $a, $d );
    return [ $x + cos($a) * $d, $y + sin($a) * $d ];
}

sub smoothLerp {
    my ( $self, $a, $b, $t, $smooth ) = @_;
    return $a unless _valid( $a, $b, $t );
    $t      = _clamp( $t, 0, 1 );
    $smooth = 2 unless defined $smooth;
    for ( my $i = 0 ; $i < $smooth ; $i++ ) { $t = $t * $t * ( 3 - 2 * $t ) }
    return $a * ( 1 - $t ) + $b * $t;
}

sub weightedRandom {
    my ( $self, $weights ) = @_;
    return -1 unless ref($weights) eq 'ARRAY' && @$weights;
    my $sum = 0;
    $sum += $_ > 0 ? $_ : 0 for @$weights;
    return -1 if $sum <= 0;
    my $random  = $self->{random}->() * $sum;
    my $partial = 0;
    for my $i ( 0 .. $#$weights ) {
        $partial += $weights->[$i] > 0 ? $weights->[$i] : 0;
        return $i if $random < $partial;
    }
    return $#$weights;
}

sub factorial {
    my ( $self, $n ) = @_;
    return 1 unless Bufo::Util::Validation::isValidInteger($n) && $n >= 0;
    my $r = 1;
    for ( my $i = 2 ; $i <= $n ; $i++ ) { $r *= $i }
    return $r;
}

sub chance {
    my ( $self, $n ) = @_;
    return 0 unless _valid($n);
    return $self->{random}->() * 100 < _clamp( $n, 0, 100 ) ? 1 : 0;
}

sub randomNormal {
    my ( $self, $mean, $std ) = @_;
    $mean = 0 unless defined $mean;
    $std  = 1 unless defined $std;
    return 0 unless _valid( $mean, $std );
    my ( $u, $v ) = ( 0, 0 );
    $u = $self->{random}->() while $u == 0;
    $v = $self->{random}->() while $v == 0;
    return sqrt( -2 * log($u) ) * cos( 8 * atan2( 1, 1 ) * $v ) * $std + $mean;
}
1;
