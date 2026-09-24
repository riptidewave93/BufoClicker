package Bufo::Browser::Initialization;
use strict;
use warnings;
use WebPerl qw/js_new/;
use Bufo::Browser::DOM;

sub createLoadingUI {
    my ($id) = @_;
    $id ||= 'game-container';
    my $container = Bufo::Browser::DOM::document()->getElementById($id);
    return { update => sub { return; }, remove => sub { return; } } unless defined $container;
    my $el = Bufo::Browser::DOM::createElement( 'div',
        { classes => 'game-loading', parent => $container } );
    $el->{style}->{cssText} =
      'position:absolute;inset:0;display:flex;flex-direction:column;align-items:center;justify-content:center;background:rgba(0,0,0,.7);color:#fff;z-index:1000';
    $el->{innerHTML} =
      '<h2>Loading Bufo Idle...</h2><div class="loading-progress-track" style="width:min(300px,90vw);height:20px;background:#333;overflow:hidden"><div class="loading-progress" style="width:0%;height:100%;background:#4caf50;transition:width .3s ease-out"></div></div><div class="loading-step" role="status"></div>';
    my $bar    = Bufo::Browser::DOM::querySelector( '.loading-progress', $el );
    my $status = Bufo::Browser::DOM::querySelector( '.loading-step',     $el );
    return {
        update => sub {
            my ($value) = @_;
            $bar->{style}->{width} = ( $value->{progress} || 0 ) . '%';
            $status->{textContent} = $value->{step} || '';
            if ( $value->{error} ) {
                my $error = ref( $value->{error} ) ? $value->{error}{message} : $value->{error};
                $status->{textContent} = 'Error: ' . $error;
                $status->{style}->{color} = '#ff5252';
            }
            return;
        },
        remove => sub {
            $el->{style}->{transition} = 'opacity .5s ease-out';
            $el->{style}->{opacity}    = 0;
            Bufo::Browser::DOM::later( 500, sub { $el->remove; return; } );
            return;
        }
    };
}

sub initializeGame {
    my ( $id, $status ) = @_;
    $id ||= 'game-container';
    my $executor = sub {
        my ($resolve) = @_;
        my $report = sub { $status->( { step => $_[0], progress => $_[1] } ) if $status; return; };
        $report->( 'Initializing core systems', 10 );
        $report->( 'Loading game data',         20 );
        $Bufo::Browser::loader->loadGameData(
            sub {
                my ($loaded) = @_;
                if ( !$loaded->{isComplete} ) {
                    my $error = $loaded->{error} || 'Catalog data could not load';
                    $status->(
                        {
                            step     => 'Initialization failed',
                            progress => 0,
                            error    => { message => $error }
                        }
                    ) if $status;
                    Bufo::Browser::fatal($error);
                    $resolve->(0);
                    return;
                }
                my $success = Bufo::Browser::start( $id, $report );
                $status->(
                    {
                        step     => 'Initialization failed',
                        progress => 0,
                        error    => { message => 'Game initialization failed' }
                    }
                ) if !$success && $status;
                $resolve->( $success ? 1 : 0 );
                return;
            }
        );
        return;
    };
    my $promise = js_new( 'Promise', $executor );
    WebPerl::unregister($executor);
    return $promise;
}
1;
