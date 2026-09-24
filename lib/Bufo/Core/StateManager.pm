package Bufo::Core::StateManager;
use strict;
use warnings;
use Scalar::Util        qw(refaddr);
use Bufo::Util::General ();
use Bufo::Util::State   ();
our $INSTANCE;

sub new {
    my ( $class, %args ) = @_;
    die 'State get/set providers must be supplied together' if !!$args{get} != !!$args{set};
    my $utils = Bufo::Util::State->new;
    my $self  = bless {
        defaults    => $args{defaults} // sub { $utils->createDefaultState },
        derive      => $args{derive}   // \&Bufo::Util::State::calculateDerivedState,
        validate    => $args{validate} // \&Bufo::Util::State::validateState,
        on_error    => $args{on_error} // sub { warn "$_[0]: $_[1]" },
        subscribers => [],
        batch       => 0,
        pending     => 0,
        %args
    }, $class;
    $self->{state}    = Bufo::Util::General::deepClone( $self->{defaults}->() ) unless $self->{get};
    $self->{observed} = $self->getState;
    return $self;
}

sub setInstance {
    my ( $class, $instance ) = @_;
    die 'Invalid StateManager instance' unless ref($instance) && $instance->isa(__PACKAGE__);
    $INSTANCE = $instance;
    return $instance;
}
sub getInstance     { my ( $class, %args ) = @_; $INSTANCE //= $class->new(%args) }
sub getStateManager { __PACKAGE__->getInstance }
sub _current        { $_[0]{get} ? $_[0]{get}->() : $_[0]{state} }

sub _set {
    my ( $self, $state ) = @_;
    $self->{set} ? $self->{set}->($state) : ( $self->{state} = $state );
    return;
}
sub getState { Bufo::Util::General::deepClone( $_[0]->_current ) }

sub setState {
    my ( $self, $patch ) = @_;
    my $old  = $self->getState;
    my $next = Bufo::Util::State::updateState( $old, $patch );
    $next = $self->{derive}->($next);
    die 'Invalid state update' unless $self->{validate}->($next);
    $self->_set($next);
    if   ( $self->{batch} ) { $self->{pending}++ }
    else                    { $self->notifySubscribers($old) }
    return;
}
sub startBatch { $_[0]{batch} = 1; $_[0]{pending} = 0; return }

sub endBatch {
    my ($self) = @_;
    return unless $self->{batch};
    $self->{batch} = 0;
    if ( $self->{pending} ) { $self->notifySubscribers( $self->getState ); $self->{pending} = 0 }
    return;
}

sub subscribe {
    my ( $self, $callback ) = @_;
    die 'Subscriber must be callable' unless ref($callback) eq 'CODE';
    push @{ $self->{subscribers} }, $callback;
    return sub { $self->unsubscribe($callback) }
}

sub unsubscribe {
    my ( $self, $callback ) = @_;
    for my $i ( 0 .. $#{ $self->{subscribers} } ) {
        if ( refaddr( $self->{subscribers}[$i] ) == refaddr($callback) ) {
            splice @{ $self->{subscribers} }, $i, 1;
            last;
        }
    }
    return;
}

sub resetState {
    my ($self) = @_;
    my $old = $self->getState;
    $self->_set( Bufo::Util::General::deepClone( $self->{defaults}->() ) );
    $self->notifySubscribers($old);
    return;
}

sub loadState {
    my ( $self, $state ) = @_;
    return 0 unless $self->{validate}->($state);
    my $old = $self->getState;
    $self->_set($state);
    $self->notifySubscribers($old);
    return 1;
}

sub notifyStateChange {
    my ( $self, $old ) = @_;
    if   ( $self->{batch} ) { $self->{pending}++ }
    else                    { $self->notifySubscribers($old) }
    return;
}

sub notifySubscribers {
    my ( $self, $old ) = @_;
    $old = $self->{observed} unless defined $old;
    my $current = $self->getState;
    $self->{observed} = Bufo::Util::General::deepClone($current);
    for my $callback ( @{ $self->{subscribers} } ) {
        eval { $callback->( $current, $old ); 1 }
          or $self->{on_error}->( 'Error in state change subscriber', $@ );
    }
    return;
}
1;
