package Bufo::Browser::StyleLoader;
use strict;
use warnings;
use WebPerl qw/js js_new/;
use Bufo::Browser::DOM;

sub loadStylesheet {
    my ($path) = @_;
    my $executor = sub {
        my ( $resolve, $reject ) = @_;
        my $link = Bufo::Browser::DOM::createElement( 'link',
            { attributes => { rel => 'stylesheet', href => $path } } );
        my ( $loaded, $failed );
        my $cleanup = sub {
            Bufo::Browser::DOM::unlisten( $link, 'load',  $loaded );
            Bufo::Browser::DOM::unlisten( $link, 'error', $failed );

            return;
        };
        $loaded = sub { $resolve->($link);                                  $cleanup->(); return; };
        $failed = sub { $reject->( 'Failed to load stylesheet: ' . $path ); $cleanup->(); return; };
        Bufo::Browser::DOM::listen( $link, 'load',  $loaded );
        Bufo::Browser::DOM::listen( $link, 'error', $failed );
        Bufo::Browser::DOM::document()->{head}->appendChild($link);
        return;
    };
    my $promise = js_new( 'Promise', $executor );
    WebPerl::unregister($executor);
    return $promise;
}

sub addStyles {
    my ( $styles, $id ) = @_;
    return Bufo::Browser::DOM::createElement( 'style',
        { id => $id, content => $styles, parent => Bufo::Browser::DOM::document()->{head} } );
}

sub initializeStyles {
    my $executor = sub {
        my ($resolve) = @_;
        my ( $success, $failure );
        my $cleanup = sub { WebPerl::unregister($success); WebPerl::unregister($failure); return; };
        $success = sub {
            js('console')->log('Styles loaded successfully');
            $resolve->();
            $cleanup->();
            return;
        };
        $failure = sub {
            js('console')->error( 'Error loading styles:', $_[0] );
            addStyles(
                '.three-column-layout{display:flex;gap:16px;width:100%}.column{flex:1;display:flex;flex-direction:column;gap:16px}.game-tooltip{position:absolute;z-index:100;background:#182b20;color:#fff;padding:16px;max-width:300px;pointer-events:none}@media(max-width:1024px){.three-column-layout{flex-direction:column}}',
                'critical-fallback-styles'
            );
            $resolve->();
            $cleanup->();
            return;
        };
        loadStylesheet('./styles/index.css')->then( $success, $failure );
        return;
    };
    my $promise = js_new( 'Promise', $executor );
    WebPerl::unregister($executor);
    return $promise;
}

sub cleanupStyles {
    $_->remove for @{ Bufo::Browser::DOM::querySelectorAll('style[id^="dynamic-"]') };
    return;
}
1;
