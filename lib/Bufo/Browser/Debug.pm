package Bufo::Browser::Debug;
use strict;
use warnings;
use WebPerl      qw/js/;
use Scalar::Util qw/blessed refaddr weaken/;
use mro;
use Sub::Util qw/subname/;
my ( @callbacks, @bindings );

sub from_js {
    my ($v) = @_;
    return $v unless blessed($v) && $v->isa('WebPerl::JSObject');
    my $type;
    { no overloading '%{}'; $type = $v->{type}; }
    if ( $type eq 'F' ) {
        @callbacks = grep { defined $_->[1] } @callbacks;
        for (@callbacks) { return $_->[1] if js('Object')->is( $_->[0], $v ); }
        my $cb = sub {
            return from_js( $v->coderef->( map { to_js($_) } @_ ) );
        };
        my $entry = [ $v, $cb ];
        weaken( $entry->[1] );
        push @callbacks, $entry;
        return $cb;
    }
    return $v                                        if $type eq 'O' && defined( $v->{nodeType} );
    return [ map { from_js($_) } @{ $v->arrayref } ] if $type eq 'A';
    my $hash = $v->hashref;
    return { map { $_ => from_js( $hash->{$_} ) } keys %$hash };
}

sub to_js {
    my ($v) = @_;
    return $v unless ref $v;
    return $v                        if blessed($v) && $v->isa('WebPerl::JSObject');
    return object( sub { $v } )      if blessed $v;
    return [ map { to_js($_) } @$v ] if ref $v eq 'ARRAY';
    return { map { $_ => to_js( $v->{$_} ) } keys %$v } if ref $v eq 'HASH';
    return $v;
}

sub methods {
    my ($obj) = @_;
    my %names;
    no strict 'refs';
    for my $pkg ( @{ mro::get_linear_isa( ref $obj ) } ) {
        for my $name ( keys %{ $pkg . '::' } ) {
            next if $name =~ /^(?:BEGIN|import|new|DESTROY)$/;
            my $code = *{ $pkg . '::' . $name }{CODE};
            $names{$name} = 1 if $code && subname($code) =~ /^\Q$pkg\E\::/;
        }
    }
    return sort keys %names;
}

sub object {
    my ($provider) = @_;
    my $obj = $provider->();
    return unless defined $obj;
    my %wrapped;
    for my $method ( methods($obj) ) {
        $wrapped{$method} = sub {
            my @args    = map { from_js($_) } @_;
            my $current = $provider->();
            my $r       = $current->$method(@args);
            if (   blessed($r)
                && !$r->isa('WebPerl::JSObject')
                && $method =~ /^get(?:.*Manager|GameCore|GameLoop|EventBus)$/ )
            {
                return object( sub { $provider->()->$method(@args) } );
            }
            return to_js($r);
        };
    }
    my $out = js( \%wrapped );
    push @bindings, \%wrapped;
    return $out;
}

sub expose {
    my ($class) = @_;
    my $api     = $Bufo::Browser::api;
    my $state   = $Bufo::Browser::state;
    my $events  = $Bufo::Browser::events;
    my $window  = js('window');
    my %tools   = (
        state    => object( sub { $Bufo::Browser::state } ),
        events   => object( sub { $Bufo::Browser::events } ),
        gameCore => object( sub { $Bufo::Browser::api } ),
        gameLoop => object( sub { $Bufo::Browser::loop } ),
        ui       => object( sub { $Bufo::Browser::ui } )
    );
    my %manager = (
        generators => 'getGeneratorManager',
        upgrades   => 'getUpgradeManager',
        explorer   => 'getExplorerManager',
        prestige   => 'getPrestigeManager'
    );
    for my $key ( keys %manager ) {
        my $method = $manager{$key};
        $tools{$key} = object( sub { $Bufo::Browser::api->$method() } );
    }
    $tools{golden} = {
        spawn => sub {
            $api->getGoldenBufoManager->forceSpawn;
            return 'Golden Bufo spawned (or already on screen)';
        },
        collect => sub {
            my $r = $api->getGoldenBufoManager->collect;
            return $r
              ? 'Collected: ' . $r->{label} . ' - ' . $r->{detail}
              : 'No Golden Bufo on screen';
        }
    };
    $tools{boss} = {
        available => sub { return to_js( $api->getBossManager->getAvailableBoss ) },
        start     => sub {
            return $api->getBossManager->startFight
              ? 'Fight started'
              : 'No boss available (or one is already active)';
        },
        hit => sub {
            my $amount = $_[0];
            $amount = $api->getState->{resources}{clickPower} unless defined $amount;
            return to_js( $api->getBossManager->hit($amount) );
        },
        win => sub {
            my $f = $api->getBossManager->getActiveFight;
            return $f ? to_js( $api->getBossManager->hit( $f->{health} ) ) : 'No active fight';
        },
        lose => sub {
            my $f = $api->getBossManager->getActiveFight;
            return 'No active fight' unless $f;
            $api->getBossManager->retreat;
            $state->setState( { resources => { bufos => 0 } } );
            return 'Simulated a loss (bufos zeroed, fight cleared)';
        },
        status        => sub { return to_js( $api->getBossManager->getActiveFight ) },
        multiplier    => sub { return $api->getBossManager->getMultiplier },
        defeatedCount => sub { return $api->getBossManager->getDefeatedCount }
    };
    $tools{save} = {
        save   => sub { return $api->save },
        load   => sub { return $api->load },
        export => sub { return $api->exportSave },
        import => sub { return $api->importSave( $_[0] ) }
    };
    $tools{time} = {
        pause        => sub { $Bufo::Browser::loop->stop;                  return; },
        resume       => sub { $Bufo::Browser::loop->start;                 return; },
        setTimeScale => sub { $Bufo::Browser::loop->setTimeScale( $_[0] ); return; },
        getTimeScale => sub { return $Bufo::Browser::loop->getTimeScale }
    };
    $tools{resources} = {
        get => sub {
            my $r = $api->getState->{resources};
            return { bufos => $r->{bufos}, totalBufos => $r->{totalBufos} };
        },
        add => sub {
            my $r = $api->getState->{resources};
            $state->setState(
                {
                    resources =>
                      { bufos => $r->{bufos} + $_[0], totalBufos => $r->{totalBufos} + $_[0] }
                }
            );
            return $r->{bufos} + $_[0];
        },
        set => sub {
            my $n = $_[0];
            my $r = $api->getState->{resources};
            $state->setState(
                {
                    resources =>
                      { bufos => $n, totalBufos => $n > $r->{totalBufos} ? $n : $r->{totalBufos} }
                }
            );
            return $n;
        }
    };
    $tools{inspect} = {
        state      => sub { return to_js( $api->getState ) },
        generators => sub { return to_js( $api->getGeneratorManager->getAllGenerators ) },
        upgrades   => sub {
            return {
                purchased => to_js( $api->getUpgradeManager->getPurchasedUpgrades ),
                available => to_js( $api->getUpgradeManager->getAvailableUpgrades )
            };
        },
        explorer   => sub { return to_js( $api->getExplorer ) },
        production => sub { return to_js( $api->getProductionStatistics ) }
    };
    $tools{events_debug} = {
        enableDebug  => sub { $events->setDebugMode(1); return; },
        disableDebug => sub { $events->setDebugMode(0); return; },
        listEvents   => sub { return $events->getEventNames },
        emit         => sub { $events->emit( $_[0], from_js( $_[1] ) ); return; }
    };
    my $logger = $Bufo::Browser::logger;
    $tools{logging} = {
        setLevel            => sub { $logger->setLogLevel( $_[0] ); return; },
        getLevel            => sub { return $logger->getLogLevel },
        enableTimestamps    => sub { $logger->enableTimestamps( $_[0] );    return; },
        enableConsoleColors => sub { $logger->enableConsoleColors( $_[0] ); return; }
    };
    $tools{generator_debug} = {
        unlockAll => sub {
            my $g     = $api->getState->{generators};
            my %patch = map { $_ => { unlocked => 1, enabled => 1 } } keys %$g;
            $state->setState( { generators => \%patch } );
            return 'All generators unlocked';
        },
        give => sub {
            my ( $type, $amount ) = @_;
            $amount = 1 unless defined $amount;
            my $g = $api->getState->{generators};
            return
                'Generator '
              . $type
              . ' not found - valid types are: '
              . join( ', ', sort keys %$g )
              unless $g->{$type};
            $state->setState(
                { generators => { $type => { count => $g->{$type}{count} + $amount } } } );
            $api->getGeneratorManager->recalculateGenerator($type);
            return 'Added ' . $amount . ' ' . $g->{$type}{name} . ' generators';
        }
    };
    $tools{upgrade_debug} = {
        unlockAll => sub {
            my $all     = $api->getUpgradeManager->getAvailableUpgrades;
            my $current = $api->getState->{upgrades}{available};
            $state->setState(
                { upgrades => { available => [ @$current, map { $_->{id} } @$all ] } } );
            return 'Unlocked ' . scalar(@$all) . ' upgrades';
        },
        purchase => sub {
            my $id = $_[0];
            my $r  = $api->getUpgradeManager->purchaseUpgrade( $id, 1e308 );
            return $r->{success} ? 'Purchased upgrade ' . $id : 'Failed to purchase ' . $id;
        }
    };
    $tools{reset} = {
        softReset => sub { $api->resetState; return 'Game state reset' },
        hardReset => sub {
            js('window')->{localStorage}->clear;
            js('window')->{location}->reload;
            return 'Local storage cleared, reloading page';
        }
    };
    $tools{performance} = {
        measure => sub {
            my ( $label, $fn ) = @_;
            my $cb = from_js($fn);
            js('console')->time($label);
            my $ok  = eval { $cb->(); 1 };
            my $err = $@;
            js('console')->timeEnd($label);
            die $err unless $ok;
            return;
        }
    };
    $tools{help} = sub {
        js('console')->group('Bufo Idle Debug Tools');
        js('console')
          ->log('state, events, gameCore, gameLoop, ui, generators, upgrades, explorer, prestige');
        js('console')
          ->log(
            'resources, inspect, save, time, golden, boss, generator_debug, upgrade_debug, events_debug, logging, reset, performance'
          );
        js('console')->groupEnd;
        return 'Debug tools help displayed in console';
    };
    my %default = %tools;
    $tools{default} = \%default;
    $window->{debugTools} = js( \%tools );
    push @bindings, \%tools;
    return;
}

sub destroy {
    my $window = js('window');
    $window->{debugTools} = undef;
    for my $b (@bindings) {
        for my $cb ( values %$b ) { WebPerl::unregister($cb) if ref($cb) eq 'CODE'; }
    }
    @bindings  = ();
    @callbacks = ();
    return;
}
1;
