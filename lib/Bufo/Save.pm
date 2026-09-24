package Bufo::Save;
use strict;
use warnings;
use JSON::PP ();

my $JSON = JSON::PP->new->canonical->allow_nonref->max_depth(64);
my $FORMAT = 'bufo-clicker-perl';
my $MAX_INTEGER = 9007199254740991;

sub key { 'bufo_idle_save_perl_v1' }
sub legacy_key { 'bufo_idle_save' }

sub new {
    my ($class, %args) = @_;
    die "Save requires a catalog\n" unless $args{catalog};
    return bless { catalog => $args{catalog} }, $class;
}

# Only an absent new key permits migration from the original save.
sub choose_load {
    my ($self, %args) = @_;
    for my $source (qw(new legacy)) {
        next unless defined $args{"${source}_raw"};
        my $state = $self->parse($args{"${source}_raw"}, now => $args{now}, require_current => $source eq 'new');
        return { source => $source, state => $state };
    }
    return { source => 'none', state => undef };
}

# Parse into fresh durable state. Construction of Game rebuilds permanent effects.
sub parse {
    my ($self, $raw, %args) = @_;
    die "Save must be nonempty JSON text\n" if !defined($raw) || ref($raw) || !length($raw);
    die "Save exceeds the 5 MB limit\n" if length($raw) > 5 * 1024 * 1024;
    my $envelope = eval { $JSON->decode($raw) };
    die "Invalid save JSON\n" if $@;
    _object($envelope, 'save');
    my $current = exists($envelope->{format}) || exists($envelope->{schemaVersion});
    if ($current) {
        die "Unsupported save format\n" unless defined($envelope->{format})
            && !ref($envelope->{format}) && $envelope->{format} eq $FORMAT;
        die "Unsupported save schema\n" unless _number($envelope->{schemaVersion}, 'schemaVersion', 1) == 1;
    }
    else {
        die "The current save key requires a Perl save envelope\n" if $args{require_current};
        die "Unsupported legacy save version\n" unless defined($envelope->{version})
            && !ref($envelope->{version}) && $envelope->{version} eq '1.0.0';
    }
    return $self->_normalize($envelope->{state}, now => $args{now}, strict => $current);
}

# Snapshot timestamps change only in the encoded copy, never in the active game.
sub serialize {
    my ($self, $state, %args) = @_;
    my $now = _number($args{now}, 'now', 1);
    my $copy = $self->_normalize($state, now => $now, strict => 1);
    $copy->{gameSettings}{lastSaved} = $now;
    return $JSON->encode({ format => $FORMAT, schemaVersion => 1,
        timestamp => $now, state => $copy });
}

sub elapsed_seconds {
    my ($self, %args) = @_;
    my $last = _number($args{last_tick}, 'last_tick', 1);
    my $now = _number($args{now}, 'now', 1);
    my $minimum = exists $args{minimum_ms} ? _number($args{minimum_ms}, 'minimum_ms') : 60000;
    my $gap = $now - $last;
    return 0 if $gap <= 0 || $gap < $minimum;
    return $gap > 43200000 ? 43200 : $gap / 1000;
}

sub _normalize {
    my ($self, $input, %args) = @_;
    my $now = _number($args{now}, 'now', 1);
    my $strict = $args{strict};
    my $s = _object($input, 'state');
    my $r = _object($s->{resources}, 'resources');
    my $g = _object($s->{generators}, 'generators');
    my $u = _object($s->{upgrades}, 'upgrades');
    my $settings = _object($s->{gameSettings}, 'gameSettings');
    my $a = _optional_object($s, 'achievements', $strict);
    my $p = _optional_object($s, 'prestige', $strict);
    my $b = _optional_object($s, 'bosses', $strict);
    if ($strict) {
        _require_fields($a, 'achievements', qw(unlocked progress customEvents clickCount));
        _require_fields($u, 'upgrades', 'purchased');
        _require_fields($b, 'bosses', qw(defeated lifetimeDefeats));
        _require_fields($settings, 'gameSettings', qw(autoSave version));
    }
    my $catalog = $self->{catalog};
    my %upgrade_ids = map { $_->{id} => 1 } @{$catalog->upgrades};
    my %achievement_ids = map { $_->{id} => 1 } @{$catalog->achievements};
    my @bosses = @{$catalog->bosses};
    my %boss_ids = map { $_->{id} => 1 } @bosses;
    my %events = (golden_bufo_caught => 1, console_opened => 1, map { 'boss_'.$_->{id} => 1 } @bosses);
    my $bufos = _number($r->{bufos}, 'resources.bufos');
    my $total = _number($r->{totalBufos}, 'resources.totalBufos');
    die "Current currency exceeds run earnings\n" if $bufos > $total;
    my $resource_clicks = _field_number($r, 'clickCount', 0, 1, $strict);
    my $achievement_clicks = _field_number($a, 'clickCount', 0, 1, $strict);
    die "Inconsistent click counters\n" if $strict && $resource_clicks != $achievement_clicks;
    my $clicks = $strict || $resource_clicks ? $resource_clicks : $achievement_clicks;
    my $base = _field_number($r, 'baseClickPower', 1, 0, $strict);
    die "Base click power must be positive and at most 1e200\n" unless $base > 0 && $base <= 1e200;
    my %generators;
    for my $id (keys %$g) {
        die "Unknown generator $id\n" unless exists $catalog->generators->{$id};
    }
    for my $id (sort keys %{$catalog->generators}) {
        my $definition = $catalog->generators->{$id};
        if (!exists $g->{$id}) {
            die "Missing generator $id\n" if $strict;
            $generators{$id} = { count => 0, unlocked => $definition->{unlocked} ? 1 : 0 };
            next;
        }
        my $saved = _object($g->{$id}, "generators.$id");
        _require_fields($saved, "generators.$id", qw(count unlocked)) if $strict;
        my $count = _field_number($saved, 'count', 0, 1, $strict);
        die "Generator $id count exceeds finite cost range\n"
            if log($definition->{baseCost}) + $count * log($definition->{costMultiplier}) > log(1e300);
        my $unlocked = exists($saved->{unlocked}) ? _boolean($saved->{unlocked}, "$id.unlocked")
            : $count > 0 || $definition->{unlocked} ? 1 : 0;
        die "Owned generator $id is locked\n" if $strict && $count && !$unlocked;
        $unlocked = 1 if !$strict && $count;
        _boolean($saved->{enabled}, "$id.enabled") if exists $saved->{enabled};
        $generators{$id} = { count => $count, unlocked => $unlocked };
    }
    my $purchased = _ids($u->{purchased}, \%upgrade_ids, 'upgrades.purchased');
    my $unlocked = _ids(exists($a->{unlocked}) ? $a->{unlocked} : [], \%achievement_ids, 'achievements.unlocked');
    my %progress;
    if (exists $a->{progress}) {
        my $values = _object($a->{progress}, 'achievements.progress');
        for my $id (keys %$values) {
            die "Unknown achievement progress $id\n" unless $achievement_ids{$id};
            $progress{$id} = _number($values->{$id}, "progress.$id");
        }
    }
    my %custom;
    if (exists $a->{customEvents}) {
        my $values = _object($a->{customEvents}, 'achievements.customEvents');
        for my $id (keys %$values) {
            die "Unknown custom event $id\n" unless $events{$id};
            $custom{$id} = _boolean($values->{$id}, "customEvents.$id");
        }
    }
    my $points = _field_number($p, 'points', 0, 1, $strict);
    my $lifetime = _field_number($p, 'lifetimePoints', $points, 1, $strict);
    die "Prestige points exceed lifetime points\n" if $points > $lifetime;
    my $transcendences = _field_number($p, 'transcendences', 0, 1, $strict);
    my $defeated = _ids(exists($b->{defeated}) ? $b->{defeated} : [], \%boss_ids, 'bosses.defeated');
    for my $index (0 .. $#$defeated) {
        die "Bosses must follow the ladder order\n" unless $defeated->[$index] eq $bosses[$index]{id};
    }
    my $banked = _field_number($b, 'lifetimeDefeats', 0, 1, $strict);
    my $last_tick = _field_number($settings, 'lastTick', $now, 1, $strict);
    my $last_saved = _field_number($settings, 'lastSaved', $now, 1, $strict);
    my $first_start = _field_number($settings, 'firstStartTime', $now, 1, $strict);
    my $autosave = exists($settings->{autoSave}) ? _boolean($settings->{autoSave}, 'autoSave') : 1;
    my $version = exists($settings->{version}) ? $settings->{version} : '1.0.0';
    die "Invalid game version\n" unless defined($version) && !ref($version) && $version eq '1.0.0';
    return {
        resources => { bufos => $bufos, totalBufos => $total, baseClickPower => $base, clickCount => $clicks },
        generators => \%generators,
        upgrades => { purchased => $purchased },
        achievements => { unlocked => $unlocked, progress => \%progress, customEvents => \%custom, clickCount => $clicks },
        prestige => { points => $points, lifetimePoints => $lifetime, transcendences => $transcendences },
        bosses => { defeated => $defeated, lifetimeDefeats => $banked },
        gameSettings => { lastTick => $last_tick, lastSaved => $last_saved, firstStartTime => $first_start,
            autoSave => $autosave, version => $version },
    };
}

sub _require_fields {
    my ($value, $name, @fields) = @_;
    for my $field (@fields) {
        die "Missing $name.$field\n" unless exists $value->{$field};
    }
}

sub _object {
    my ($value, $name) = @_;
    die "Invalid $name object\n" unless ref($value) eq 'HASH';
    return $value;
}

sub _optional_object {
    my ($parent, $name, $strict) = @_;
    return {} if !$strict && !exists $parent->{$name};
    return _object($parent->{$name}, $name);
}

sub _field_number {
    my ($parent, $name, $default, $integer, $strict) = @_;
    return $default if !$strict && !exists $parent->{$name};
    return _number($parent->{$name}, $name, $integer);
}

sub _number {
    my ($value, $name, $integer) = @_;
    die "Invalid number $name\n" if !defined($value) || ref($value);
    my $encoded = $JSON->encode($value);
    die "Invalid number $name\n" unless $encoded =~ /\A-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?\z/;
    die "Number $name is out of range\n" if $value < 0 || $value > 1e300;
    die "Invalid integer $name\n" if $integer && ($value > $MAX_INTEGER || int($value) != $value);
    return 0 + $value;
}

sub _boolean {
    my ($value, $name) = @_;
    return $value ? 1 : 0 if JSON::PP::is_bool($value);
    my $number = _number($value, $name, 1);
    die "Invalid boolean $name\n" unless $number == 0 || $number == 1;
    return $number;
}

sub _ids {
    my ($values, $known, $name) = @_;
    die "Invalid $name list\n" unless ref($values) eq 'ARRAY';
    my %seen;
    my @result;
    for my $id (@$values) {
        die "Unknown $name identifier\n" unless defined($id) && !ref($id) && exists $known->{$id};
        die "Duplicate $name identifier $id\n" if $seen{$id}++;
        push @result, "$id";
    }
    return \@result;
}

1;
