use strict;
use warnings;
use Test::More;
use JSON::PP qw(decode_json encode_json);
use lib 'lib';
use Bufo::Save;
use Bufo::Catalog;
use Bufo::Game;

sub read_json {
    my ($file) = @_;
    open my $fh, '<', $file or die "$file: $!";
    local $/;
    return decode_json(<$fh>);
}
my $catalog = Bufo::Catalog->new(map { $_ => read_json("assets/data/$_.json") }
    qw(generators upgrades achievements));
my $save = Bufo::Save->new(catalog => $catalog);
my $legacy = read_json('t/fixtures/legacy-progression.json');
my $raw = encode_json($legacy);
my $state = $save->parse($raw, now => 1700000100000);
is($state->{resources}{clickCount}, 10000, 'legacy click fallback preserves achievement counter');
is($state->{generators}{tadpole}{count}, 10, 'nested generator state wins over duplicate envelope');
is_deeply($state->{upgrades}{purchased}, ['stronger_clicks_1'], 'nested upgrade state wins');
is($state->{prestige}{lifetimePoints}, 3, 'older prestige points supply missing lifetime points');
is($state->{gameSettings}{autoSave}, 0, 'false autosave setting survives');
is($state->{gameSettings}{firstStartTime}, 1690000000000, 'first start time survives');
is($state->{resources}{bufos}, 450, 'load does not pay achievement currency bonuses again');
ok(!exists $state->{resources}{frenzyClickMultiplier}, 'transient multipliers are excluded');
my $encoded = $save->serialize($state, now => 1700000100000);
my $roundtrip = $save->parse($encoded, now => 1700000100000);
my $missing_current = decode_json($encoded);
delete $missing_current->{state}{achievements}{unlocked};
ok(!eval { $save->parse(encode_json($missing_current),now=>1700000100000); 1 }, 'current schema requires durable progression fields');
my $locked_current = decode_json($encoded);
$locked_current->{state}{generators}{tadpole}{unlocked} = 0;
ok(!eval { $save->parse(encode_json($locked_current),now=>1700000100000); 1 }, 'current schema rejects owned locked generator');
is($roundtrip->{resources}{bufos}, 450, 'round trip retains currency');
is($roundtrip->{gameSettings}{lastSaved}, 1700000100000, 'serialize stamps saved snapshot');
is($state->{gameSettings}{lastSaved}, 1700000000000, 'serialize leaves active state untouched');
my $chosen = $save->choose_load(new_raw => $encoded, legacy_raw => $raw, now => 1700000100000);
is($chosen->{source}, 'new', 'new save wins with both keys present');
$chosen = $save->choose_load(new_raw => undef, legacy_raw => $raw, now => 1700000100000);
is($chosen->{source}, 'legacy', 'legacy selected only when new key absent');
is($save->choose_load(now => 1700000100000)->{source}, 'none', 'absent saves leave new game choice to UI');
ok(!eval { $save->choose_load(new_raw => $raw, legacy_raw => $raw, now => 1700000100000); 1 }, 'new key requires current envelope');
ok(!eval { $save->choose_load(new_raw => '', legacy_raw => $raw, now => 1700000100000); 1 }, 'empty present new save blocks legacy fallback');
ok(!eval { $save->choose_load(new_raw => '{bad', legacy_raw => $raw, now => 1700000100000); 1 }, 'corrupt new save blocks legacy fallback');

for my $case (
    ['overflowing base click power', sub { $_[0]{state}{resources}{baseClickPower} = 1e250 }],
    ['negative currency', sub { $_[0]{state}{resources}{bufos} = -1 }],
    ['currency exceeds run earnings', sub { $_[0]{state}{resources}{bufos} = 20000 }],
    ['numeric string', sub { $_[0]{state}{resources}{bufos} = '450' }],
    ['overflowing generator cost', sub { $_[0]{state}{generators}{tadpole}{count} = 9007199254740991 }],
    ['fractional count', sub { $_[0]{state}{generators}{tadpole}{count} = 1.5 }],
    ['unknown generator', sub { $_[0]{state}{generators}{fake} = {count=>0,unlocked=>0} }],
    ['duplicate upgrades', sub { push @{$_[0]{state}{upgrades}{purchased}}, 'stronger_clicks_1' }],
    ['unknown achievement', sub { push @{$_[0]{state}{achievements}{unlocked}}, 'fake' }],
    ['invalid boolean', sub { $_[0]{state}{gameSettings}{autoSave} = 'false' }],
    ['invalid generator boolean', sub { $_[0]{state}{generators}{tadpole}{unlocked} = 2 }],
    ['inconsistent prestige', sub { $_[0]{state}{prestige}{lifetimePoints} = 2 }],
    ['out of order boss ladder', sub { $_[0]{state}{bosses}{defeated} = ['the_enraged_bufo'] }],
    ['future schema', sub { $_[0]{format} = 'bufo-clicker-perl'; $_[0]{schemaVersion} = 2 }],
    ['foreign schema', sub { $_[0]{format} = 'bufo-clicker-rust'; $_[0]{schemaVersion} = 1 }],
) {
    my $bad = decode_json($raw);
    $case->[1]->($bad);
    ok(!eval { $save->parse(encode_json($bad), now => 1700000100000); 1 }, "reject $case->[0]");
}
ok(!eval { $save->parse('{"state":{"resources":{"bufos":1e999}}}', now => 1700000100000); 1 }, 'reject overflowing numeric input');
my $zero_clicks = decode_json($raw);
$zero_clicks->{state}{resources}{clickCount} = 0;
is($save->parse(encode_json($zero_clicks), now=>1700000100000)->{resources}{clickCount}, 10000,
    'legacy zero resource counter falls back to achievement counter');
my $old = decode_json($raw);
delete $old->{state}{prestige}; delete $old->{state}{bosses};
my $before_prestige = $save->parse(encode_json($old), now => 1700000100000);
is_deeply($before_prestige->{prestige}, {points=>0,lifetimePoints=>0,transcendences=>0}, 'pre-prestige save gets safe defaults');
is_deeply($before_prestige->{bosses}, {defeated=>[],lifetimeDefeats=>0}, 'pre-boss save gets safe defaults');
for my $gap (0, -1000, 59999) {
    is($save->elapsed_seconds(last_tick=>100000,now=>100000+$gap), 0, 'reload floor rejects short or negative gap');
}
is($save->elapsed_seconds(last_tick=>100000,now=>160000), 60, 'reload credits exact one-minute boundary');
is($save->elapsed_seconds(last_tick=>100000,now=>100500,minimum_ms=>0), 0.5, 'resume credits sub-minute gap');
is($save->elapsed_seconds(last_tick=>0,now=>86400000), 43200, 'offline elapsed is capped at twelve hours');
is($save->elapsed_seconds(last_tick=>1700000100000,now=>1700000100000), 0, 'saved current last tick prevents repeated elapsed credit');
is(Bufo::Save->key, 'bufo_idle_save_perl_v1', 'Perl save has independent key');
is(Bufo::Save->legacy_key, 'bufo_idle_save', 'legacy key matches original');
my $restored_game = Bufo::Game->new(catalog=>$catalog, now=>1700000100000, state=>$state);
cmp_ok(abs($restored_game->production - 2.275), '<', 1e-10, 'engine reconstructs permanent generator multipliers once');
cmp_ok(abs($restored_game->state->{resources}{clickPower} - 5.005), '<', 1e-10, 'engine reconstructs purchased and achievement click boosts once');
for (1 .. 2) {
    $restored_game = Bufo::Game->new(catalog=>$catalog, now=>1700000100000,
        state=>$save->parse($save->serialize($restored_game->state,now=>1700000100000),now=>1700000100000));
}
is($restored_game->state->{resources}{bufos}, 450, 'repeated engine reload never replays one-time bonus');
cmp_ok(abs($restored_game->production - 2.275), '<', 1e-10, 'repeated engine reload does not stack effects');
my $captured = read_json('t/fixtures/legacy-captured.json');
my $captured_state = $save->parse(encode_json($captured), now => 1800000000000);
is($captured_state->{generators}{tadpole}{count}, 12, 'actual original browser save retains Tadpoles');
is($captured_state->{generators}{froglet}{count}, 8, 'actual original browser save retains Froglets');
is($captured_state->{generators}{froglet}{unlocked}, 1, 'legacy owned generator normalizes stale unlock flag');
done_testing;
