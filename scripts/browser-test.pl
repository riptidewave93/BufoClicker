#!/usr/bin/env perl
use strict;
use warnings;
use HTTP::Tiny;
use JSON::PP;
use MIME::Base64 qw(decode_base64);
use Time::HiRes  qw(time sleep);
use File::Path   qw(make_path);
use Test::More;

my $driver = $ENV{WEBDRIVER_URL} || 'http://127.0.0.1:14444';
my $base   = $ENV{BUFO_URL}      || 'http://host.docker.internal:9000';
my $http   = HTTP::Tiny->new(
    timeout  => 60,
    max_redirect => 0,
    proxy    => undef,
    no_proxy => 'localhost,127.0.0.1,webdriver,site,host.docker.internal'
);
my $json = JSON::PP->new->canonical;
my $session;
my @measurements;
make_path('artifacts');

END {
    if ($session) {
        eval {
            my $logs = command( 'POST', '/log', { type => 'browser' } );
            open my $fh, '>', 'artifacts/final-console.json';
            print {$fh} $json->encode($logs);
            close $fh;
        };
        eval { request( 'DELETE', "/session/$session" ) };
    }
}
my $deadline = time + 60;
while (1) {
    last                                   if eval { request( 'GET', '/status' )->{ready} };
    die "WebDriver did not become ready\n" if time > $deadline;
    sleep 0.5;
}
my $created = request(
    'POST',
    '/session',
    {
        capabilities => {
            alwaysMatch => {
                browserName          => 'chrome',
                'goog:chromeOptions' =>
                  { args => [ '--headless=new', '--no-sandbox', '--disable-dev-shm-usage' ] },
                'goog:loggingPrefs' => { browser => 'ALL' },
            }
        }
    }
);
$session = $created->{sessionId};
note(   'Browser '
      . $created->{capabilities}{browserName} . ' '
      . $created->{capabilities}{browserVersion} );

# The suite drives the deployed page. Perl.eval calls the application's Perl APIs.
for my $path ( '/', '/BufoClicker/' ) {
    command( 'POST', '/window/rect', { width => 1440, height => 1000 } );
    command( 'POST', '/url',         { url   => "$base/styles/index.css" } );
    evaluate('localStorage.clear();');
    command( 'POST', '/url', { url => "$base$path" } );
    ready();
    push @measurements,
      {
        path => $path,
        %{
            evaluate(
'return {readyUpperBoundMs:performance.now(),runtime:performance.getEntriesByType("resource").filter(e=>/emperl|webperl/.test(e.name)).map(e=>({name:e.name.split("/").pop(),encodedBytes:e.encodedBodySize,decodedBytes:e.decodedBodySize,durationMs:e.duration}))};'
            )
        }
      };
    ok( evaluate('return document.body.innerText.length > 100;'), "$path renders game content" );
    like( command( 'GET', '/title' ), qr/Bufo/i, "$path page identity" );
    is( state()->{resources}{clickCount}, 0, "$path starts fresh" );
    click('#frog-display');
    is( state()->{resources}{clickCount}, 1, "$path DOM click reaches Perl exactly once" );
    cmp_ok( state()->{resources}{bufos}, '>=', 1, "$path click earns currency" );
    command( 'POST', '/refresh', {} );
    ready();
    is( state()->{resources}{clickCount}, 1, "$path pagehide saves click without manual save" );
    click('#buy-tadpole');
    is( state()->{generators}{tadpole}{count},
        0, "$path unaffordable control responds without purchase" );
    seed('$s->{resources}{bufos}=20000; $s->{resources}{totalBufos}=20000;');
    click('#buy-tadpole');
    is( state()->{generators}{tadpole}{count}, 1, "$path buys generator through UI" );
    click('.upgrade-icon[data-id="stronger_clicks_1"]');
    ok( grep( $_ eq 'stronger_clicks_1', @{ state()->{upgrades}{purchased} } ),
        "$path buys upgrade through UI" );
    click('#save-button');
    command( 'POST', '/refresh', {} );
    ready();
    is( state()->{generators}{tadpole}{count}, 1, "$path purchase survives reload" );
    click('#stats-button');
    like(
        evaluate('return document.querySelector("[role=dialog]").innerText;'),
        qr/Game Statistics/,
        "$path statistics opens"
    );
    click('[data-action=saves]');
    click('[data-action=export]');
    my $export  = evaluate('return document.getElementById("save-transfer").value;');
    my $decoded = evaluate( 'return decodeURIComponent(atob(arguments[0]));', $export );
    is( $json->decode($decoded)->{format},
        'bufo-clicker-perl', "$path export uses legacy-compatible codec" );
    evaluate( 'document.getElementById("save-transfer").value=arguments[0];', 'invalid backup' );
    click('[data-action=import]');
    like(
        evaluate('return document.getElementById("save-transfer-status").innerText;'),
        qr/Import failed/,
        "$path malformed import reports failure"
    );
    is( state()->{generators}{tadpole}{count}, 1, "$path failed import preserves progress" );
    evaluate( 'document.getElementById("save-transfer").value=arguments[0];', $export );
    click('[data-action=import]');
    is( state()->{generators}{tadpole}{count}, 1, "$path exported save imports" );
    seed(
'$s->{resources}{bufos}=20000; $s->{resources}{totalBufos}=20000; $s->{generators}{tadpole}{count}=12; $s->{generators}{froglet}{count}=8; $s->{generators}{froglet}{unlocked}=1;'
    );
    my $label = $path eq '/' ? 'root' : 'subpath';
    screenshot("$label-desktop");
    click('#stats-button');
    screenshot("$label-stats");
    click('[data-action=close]');

    for my $width ( 375, 390, 412, 768 ) {
        command( 'POST', '/window/rect', { width => $width, height => 1000 } );
        my $overflow = evaluate(
'return Array.from(document.querySelectorAll("button,.column,.modal-content")).filter(e=>{const r=e.getBoundingClientRect();return r.width&&r.height&&(r.left < -1 || r.right > innerWidth+1);}).map(e=>e.id||e.className);'
        );
        is_deeply( $overflow, [], "$path controls fit $width px" );
        screenshot("$label-mobile") if $width == 390;
    }
    command( 'POST', '/window/rect', { width => 1440, height => 1000 } );
    seed(
'$s->{resources}{baseClickPower}=10000; $s->{resources}{bufos}=10000; $s->{resources}{totalBufos}=20000;'
    );
    click('.boss-banner__fight');
    ok( evaluate('return document.querySelector(".boss-fight-overlay") !== null;'),
        "$path boss overlay opens" );
    screenshot("$label-boss");
    my $clicks = state()->{resources}{clickCount};
    click('#boss-sprite');
    is( state()->{resources}{clickCount}, $clicks + 1,       "$path boss click counted once" );
    is( state()->{bosses}{defeated}[0],   'furious_froglet', "$path boss victory reaches state" );
    ok( evaluate('return document.getElementById("boss-victory-modal") !== null;'),
        "$path result remains visible" );
    sleep 0.9;
    click('[data-action=close]');
    perl_eval('Bufo::Browser::spawn_golden(); 1;');
    click('#golden-bufo');
    ok( state()->{achievements}{customEvents}{golden_bufo_caught},
        "$path golden collection reaches engine" );
    seed('$s->{resources}{totalBufos}=1e12; $s->{resources}{bufos}=1e12;');
    click('#transcend-button');
    click('[data-action=confirm-prestige]');
    is( state()->{prestige}{transcendences},     1, "$path prestige commits through UI" );
    is( scalar @{ state()->{bosses}{defeated} }, 0, "$path prestige reopens boss ladder" );
    is( perl_eval('my $n=15000000000; $n * (1.6 ** 0)'),
        15000000000, "$path runtime handles large arithmetic" );
    seed(
'$s->{resources}{totalBufos}=1e20; $s->{resources}{bufos}=1e20; $s->{generators}{singularity_bufo}{unlocked}=1;'
    );
    click('#buy-singularity_bufo');
    is( state()->{generators}{singularity_bufo}{count}, 1, "$path late-game purchase works" );
    command( 'POST', '/refresh', {} );
    ready();
    is( state()->{generators}{singularity_bufo}{count}, 1, "$path late-game save reloads" );
    my $logs   = command( 'POST', '/log', { type => 'browser' } );
    my @errors = grep { $_->{level} eq 'SEVERE' } @$logs;
    is_deeply( \@errors, [], "$path no browser errors" );
    open my $log, '>', "artifacts/$label-console.json" or die $!;
    print {$log} $json->pretty->encode($logs);
    close $log;
}

my $redirect = $http->head("$base/BufoClicker");
is($redirect->{status}, 301, 'prefix without slash redirects');
is($redirect->{headers}{location}, '/BufoClicker/', 'relative redirect preserves the published port');

# Captured legacy data, precedence, corruption and recovery run on the prefixed route.
open my $fixture, '<', 't/fixtures/legacy-captured.json' or die $!;
my $legacy = do { local $/; <$fixture> };
close $fixture;
command( 'POST', '/url', { url => "$base/styles/index.css" } );
evaluate( 'localStorage.clear(); localStorage.setItem("bufo_idle_save",arguments[0]);', $legacy );
command( 'POST', '/url', { url => "$base/BufoClicker/" } );
ready();
ok( evaluate('return localStorage.getItem("bufo_idle_save_perl_v1") !== null;'),
    'legacy save migrates' );
is( evaluate('return localStorage.getItem("bufo_idle_save");'),
    $legacy, 'legacy source remains byte-for-byte intact' );
my $before = state()->{resources}{clickCount};
click('#frog-display');
click('#save-button');
command( 'POST', '/refresh', {} );
ready();
is( state()->{resources}{clickCount}, $before + 1, 'new save wins when both keys exist' );
command( 'POST', '/url', { url => "$base/styles/index.css" } );
evaluate('localStorage.setItem("bufo_idle_save_perl_v1","{broken");');
command( 'POST', '/url', { url => "$base/BufoClicker/" } );
ready();
ok( evaluate('return document.getElementById("save-recovery-modal") !== null;'),
    'corrupt new save opens recovery' );
is( evaluate('return localStorage.getItem("bufo_idle_save_perl_v1");'),
    '{broken', 'corrupt save is not overwritten' );
click('#save-recovery-modal [data-action=reset]');
click('[data-action=confirm-reset]');
is( state()->{resources}{clickCount}, 0, 'explicit recovery reset starts fresh' );
command( 'POST', '/refresh', {} );
ready();
is( state()->{resources}{clickCount}, 0, 'reset does not reimport legacy progress' );

require './scripts/browser-faults.pl';
browser_fault_checks($base);

open my $metrics, '>', 'artifacts/runtime-metrics.json' or die $!;
print {$metrics} $json->pretty->encode( \@measurements );
close $metrics;
done_testing;

sub request {
    my ( $method, $path, $body ) = @_;
    my %options = ( headers => { 'Content-Type' => 'application/json; charset=utf-8' } );
    $options{content} = $json->encode($body) if defined $body;
    my $response = $http->request( $method, "$driver$path", \%options );
    my $decoded  = eval { $json->decode( $response->{content} ) };
    die "WebDriver $method $path: $response->{status} $response->{content}\n"
      unless $response->{success} && $decoded;
    return $decoded->{value};
}

sub command {
    my ( $method, $path, $body ) = @_;
    return request( $method, "/session/$session$path", $body );
}

sub evaluate {
    my ( $script, @args ) = @_;
    return command( 'POST', '/execute/sync', { script => $script, args => \@args } );
}
sub perl_eval { return evaluate( 'return Perl.eval(arguments[0]);', $_[0] ); }

sub element {
    return command( 'POST', '/element', { using => 'css selector', value => $_[0] } )
      ->{'element-6066-11e4-a52e-4f735466cecf'};
}

sub click {
    my ($selector) = @_;
    wait_for(
        sub {
            evaluate(
'const e=document.querySelector(arguments[0]); if(!e)return false; const r=e.getBoundingClientRect(),s=getComputedStyle(e); return r.width>2 && r.height>2 && Number(s.opacity)>.99 && s.pointerEvents!=="none";',
                $selector
            );
        }
    );
    my $id = element($selector);
    command( 'POST', "/element/$id/click", {} );
}

sub wait_for {
    my ($check) = @_;
    my $until = time + 30;
    my $error;
    while ( time < $until ) {
        my $value = eval { $check->() };
        return $value if $value;
        $error = $@   if $@;
        sleep 0.1;
    }
    eval {
        screenshot('failure');
        diag( evaluate('return document.body.innerText;') );
        diag( $json->encode( command( 'POST', '/log', { type => 'browser' } ) ) );
    };
    die "Browser condition timed out: " . ( $error || 'condition remained false' ) . "\n";
}

sub screenshot {
    my ($name) = @_;
    my $encoded = command( 'GET', '/screenshot' );
    open my $fh, '>:raw', "artifacts/$name.png" or die $!;
    print {$fh} decode_base64($encoded);
    close $fh;
}

sub ready {
    wait_for( sub { evaluate('return document.querySelector("[data-ready=true]") !== null;') } );
}

sub state {
    return $json->decode( perl_eval('JSON::PP::encode_json($Bufo::Browser::game->state)') );
}

sub seed {
    my ($edits) = @_;
    perl_eval( 'my $s=JSON::PP::decode_json(JSON::PP::encode_json($Bufo::Browser::game->state)); '
          . $edits
          . ' Bufo::Browser::accept_game(Bufo::Game->new(catalog=>$Bufo::Browser::catalog,now=>Bufo::Browser::now(),state=>$s)); 1;'
    );
}
