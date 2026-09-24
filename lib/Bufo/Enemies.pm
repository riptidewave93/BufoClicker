package Bufo::Enemies;
use strict;
use warnings;
use JSON::PP            ();
use Bufo::ExplorerModel ();

my $DATA = JSON::PP::decode_json(<<'DATA');
{
  "items": {
    "common_slime": {
      "id": "common_slime",
      "name": "Common Slime",
      "dropRate": 0.8
    },
    "water_essence": {
      "id": "water_essence",
      "name": "Water Essence",
      "dropRate": 0.5
    },
    "thorn_spike": {
      "id": "thorn_spike",
      "name": "Thorn Spike",
      "dropRate": 0.4
    },
    "frog_scale": {
      "id": "frog_scale",
      "name": "Frog Scale",
      "dropRate": 0.6
    },
    "golden_egg": {
      "id": "golden_egg",
      "name": "Golden Egg",
      "dropRate": 0.05
    }
  },
  "templates": [
    {
      "baseId": "waterBug",
      "nameTemplate": "Water Bug",
      "baseMaxHealth": 20,
      "baseAttack": 3,
      "baseDefense": 1,
      "baseSpeed": 5,
      "possibleTypes": [
        "normal",
        "elite"
      ],
      "typeWeights": [
        95,
        5
      ],
      "colorTheme": "#6BCDFF",
      "spriteRef": "assets/images/enemies/water_bug.png",
      "areas": [
        "Pond",
        "Creek",
        "Swamp"
      ],
      "minAreaLevel": 1,
      "baseDropTable": {
        "possibleDrops": [
          {
            "id": "common_slime",
            "name": "Common Slime",
            "dropRate": 0.8
          },
          {
            "id": "water_essence",
            "name": "Water Essence",
            "dropRate": 0.5
          }
        ],
        "baseBufos": 5,
        "baseExperience": 10
      },
      "healthScaling": 1.2,
      "attackScaling": 1.1,
      "defenseScaling": 1.05,
      "speedScaling": 1.15
    },
    {
      "baseId": "mudCrawler",
      "nameTemplate": "Mud Crawler",
      "baseMaxHealth": 35,
      "baseAttack": 4,
      "baseDefense": 3,
      "baseSpeed": 2,
      "possibleTypes": [
        "normal",
        "elite"
      ],
      "typeWeights": [
        90,
        10
      ],
      "colorTheme": "#8B4513",
      "spriteRef": "assets/images/enemies/mud_crawler.png",
      "areas": [
        "Creek",
        "Swamp",
        "River"
      ],
      "minAreaLevel": 2,
      "baseDropTable": {
        "possibleDrops": [
          {
            "id": "common_slime",
            "name": "Common Slime",
            "dropRate": 0.8
          },
          {
            "id": "thorn_spike",
            "name": "Thorn Spike",
            "dropRate": 0.4
          }
        ],
        "baseBufos": 10,
        "baseExperience": 15
      },
      "healthScaling": 1.25,
      "attackScaling": 1.15,
      "defenseScaling": 1.2,
      "speedScaling": 1.05
    },
    {
      "baseId": "poisonDartFrog",
      "nameTemplate": "Poison Dart Frog",
      "baseMaxHealth": 25,
      "baseAttack": 8,
      "baseDefense": 2,
      "baseSpeed": 7,
      "possibleTypes": [
        "normal",
        "elite",
        "boss"
      ],
      "typeWeights": [
        85,
        13,
        2
      ],
      "colorTheme": "#FF4D4D",
      "spriteRef": "assets/images/enemies/poison_frog.png",
      "areas": [
        "Swamp",
        "River",
        "Forest"
      ],
      "minAreaLevel": 3,
      "baseDropTable": {
        "possibleDrops": [
          {
            "id": "frog_scale",
            "name": "Frog Scale",
            "dropRate": 0.6
          },
          {
            "id": "water_essence",
            "name": "Water Essence",
            "dropRate": 0.5
          }
        ],
        "baseBufos": 25,
        "baseExperience": 30
      },
      "healthScaling": 1.2,
      "attackScaling": 1.25,
      "defenseScaling": 1.1,
      "speedScaling": 1.2
    },
    {
      "baseId": "giantSnapper",
      "nameTemplate": "Giant Snapper",
      "baseMaxHealth": 80,
      "baseAttack": 12,
      "baseDefense": 10,
      "baseSpeed": 2,
      "possibleTypes": [
        "normal",
        "elite",
        "boss"
      ],
      "typeWeights": [
        80,
        15,
        5
      ],
      "colorTheme": "#006400",
      "spriteRef": "assets/images/enemies/giant_snapper.png",
      "areas": [
        "River",
        "Lake",
        "Swamp"
      ],
      "minAreaLevel": 4,
      "baseDropTable": {
        "possibleDrops": [
          {
            "id": "water_essence",
            "name": "Water Essence",
            "dropRate": 0.5
          },
          {
            "id": "thorn_spike",
            "name": "Thorn Spike",
            "dropRate": 0.4
          },
          {
            "id": "golden_egg",
            "name": "Golden Egg",
            "dropRate": 0.05
          }
        ],
        "baseBufos": 40,
        "baseExperience": 50
      },
      "healthScaling": 1.3,
      "attackScaling": 1.2,
      "defenseScaling": 1.3,
      "speedScaling": 1.05
    },
    {
      "baseId": "forestStalker",
      "nameTemplate": "Forest Stalker",
      "baseMaxHealth": 60,
      "baseAttack": 15,
      "baseDefense": 6,
      "baseSpeed": 10,
      "possibleTypes": [
        "normal",
        "elite",
        "boss"
      ],
      "typeWeights": [
        75,
        20,
        5
      ],
      "colorTheme": "#3D7B3D",
      "spriteRef": "assets/images/enemies/forest_stalker.png",
      "areas": [
        "Forest",
        "Mountains"
      ],
      "minAreaLevel": 5,
      "baseDropTable": {
        "possibleDrops": [
          {
            "id": "thorn_spike",
            "name": "Thorn Spike",
            "dropRate": 0.4
          },
          {
            "id": "golden_egg",
            "name": "Golden Egg",
            "dropRate": 0.05
          }
        ],
        "baseBufos": 60,
        "baseExperience": 80
      },
      "healthScaling": 1.25,
      "attackScaling": 1.3,
      "defenseScaling": 1.15,
      "speedScaling": 1.25
    },
    {
      "baseId": "darkDweller",
      "nameTemplate": "Dark Dweller",
      "baseMaxHealth": 100,
      "baseAttack": 20,
      "baseDefense": 15,
      "baseSpeed": 5,
      "possibleTypes": [
        "elite",
        "boss"
      ],
      "typeWeights": [
        80,
        20
      ],
      "colorTheme": "#4B0082",
      "spriteRef": "assets/images/enemies/dark_dweller.png",
      "areas": [
        "Mountains",
        "Dungeon"
      ],
      "minAreaLevel": 7,
      "baseDropTable": {
        "possibleDrops": [
          {
            "id": "frog_scale",
            "name": "Frog Scale",
            "dropRate": 0.6
          },
          {
            "id": "golden_egg",
            "name": "Golden Egg",
            "dropRate": 0.05
          }
        ],
        "baseBufos": 100,
        "baseExperience": 120
      },
      "healthScaling": 1.35,
      "attackScaling": 1.35,
      "defenseScaling": 1.3,
      "speedScaling": 1.15
    }
  ]
}
DATA
sub types                   { return { Normal => 'normal', Elite => 'elite', Boss => 'boss' }; }
sub base_drop_items         { return Bufo::ExplorerModel::_clone( $DATA->{items} ); }
sub initial_enemy_templates { return Bufo::ExplorerModel::_clone( $DATA->{templates} ); }
sub _random                 { return Bufo::ExplorerModel::_random( $_[0] ); }
sub _round                  { return Bufo::ExplorerModel::_round( $_[0] ); }
sub _max                    { return Bufo::ExplorerModel::_max(@_); }

sub generateEnemy {
    my ( $class, $area, $distance, $level, %args ) = @_;
    my @valid = grep {
        my $t = $_;
        $t->{minAreaLevel} <= $level && grep { $_ eq $area } @{ $t->{areas} }
    } @{ $DATA->{templates} };
    die "No valid enemy templates for area $area at level $level\n" unless @valid;
    my $template = $valid[ Bufo::ExplorerModel::_floor( _random( $args{random} ) * @valid ) ];
    my $total    = 0;
    $total += $_ for @{ $template->{typeWeights} };
    my $roll  = _random( $args{random} ) * $total;
    my $index = 0;
    for my $i ( 0 .. $#{ $template->{typeWeights} } ) {
        $roll -= $template->{typeWeights}[$i];
        if ( $roll <= 0 ) { $index = $i; last; }
    }
    my $type = $template->{possibleTypes}[$index];
    my %multipliers =
      ( normal => [ 1, 1, 1, 1 ], elite => [ 2.5, 1.8, 1.5, 1.2 ], boss => [ 5, 3, 2.5, 1.5 ] );
    my $effective = $level + $distance * 0.5;
    my %stats;
    my $i = 0;
    for my $spec (
        [ 'maxHealth', 'baseMaxHealth', 'healthScaling' ],
        [ 'attack',    'baseAttack',    'attackScaling' ],
        [ 'defense',   'baseDefense',   'defenseScaling' ],
        [ 'speed',     'baseSpeed',     'speedScaling' ]
      )
    {
        $stats{ $spec->[0] } =
          _round( $template->{ $spec->[1] } *
              $template->{ $spec->[2] }**sqrt($effective) *
              $multipliers{$type}[ $i++ ] *
              ( 0.9 + _random( $args{random} ) * 0.2 ) );
    }
    my $reward_multiplier = $type eq 'boss' ? 5 : $type eq 'elite' ? 2.5 : 1;
    my $drops             = Bufo::ExplorerModel::_clone( $template->{baseDropTable} );
    $drops->{$_} = _round( $drops->{$_} * 1.1**$effective * $reward_multiplier )
      for qw(baseBufos baseExperience);
    my $name = $template->{nameTemplate};
    $name = "Elite $name" if $type eq 'elite';
    $name .= ' Boss' if $type eq 'boss';
    return {
        id   => $template->{baseId} . '_' . $area . '_' . Bufo::ExplorerModel::_now( $args{now} ),
        name => $name,
        %stats,
        health          => $stats{maxHealth},
        type            => $type,
        colorTheme      => $template->{colorTheme},
        spriteRef       => $template->{spriteRef},
        area            => $area,
        difficultyLevel => $effective,
        dropTable       => $drops
    };
}

sub calculateEnemyRewards {
    my ( $class, $enemy, %args ) = @_;
    my $table = $enemy->{dropTable};
    my $bufos = _max( 1, _round( $table->{baseBufos} * ( 0.8 + _random( $args{random} ) * 0.4 ) ) );
    my $xp =
      _max( 1, _round( $table->{baseExperience} * ( 0.8 + _random( $args{random} ) * 0.4 ) ) );
    my @drops = @{ $table->{guaranteedDrops} // [] };
    for my $drop ( @{ $table->{possibleDrops} } ) {
        push @drops, $drop->{id} if _random( $args{random} ) < $drop->{dropRate};
    }
    return { bufos => $bufos, experience => $xp, drops => \@drops };
}

sub calculateRelativeDifficulty {
    my ( $class, $enemy, $explorer ) = @_;
    my $power = sub {
        my $s = shift;
        return $s->{attack} * 1.5 + $s->{defense} + $s->{health} * 0.2 + $s->{speed} * 0.8;
    };
    my $denominator = $power->($explorer);
    return $power->($enemy) / $denominator if $denominator;
    return $power->($enemy) ? 0 + 'Inf' : 0 + 'NaN';
}
1;
