use strict;
use warnings;
use Test::More;
use JSON::PP qw(decode_json);
use lib 'lib';
use Bufo::Util::Number;
use Bufo::Util::Math;
use Bufo::Util::Time;
use Bufo::Util::Validation;
open my $fh, '<', 't/fixtures/core/original-utilities.json' or die $!;
my $data = decode_json( do { local $/; <$fh> } );
my $math = Bufo::Util::Math->new( random => sub { 0.25 } );
my $time = Bufo::Util::Time->new( now    => sub { 1000000000000 } );

for my $case ( @{ $data->{cases} } ) {
    my $name   = $case->{module} . '.' . $case->{method};
    my @args   = @{ $case->{args} };
    my $method = $case->{method};
    my $actual;
    if    ( $case->{module} eq 'mathUtils' ) { $actual = $math->$method(@args) }
    elsif ( $case->{module} eq 'timeUtils' ) { $actual = $time->$method(@args) }
    else {
        my $package =
          $case->{module} eq 'numberUtils' ? 'Bufo::Util::Number' : 'Bufo::Util::Validation';
        no strict 'refs';
        $actual = &{"${package}::$method"}(@args);
    }
    my $expected = $case->{expected};
    if    ( JSON::PP::is_bool($expected) ) { is( $actual ? 1 : 0, $expected ? 1 : 0, $name ) }
    elsif ( !ref($actual) && !ref($expected) && Bufo::Util::Validation::isValidNumber($expected) ) {
        cmp_ok( abs( $actual - $expected ), '<', 1e-10 * ( abs($expected) || 1 ), $name );
    } else {
        is_deeply( $actual, $expected, $name );
    }
}
done_testing;
