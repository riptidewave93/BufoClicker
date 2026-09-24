package Bufo::Util::SaveManager;
use strict;
use warnings;
use JSON::PP ();

sub new {
    my ( $class, %args ) = @_;
    for (qw(key storage serialize parse)) { die "SaveManager requires $_\n" unless $args{$_} }
    bless \%args, $class;
}
our $INSTANCE;

sub getInstance {
    my ( $class, %args ) = @_;
    return $INSTANCE if $INSTANCE;
    die 'Configure SaveManager before requesting its singleton' unless %args;
    return $INSTANCE = $class->new(%args);
}
sub getSaveManager { return __PACKAGE__->getInstance(@_) }

sub setInstance {
    my ( $class, $instance ) = @_;
    die 'Invalid SaveManager instance' unless ref($instance) && $instance->isa(__PACKAGE__);
    $INSTANCE = $instance;
    return $instance;
}

sub legacy {
    my ( $class, %args ) = @_;
    my $now = $args{now} // sub { time() * 1000 };
    return $class->new(
        %args,
        legacy_envelope => 1,
        key             => $args{key} // 'bufo_idle_save',
        serialize       => sub {
            my ( $state, $generators, $upgrades, $explorer ) = @_;
            JSON::PP->new->encode(
                {
                    state      => $state,
                    generators => $generators,
                    upgrades   => $upgrades,
                    explorer   => $explorer,
                    timestamp  => $now->(),
                    version    => $state->{gameSettings}{version} // '1.0.0'
                }
            );
        },
        parse => sub {
            my $save = JSON::PP->new->decode( $_[0] );
            die 'Invalid save data' unless ref($save) eq 'HASH' && $save->{state};
            return $save->{state};
        }
    );
}

sub _error {
    my ( $self, $message, $error ) = @_;
    $self->{logger}->error( $message, $error ) if $self->{logger};
    return;
}

sub saveGame {
    my ( $self, @parts ) = @_;
    my $ok = eval {
        my $raw = $self->{serialize}->(@parts);
        $self->{storage}->set_raw( $self->{key}, $raw );
        1;
    };
    $self->_error( 'Failed to save game:', $@ ) unless $ok;
    return $ok ? 1 : 0;
}

sub loadGame {
    my ($self) = @_;
    my $value = eval {
        my $raw = $self->{storage}->get_raw( $self->{key} );
        return undef unless defined $raw;
        my $state    = $self->{parse}->($raw);
        my $envelope = $self->{legacy_envelope} ? JSON::PP->new->decode($raw) : {};
        return {
            state    => $state,
            upgrades => $self->{legacy_envelope} ? ( $envelope->{upgrades} // [] )
            : ( $state->{upgrades}{purchased} // [] ),
            explorer => $self->{legacy_envelope} ? ( $envelope->{explorer} // {} )
            : ( $state->{explorer} // {} )
        };
    };
    $self->_error( 'Error loading saved game:', $@ ) if $@;
    return $value;
}

sub clearSave {
    my ($self) = @_;
    my $ok = eval { $self->{storage}->remove_raw( $self->{key} ); 1 };
    $self->_error( 'Failed to clear save:', $@ ) unless $ok;
    return $ok ? 1 : 0;
}

sub exportSave {
    my ($self) = @_;
    my $result = eval {
        my $raw = $self->{storage}->get_raw( $self->{key} );
        return '' unless defined $raw;
        JSON::PP->new->decode($raw);
        $self->{storage}->_encode_text($raw);
    };
    $self->_error( 'Error exporting save:', $@ ) if $@;
    return $result // '';
}

sub importSave {
    my ( $self, $text ) = @_;
    return 0 unless defined($text) && length($text);
    my $ok = eval {
        my $raw     = $self->{storage}->_decode_text($text);
        my $state   = $self->{parse}->($raw);
        my $checked = $self->{legacy_envelope} ? $raw : $self->{serialize}->($state);
        $self->{storage}->set_raw( $self->{key}, $checked );
        1;
    };
    $self->_error( 'Error importing save:', $@ ) unless $ok;
    return $ok ? 1 : 0;
}
1;
