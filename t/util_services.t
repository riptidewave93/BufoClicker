use strict;
use warnings;
use utf8;
use Test::More;
use lib 'lib';
use Bufo::Util::General;
use Bufo::Util::Time;
use Bufo::Util::Storage;
use Bufo::Util::SaveManager;
use Bufo::Util::DataLoader;
use Bufo::Util::Index;
use Bufo::Loader;

my %store;
my $deny    = 0;
my $storage = Bufo::Util::Storage->new(
    get    => sub { $store{ $_[0] } },
    set    => sub { die 'QuotaExceededError' if $deny; $store{ $_[0] } = $_[1] },
    remove => sub { delete $store{ $_[0] } },
    clear  => sub { %store = () },
    keys   => sub { [ keys %store ] }
);
my $unicode = { frog => "🐸", text => "étang" };
is_deeply( $storage->importFromString( $storage->exportToString($unicode) ),
    $unicode, 'Unicode export codec round-trips original URI/base64 format' );

for my $bad ( '!', 'abcd===', 'JQ==', '/w==', 'bm90IGpzb24=' ) {
    is( $storage->importFromString($bad), undef, "invalid encoded save rejected: $bad" );
}
$store{raw} = 'broken';
my $fallback = { kept => 1 };
is( $storage->loadFromStorage( 'raw', $fallback ),
    $fallback, 'corrupt JSON returns exact fallback' );
$store{'🐸'} = 'x';
is( $storage->getStorageSize, 24,
    'storage size counts UTF16 code units including surrogate pairs' );
ok( $storage->hasStorageKey('raw'), 'key existence accepts malformed data' );
ok( $storage->clearStorage('raw'),  'explicit keyed clear succeeds' );
ok( exists $store{'🐸'},             'keyed clear preserves unrelated keys' );
$deny = 1;
ok( !$storage->isStorageAvailable, 'availability checks writes' );
is( $storage->loadFromStorage( 'missing', $fallback ),
    $fallback, 'storage failure returns caller fallback' );
$deny = 0;
my $legacy = Bufo::Util::SaveManager->legacy( storage => $storage, now => sub { 1234 } );
my $state  = { gameSettings => { version => '1.2' }, resources => { bufos => 4 } };
ok( $legacy->saveGame( $state, { one => 1 }, ['old-upgrade'], { level => 8 } ),
    'legacy service serializes all envelope slices' );
is_deeply(
    $legacy->loadGame,
    { state => $state, upgrades => ['old-upgrade'], explorer => { level => 8 } },
    'legacy service load uses its original top-level duplicates'
);
my $export = $legacy->exportSave;
ok( $legacy->clearSave,             'clearSave removes only its key' );
ok( !exists $store{bufo_idle_save}, 'legacy key removed' );
ok( $legacy->importSave($export),   'legacy import restores exact decoded envelope' );
is_deeply( $legacy->loadGame->{explorer}, { level => 8 }, 'import retains legacy explorer data' );
my $guard = Bufo::Util::SaveManager->new(
    key       => 'current',
    storage   => $storage,
    serialize => sub { JSON::PP::encode_json( $_[0] ) },
    parse => sub { my $s = JSON::PP::decode_json( $_[0] ); die 'invalid' unless $s->{valid}; $s }
);
ok( $guard->saveGame( { valid => 1 } ), 'configured current codec writes current key' );
my $before = $store{current};
ok( !$guard->importSave( $storage->exportToString( { invalid => 1 } ) ),
    'current codec rejects invalid import' );
is( $store{current}, $before, 'rejected import leaves bytes unchanged' );
$deny = 1;
ok( !$guard->saveGame( { valid => 2 } ), 'failed storage write returns false' );
is( $store{current}, $before, 'failed write preserves bytes' );
$deny = 0;
Bufo::Util::SaveManager->setInstance($guard);
is( Bufo::Util::SaveManager::getSaveManager(),
    $guard, 'save singleton resolves configured authoritative instance' );

my ( $now, $serial ) = ( 1000, 0 );
my %timers;
my $time = Bufo::Util::Time->new(
    now      => sub { $now },
    schedule => sub { my ( $fn, $ms ) = @_; $timers{ ++$serial } = [ $now + $ms, $fn ]; $serial },
    cancel   => sub { delete $timers{ $_[0] } },
    format_date => sub { join ':', @_ }
);

sub advance {
    my ($ms) = @_;
    $now += $ms;
    for my $id ( sort { $timers{$a}[0] <=> $timers{$b}[0] } keys %timers ) {
        next unless exists $timers{$id} && $timers{$id}[0] <= $now;
        my $fn = delete( $timers{$id} )->[1];
        $fn->();
    }
}
my @calls;
my $throttle = $time->throttle( sub { push @calls, $_[0] }, 100 );
$throttle->('first');
advance(20);
$throttle->('discard');
advance(20);
$throttle->('last');
advance(60);
is_deeply(
    \@calls,
    [ 'first', 'last' ],
    'throttle preserves leading and latest trailing arguments'
);
@calls = ();
my $debounce = $time->debounce( sub { push @calls, $_[0] }, 100 );
$debounce->('discard');
advance(50);
$debounce->('last');
advance(99);
is_deeply( \@calls, [], 'debounce waits full period after final call' );
advance(1);
is_deeply( \@calls, ['last'], 'debounce runs latest arguments once' );
my $delayed = 0;
$time->delay(10)->then( sub { $delayed++ } );
advance(9);
is( $delayed, 0, 'delay remains pending before deadline' );
advance(1);
is( $delayed, 1, 'delay settles at deadline' );
my $cancel = $time->cancellableDelay(10);
$cancel->{promise}->then( sub { $delayed++ } );
$cancel->{cancel}->();
advance(10);
is( $delayed, 1, 'cancellable delay never resolves after cancellation' );
is( $time->formatTimestamp( 1234, 0 ),
    '1234:0', 'date formatting delegates locale and include-time choice' );
my $d = Bufo::Util::Deferred->new;
my ( $result, $error );
$d->then( sub { $_[0] * 2 } )->then( sub { $result = $_[0] } );
$d->then( sub { die 'callback failure' } )->catch( sub { $error = $_[0] } );
$d->resolve(4);
is( $result, 8, 'completion chaining passes transformed values' );
like(
    $error,
    qr/callback failure/,
    'completion callback errors reject its chain without blocking siblings'
);
my $general = Bufo::Util::General->new( time => $time, random => sub { 0.25 } );
like( $general->generateId('f-'), qr/^f-\d+-2500$/, 'ID uses injected clock and random source' );
is( Bufo::Util::General::defaultIfNullOrUndefined( 0, 7 ), 0, 'null fallback retains zero' );
my $cycle = {};
$cycle->{self} = $cycle;
my $copy = Bufo::Util::General::deepClone($cycle);
is( $copy->{self}, $copy, 'structured clone preserves cycles' );
isnt( $copy, $cycle, 'structured clone isolates object identity' );
my $array = [ 1, 2, 3, 4 ];
is_deeply( $general->shuffleArray($array), [ 4, 3, 1, 2 ], 'Fisher-Yates deterministic shuffle' );
is_deeply( $array, [ 1, 2, 3, 4 ], 'shuffle leaves original array unchanged' );
is( Bufo::Util::General::safeJsonStringify( $cycle, 'fallback' ),
    'fallback', 'cyclic JSON uses provided fallback' );
is( Bufo::Util::General::attempt( sub { die 'failure' }, 12 ),
    12, 'attempt catches callback failures' );
my $utils = Bufo::Util::Index->new(
    time         => $time,
    storage      => $storage,
    general      => $general,
    is_valid_url => sub { $_[0] eq 'platform-url' }
);
is( $utils->formatDuration(3600), '1h 0m 0s', 'utility barrel delegates pure format functions' );
is( $utils->getCurrentTime,       $now,       'utility barrel delegates configured services' );
ok( $utils->isValidUrl('platform-url'), 'utility barrel invokes exact platform URL adapter' );

my %pending;
my $loader = Bufo::Util::DataLoader->new(
    storage => $storage,
    fetch   =>
      sub { my ( $path, $ok, $fail, $timeout ) = @_; $pending{$path} = [ $ok, $fail, $timeout ] }
);
my $game = Bufo::Loader->new(
    loader     => $loader,
    initialize => { generators => sub { die 'invalid generators' unless ref( $_[0] ) eq 'HASH' } }
);
my $status;
$game->loadGameData->then( sub { $status = $_[0] } );
is( scalar keys %pending, 3, 'game loader starts all catalogs before completion' );
is( $pending{'assets/data/generators.json'}[2],
    10000, 'transport receives original ten-second timeout' );
$pending{'assets/data/generators.json'}[0]->( { status => 200, text => '{"tadpole":{}}' } );
$pending{'assets/data/upgrades.json'}[0]->( { status => 200, text => '[1,2]' } );
ok( !defined $status, 'game loading waits for every required catalog' );
$pending{'assets/data/achievements.json'}[0]->( { status => 200, text => '[]' } );
ok( $status->{isComplete} && $game->isGameDataLoaded, 'all catalogs complete loader' );
is_deeply(
    $game->verifyGameData,
    { generatorsLoaded => 1, upgradesLoaded => 2, isComplete => 1 },
    'verification exposes original count contract'
);
my $badgame = Bufo::Loader->new( loader => $loader );
my $badstatus;
$badgame->loadGameData->then( sub { $badstatus = $_[0] } );
$pending{'assets/data/upgrades.json'}[0]->( { status => 404, text => '{}' } );
like(
    $badstatus->{error},
    qr/upgrades.json.*HTTP 404/s,
    'game loader resolves failure with requested catalog and error'
);
ok( !$badstatus->{isComplete}, 'catalog failure cannot report complete' );
$pending{'assets/data/generators.json'}[0]->( { status => 200, text => '{}' } );
ok( $badgame->loadingStatus->{generators},
    'other loads may finish after early failure as original' );
ok( !$badstatus->{generators}, 'returned loading status is a snapshot' );
$loader->updateDataCacheVersion( 'catalog', '1' );
ok( !$loader->shouldLoadData( 'catalog', '1' ), 'matching raw cache version skips reload' );
ok( $loader->shouldLoadData( 'catalog',  '2' ), 'changed cache version requests reload' );
ok( $storage->clearAllStorage, 'explicit clear-all service succeeds' );
is_deeply( \%store, {}, 'explicit clear-all removes all isolated adapter keys' );
my $unicode_legacy=Bufo::Util::SaveManager->legacy(storage=>$storage,now=>sub{100});
ok($unicode_legacy->saveGame({gameSettings=>{version=>'1'},name=>"étang 🐸"},{},[],{}),'legacy utility saves Unicode JSON text');
is_deeply($storage->importFromString($unicode_legacy->exportSave)->{state}{name},"étang 🐸",'legacy export uses same Unicode codec as generic storage');
done_testing;
