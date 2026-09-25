identification division.
program-id. BUFO-VALIDATE-CATALOGS.
environment division.
configuration section.
repository. function J-NUM function J-STR function all intrinsic.
data division.
local-storage section.
01 catalog usage pointer.
01 catalog-item usage pointer.
01 entries usage pointer.
01 children usage pointer.
01 condition-node usage pointer.
01 condition-list usage pointer.
01 nested-node usage pointer.
01 checked-node usage pointer.
01 field-node usage pointer.
01 lookup-node usage pointer.
01 reference-list usage pointer.
01 seen usage pointer.
01 category pic x(32).
01 field-name pic x(96).
01 key-z pic x(256).
01 record-id pic x(128).
01 record-key pic x(128).
01 reference-id pic x(128).
01 reference-catalog pic x(64).
01 text-value pic x(256).
01 message-text pic x(512).
01 expected-type binary-long.
01 actual-type binary-long.
01 optional-field binary-long.
01 failed binary-long.
01 found binary-long.
01 i binary-long.
01 j binary-long.
01 k binary-long.
01 m binary-long.
01 count-items binary-long.
01 child-count binary-long.
01 nested-count binary-long.
01 reference-count binary-long.
01 compare-code binary-long.
01 lower-bound comp-2.
01 upper-bound comp-2.
01 value-number comp-2.
01 previous-threshold comp-2 value -1.
01 sum-weights comp-2.
linkage section.
01 req usage pointer.
01 ctx usage pointer.
01 res usage pointer.
procedure division using by value req ctx res.
call static 'j_get_into' using by value ctx by reference z'catalog' catalog end-call
move 'generators' to category perform load-catalog
move 5 to expected-type perform check-container
if count-items = 0 move 1 to failed end-if
perform varying i from 0 by 1 until i >= count-items or failed = 1
call static 'j_at_into' using by value entries i by reference catalog-item end-call
perform record-identity
call static 'j_key' using by value catalog-item by reference record-key by value 128 end-call
if record-key not = record-id move 1 to failed end-if
move catalog-item to checked-node move 'name' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'description' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'iconPath' to field-name move 3 to expected-type move 1 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'detailedDescription' to field-name move 3 to expected-type move 1 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'category' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move function J-STR(catalog-item,'category') to text-value
if text-value not = 'basic' and 'premium' and 'special' move 1 to failed end-if
move catalog-item to checked-node move 'baseCost' to field-name move 2 to expected-type move 0 to optional-field
move 0.000000000001 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'currentCost' to field-name move 2 to expected-type move 0 to optional-field
move 0.000000000001 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'baseProduction' to field-name move 2 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'currentProduction' to field-name move 2 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'totalProduction' to field-name move 2 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'count' to field-name move 2 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move function J-NUM(catalog-item,'count') to value-number
compute lower-bound = function integer(value-number)
call static 'h_number_compare' using by reference value-number lower-bound returning compare-code end-call
if compare-code not = 0 move 1 to failed end-if
move catalog-item to checked-node move 'costMultiplier' to field-name move 2 to expected-type move 0 to optional-field
move 1.000000000001 to lower-bound move 100 to upper-bound perform check-field
move catalog-item to checked-node move 'unlocked' to field-name move 1 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'enabled' to field-name move 1 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'boosts' to field-name move 4 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
call static 'j_get_into' using by value catalog-item by reference z'boosts' children end-call
call static 'j_size' using by value children by reference x'00' returning child-count end-call
perform varying j from 0 by 1 until j >= child-count or failed = 1
call static 'j_at_into' using by value children j by reference condition-node end-call
move condition-node to checked-node move 'id' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move condition-node to checked-node move 'multiplier' to field-name move 2 to expected-type move 0 to optional-field
move 0.000000000001 to lower-bound move 1000000 to upper-bound perform check-field
move condition-node to checked-node move 'source' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move condition-node to checked-node move 'active' to field-name move 1 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
end-perform
move catalog-item to checked-node move 'unlockRequirements' to field-name move 4 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
call static 'j_get_into' using by value catalog-item by reference z'unlockRequirements' children end-call
call static 'j_size' using by value children by reference x'00' returning child-count end-call
perform varying j from 0 by 1 until j >= child-count or failed = 1
call static 'j_at_into' using by value children j by reference condition-node end-call
move condition-node to checked-node move 'type' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move function J-STR(condition-node,'type') to text-value
if text-value not = 'bufos' and 'generators' and 'achievement' and 'special' move 1 to failed end-if
move condition-node to checked-node move 'value' to field-name move 2 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
evaluate function J-STR(condition-node,'type')
when 'generators'
move condition-node to checked-node move 'target' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move function J-STR(condition-node,'target') to reference-id move 'generators' to reference-catalog perform check-reference
when 'achievement'
move condition-node to checked-node move 'target' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move function J-STR(condition-node,'target') to reference-id move 'achievements' to reference-catalog perform check-reference
when 'special'
move condition-node to checked-node move 'target' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
end-evaluate end-perform end-perform
call static 'j_delete' using by value seen end-call
if failed = 1 perform report-failure goback end-if
move 'upgrades' to category perform load-catalog
move 4 to expected-type perform check-container
if count-items = 0 move 1 to failed end-if
perform varying i from 0 by 1 until i >= count-items or failed = 1
call static 'j_at_into' using by value entries i by reference catalog-item end-call
perform record-identity
move catalog-item to checked-node move 'name' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'description' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'category' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move function J-STR(catalog-item,'category') to text-value
if text-value not = 'click' and 'generator' and 'global' move 1 to failed end-if
move catalog-item to checked-node move 'cost' to field-name move 2 to expected-type move 0 to optional-field
move 0.000000000001 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'effects' to field-name move 4 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'unlockConditions' to field-name move 4 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field

call static 'j_get_into' using by value catalog-item by reference z'effects' children end-call
call static 'j_size' using by value children by reference x'00' returning child-count end-call
if child-count = 0 move 1 to failed end-if
perform varying j from 0 by 1 until j >= child-count or failed = 1
call static 'j_at_into' using by value children j by reference condition-node end-call
move condition-node to checked-node move 'type' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move function J-STR(condition-node,'type') to text-value
if text-value not = 'clickMultiplier' and 'generatorProduction' and 'globalMultiplier' and 'unlockSpecial' move 1 to failed end-if
move condition-node to checked-node move 'multiplier' to field-name move 2 to expected-type move 0 to optional-field
move 0.000000000001 to lower-bound move 1000000 to upper-bound perform check-field

if function J-STR(condition-node,'type') = 'generatorProduction'
move condition-node to checked-node move 'target' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move function J-STR(condition-node,'target') to reference-id move 'generators' to reference-catalog perform check-reference
end-if
end-perform
call static 'j_get_into' using by value catalog-item by reference z'unlockConditions' children end-call
call static 'j_size' using by value children by reference x'00' returning child-count end-call
perform varying j from 0 by 1 until j >= child-count or failed = 1
call static 'j_at_into' using by value children j by reference condition-node end-call
move condition-node to checked-node move 'type' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move function J-STR(condition-node,'type') to text-value
if text-value not = 'totalBufos' and 'generatorCount' and 'achievements' and 'upgrade' move 1 to failed end-if
evaluate function J-STR(condition-node,'type')
when 'upgrade'
call static 'j_get_into' using by value condition-node by reference z'target' field-node end-call
if field-node = null
move condition-node to checked-node move 'id' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move function J-STR(condition-node,'id') to reference-id move 'upgrades' to reference-catalog perform check-reference
else
move condition-node to checked-node move 'target' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move function J-STR(condition-node,'target') to reference-id move 'upgrades' to reference-catalog perform check-reference
end-if
if reference-id = record-id move 1 to failed end-if
when 'generatorCount'
move condition-node to checked-node move 'value' to field-name move 2 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move condition-node to checked-node move 'target' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move function J-STR(condition-node,'target') to reference-id move 'generators' to reference-catalog perform check-reference
when 'achievements'
move condition-node to checked-node move 'value' to field-name move 2 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move condition-node to checked-node move 'target' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move function J-STR(condition-node,'target') to reference-id move 'achievements' to reference-catalog perform check-reference
when other
move condition-node to checked-node move 'value' to field-name move 2 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
end-evaluate end-perform end-perform
call static 'j_delete' using by value seen end-call
if failed = 1 perform report-failure goback end-if
move 'achievements' to category perform load-catalog
move 4 to expected-type perform check-container
if count-items = 0 move 1 to failed end-if
perform varying i from 0 by 1 until i >= count-items or failed = 1
call static 'j_at_into' using by value entries i by reference catalog-item end-call
perform record-identity
move catalog-item to checked-node move 'name' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'description' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'category' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move function J-STR(catalog-item,'category') to text-value
if text-value not = 'generators' and 'production' and 'clicks' and 'special' move 1 to failed end-if
move catalog-item to checked-node move 'secret' to field-name move 1 to expected-type move 1 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'order' to field-name move 2 to expected-type move 1 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'requirement' to field-name move 5 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field

call static 'j_get_into' using by value catalog-item by reference z'requirement' condition-node end-call
move condition-node to checked-node move 'type' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move function J-STR(condition-node,'type') to text-value
if text-value not = 'totalBufos' and 'bufosPerSecond' and 'totalGenerators' and 'generatorType' and 'clickCount' and 'consoleOpened' and 'upgradeCount' and 'explorationCount' and 'bossesDefeated' and 'transcendences' and 'prestigePoints' and 'customEvent' move 1 to failed end-if
move condition-node to checked-node move 'value' to field-name move 2 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
evaluate function J-STR(condition-node,'type')
when 'generatorType'
move condition-node to checked-node move 'target' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move function J-STR(condition-node,'target') to reference-id move 'generators' to reference-catalog perform check-reference
when 'customEvent'
move condition-node to checked-node move 'target' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
end-evaluate
move catalog-item to checked-node move 'reward' to field-name move 5 to expected-type move 1 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
call static 'j_get_into' using by value catalog-item by reference z'reward' condition-node end-call
if condition-node not = null
move condition-node to checked-node move 'type' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move function J-STR(condition-node,'type') to text-value
if text-value not = 'productionBoost' and 'clickBoost' and 'generatorBoost' and 'unlockGenerator' and 'unlockUpgrade' and 'unlockFeature' and 'bufoBonus' move 1 to failed end-if
move condition-node to checked-node move 'value' to field-name move 2 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move condition-node to checked-node move 'description' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
evaluate function J-STR(condition-node,'type')
when 'productionBoost' when 'clickBoost' when 'generatorBoost'
move condition-node to checked-node move 'value' to field-name move 2 to expected-type move 0 to optional-field
move 0.000000000001 to lower-bound move 1000000 to upper-bound perform check-field
end-evaluate
evaluate function J-STR(condition-node,'type')
when 'generatorBoost' when 'unlockGenerator'
move condition-node to checked-node move 'target' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move function J-STR(condition-node,'target') to reference-id move 'generators' to reference-catalog perform check-reference
when 'unlockUpgrade'
move condition-node to checked-node move 'target' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move function J-STR(condition-node,'target') to reference-id move 'upgrades' to reference-catalog perform check-reference
when 'unlockFeature'
move condition-node to checked-node move 'target' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
end-evaluate end-if end-perform
call static 'j_delete' using by value seen end-call
if failed = 1 perform report-failure goback end-if
move 'bosses' to category perform load-catalog
move 4 to expected-type perform check-container
if count-items = 0 move 1 to failed end-if
perform varying i from 0 by 1 until i >= count-items or failed = 1
call static 'j_at_into' using by value entries i by reference catalog-item end-call
perform record-identity
move catalog-item to checked-node move 'name' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'iconPath' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'flavorText' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'baseHealth' to field-name move 2 to expected-type move 0 to optional-field
move 1 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'threshold' to field-name move 2 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field

move function J-NUM(catalog-item,'threshold') to value-number
call static 'h_number_compare' using by reference value-number previous-threshold returning compare-code end-call
if compare-code <= 0 move 1 to failed end-if
move value-number to previous-threshold
end-perform
call static 'j_delete' using by value seen end-call
if failed = 1 perform report-failure goback end-if
move 'enemies.BASE_DROP_ITEMS' to category perform load-catalog
move 5 to expected-type perform check-container
perform varying i from 0 by 1 until i >= count-items or failed = 1
call static 'j_at_into' using by value entries i by reference catalog-item end-call
perform record-identity
move catalog-item to checked-node move 'name' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'dropRate' to field-name move 2 to expected-type move 0 to optional-field
move 0 to lower-bound move 1 to upper-bound perform check-field
end-perform
call static 'j_delete' using by value seen end-call
if failed = 1 perform report-failure goback end-if
move 'enemies.INITIAL_ENEMY_TEMPLATES' to category perform load-catalog
move 4 to expected-type perform check-container
if count-items = 0 move 1 to failed end-if
perform varying i from 0 by 1 until i >= count-items or failed = 1
call static 'j_at_into' using by value entries i by reference catalog-item end-call
move catalog-item to checked-node move 'baseId' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move function J-STR(catalog-item,'baseId') to record-id perform unique-id
move catalog-item to checked-node move 'nameTemplate' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'colorTheme' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'spriteRef' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'baseMaxHealth' to field-name move 2 to expected-type move 0 to optional-field
move 0.000000000001 to lower-bound move 1000000 to upper-bound perform check-field
move catalog-item to checked-node move 'baseAttack' to field-name move 2 to expected-type move 0 to optional-field
move 0.000000000001 to lower-bound move 1000000 to upper-bound perform check-field
move catalog-item to checked-node move 'baseDefense' to field-name move 2 to expected-type move 0 to optional-field
move 0.000000000001 to lower-bound move 1000000 to upper-bound perform check-field
move catalog-item to checked-node move 'baseSpeed' to field-name move 2 to expected-type move 0 to optional-field
move 0.000000000001 to lower-bound move 1000000 to upper-bound perform check-field
move catalog-item to checked-node move 'minAreaLevel' to field-name move 2 to expected-type move 0 to optional-field
move 0.000000000001 to lower-bound move 1000000 to upper-bound perform check-field
move catalog-item to checked-node move 'healthScaling' to field-name move 2 to expected-type move 0 to optional-field
move 0.000000000001 to lower-bound move 1000000 to upper-bound perform check-field
move catalog-item to checked-node move 'attackScaling' to field-name move 2 to expected-type move 0 to optional-field
move 0.000000000001 to lower-bound move 1000000 to upper-bound perform check-field
move catalog-item to checked-node move 'defenseScaling' to field-name move 2 to expected-type move 0 to optional-field
move 0.000000000001 to lower-bound move 1000000 to upper-bound perform check-field
move catalog-item to checked-node move 'speedScaling' to field-name move 2 to expected-type move 0 to optional-field
move 0.000000000001 to lower-bound move 1000000 to upper-bound perform check-field
move catalog-item to checked-node move 'possibleTypes' to field-name move 4 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'typeWeights' to field-name move 4 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'areas' to field-name move 4 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'baseDropTable' to field-name move 5 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'baseDropTable.baseBufos' to field-name move 2 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'baseDropTable.baseExperience' to field-name move 2 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move catalog-item to checked-node move 'baseDropTable.possibleDrops' to field-name move 4 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field

call static 'j_get_into' using by value catalog-item by reference z'possibleTypes' children end-call
call static 'j_get_into' using by value catalog-item by reference z'typeWeights' condition-list end-call
call static 'j_size' using by value children by reference x'00' returning child-count end-call
call static 'j_size' using by value condition-list by reference x'00' returning nested-count end-call
if child-count = 0 or child-count not = nested-count move 1 to failed end-if
move 0 to sum-weights
perform varying j from 0 by 1 until j >= child-count or failed = 1
call static 'j_at_into' using by value children j by reference condition-node end-call
move condition-node to checked-node move ' ' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move function J-STR(condition-node,' ') to text-value
if text-value not = 'normal' and 'elite' and 'boss' and 'legendary' move 1 to failed end-if
call static 'j_at_into' using by value condition-list j by reference condition-node end-call
move condition-node to checked-node move ' ' to field-name move 2 to expected-type move 0 to optional-field
move 0 to lower-bound move 1000000 to upper-bound perform check-field
add value-number to sum-weights
end-perform
if sum-weights <= 0 move 1 to failed end-if
call static 'j_get_into' using by value catalog-item by reference z'areas' children end-call
call static 'j_size' using by value children by reference x'00' returning child-count end-call
if child-count = 0 move 1 to failed end-if
perform varying j from 0 by 1 until j >= child-count or failed = 1
call static 'j_at_into' using by value children j by reference condition-node end-call
move condition-node to checked-node move ' ' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move function J-STR(condition-node,' ') to text-value
if text-value not = 'Pond' and 'Creek' and 'Swamp' and 'River' and 'Lake' and 'Forest' and 'Mountains' and 'Dungeon' move 1 to failed end-if
end-perform
call static 'j_get_into' using by value catalog-item by reference z'baseDropTable.possibleDrops' children end-call
call static 'j_size' using by value children by reference x'00' returning child-count end-call
perform varying j from 0 by 1 until j >= child-count or failed = 1
call static 'j_at_into' using by value children j by reference condition-node end-call
move condition-node to checked-node move 'id' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move function J-STR(condition-node,'id') to reference-id move 'enemies.BASE_DROP_ITEMS' to reference-catalog perform check-reference
move condition-node to checked-node move 'name' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move condition-node to checked-node move 'dropRate' to field-name move 2 to expected-type move 0 to optional-field
move 0 to lower-bound move 1 to upper-bound perform check-field
end-perform end-perform
call static 'j_delete' using by value seen end-call
if failed = 1 perform report-failure
else
call static 'j_set_boolean' using by value res by reference z'ok' by value 1 end-call
call static 'j_set_boolean' using by value res by reference z'result' by value 1 end-call end-if
goback.
report-failure.
call static 'j_set_boolean' using by value res by reference z'ok' by value 0 end-call
move spaces to message-text
string 'Invalid catalog: ' function trim(category) ' catalog-item ' function trim(record-id) ' field ' function trim(field-name) into message-text end-string
call static 'j_set_string' using by value res by reference z'error' message-text by value function length(function trim(message-text)) end-call
.
load-catalog.
move low-values to key-z string function trim(category) x'00' into key-z end-string
call static 'j_get_into' using by value catalog by reference key-z entries end-call
call static 'j_size' using by value entries by reference x'00' returning count-items end-call
call static 'j_object_into' using by reference seen end-call.
check-container.
call static 'j_type' using by value entries by reference x'00' returning actual-type end-call
if actual-type not = expected-type or count-items > 10000 move 1 to failed end-if.
record-identity.
move catalog-item to checked-node move 'id' to field-name move 3 to expected-type move 0 to optional-field
move 0 to lower-bound move 1.0e+200 to upper-bound perform check-field
move function J-STR(catalog-item,'id') to record-id perform unique-id.
unique-id.
if record-id = spaces move 1 to failed else
perform varying k from 1 by 1 until k > function length(function trim(record-id))
if record-id(k:1) = '.' or '[' or ']' move 1 to failed end-if end-perform
move low-values to key-z string function trim(record-id) x'00' into key-z end-string
call static 'j_has' using by value seen by reference key-z returning found end-call
if found = 1 move 1 to failed end-if
call static 'j_set_boolean' using by value seen by reference key-z by value 1 end-call end-if.
check-field.
move low-values to key-z string function trim(field-name) x'00' into key-z end-string
call static 'j_get_into' using by value checked-node by reference key-z field-node end-call
if field-node = null and optional-field = 1 exit paragraph end-if
call static 'j_type' using by value field-node by reference x'00' returning actual-type end-call
if actual-type not = expected-type move 1 to failed exit paragraph end-if
if actual-type = 3
move function J-STR(field-node,' ') to text-value
if text-value = spaces move 1 to failed end-if end-if
if actual-type = 2
move function J-NUM(field-node,' ') to value-number
call static 'h_number_compare' using by reference value-number lower-bound returning compare-code end-call
if compare-code < 0 move 1 to failed end-if
call static 'h_number_compare' using by reference value-number upper-bound returning compare-code end-call
if compare-code > 0 move 1 to failed end-if end-if.
check-reference.
move low-values to key-z string function trim(reference-catalog) x'00' into key-z end-string
call static 'j_get_into' using by value catalog by reference key-z reference-list end-call
call static 'j_size' using by value reference-list by reference x'00' returning reference-count end-call
move 0 to found
perform varying m from 0 by 1 until m >= reference-count or found = 1
call static 'j_at_into' using by value reference-list m by reference lookup-node end-call
if function J-STR(lookup-node,'id') = reference-id move 1 to found end-if
end-perform
if found = 0 move 1 to failed end-if.
end program BUFO-VALIDATE-CATALOGS.
