package Bufo::Catalog;
use strict;
use warnings;
use JSON::PP     ();
use Scalar::Util ();

sub _number {
    my ( $value, $minimum ) = @_;
    return
         defined($value)
      && !ref($value)
      && Scalar::Util::looks_like_number($value)
      && "$value" !~ /nan|inf/i
      && $value >= $minimum
      && $value <= 1.7976931348623157e308;
}

sub _id {
    my ($value) = @_;
    return defined($value) && !ref($value) && $value =~ /\A[a-z0-9][a-z0-9_]*\z/;
}

sub _array { die "Catalog $_[1] must be an array\n"  unless ref( $_[0] ) eq 'ARRAY'; }
sub _hash  { die "Catalog $_[1] must be an object\n" unless ref( $_[0] ) eq 'HASH'; }

sub _positive {
    die "Catalog $_[1] must be positive and finite\n" unless _number( $_[0], 0 ) && $_[0] > 0;
}

sub _target {
    die "Unknown catalog target $_[1]\n" unless defined( $_[1] ) && exists $_[0]{ $_[1] };
}

sub new {
    my ( $class, %args ) = @_;
    _hash( $args{generators}, 'generators' );
    _array( $args{upgrades},     'upgrades' );
    _array( $args{achievements}, 'achievements' );
    die "Catalogs must not be empty\n"
      unless keys( %{ $args{generators} } ) && @{ $args{upgrades} } && @{ $args{achievements} };
    my $self = bless JSON::PP::decode_json( JSON::PP::encode_json( \%args ) ), $class;
    my ( %upgrades, %achievements );
    for my $group ( [ 'upgrades', \%upgrades ], [ 'achievements', \%achievements ] ) {
        for my $item ( @{ $self->{ $group->[0] } } ) {
            _hash( $item, $group->[0] );
            die "Invalid or duplicate catalog ID\n"
              unless _id( $item->{id} ) && !$group->[1]{ $item->{id} }++;
            die "Missing catalog name\n"
              unless defined( $item->{name} ) && !ref( $item->{name} ) && length( $item->{name} );
        }
    }
    my $generators = $self->{generators};
    for my $id ( keys %$generators ) {
        my $g = $generators->{$id};
        _hash( $g, "generator $id" );
        die "Invalid generator ID\n" unless _id($id) && ( $g->{id} // '' ) eq $id;
        die "Missing generator name\n"
          unless defined( $g->{name} ) && !ref( $g->{name} ) && length( $g->{name} );
        _positive( $g->{$_}, "$id.$_" ) for qw(baseProduction baseCost costMultiplier);
        die "Generator cost multiplier must be at least 1\n" if $g->{costMultiplier} < 1;
        _array( $g->{unlockRequirements}, "$id.unlockRequirements" );
        for my $req ( @{ $g->{unlockRequirements} } ) {
            _hash( $req, 'generator requirement' );
            my $type = $req->{type} // '';
            die "Unknown generator requirement $type\n"
              unless $type =~ /\A(?:bufos|generators|achievement|special)\z/;
            die "Invalid generator threshold\n" unless _number( $req->{value}, 0 );
            _target( $generators,    $req->{target} ) if $type eq 'generators';
            _target( \%achievements, $req->{target} ) if $type eq 'achievement';
            die "Missing special requirement target\n"
              if $type eq 'special' && !_id( $req->{target} );
        }
    }
    for my $u ( @{ $self->{upgrades} } ) {
        _positive( $u->{cost}, "$u->{id}.cost" );
        _array( $u->{effects}, 'upgrade effects' );
        die "Upgrade needs an effect\n" unless @{ $u->{effects} };
        for my $effect ( @{ $u->{effects} } ) {
            _hash( $effect, 'upgrade effect' );
            my $type = $effect->{type} // '';
            die "Unknown upgrade effect $type\n"
              unless $type =~ /\A(?:clickMultiplier|generatorProduction|globalMultiplier)\z/;
            _positive( $effect->{multiplier}, 'effect multiplier' );
            _target( $generators, $effect->{target} ) if $type eq 'generatorProduction';
        }
        _array( $u->{unlockConditions}, 'upgrade conditions' );
        for my $req ( @{ $u->{unlockConditions} } ) {
            _hash( $req, 'upgrade condition' );
            my $type = $req->{type} // '';
            die "Unknown upgrade condition $type\n"
              unless $type =~ /\A(?:totalBufos|generatorCount|upgrade|achievements)\z/;
            if    ( $type eq 'upgrade' ) { _target( \%upgrades, $req->{id} // $req->{target} ); }
            elsif ( $type eq 'achievements' ) { _target( \%achievements, $req->{target} ); }
            else {
                die "Invalid upgrade threshold\n" unless _number( $req->{value}, 0 );
                _target( $generators, $req->{target} ) if $type eq 'generatorCount';
            }
        }
    }
    for my $a ( @{ $self->{achievements} } ) {
        _hash( $a->{requirement}, 'achievement requirement' );
        my $req  = $a->{requirement};
        my $type = $req->{type} // '';
        die "Unknown achievement requirement $type\n"
          unless $type =~
          /\A(?:totalBufos|bufosPerSecond|totalGenerators|generatorType|clickCount|consoleOpened|upgradeCount|bossesDefeated|transcendences|prestigePoints|customEvent)\z/;
        _positive( $req->{value}, 'achievement threshold' );
        _target( $generators, $req->{target} ) if $type eq 'generatorType';
        die "Invalid custom event target\n"    if $type eq 'customEvent' && !_id( $req->{target} );
        next unless exists $a->{reward};
        _hash( $a->{reward}, 'achievement reward' );
        my $reward      = $a->{reward};
        my $reward_type = $reward->{type} // '';
        die "Unknown achievement reward $reward_type\n"
          unless $reward_type =~ /\A(?:productionBoost|clickBoost|generatorBoost|bufoBonus)\z/;
        _positive( $reward->{value}, 'achievement reward' );
        _target( $generators, $reward->{target} ) if $reward_type eq 'generatorBoost';
    }
    $self->{upgradeById}     = { map { $_->{id} => $_ } @{ $self->{upgrades} } };
    $self->{achievementById} = { map { $_->{id} => $_ } @{ $self->{achievements} } };
    return $self;
}
sub generators   { $_[0]{generators} }
sub upgrades     { $_[0]{upgrades} }
sub achievements { $_[0]{achievements} }
sub upgrade      { $_[0]{upgradeById}{ $_[1] } }
sub achievement  { $_[0]{achievementById}{ $_[1] } }

sub bosses {
    return [
        {
            id         => 'furious_froglet',
            name       => 'Furious Froglet',
            threshold  => 10000,
            baseHealth => 975,
            iconPath   => './assets/images/bosses/bufo-very-angry.png',
            flavorText => "It's smaller than you, but it is FURIOUS about it."
        },
        {
            id         => 'the_enraged_bufo',
            name       => 'The Enraged Bufo',
            threshold  => 100000000,
            baseHealth => 53800,
            iconPath   => './assets/images/bosses/bufo-enraged.png',
            flavorText => 'Every click you have ever made has led to this moment of pure rage.'
        },
        {
            id         => 'bufo_dragon',
            name       => 'Bufo Dragon',
            threshold  => 5000000000,
            baseHealth => 38700000,
            iconPath   => './assets/images/bosses/bufo-dragon.png',
            flavorText => 'Legends spoke of a bufo that ascended beyond amphibian. This is it.'
        },
        {
            id         => 'bufo_devil',
            name       => 'Bufo Devil',
            threshold  => 100000000000,
            baseHealth => 65600000,
            iconPath   => './assets/images/bosses/bufo-devil.png',
            flavorText => 'It offers you a deal. You should probably just click it instead.'
        },
        {
            id         => 'mega_bufo',
            name       => 'MEGA BUFO',
            threshold  => 10000000000000,
            baseHealth => 7070000000,
            iconPath   => './assets/images/bosses/mega-bufo.png',
            flavorText =>
              'The one all other bufos speak of in hushed croaks. Surely nothing tops this... right?'
        },
        {
            id         => 'interdimensional_bufo',
            name       => 'Interdimensional Bufo',
            threshold  => 50000000000000,
            baseHealth => 78200000000,
            iconPath   => './assets/images/bosses/terrarium.png',
            flavorText =>
              'It rests atop the terrarium of existence, watching your entire pond like it were a fish tank.'
        },
        {
            id         => 'omniscient_bufo',
            name       => 'The Omniscient Bufo',
            threshold  => 2000000000000000,
            baseHealth => 1670000000000,
            iconPath   => './assets/images/bosses/omniscient.png',
            flavorText => 'It already knows how this fight ends. Prove it wrong.'
        },
    ];
}
1;
