package Bufo::Browser::Component;
use strict;
use warnings;
use Scalar::Util qw/refaddr/;
use JSON::PP;
use Bufo::Browser::DOM;

sub new {
    my ( $class, $o ) = @_;
    $o ||= {};
    my $el = $o->{element};
    $el = Bufo::Browser::DOM::document()->getElementById( $o->{id} )
      if !defined($el) && defined( $o->{id} );
    $el = Bufo::Browser::DOM::createElement( $o->{tagName} || 'div', { id => $o->{id} } )
      unless defined $el;
    $el->{className} = $o->{className} if defined( $o->{className} ) && !defined( $o->{element} );
    $el->{innerHTML} = $o->{template}  if defined $o->{template};
    return bless {
        element       => $el,
        options       => $o,
        initialized   => 0,
        handlers      => {},
        unsubscribers => []
    }, $class;
}

sub init {
    my ($s) = @_;
    return if $s->{initialized};
    my $ok = eval { $s->setup; $s->{initialized} = 1; 1 };
    warn $@ unless $ok;
    return;
}
sub setup      { return; }
sub render     { return ''; }
sub update     { return; }
sub getElement { return $_[0]{element}; }
sub getId      { my $el = $_[0]{element}; return defined($el) ? ( $el->{id} || undef ) : undef; }

sub setContent {
    my ( $s, $content, $o ) = @_;
    $o = { replace => 1 } unless defined $o;
    return unless $o->{replace} || $o->{append};
    my $el = $s->{element};
    return unless defined $el;
    $el->{innerHTML} = '' if $o->{replace};
    if ( !ref $content ) {
        $el->insertAdjacentHTML( 'beforeend', defined($content) ? $content : '' );
    } else {
        $el->appendChild($content);
    }
    return;
}

sub createElement {
    my ( $s, $tag, $o ) = @_;
    $o ||= {};
    return Bufo::Browser::DOM::createElement( $tag,
        { id => $o->{id}, classes => $o->{className} } );
}

sub addClass {
    my ( $s, $c ) = @_;
    Bufo::Browser::DOM::addClass( $s->{element}, $_ ) for split /\s+/, $c;
    return;
}

sub removeClass {
    my ( $s, $c ) = @_;
    Bufo::Browser::DOM::removeClass( $s->{element}, $_ ) for split /\s+/, $c;
    return;
}

sub toggleClass {
    my ( $s, $c, $force ) = @_;
    Bufo::Browser::DOM::toggleClass( $s->{element}, $c, $force );
    return;
}

sub addEventListener {
    my ( $s, $name, $cb ) = @_;
    my $id = refaddr($cb);
    return if exists $s->{handlers}{$name}{$id};
    $s->{handlers}{$name}{$id} = $cb;
    Bufo::Browser::DOM::listen( $s->{element}, $name, $cb );
    return;
}

sub removeEventListener {
    my ( $s, $name, $cb ) = @_;
    my $id = refaddr($cb);
    return unless delete $s->{handlers}{$name}{$id};
    Bufo::Browser::DOM::unlisten( $s->{element}, $name, $cb );
    return;
}

sub connectToState {
    my ( $s, $select, $change ) = @_;
    my $state = $s->{options}{state} || $Bufo::Browser::state;
    $change->( $select->( $state->getState ) );
    my $watch = sub {
        my ( $new, $old ) = @_;
        my $a = $select->($new);
        my $b = $select->($old);
        my $j = JSON::PP->new->canonical->allow_nonref;
        $change->($a) if $j->encode($a) ne $j->encode($b);
        return;
    };
    push @{ $s->{unsubscribers} }, $state->subscribe($watch);
    return;
}

sub subscribeToEvent {
    my ( $s, $name, $cb ) = @_;
    my $bus = $s->{options}{events} || $Bufo::Browser::events;
    $bus->on( $name, $cb );
    push @{ $s->{unsubscribers} }, sub { $bus->off( $name, $cb ); return; };
    return;
}

sub destroy {
    my ($s) = @_;
    for my $name ( keys %{ $s->{handlers} } ) {
        for my $cb ( values %{ $s->{handlers}{$name} } ) {
            Bufo::Browser::DOM::unlisten( $s->{element}, $name, $cb );
        }
    }
    $_->() for @{ $s->{unsubscribers} };
    $s->{unsubscribers}        = [];
    $s->{handlers}             = {};
    $s->{element}->{innerHTML} = '';
    $s->{initialized}          = 0;
    return;
}
1;
