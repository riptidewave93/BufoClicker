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
    timeout      => 60,
    max_redirect => 0,
    proxy        => undef,
    no_proxy     => 'localhost,127.0.0.1,webdriver,site,dev,host.docker.internal'
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

# Development UI contracts taken from the original TypeScript instance inventory.
for my $path ( '/', '/BufoClicker/' ) {
    command( 'POST', '/window/rect', { width => 1440, height => 1000 } );
    command( 'POST', '/url',         { url   => "$base/styles/index.css" } );
    evaluate('localStorage.clear();sessionStorage.clear();');
    command( 'POST', '/url', { url => "$base$path" } );
    ready();
    ok( evaluate('return typeof window.debugTools === "object";'),
        "$path development tools exposed" );
    my $keys = evaluate('return Object.keys(debugTools).sort();');
    is_deeply(
        $keys,
        [
            sort
              qw(boss default events events_debug explorer gameCore gameLoop generator_debug generators golden help inspect logging performance prestige reset resources save state time ui upgrade_debug upgrades)
        ],
        "$path original development namespace"
    );
    is( evaluate('return debugTools.ui.getComponent("absent");'),
        undef, "$path absent component returns null" );

    for my $id (
        qw(resourceDisplay clickArea generatorList shop upgradeList productionStats goldenBufo bossFight)
      )
    {
        ok(
            evaluate(
                'const c=debugTools.ui.getComponent(arguments[0]);return c && typeof c.init==="function" && typeof c.destroy==="function";',
                $id
            ),
            "$path component $id lifecycle"
        );
    }
    my $before = state()->{resources}{clickCount};
    evaluate(
        'window.clickFeedback={art:false,number:false};window.feedbackObserver=new MutationObserver(records=>{for(const record of records)for(const node of record.addedNodes){if(node.nodeType!==1)continue;clickFeedback.art ||= node.matches(".click-emoji-pop") || !!node.querySelector(".click-emoji-pop");clickFeedback.number ||= !!node.querySelector(".floating-number .value") || (node.matches(".floating-number") && !!node.querySelector(".value"));}});feedbackObserver.observe(document.body,{childList:true,subtree:true});'
    );
    click('#frog-display');
    is( state()->{resources}{clickCount}, $before + 1,
        "$path component pointer click counts once" );
    ok( evaluate('return clickFeedback.art;'), "$path random art click feedback" );
    ok( evaluate('feedbackObserver.disconnect();return clickFeedback.number;'),
        "$path original floating-number structure" );
    wait_for(
        sub {
            evaluate(
                'return !document.querySelector(".click-effect-layer .click-emoji-pop,.click-effect-layer .floating-number");'
            );
        }
    );
    evaluate(
        'window.uiEvents=[];window.modalCallback=0;debugTools.events.on("UI_MODAL_OPENED",x=>uiEvents.push(["open",x.modalId]));debugTools.events.on("UI_MODAL_CLOSED",x=>uiEvents.push(["close",x.modalId]));window.modalNode=debugTools.ui.showModal({id:"contract-modal",title:"Contract",content:"<b>Custom body</b>",buttons:[{text:"Apply",callback:()=>modalCallback++}],closeOnBackdrop:false});'
    );
    ok( evaluate('return modalNode instanceof HTMLElement && modalNode.id==="contract-modal";'),
        "$path modal returns actual node" );
    click('#contract-modal .modal-footer button');
    wait_for( sub { evaluate('return !document.getElementById("contract-modal");') } );
    is( evaluate('return modalCallback;'), 1, "$path custom modal callback runs once" );
    is_deeply(
        evaluate('return uiEvents;'),
        [ [ 'open', 'contract-modal' ], [ 'close', 'contract-modal' ] ],
        "$path modal lifecycle events"
    );
    evaluate(
        'window.toastNode=debugTools.ui.showNotification({message:"Dismiss me",duration:10000});');
    ok( evaluate('return toastNode instanceof HTMLElement;'),
        "$path notification returns actual node" );
    click('.notification-close');
    wait_for( sub { evaluate('return !toastNode.isConnected;') } );
    ok( 1, "$path notification close control works" );
    my $dom = $json->decode(
        perl_eval(
            q{my $e=Bufo::Browser::DOM::createElement('div',{content=>'<b>literal</b>'}); Bufo::Browser::DOM::setVisible($e,0); JSON::PP::encode_json({html=>$e->{innerHTML},display=>$e->{style}->{display},invalid=>scalar @{Bufo::Browser::DOM::querySelectorAll('[')}})}
        )
    );
    is_deeply(
        $dom,
        { html => '&lt;b&gt;literal&lt;/b&gt;', display => 'none', invalid => 0 },
        "$path DOM text-content and safe-selector contracts"
    );
    perl_eval(
        q{our $contract_component=Bufo::Browser::Component->new({id=>'component-contract'}); WebPerl::js('document')->{body}->appendChild($contract_component->getElement); $contract_component->setContent('<b>A</b>'); $contract_component->setContent('<i>B</i>',{append=>1}); our $contract_hits=0; our $contract_callback=sub{$contract_hits++;return;};$contract_component->addEventListener('click',$contract_callback);$contract_component->addEventListener('click',$contract_callback);$contract_component->subscribeToEvent('CONTRACT_EVENT',$contract_callback);1;}
    );
    is( evaluate('return document.getElementById("component-contract").innerHTML;'),
        '<b>A</b><i>B</i>', "$path component HTML replace/append" );
    evaluate(
        'document.getElementById("component-contract").click();debugTools.events.emit("CONTRACT_EVENT",{});'
    );
    is( perl_eval('$main::contract_hits'), 2, "$path handler identity and event subscription" );
    perl_eval('$main::contract_component->destroy;1;');
    evaluate(
        'document.getElementById("component-contract").click();debugTools.events.emit("CONTRACT_EVENT",{});'
    );
    is( perl_eval('$main::contract_hits'), 2, "$path destroy releases DOM/event callbacks" );
    perl_eval(
        q{our $contract_container=Bufo::Browser::Container->new({id=>'container-contract'});our $child=Bufo::Browser::Component->new({id=>'child-contract'});$contract_container->addChild($child,{tag=>'metadata'});1;}
    );
    is( perl_eval('scalar @{$main::contract_container->getChildren}'),
        1, "$path container owns child" );
    is( perl_eval('$main::contract_container->removeChild("child-contract")'),
        1, "$path child removed by ID" );
    is( perl_eval('$main::contract_container->removeChild("child-contract")'),
        0, "$path missing child removal false" );
    my $ease = $json->decode(
        perl_eval(
            'JSON::PP::encode_json([map{$Bufo::Browser::Animation::Easing{$_}->(.25)}qw(linear easeIn easeOut easeInOut)])'
        )
    );
    is_deeply( $ease, [ .25, .0625, .4375, .125 ], "$path original easing samples" );
    evaluate(
        'window.animationNode=document.createElement("div");animationNode.id="animation-contract";animationNode.style.opacity="1";document.body.append(animationNode);'
    );
    perl_eval(
        q{Bufo::Browser::Animation::fadeOut(WebPerl::js('document')->getElementById('animation-contract'),100,1);1;}
    );
    wait_for( sub { evaluate('return animationNode.style.display==="none";') } );
    ok(
        evaluate('return animationNode.isConnected;'),
        "$path fadeOut hides but does not remove element"
    );
    is_deeply(
        $json->decode(
            perl_eval(
                q{our $timer_probe={value=>1};our $timer_weak=$timer_probe;Scalar::Util::weaken($timer_weak);my $id;{my $held=$timer_probe;$id=Bufo::Browser::DOM::later(60000,sub{my $value=$held->{value};return;});}undef $timer_probe;my $before=defined($timer_weak)?1:0;Bufo::Browser::DOM::cancel($id);JSON::PP::encode_json([$before,defined($timer_weak)?1:0])}
            )
        ),
        [ 1, 0 ],
        "$path cancelled timer releases captured objects"
    );
    evaluate('debugTools.resources.set(20000);');
    click('#buy-tadpole');
    wait_for( sub { evaluate('return !!document.getElementById("generator-tadpole");') } );
    click('#shop-item-tadpole .generator-left');
    wait_for( sub { evaluate('return !!document.querySelector("#game-tooltip.visible");') } );
    like(
        evaluate('return document.getElementById("game-tooltip").innerText;'),
        qr/You can afford/,
        "$path shop detailed affordability tooltip"
    );
    perl_eval('Bufo::Browser::Tooltip::hideTooltip();1;');
    evaluate('debugTools.time.pause();debugTools.golden.spawn();');
    wait_for( sub { evaluate('return !!document.getElementById("golden-bufo");') } );
    click('#golden-bufo');
    wait_for( sub { evaluate('return !!document.querySelector(".golden-bufo-toast");') } );
    ok( evaluate('return !!document.querySelector(".golden-bufo-toast__detail");'),
        "$path dedicated golden reward toast" );
    evaluate('debugTools.time.resume();');
    my $export = evaluate('return debugTools.save.export();');
    ok( evaluate( 'return debugTools.save.import(arguments[0]);', $export ),
        "$path development save import" );
    evaluate('debugTools.resources.add(1000);debugTools.save.save();');
    my $bank = state()->{resources}{bufos};
    command( 'POST', '/refresh', {} );
    ready();
    cmp_ok( state()->{resources}{bufos}, '>=', $bank, "$path replacement Game remains durable" );

    open my $legacy_file, '<', 't/fixtures/legacy-captured.json' or die $!;
    my $legacy_bytes = do { local $/; <$legacy_file> };
    close $legacy_file;
    evaluate(
        'localStorage.setItem("bufo_idle_save",arguments[0]);window.retainedExplorer=debugTools.explorer;window.combatEvents=0;debugTools.events.on("COMBAT_ACTION",()=>{combatEvents++;debugTools.ui.showNotification({message:"Combat action observed",duration:10000});});',
        $legacy_bytes
    );
    my $replacement = evaluate('return debugTools.save.export();');
    ok( evaluate( 'return debugTools.save.import(arguments[0]);', $replacement ),
        "$path second import installs replacement engine" );
    evaluate('debugTools.time.pause();retainedExplorer.reset();');
    ok(
        evaluate('return retainedExplorer.startExploration("Pond");'),
        "$path retained manager resolves replacement Game"
    );
    is( state()->{explorer}{state},
        'exploring', "$path replacement state receives exploration start" );
    perl_eval(
        '$Bufo::Browser::game->getExplorerManager->{random}=sub{0};$Bufo::Browser::api->processTick(.1);$Bufo::Browser::game->getExplorerManager->{random}=sub{.5};1;'
    );
    ok(
        evaluate('return retainedExplorer.getCurrentCombat()!==null;'),
        "$path deterministic encounter through real tick"
    );
    ok( evaluate('return retainedExplorer.performCombatAction("attack");'),
        "$path combat action uses replacement manager" );
    is( evaluate('return combatEvents;'), 1, "$path one shared-bus combat event after import" );
    is(
        evaluate(
            'return [...document.querySelectorAll(".notification-message")].filter(e=>e.textContent==="Combat action observed").length;'
        ),
        1,
        "$path one UI notification from post-import event"
    );
    my $explorer_snapshot = state()->{explorer};
    evaluate('window.realNow=Date.now;Date.now=()=>realNow()+61000;');
    perl_eval('Bufo::Browser::on_tick();1;');
    evaluate('Date.now=realNow;');
    my $saved_explorer =
      evaluate('return JSON.parse(localStorage.getItem("bufo_idle_save_perl_v1")).state.explorer;');
    is_deeply( $saved_explorer, $explorer_snapshot,
        "$path periodic autosave writes replacement Explorer" );
    command( 'POST', '/refresh', {} );
    ready();
    evaluate('debugTools.time.pause();');
    my $reloaded_explorer = state()->{explorer};
    is_deeply(
        [ @{$reloaded_explorer}{qw(health experience explorationProgress)} ],
        [ @{$explorer_snapshot}{qw(health experience explorationProgress)} ],
        "$path Explorer health XP progress survive reload"
    );
    is( evaluate('return localStorage.getItem("bufo_idle_save");'),
        $legacy_bytes, "$path import combat autosave leaves legacy bytes intact" );
    diag( evaluate('return sessionStorage.getItem("contractErrors") || "[]";') );
    my $logs   = command( 'POST', '/log', { type => 'browser' } );
    my @severe = grep { $_->{level} eq 'SEVERE' } @$logs;
    diag( $json->encode( \@severe ) ) if @severe;
    is_deeply( \@severe, [], "$path no browser errors" );
}
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
                'const e=document.querySelector(arguments[0]); if(!e)return false; const r=e.getBoundingClientRect(),s=getComputedStyle(e); return r.width>2 && r.height>2 && Number(s.opacity)>0 && s.visibility!=="hidden" && s.pointerEvents!=="none";',
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
    evaluate(
        'window.addEventListener("error",event=>{const errors=JSON.parse(sessionStorage.getItem("contractErrors")||"[]");errors.push({message:event.message,error:String(event.error),stack:event.error?.stack});sessionStorage.setItem("contractErrors",JSON.stringify(errors));});'
    );
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
