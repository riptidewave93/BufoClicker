package Bufo::Core::EventBus;
use strict;
use warnings;
use Scalar::Util qw(refaddr);
use Bufo::Core::Logger;
our $INSTANCE;

sub new {
    my ( $class, %args ) = @_;
    bless {
        events   => {},
        order    => [],
        debug    => 0,
        excluded => {},
        logger   => $args{logger} // Bufo::Core::Logger->new
    }, $class;
}

sub setInstance {
    my ( $class, $instance ) = @_;
    die 'Invalid EventBus instance' unless ref($instance) && $instance->isa(__PACKAGE__);
    $INSTANCE = $instance;
    return $instance;
}
sub getInstance  { my ( $class, %args ) = @_; $INSTANCE //= $class->new(%args) }
sub getEventBus  { __PACKAGE__->getInstance }
sub setDebugMode { $_[0]{debug} = $_[1] ? 1 : 0; return }

sub setExcludedEvents {
    $_[0]{excluded} = { map { $_ => 1 } @{ $_[1] } };
    return;
}
sub addExcludedEvent    { $_[0]{excluded}{ $_[1] } = 1;    return }
sub removeExcludedEvent { delete $_[0]{excluded}{ $_[1] }; return }

sub on {
    my ( $self, $name, $callback ) = @_;
    die 'Event callback must be callable' unless ref($callback) eq 'CODE';
    if ( !exists $self->{events}{$name} ) {
        $self->{events}{$name} = [];
        push @{ $self->{order} }, $name;
    }
    my $callbacks = $self->{events}{$name};
    return if grep { refaddr( $_->{callback} ) == refaddr($callback) } @$callbacks;
    push @$callbacks, { callback => $callback };
    $self->{logger}
      ->debug( "EventBus: Subscribed to '$name'", { listenersCount => scalar @$callbacks } )
      if $self->{debug};
    return;
}

sub once {
    my ( $self, $name, $callback ) = @_;
    $self->on( $name, $callback );
    for ( @{ $self->{events}{$name} } ) {
        $_->{once} = 1 if refaddr( $_->{callback} ) == refaddr($callback);
    }
    return;
}

sub off {
    my ( $self, $name, $callback ) = @_;
    return unless exists $self->{events}{$name};
    my $list = $self->{events}{$name};
    for my $i ( 0 .. $#$list ) {
        next unless refaddr( $list->[$i]{callback} ) == refaddr($callback);
        splice @$list, $i, 1;
        $self->{logger}
          ->debug( "EventBus: Unsubscribed from '$name'", { listenersCount => scalar @$list } )
          if $self->{debug};
        last;
    }
    if ( !@$list ) {
        delete $self->{events}{$name};
        @{ $self->{order} } = grep { $_ ne $name } @{ $self->{order} };
    }
    return;
}

sub emit {
    my ( $self, $name, $payload ) = @_;
    my $debug = $self->{debug} && !$self->{excluded}{$name};
    my $list  = $self->{events}{$name};
    if ( !$list ) {
        $self->{logger}->debug("EventBus: Emitted '$name' (no listeners)") if $debug;
        return;
    }
    if ($debug) {
        $self->{logger}->debug( "EventBus: Emitting '$name'",
            { listenersCount => scalar @$list, payload => $payload } );
        $self->{logger}->group("EventBus: '$name' callbacks");
    }
    my $i = 0;
    while ( $i < @$list ) {
        my $entry = $list->[$i];
        if ( $entry->{once} ) { $self->off( $name, $entry->{callback} ) }
        else                  { $i++ }
        eval { $entry->{callback}->($payload); 1 }
          or $self->{logger}->error( "Error in '$name' event handler:", $@ );
    }
    $self->{logger}->groupEnd if $debug;
    return;
}
sub hasListeners     { $_[0]->getListenerCount( $_[1] ) > 0 ? 1 : 0 }
sub getListenerCount { scalar @{ $_[0]{events}{ $_[1] } // [] } }
sub getEventNames    { [ @{ $_[0]{order} } ] }

sub clearEvent {
    my ( $self, $name ) = @_;
    return unless exists $self->{events}{$name};
    $self->{logger}->debug(
        "EventBus: Cleared all listeners for '$name'",
        { removedCount => $self->getListenerCount($name) }
    ) if $self->{debug};
    delete $self->{events}{$name};
    @{ $self->{order} } = grep { $_ ne $name } @{ $self->{order} };
    return;
}

sub clearAllEvents {
    my ($self) = @_;
    $self->{logger}->debug('EventBus: Cleared all events and listeners') if $self->{debug};
    $self->{events} = {};
    $self->{order}  = [];
    return;
}
1;
