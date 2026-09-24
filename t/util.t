use strict;
use warnings;
use Test::More;
use lib 'lib';
use Bufo::Util::Math;
use Bufo::Util::Number;
use Bufo::Util::Validation;
use Bufo::Util::General;
use Bufo::Util::Time;
use Bufo::Util::Storage;
use Bufo::Util::SaveManager;
use Bufo::Util::DataLoader;
use Bufo::Util::State;
my $math = Bufo::Util::Math->new( random => sub { 0.25 } );
is( $math->mapRange( 2, 0, 1, 10, 0 ),    0, 'mapping clamps reversed target range' );
is( $math->weightedRandom( [ 0, 1, 3 ] ), 2, 'weighted sampling uses original strict threshold' );
is( Bufo::Util::Number::formatNumberWithPrecision(1234567),
    '1,234,567', 'primary resource format stays unabridged' );
is( Bufo::Util::Number::formatDuration(86400),
    '24h 0m 0s', 'duration retains original unbounded hours' );
ok( !Bufo::Util::Validation::isValidNumber('12'), 'validation rejects numeric strings' );
my %store;
my $storage = Bufo::Util::Storage->new(
    get    => sub { $store{ $_[0] } },
    set    => sub { $store{ $_[0] } = $_[1] },
    remove => sub { delete $store{ $_[0] } },
    clear  => sub { %store = () },
    keys   => sub { [ keys %store ] }
);
ok( $storage->saveToStorage( 'x', { value => 3 } ), 'generic storage saves JSON' );
is_deeply( $storage->loadFromStorage( 'x', {} ), { value => 3 }, 'generic storage loads JSON' );
is_deeply( $storage->loadFromStorage( 'missing', [1] ),
    [1], 'missing storage uses supplied fallback' );
my $loader = Bufo::Util::DataLoader->new(
    storage => $storage,
    fetch   => sub {
        my ( $path, $ok, $fail ) = @_;
        $path eq 'bad' ? $fail->('missing') : $ok->( { status => 200, text => '{"answer":42}' } );
    }
);
my $loaded;
$loader->loadMultipleJsonData( { good => 'good', bad => 'bad' }, sub { $loaded = $_[0] } );
is_deeply( $loaded, { good => { answer => 42 } }, 'loader returns partial successes' );
done_testing;
