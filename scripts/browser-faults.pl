use strict;
use warnings;

# Browser fault injection exercises the deployed Perl app through its normal controls.
sub browser_fault_checks {
    my ($base) = @_;
    command( 'POST', '/window/rect', { width => 1440, height => 1000 } );
    my $key        = 'bufo_idle_save_perl_v1';
    my $legacy_key = 'bufo_idle_save';
    open my $fixture, '<', 't/fixtures/legacy-captured.json' or die $!;
    my $legacy = do { local $/; <$fixture> };
    close $fixture;

    for my $action (qw(reset import prestige)) {
        command( 'POST', '/url', { url => "$base/" } );
        ready();
        evaluate('const fixed = Date.now(); Date.now = () => fixed;');
        seed('$s->{resources}{bufos}=1e12; $s->{resources}{totalBufos}=1e12;');
        perl_eval(
            '$Bufo::Browser::game->pause(Bufo::Browser::now()); Bufo::Browser::persist(0); 1;');
        evaluate( 'localStorage.setItem(arguments[0], arguments[1]);', $legacy_key, $legacy );
        my $before   = state();
        my $stored   = _fault_keys( $key, $legacy_key );
        my $imported = evaluate(
            'const save = JSON.parse(arguments[0]); save.state.resources.clickCount = 123; save.state.achievements.clickCount = 123; return JSON.stringify(save);',
            $stored->[0]
        );
        evaluate(
            q{
            window.__faultWrites = [];
            Storage.prototype.setItem = function (key, value) {
                window.__faultWrites.push(key);
                throw new DOMException('Injected quota failure', 'QuotaExceededError');
            };
        }
        );

        if ( $action eq 'reset' ) {
            click('#reset-button');
            click('[data-action=confirm-reset]');
            wait_for(
                sub { evaluate('return document.body.innerText.includes("Reset failed because");') }
            );
        } elsif ( $action eq 'import' ) {
            click('#stats-button');
            click('[data-action=saves]');
            evaluate( 'document.getElementById("save-transfer").value = arguments[0];', $imported );
            click('[data-action=import]');
            wait_for(
                sub {
                    evaluate(
                        'return document.getElementById("save-transfer-status").innerText.includes("Import failed");'
                    );
                }
            );
        } else {
            click('#transcend-button');
            click('[data-action=confirm-prestige]');
            wait_for(
                sub {
                    evaluate(
                        'return document.body.innerText.includes("Could not save transcendence");');
                }
            );
        }
        is_deeply( state(), $before, "failed $action storage leaves active state unchanged" );
        is_deeply( _fault_keys( $key, $legacy_key ),
            $stored, "failed $action storage preserves current and legacy keys" );
        is_deeply( evaluate('return window.__faultWrites;'),
            [$key], "failed $action attempts only the current save key" );
    }

    # A new document restores the unmodified Storage prototype after quota injection.
    command( 'POST', '/url', { url => "$base/" } );
    ready();
    evaluate(
        'localStorage.setItem(arguments[0], "{corrupt"); localStorage.setItem(arguments[1], arguments[2]);',
        $key, $legacy_key, $legacy );
    my $script = command(
        'POST',
        '/goog/cdp/execute',
        {
            cmd    => 'Page.addScriptToEvaluateOnNewDocument',
            params => {
                source => q{
            window.__faultWrites = [];
            window.__faultReads = [];
            const originalSet = Storage.prototype.setItem;
            const originalGet = Storage.prototype.getItem;
            Storage.prototype.setItem = function (key, value) {
                window.__faultWrites.push(key);
                return originalSet.call(this, key, value);
            };
            Storage.prototype.getItem = function (key) {
                window.__faultReads.push(key);
                return originalGet.call(this, key);
            };
        }
            }
        }
    );

    # pagehide persists the old healthy game; inject corrupt bytes after it runs.
    evaluate(
        q~
        window.addEventListener('pagehide', () => localStorage.setItem(arguments[0], '{corrupt'));
    ~, $key
    );
    command( 'POST', '/refresh', {} );
    ready();
    command(
        'POST',
        '/goog/cdp/execute',
        {
            cmd    => 'Page.removeScriptToEvaluateOnNewDocument',
            params => { identifier => $script->{identifier} }
        }
    );
    ok( evaluate('return document.getElementById("save-recovery-modal") !== null;'),
        'corrupt current key opens recovery' );
    my $blocked_before = state();
    evaluate(
        q{
        const fixed = Date.now() + 120000;
        Date.now = () => fixed;
        document.getElementById('frog-display').dispatchEvent(new MouseEvent('click', { bubbles: true }));
    }
    );
    perl_eval('Bufo::Browser::on_tick(); Bufo::Browser::persist(0); 1;');
    is_deeply( state(), $blocked_before, 'recovery blocks gameplay and automatic progress' );
    perl_eval('Bufo::Browser::on_pagehide(); 1;');
    is_deeply( evaluate('return window.__faultWrites;'),
        [], 'recovery blocks automatic and lifecycle writes' );
    ok( !evaluate( 'return window.__faultReads.includes(arguments[0]);', $legacy_key ),
        'corrupt current key never reads the legacy fallback' );
    is_deeply(
        _fault_keys( $key, $legacy_key ),
        [ '{corrupt', $legacy ],
        'recovery preserves both stored keys'
    );

    click('#save-recovery-modal [data-action=reset]');
    click('[data-action=confirm-reset]');
    command( 'POST', '/url', { url => "$base/" } );
    ready();
    evaluate(
        q{
        window.__faultTime = Date.now();
        Date.now = () => window.__faultTime;
        window.__faultHidden = false;
        Object.defineProperty(document, 'hidden', {
            configurable: true, get: () => window.__faultHidden
        });
    }
    );
    seed(
        '$s->{resources}{bufos}=20000; $s->{resources}{totalBufos}=20000; $s->{generators}{tadpole}{count}=10; $s->{explorer}{state}="exploring"; $s->{explorer}{stateStartTime}=Bufo::Browser::now(); $s->{explorer}{explorationProgress}=25;'
    );
    perl_eval(
        '$Bufo::Browser::game->tick(0, Bufo::Browser::now()); Bufo::Browser::process_events(); Bufo::Browser::render(); 1;'
    );
    click('.boss-banner__fight');
    my $rate  = 0 + perl_eval('$Bufo::Browser::game->production');
    my $fight = JSON::PP::decode_json(
        perl_eval('JSON::PP::encode_json($Bufo::Browser::game->active_boss)') );
    evaluate('window.__faultHidden=true; document.dispatchEvent(new Event("visibilitychange"));');
    my $hidden_before = state();
    evaluate('window.__faultTime += 86400000;');
    perl_eval('Bufo::Browser::on_tick(); 1;');
    is_deeply( state(), $hidden_before, 'simulated hidden tab does not tick gameplay' );
    evaluate('window.__faultHidden=false; document.dispatchEvent(new Event("visibilitychange"));');
    my $resumed       = state();
    my $resumed_fight = JSON::PP::decode_json(
        perl_eval('JSON::PP::encode_json($Bufo::Browser::game->active_boss)') );
    is(
        $resumed->{resources}{bufos} - $hidden_before->{resources}{bufos},
        $rate * 43200,
        'simulated 24-hour background gap credits exactly the 12-hour cap'
    );
    is( $resumed_fight->{remainingMs},
        $fight->{remainingMs}, 'simulated background gap preserves fight time' );
    is( $resumed_fight->{health},
        $fight->{health}, 'simulated background gap preserves fight health' );
    is_deeply(
        $resumed->{explorer},
        $hidden_before->{explorer},
        'simulated background gap preserves Explorer progress and health'
    );

    evaluate(
        'window.__faultHidden=true; document.dispatchEvent(new Event("visibilitychange")); window.__faultTime -= 60000; window.__faultHidden=false; document.dispatchEvent(new Event("visibilitychange"));'
    );
    ok( perl_eval('$Bufo::Browser::game->tick(1, Bufo::Browser::now())->{ok}'),
        'backward wall-clock adjustment resumes production' );
    click('#boss-sprite');
    cmp_ok(
        0 + perl_eval('$Bufo::Browser::game->active_boss->{health}'),
        '<',
        $resumed_fight->{health},
        'backward wall-clock adjustment keeps boss controls usable'
    );

    # Block the real catalog request before navigation; never alter deployed files.
    perl_eval('Bufo::Browser::persist(0);1;');
    my $stored_before_catalog = _fault_keys( $key, $legacy_key );
    command( 'POST', '/goog/cdp/execute', { cmd => 'Network.enable', params => {} } );
    command(
        'POST',
        '/goog/cdp/execute',
        {
            cmd    => 'Network.setBlockedURLs',
            params => { urls => ['*assets/data/generators.json*'] }
        }
    );
    my $catalog_ok = eval {
        command( 'POST', '/url', { url => "$base/" } );
        wait_for(
            sub { evaluate('return document.body.innerText.includes("The pond could not open");') }
        );
        ok( !evaluate('return document.querySelector("[data-ready=true]") !== null;'),
            'blocked catalog prevents startup' );
        my $after_navigation = _fault_keys( $key, $legacy_key );
        is_deeply( $after_navigation, $stored_before_catalog,
            'catalog failure preserves both prior stored keys' );
        perl_eval('Bufo::Browser::on_tick(); Bufo::Browser::on_pagehide(); 1;');
        is_deeply( _fault_keys( $key, $legacy_key ),
            $after_navigation, 'catalog failure never writes saves' );
        is(
            $after_navigation->[1],
            $stored_before_catalog->[1],
            'catalog failure preserves legacy save'
        );
        1;
    };
    my $catalog_error = $@;
    command( 'POST', '/goog/cdp/execute',
        { cmd => 'Network.setBlockedURLs', params => { urls => [] } } );
    die $catalog_error unless $catalog_ok;
    command( 'POST', '/url', { url => "$base/" } );
    ready();
    return 1;
}

sub _fault_keys {
    my ( $key, $legacy_key ) = @_;
    return evaluate(
        'return [localStorage.getItem(arguments[0]), localStorage.getItem(arguments[1])];',
        $key, $legacy_key );
}

1;
