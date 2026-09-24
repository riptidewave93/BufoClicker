package Bufo::Util::Number;
use strict;
use warnings;
use Bufo::Util::Validation ();
my @suffix = ( '', qw(K M B T Qa Qi Sx Sp Oc No Dc) );
my @names  = (
    '',
    qw(Thousand Million Billion Trillion Quadrillion Quintillion Sextillion Septillion Octillion Nonillion Decillion)
);
sub _finite { Bufo::Util::Validation::isValidNumber( $_[0] ) }
sub _floor  { my ($v) = @_; my $n = 0 + sprintf( '%.0f', $v ); return $n > $v ? $n - 1 : $n }

sub roundTo {
    my ( $v, $digits ) = @_;
    return 0 unless _finite($v);
    $digits = 2 unless defined $digits;
    my $factor = 10**$digits;
    return _floor( $v * $factor + 0.5 ) / $factor;
}

sub clamp {
    my ( $v, $min, $max ) = @_;
    return $min unless _finite($v);
    my $atleast = $v < $min ? $min : $v;
    return $atleast > $max ? $max : $atleast;
}

sub calculateExponentialCost {
    my ( $base, $mult, $owned ) = @_;
    $owned = 0 if $owned < 0;
    return $base * $mult**$owned;
}

sub _group {
    my ($text) = @_;
    my ( $whole, $fraction ) = split /\./, $text, 2;
    $whole =~ s/(\d)(?=(\d{3})+$)/$1,/g;
    return $whole . ( defined($fraction) ? '.' . $fraction : '' );
}

sub _tier {
    my ($n) = @_;
    my $t   = 0;
    my $v   = abs($n);
    while ( $v >= 1000 && $t < $#suffix ) { $v /= 1000; $t++ }
    return $t;
}

sub _digits {
    my ($d) = @_;
    die 'Decimal precision out of range' unless _finite($d) && $d >= 0 && $d <= 100;
    return _floor($d);
}

sub formatNumber {
    my ( $v, $digits ) = @_;
    return '0' unless _finite($v) && $v != 0;
    $digits = defined($digits) ? $digits : 1;
    if ( abs($v) < 1000 ) {
        my $rounded = roundTo( $v,            $digits );
        my $locale  = roundTo( abs($rounded), 3 );
        $locale = -$locale if $rounded < 0;
        my $text = sprintf( '%.3f', $locale );
        $text =~ s/\.?0+$// if $text =~ /\./;
        return _group($text);
    }
    return _group( sprintf( '%.0f', roundTo( $v, 0 ) ) ) if abs($v) < 1000000;
    $digits = _digits($digits);
    my $tier    = _tier($v);
    my $scaled  = $v / ( 1000**$tier );
    my $display = $scaled > 999999 ? 999999 : $scaled;
    my $rounded = roundTo( abs($display), $digits );
    $rounded = -$rounded if $display < 0;
    return
        _group( sprintf( '%.*f', $digits, $rounded ) )
      . $suffix[$tier]
      . ( $scaled > $display ? '+' : '' );
}

sub formatNumberWithPrecision {
    my ($v) = @_;
    return '0' unless _finite($v) && $v != 0;
    return _group( sprintf( '%.0f', roundTo( $v, 0 ) ) ) if abs($v) < 1e12;
    return formatNumber( $v, 3 );
}

sub getNumberFullName {
    return '' unless _finite( $_[0] ) && abs( $_[0] ) >= 1000;
    return $names[ _tier( $_[0] ) ];
}

sub formatDuration {
    my ($s) = @_;
    return '0s' unless _finite($s) && $s >= 0;
    return _floor($s) . 's' if $s < 60;
    my $h   = _floor( $s / 3600 );
    my $m   = _floor( ( $s - $h * 3600 ) / 60 );
    my $sec = _floor( $s - $h * 3600 - $m * 60 );
    return ( $h ? $h . 'h ' : '' ) . ( $m || $h ? $m . 'm ' : '' ) . $sec . 's';
}

sub calculatePercentage {
    my ( $v, $total, $digits ) = @_;
    return 0 unless _finite($v) && _finite($total) && $total != 0;
    return roundTo( $v / $total * 100, $digits // 0 );
}
sub formatPercentage { _finite( $_[0] ) ? roundTo( $_[0], $_[1] // 0 ) . '%' : '0%' }

sub sum {
    my ($values) = @_;
    return 0 unless ref($values) eq 'ARRAY';
    my $sum = 0;
    $sum += $_ for grep { _finite($_) } @$values;
    return $sum;
}
sub average { ref( $_[0] ) eq 'ARRAY' && @{ $_[0] } ? sum( $_[0] ) / @{ $_[0] } : 0 }
1;
