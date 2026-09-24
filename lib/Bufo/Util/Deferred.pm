package Bufo::Util::Deferred;
use strict;
use warnings;
use Scalar::Util qw(blessed refaddr);

# Browser-neutral completion with value/error propagation and chained completions.
sub new   { bless { state => 'pending', handlers => [] }, $_[0] }
sub state { $_[0]{state} }

sub then {
    my ( $self, $ok, $fail ) = @_;
    my $next = __PACKAGE__->new;
    push @{ $self->{handlers} }, [ $ok, $fail, $next ];
    $self->_deliver unless $self->{state} eq 'pending';
    return $next;
}
sub catch { my ( $self, $fail ) = @_; return $self->then( undef, $fail ) }

sub resolve {
    my ( $self, $value ) = @_;
    return $self unless $self->{state} eq 'pending';
    if ( blessed($value) && $value->isa(__PACKAGE__) ) {
        return $self->reject('A completion cannot resolve itself')
          if refaddr($self) == refaddr($value);
        $value->then( sub { $self->resolve( $_[0] ); return },
            sub { $self->reject( $_[0] ); return } );
        return $self;
    }
    $self->{state} = 'fulfilled';
    $self->{value} = $value;
    $self->_deliver;
    return $self;
}

sub reject {
    my ( $self, $value ) = @_;
    return $self unless $self->{state} eq 'pending';
    $self->{state} = 'rejected';
    $self->{value} = $value;
    $self->_deliver;
    return $self;
}

sub _deliver {
    my ($self) = @_;
    while ( my $pair = shift @{ $self->{handlers} } ) {
        my ( $ok, $fail, $next ) = @$pair;
        my $fn = $self->{state} eq 'fulfilled' ? $ok : $fail;
        if ( !$fn ) {
            $self->{state} eq 'fulfilled'
              ? $next->resolve( $self->{value} )
              : $next->reject( $self->{value} );
            next;
        }
        my $value = eval { $fn->( $self->{value} ) };
        $@ ? $next->reject($@) : $next->resolve($value);
    }
    return;
}
1;
