package Bufo::Browser::Container;
use strict;
use warnings;
use parent 'Bufo::Browser::Component';
sub new { my ( $class, $o ) = @_; my $s = $class->SUPER::new($o); $s->{children} = []; return $s; }

sub addChild {
    my ( $s, $c, $data ) = @_;
    push @{ $s->{children} }, { component => $c, data => $data };
    $s->{element}->appendChild( $c->getElement );
    $c->init;
    return $c;
}

sub removeChild {
    my ( $s, $key ) = @_;
    for my $i ( 0 .. $#{ $s->{children} } ) {
        my $c = $s->{children}[$i]{component};
        if ( ref($key) ? $c == $key : ( $c->getId || '' ) eq $key ) {
            Bufo::Browser::DOM::removeElement( $c->getElement );
            $c->destroy;
            splice @{ $s->{children} }, $i, 1;
            return 1;
        }
    }
    return 0;
}
sub getChildren { return [ @{ $_[0]{children} } ]; }

sub getChildById {
    my ( $s, $id ) = @_;
    for ( @{ $s->{children} } ) {
        return $_->{component} if ( $_->{component}->getId || '' ) eq $id;
    }
    return;
}

sub clearChildren {
    my ($s) = @_;
    $s->removeChild( $_->{component} ) for @{ $s->getChildren };
    return;
}

sub renderChildren {
    my ($s) = @_;
    $s->{element}->{innerHTML} = '';
    $s->{element}->appendChild( $_->{component}->getElement ) for @{ $s->{children} };
    return;
}
sub destroy { my ($s) = @_; $s->clearChildren; $s->SUPER::destroy; return; }
1;
