package Bufo::Game;
use strict;
use warnings;
use JSON::PP      ();
use Scalar::Util  ();
use Bufo::Catalog ();
use Bufo::Number  ();

sub _clone { JSON::PP::decode_json( JSON::PP::encode_json( $_[0] ) ) }

sub _finite {
    defined( $_[0] )
      && !ref( $_[0] )
      && Scalar::Util::looks_like_number( $_[0] )
      && "$_[0]" !~ /nan|inf/i;
}

# WebPerl uses 32-bit integers. Keep large prices and awards in floating point.
sub _ceil {
    my ($number) = @_;
    my $rounded = 0 + sprintf( '%.0f', $number );
    return $rounded < $number ? $rounded + 1 : $rounded;
}

sub _floor {
    my ($number) = @_;
    my $rounded = 0 + sprintf( '%.0f', $number );
    return $rounded > $number ? $rounded - 1 : $rounded;
}
sub _min  { $_[0] < $_[1] ? $_[0] : $_[1] }
sub _max  { $_[0] > $_[1] ? $_[0] : $_[1] }
sub _ok   { return { ok => 1, @_ }; }
sub _fail { return { ok => 0, error => $_[0] }; }

sub _set {
    return { map { $_ => 1 } @{ $_[0] } };
}

sub new {
    my ( $class, %args ) = @_;
    die "A validated catalog is required\n"
      unless Scalar::Util::blessed( $args{catalog} ) && $args{catalog}->isa('Bufo::Catalog');
    my $now = defined( $args{now} ) ? $args{now} : 0;
    die "Invalid game clock\n" unless _finite($now) && $now >= 0;
    my $saved = $args{state} ? _clone( $args{state} ) : {};
    my $self  = bless {
        catalog   => $args{catalog},
        now       => $now,
        paused    => 0,
        events    => [],
        combo     => 0,
        frenzies  => { production => 0, click => 0 },
        fight     => undef,
        lastClick => undef
    }, $class;
    my $r = $saved->{resources}    // {};
    my $a = $saved->{achievements} // {};
    my $p = $saved->{prestige}     // {};
    my $b = $saved->{bosses}       // {};
    $self->{state} = {
        resources => {
            bufos          => $r->{bufos}          // 0,
            totalBufos     => $r->{totalBufos}     // 0,
            baseClickPower => $r->{baseClickPower} // 1,
            clickCount     => $r->{clickCount}     // $a->{clickCount} // 0
        },
        generators => _clone( $self->{catalog}->generators ),
        upgrades => { purchased => _clone( $saved->{upgrades}{purchased} // [] ), available => [] },
        achievements => {
            unlocked     => _clone( $a->{unlocked}     // [] ),
            customEvents => _clone( $a->{customEvents} // {} ),
            progress     => {},
            clickCount   => 0
        },
        prestige => {
            points         => $p->{points}         // 0,
            lifetimePoints => $p->{lifetimePoints} // $p->{points} // 0,
            transcendences => $p->{transcendences} // 0
        },
        bosses => {
            defeated        => _clone( $b->{defeated} // [] ),
            lifetimeDefeats => $b->{lifetimeDefeats} // 0
        },
        gameSettings => {
            lastSaved      => $now,
            lastTick       => $now,
            firstStartTime => $now,
            autoSave       => 1,
            version        => '1.0.0',
            %{ $saved->{gameSettings} // {} }
        },
    };

    for my $id ( keys %{ $self->{state}{generators} } ) {
        my $g   = $self->{state}{generators}{$id};
        my $old = $saved->{generators}{$id} // {};
        $g->{count}    = $old->{count} // 0;
        $g->{unlocked} = ( $g->{unlocked} || $old->{unlocked} ) ? 1 : 0;
    }
    $self->refresh;
    return $self;
}
sub state               { $_[0]{state} }
sub catalog             { $_[0]{catalog} }
sub production          { $_[0]{production} // 0 }
sub format_number {
    shift;
    return Bufo::Number::format(@_);
}
sub prestige_multiplier { 1 + $_[0]{state}{prestige}{lifetimePoints} * 0.1 }

sub boss_multiplier {
    1 + ( @{ $_[0]{state}{bosses}{defeated} } + $_[0]{state}{bosses}{lifetimeDefeats} ) * 0.25;
}

sub pending_prestige {
    my $total = $_[0]{state}{resources}{totalBufos};
    return $total < 1e9 ? 0 : _floor( sqrt( $total / 1e9 ) );
}

sub drain_events {
    my $self   = shift;
    my $events = $self->{events};
    $self->{events} = [];
    return $events;
}
sub set_auto_save {
    my ($self, $enabled) = @_;
    $self->{state}{gameSettings}{autoSave} = $enabled ? 1 : 0;
    return _ok();
}

sub mark_saved {
    my ( $self, $now ) = @_;
    return _fail('Invalid save time') unless _finite($now) && $now >= 0;
    $self->{state}{gameSettings}{lastSaved} = $now;
    return _ok();
}

sub _requirements_met {
    my ( $self, $requirements ) = @_;
    my $s     = $self->{state};
    my $owned = _set( $s->{upgrades}{purchased} );
    my $ach   = _set( $s->{achievements}{unlocked} );
    for my $req (@$requirements) {
        my $type   = $req->{type};
        my $target = $req->{target};
        if ( $type eq 'bufos' || $type eq 'totalBufos' ) {
            return 0 if $s->{resources}{totalBufos} < $req->{value};
        }
        elsif ( $type eq 'generators' || $type eq 'generatorCount' ) {
            return 0 if !$target || ( $s->{generators}{$target}{count} // 0 ) < $req->{value};
        }
        elsif ( $type eq 'achievement' || $type eq 'achievements' ) {
            return 0 unless $target && $ach->{$target};
        }
        elsif ( $type eq 'upgrade' ) { return 0 unless $owned->{ $req->{id} // $target // '' }; }
        elsif ( $type eq 'special' ) {
            return 0 unless $target && $s->{achievements}{customEvents}{$target};
        }
        else { return 0; }
    }
    return 1;
}

# Durable purchases and achievement IDs are the only sources of permanent effects.
sub refresh {
    my $self = shift;
    my $s    = $self->{state};
    my $r    = $s->{resources};
    $r->{clickMultiplier}            = 1;
    $r->{productionMultiplier}       = 1;
    $r->{frenzyProductionMultiplier} = $self->{frenzies}{production} > $self->{now} ? 7 : 1;
    $r->{frenzyClickMultiplier}      = $self->{frenzies}{click} > $self->{now}      ? 7 : 1;
    for my $g ( values %{ $s->{generators} } ) { $g->{boosts} = []; }

    for my $id ( @{ $s->{upgrades}{purchased} } ) {
        my $u = $self->{catalog}->upgrade($id);
        die "Unknown purchased upgrade $id\n" unless $u;
        for my $effect ( @{ $u->{effects} } ) {
            if ( $effect->{type} eq 'clickMultiplier' ) {
                $r->{clickMultiplier} *= $effect->{multiplier};
            }
            elsif ( $effect->{type} eq 'globalMultiplier' ) {
                $r->{productionMultiplier} *= $effect->{multiplier};
            }
            else {
                push @{ $s->{generators}{ $effect->{target} }{boosts} },
                  {
                    id         => "upgrade_$id",
                    multiplier => $effect->{multiplier},
                    active     => 1,
                    source     => $u->{name}
                  };
            }
        }
    }
    for my $id ( @{ $s->{achievements}{unlocked} } ) {
        my $a = $self->{catalog}->achievement($id);
        die "Unknown achievement $id\n" unless $a;
        my $reward = $a->{reward};
        next unless $reward;
        if    ( $reward->{type} eq 'clickBoost' ) { $r->{clickMultiplier} *= $reward->{value}; }
        elsif ( $reward->{type} eq 'productionBoost' ) {
            $r->{productionMultiplier} *= $reward->{value};
        }
        elsif ( $reward->{type} eq 'generatorBoost' ) {
            push @{ $s->{generators}{ $reward->{target} }{boosts} },
              {
                id         => "achievement_$id",
                multiplier => $reward->{value},
                active     => 1,
                source     => $a->{name}
              };
        }
    }
    my $passive = $self->prestige_multiplier * $self->boss_multiplier;
    $r->{clickPower} =
      $r->{baseClickPower} * $r->{clickMultiplier} * $passive * $r->{frenzyClickMultiplier};
    my $production = 0;
    for my $g ( values %{ $s->{generators} } ) {
        $g->{unlocked} = 1 if $self->_requirements_met( $g->{unlockRequirements} );
        my $boost = 1;
        $boost *= $_->{multiplier} for @{ $g->{boosts} };
        $g->{currentProduction} =
          $g->{baseProduction} *
          $boost * $r->{productionMultiplier} *
          $passive *
          $r->{frenzyProductionMultiplier};
        $g->{totalProduction} = $g->{currentProduction} * $g->{count};
        my $cost = $g->{baseCost} * $g->{costMultiplier}**$g->{count};
        $g->{currentCost} = _finite($cost) ? _ceil($cost) : undef;
        $production += $g->{totalProduction};
    }
    $self->{production} = $production;
    my $purchased = _set( $s->{upgrades}{purchased} );
    $s->{upgrades}{available} = [
        map { $_->{id} } grep {
                !$purchased->{ $_->{id} }
              && $self->_requirements_met( $_->{unlockConditions} )
        } @{ $self->{catalog}->upgrades }
    ];
    $s->{achievements}{clickCount} = $r->{clickCount};
    for my $a ( @{ $self->{catalog}->achievements } ) {
        my $progress = $self->_achievement_value( $a->{requirement} );
        $s->{achievements}{progress}{ $a->{id} } =
          _min( 100, 100 * $progress / $a->{requirement}{value} );
    }
    return _ok();
}

sub _achievement_value {
    my ( $self, $req ) = @_;
    my $s    = $self->{state};
    my $type = $req->{type};
    return $s->{resources}{totalBufos}           if $type eq 'totalBufos';
    return $self->production                     if $type eq 'bufosPerSecond';
    return $s->{resources}{clickCount}           if $type eq 'clickCount';
    return scalar @{ $s->{upgrades}{purchased} } if $type eq 'upgradeCount';
    return scalar( @{ $s->{bosses}{defeated} } ) + $s->{bosses}{lifetimeDefeats}
      if $type eq 'bossesDefeated';
    return $s->{prestige}{transcendences}                 if $type eq 'transcendences';
    return $s->{prestige}{lifetimePoints}                 if $type eq 'prestigePoints';
    return $s->{generators}{ $req->{target} }{count} // 0 if $type eq 'generatorType';

    if ( $type eq 'totalGenerators' ) {
        my $sum = 0;
        $sum += $_->{count} for values %{ $s->{generators} };
        return $sum;
    }
    return $s->{achievements}{customEvents}{console_opened}   ? 1 : 0 if $type eq 'consoleOpened';
    return $s->{achievements}{customEvents}{ $req->{target} } ? 1 : 0 if $type eq 'customEvent';
    return 0;
}

sub _check_achievements {
    my $self     = shift;
    my $s        = $self->{state};
    my $unlocked = _set( $s->{achievements}{unlocked} );

    # Rewards can cross another threshold. Iterate until no new milestone is earned.
    while (1) {
        my $changed = 0;
        for my $a ( @{ $self->{catalog}->achievements } ) {
            next
              if $unlocked->{ $a->{id} }
              || $self->_achievement_value( $a->{requirement} ) < $a->{requirement}{value};
            $unlocked->{ $a->{id} } = 1;
            push @{ $s->{achievements}{unlocked} }, $a->{id};
            push @{ $self->{events} }, { type => 'achievement', id => $a->{id} };
            if ( $a->{reward} && $a->{reward}{type} eq 'bufoBonus' ) {
                $self->_credit( $a->{reward}{value} );
            }
            $changed = 1;
        }
        $self->refresh;
        last unless $changed;
    }
}

sub _credit {
    my ( $self, $amount ) = @_;
    $self->{state}{resources}{$_} += $amount for qw(bufos totalBufos);
}

sub _count_click {
    my $self = shift;
    $self->{state}{resources}{clickCount}++;
    $self->{state}{achievements}{clickCount} = $self->{state}{resources}{clickCount};
}
sub _valid_time { _finite( $_[1] ) && $_[1] >= 0 && $_[1] >= $_[0]{now} }

sub click {
    my ( $self, $now ) = @_;
    return _fail('Invalid click time') unless $self->_valid_time($now);
    return _fail('Game is paused')                if $self->{paused};
    return _fail('Fight the boss to deal damage') if $self->{fight};
    $self->_timers($now);
    my $combo = defined( $self->{lastClick} ) && $now - $self->{lastClick} < 500;
    $self->{combo}     = $combo ? _min( 10, $self->{combo} + 1 ) : 0;
    $self->{lastClick} = $now;
    my $multiplier = 1 + $self->{combo} * 0.05;
    my $gain       = $self->{state}{resources}{clickPower} * $multiplier;
    $self->_count_click;
    $self->_credit($gain);
    $self->_check_achievements;
    return _ok( bufosGained => $gain, isCombo => $combo ? 1 : 0, comboMultiplier => $multiplier );
}

sub generator_cost {
    my ( $self, $id, $quantity ) = @_;
    $quantity = 1 unless defined $quantity;
    my $g = $self->{state}{generators}{$id};
    return undef unless $g && _finite($quantity) && _floor($quantity) == $quantity;
    $quantity = $self->max_affordable($id) if $quantity == -1;
    return undef                           if $quantity < 0;
    return 0                               if !$quantity;
    return undef unless defined $g->{currentCost};
    return $g->{currentCost} if $quantity == 1;
    my $r = $g->{costMultiplier};
    my $cost =
        $r == 1
      ? $g->{currentCost} * $quantity
      : $g->{currentCost} * ( $r**$quantity - 1 ) / ( $r - 1 );
    return _finite($cost) ? _ceil($cost) : undef;
}

sub max_affordable {
    my ( $self, $id ) = @_;
    my $g = $self->{state}{generators}{$id};
    return 0
      unless $g
      && $g->{unlocked}
      && $g->{enabled}
      && defined( $g->{currentCost} )
      && $g->{currentCost} > 0;
    my $bank = $self->{state}{resources}{bufos};
    return 0 if $bank < $g->{currentCost};
    my $r = $g->{costMultiplier};
    my $q =
      $r == 1
      ? _floor( $bank / $g->{currentCost} )
      : _floor( log( 1 + $bank / $g->{currentCost} * ( $r - 1 ) ) / log($r) );
    $q = 0 if $q < 0;

    while ( $q > 0 ) {
        my $cost = $self->generator_cost( $id, $q );
        last if defined($cost) && $cost <= $bank;
        $q--;
    }
    my $next = $self->generator_cost( $id, $q + 1 );
    $q++ if defined($next) && $next <= $bank;
    return $q;
}

sub buy_generator {
    my ( $self, $id, $quantity ) = @_;
    $quantity = 1 unless defined $quantity;
    return _fail('Invalid purchase quantity')
      unless _finite($quantity)
      && _floor($quantity) == $quantity
      && ( $quantity > 0 || $quantity == -1 );
    my $g = $self->{state}{generators}{$id};
    return _fail('Generator is locked') unless $g && $g->{unlocked} && $g->{enabled};
    $quantity = $self->max_affordable($id) if $quantity == -1;
    my $cost = $self->generator_cost( $id, $quantity );
    return _fail('Not enough bufos')
      unless $quantity > 0 && defined($cost) && $cost <= $self->{state}{resources}{bufos};
    $self->{state}{resources}{bufos} -= $cost;
    $g->{count} += $quantity;
    $self->refresh;
    $self->_check_achievements;
    return _ok( cost => $cost, quantity => $quantity );
}

sub buy_upgrade {
    my ( $self, $id ) = @_;
    my $u = $self->{catalog}->upgrade($id);
    return _fail('Unknown upgrade') unless $u;
    return _fail('Upgrade already purchased') if _set( $self->{state}{upgrades}{purchased} )->{$id};
    return _fail('Upgrade is locked')
      unless $self->_requirements_met( $u->{unlockConditions} );
    return _fail('Not enough bufos') if $self->{state}{resources}{bufos} < $u->{cost};
    $self->{state}{resources}{bufos} -= $u->{cost};
    push @{ $self->{state}{upgrades}{purchased} }, $id;
    $self->refresh;
    $self->_check_achievements;
    return _ok( cost => $u->{cost} );
}

sub available_boss {
    my $self     = shift;
    my $defeated = _set( $self->{state}{bosses}{defeated} );
    for my $boss ( @{ $self->{catalog}->bosses } ) {
        next if $defeated->{ $boss->{id} };
        return $self->{state}{resources}{totalBufos} >= $boss->{threshold} ? $boss : undef;
    }
    return undef;
}
sub active_boss { $_[0]{fight} }

sub start_boss {
    my ( $self, $now ) = @_;
    return _fail('Invalid fight time') unless $self->_valid_time($now);
    return _fail('Game is paused')                 if $self->{paused};
    return _fail('A boss fight is already active') if $self->{fight};
    my $boss = $self->available_boss;
    return _fail('No boss available') unless $boss;
    $self->_timers($now);
    my $health =
      _max( 1, _ceil( $boss->{baseHealth} * $self->prestige_multiplier * $self->boss_multiplier ) );
    $self->{fight} = {
        boss        => $boss,
        health      => $health,
        maxHealth   => $health,
        remainingMs => 30000,
        lastAt      => $now
    };
    return _ok();
}

sub hit_boss {
    my ( $self, $now ) = @_;
    return _fail('Invalid hit time') unless $self->_valid_time($now);
    return _fail('Game is paused') if $self->{paused};
    return _fail('No active boss fight') unless $self->{fight};
    $self->_timers($now);
    return _fail('The fight has ended') unless $self->{fight};
    my $damage = $self->{state}{resources}{clickPower};
    $self->_count_click;
    $self->{fight}{health} = _max( 0, $self->{fight}{health} - $damage );

    if ( $self->{fight}{health} <= 0 ) {
        my $id = $self->{fight}{boss}{id};
        $self->{fight} = undef;
        push @{ $self->{state}{bosses}{defeated} }, $id;
        $self->{state}{achievements}{customEvents}{"boss_$id"} = 1;
        push @{ $self->{events} }, { type => 'boss_won', id => $id };
    }
    $self->refresh;
    $self->_check_achievements;
    return _ok( damage => $damage );
}

sub retreat_boss {
    my $self = shift;
    return _fail('No active boss fight') unless $self->{fight};
    $self->{fight} = undef;
    return _ok();
}

sub _timers {
    my ( $self, $now ) = @_;
    $self->{now} = $now;
    if ( $self->{fight} && !$self->{paused} ) {
        $self->{fight}{remainingMs} -= _max( 0, $now - $self->{fight}{lastAt} );
        $self->{fight}{lastAt} = $now;
        if ( $self->{fight}{remainingMs} <= 0 ) {
            push @{ $self->{events} }, { type => 'boss_lost', id => $self->{fight}{boss}{id} };
            $self->{fight} = undef;
            $self->{state}{resources}{bufos} = 0;
        }
    }
    for my $kind (qw(production click)) {
        $self->{frenzies}{$kind} = 0 if $self->{frenzies}{$kind} <= $now;
    }
    $self->refresh;
}

sub tick {
    my ( $self, $seconds, $now ) = @_;
    return _fail('Invalid tick')
      unless _finite($seconds) && $seconds >= 0 && $self->_valid_time($now);
    return _ok( production => 0 ) if $self->{paused};
    my $production = $self->production * $seconds;
    my $ends       = $self->{frenzies}{production};
    if ( $ends && $ends < $now && $seconds > 0 ) {
        my $boosted = _min( $seconds, _max( 0, ( $ends - ( $now - $seconds * 1000 ) ) / 1000 ) );
        $production = $self->production / 7 * ( $seconds + 6 * $boosted );
    }
    $self->_credit($production);
    $self->_timers($now);
    $self->{state}{gameSettings}{lastTick} = $now;
    $self->_check_achievements;
    return _ok( production => $production );
}

sub credit_elapsed {
    my ( $self, $seconds, $now ) = @_;
    return _fail('Invalid elapsed time')
      unless _finite($seconds) && $seconds >= 0 && $seconds <= 43200 && $self->_valid_time($now);
    my $production =
      $self->production / ( $self->{state}{resources}{frenzyProductionMultiplier} // 1 ) * $seconds;
    $self->_credit($production);
    $self->{now} = $now;
    $self->{state}{gameSettings}{lastTick} = $now;
    $self->_check_achievements;
    return _ok( production => $production );
}

sub pause {
    my ( $self, $now ) = @_;
    return _fail('Invalid pause time') unless $self->_valid_time($now);
    $self->_timers($now);
    $self->{paused}                        = 1;
    $self->{frenzies}                      = { production => 0, click => 0 };
    $self->{combo}                         = 0;
    $self->{lastClick}                     = undef;
    $self->{state}{gameSettings}{lastTick} = $now;
    $self->refresh;
    return _ok();
}

sub resume {
    my ( $self, $now ) = @_;
    return _fail('Invalid resume time') unless $self->_valid_time($now);
    $self->{now}                           = $now;
    $self->{paused}                        = 0;
    $self->{fight}{lastAt}                 = $now if $self->{fight};
    $self->{state}{gameSettings}{lastTick} = $now;
    return _ok();
}

sub active_frenzies {
    my ( $self, $now ) = @_;
    $now = $self->{now} unless defined $now;
    return {
        map {
            $_ => ( $self->{frenzies}{$_} > $now
                ? { multiplier => 7, endsAt => $self->{frenzies}{$_} }
                : undef )
        } qw(production click)
    };
}

sub golden_outcome {
    my ( $self, $random ) = @_;
    die "Golden roll must be in [0,1)\n" unless _finite($random) && $random >= 0 && $random < 1;
    return $random < 0.5 ? 'bufo_frenzy' : $random < 0.8 ? 'lucky' : 'click_frenzy';
}

sub collect_golden {
    my ( $self, $outcome, $now ) = @_;
    return _fail('Invalid reward time') unless $self->_valid_time($now);
    return _fail('Game is paused') if $self->{paused};
    return _fail('Unknown golden reward')
      unless defined($outcome) && $outcome =~ /\A(?:bufo_frenzy|click_frenzy|lucky)\z/;
    $self->_timers($now);
    my ( $label, $detail );
    if ( $outcome eq 'lucky' ) {
        my $gain =
          _floor( _min( $self->{state}{resources}{bufos} * 0.15, $self->production * 1200 ) + 13 );
        $self->_credit($gain);
        $label  = 'Lucky!';
        $detail = '+' . $self->format_number($gain) . ' bufos';
    } else {
        my $kind     = $outcome eq 'bufo_frenzy' ? 'production' : 'click';
        my $duration = $kind eq 'production'     ? 30000        : 15000;
        $self->{frenzies}{$kind} = $now + $duration;
        $label                   = $kind eq 'production' ? 'Bufo Frenzy!' : 'Click Frenzy!';
        $detail                  = 'x7 '
          . ( $kind eq 'production' ? 'production' : 'click power' ) . ' for '
          . ( $duration / 1000 ) . 's';
    }
    $self->{state}{achievements}{customEvents}{golden_bufo_caught} = 1;
    $self->refresh;
    $self->_check_achievements;
    return _ok( rewardType => $outcome, label => $label, detail => $detail );
}

sub trigger_custom_event {
    my ( $self, $name ) = @_;
    return _fail('Unknown milestone') unless defined($name) && $name eq 'console_opened';
    $self->{state}{achievements}{customEvents}{$name} = 1;
    $self->_check_achievements;
    return _ok();
}

sub prestige {
    my $self   = shift;
    my $gained = $self->pending_prestige;
    return _fail('Earn at least 1 billion bufos to transcend') unless $gained;
    return _fail('Finish or retreat from the boss fight first') if $self->{fight};
    my $s = $self->{state};
    $s->{prestige}{points}         += $gained;
    $s->{prestige}{lifetimePoints} += $gained;
    $s->{prestige}{transcendences}++;
    $s->{bosses}{lifetimeDefeats} += @{ $s->{bosses}{defeated} };
    $s->{bosses}{defeated}      = [];
    $s->{resources}{bufos}      = 0;
    $s->{resources}{totalBufos} = 0;
    $s->{generators}            = _clone( $self->{catalog}->generators );
    $s->{upgrades}              = { purchased  => [], available => [] };
    $self->{frenzies}           = { production => 0, click => 0 };
    $self->{combo}              = 0;
    $self->{lastClick}          = undef;
    $self->refresh;
    $self->_check_achievements;
    return _ok( gained => $gained );
}
1;
