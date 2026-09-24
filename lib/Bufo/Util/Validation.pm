package Bufo::Util::Validation;
use strict;
use warnings;
use JSON::PP     ();
use Scalar::Util qw(blessed);
my $json = JSON::PP->new->allow_nonref;

sub isValidNumber {
    my ($v) = @_;
    return 0 if !defined($v) || ref($v);
    my $text = eval { $json->encode($v) };
    return
         defined($text)
      && $text =~ /\A-?(?:0|[1-9][0-9]*)(?:\.[0-9]+)?(?:[eE][+-]?[0-9]+)?\z/
      && "$v"  !~ /inf|nan/i ? 1 : 0;
}
sub isValidInteger      { isValidNumber( $_[0] ) && sprintf( '%.0f', $_[0] ) == $_[0] ? 1 : 0 }
sub isPositiveNumber    { isValidNumber( $_[0] ) && $_[0] > 0                         ? 1 : 0 }
sub isNonNegativeNumber { isValidNumber( $_[0] ) && $_[0] >= 0                        ? 1 : 0 }
sub isInRange           { isValidNumber( $_[0] ) && $_[0] >= $_[1] && $_[0] <= $_[2] ? 1 : 0 }

sub isNonEmptyString {
    defined( $_[0] ) && !ref( $_[0] ) && $json->encode( $_[0] ) =~ /^"/ && $_[0] =~ /\S/ ? 1 : 0;
}
sub isValidArray    { ref( $_[0] ) eq 'ARRAY'             ? 1 : 0 }
sub isNonEmptyArray { isValidArray( $_[0] ) && @{ $_[0] } ? 1 : 0 }

sub isValidDate {
    my ($v) = @_;
    return 0 unless blessed($v) && $v->can('getTime');
    return isValidNumber( eval { $v->getTime } );
}

sub isValidObject {
    return 0 if JSON::PP::is_bool( $_[0] );
    return ref( $_[0] ) eq 'HASH' || blessed( $_[0] ) ? 1 : 0;
}

sub hasRequiredProperties {
    my ( $v, $keys ) = @_;
    return 0 unless ref($v) eq 'HASH';
    for (@$keys) {
        return 0
          unless exists( $v->{$_} )
          && !( blessed( $v->{$_} ) && $v->{$_}->isa('Bufo::Util::Undefined') );
    }
    return 1;
}

sub validateObject {
    my ( $obj, $schema ) = @_;
    return { isValid => JSON::PP::false, invalidProps => ['[not an object]'] }
      unless ref($obj) eq 'HASH';
    my @invalid =
      grep { !exists( $obj->{$_} ) || !$schema->{$_}->( $obj->{$_} ) } sort keys %$schema;
    return { isValid => @invalid ? JSON::PP::false : JSON::PP::true, invalidProps => \@invalid };
}

sub isValidEmail {
    isNonEmptyString( $_[0] ) && $_[0] =~ /\A[^\s\@]+\@[^\s\@]+\.[^\s\@]+\z/ ? 1 : 0;
}

sub isValidUrl {
    my ( $v, $parser ) = @_;
    return 0 unless isNonEmptyString($v);
    return eval { $parser->($v); 1 } ? 1 : 0 if $parser;
    return 0 unless $v =~ /\A([A-Za-z][A-Za-z0-9+.-]*):(.*)\z/s;
    my ( $scheme, $rest ) = ( lc($1), $2 );
    return $rest =~ m{\A//[^\s/?\#]+(?:[/?\#]|\z)} ? 1 : 0 if $scheme =~ /\A(?:https?|ftp|wss?)\z/;
    return 1;
}

sub createValidationResult {
    return {
        isValid => $_[0] ? JSON::PP::true : JSON::PP::false,
        errors  => $_[0] ? []             : ( $_[1] // [] )
    };
}

sub isOneOf {
    my ( $v, $values ) = @_;
    for my $other (@$values) {
        return 1 if !defined($v) && !defined($other);
        next unless defined($v)  && defined($other);
        return 1 if ref($v)  && ref($other)  && $v == $other;
        return 1 if !ref($v) && !ref($other) && $json->encode($v) eq $json->encode($other);
    }
    return 0;
}

sub validateSaveData {
    my ($save) = @_;
    return createValidationResult( 0, ['Save data must be an object'] ) unless ref($save) eq 'HASH';
    my @errors;
    push @errors, 'Save data missing required properties'
      unless hasRequiredProperties( $save, [qw(state version)] );
    push @errors, 'Invalid state property' if $save->{state} && !isValidObject( $save->{state} );
    push @errors, 'Invalid version property'
      if $save->{version} && !isNonEmptyString( $save->{version} );
    if ( ref( $save->{state} ) eq 'HASH' ) {
        for my $key (qw(resources gameSettings)) {
            push @errors, "Invalid $key property"
              if $save->{state}{$key} && !isValidObject( $save->{state}{$key} );
        }
    }
    return createValidationResult( !@errors, \@errors );
}

package Bufo::Util::Undefined;
use strict;
use warnings;
my $undefined = bless {}, __PACKAGE__;
sub value { $undefined }
1;
