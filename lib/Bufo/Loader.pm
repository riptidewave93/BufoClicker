package Bufo::Loader;
use strict;
use warnings;
use Bufo::Util::Deferred;

sub new {
    my ( $class, %args ) = @_;
    die 'Loader requires a DataLoader' unless $args{loader};
    return bless {
        paths      => { map { $_ => "assets/data/$_.json" } qw(generators upgrades achievements) },
        initialize => {},
        status     => { generators => 0, upgrades => 0, achievements => 0, isComplete => 0 },
        data       => {},
        %args
    }, $class;
}
sub loadingStatus { return { %{ $_[0]{status} } } }

sub isGameDataLoaded {
    my ($self) = @_;
    return
         $self->{status}{generators}
      && $self->{status}{upgrades}
      && $self->{status}{achievements} ? 1 : 0;
}

sub loadGameData {
    my ( $self, $on_complete ) = @_;
    my $result = Bufo::Util::Deferred->new;
    $result->then($on_complete) if $on_complete;
    my $remaining = 3;
    my $failed    = sub {
        my ($error) = @_;
        return unless $result->state eq 'pending';
        $self->{status}{error} = "$error";
        $self->{logger}->error( 'Failed to load game data:', "$error" ) if $self->{logger};
        $result->resolve( $self->loadingStatus );
    };
    for my $name (qw(generators upgrades achievements)) {
        $self->{loader}->loadJsonData( $self->{paths}{$name} )->then(
            sub {
                my ($data) = @_;
                my $success = eval {
                    $self->{initialize}{$name}->($data) if $self->{initialize}{$name};
                    $self->{data}{$name}   = $data;
                    $self->{status}{$name} = 1;
                    1;
                };
                if ( !$success ) { $failed->($@); return }
                if ( --$remaining == 0 && $result->state eq 'pending' ) {
                    $self->{status}{isComplete} = 1;
                    $result->resolve( $self->loadingStatus );
                }
                return;
            },
            $failed
        );
    }
    return $result;
}

sub verifyGameData {
    my ($self) = @_;
    my $count = $self->{counts} ? $self->{counts}->() : {
        map {
            my $v = $self->{data}{$_};
            ( $_ . 'Loaded' ) =>
              ( ref($v) eq 'ARRAY' ? scalar @$v : ref($v) eq 'HASH' ? scalar keys %$v : 0 )
        } qw(generators upgrades)
    };
    return {
        generatorsLoaded => $count->{generatorsLoaded} // 0,
        upgradesLoaded   => $count->{upgradesLoaded}   // 0,
        isComplete       => $self->{status}{isComplete}
    };
}
1;
