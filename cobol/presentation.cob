identification division.
program-id. BUFO-PRESENTATION recursive.
environment division.
configuration section.
repository. function J-NUM function J-STR function all intrinsic.
data division.
local-storage section.
01 events-node usage pointer.
01 event-node usage pointer.
01 item-node usage pointer.
01 copy-node usage pointer.
01 child-request usage pointer.
01 child-response usage pointer.
01 event-index binary-long.
01 event-count binary-long.
01 save-flag binary-long.
01 flag binary-long.
01 event-name pic x(96).
01 notice-text pic x(2048).
01 formatted pic x(256).
01 now-value comp-2.
01 number-value comp-2.
01 random-value comp-2.
01 frenzy-path pic x(80).
01 frenzy-end-path pic x(80).
01 frenzy-multiplier-path pic x(80).
linkage section.
01 request-node usage pointer.
01 context-node usage pointer.
01 response-node usage pointer.
procedure division using by value request-node context-node response-node.
 move function J-NUM(context-node, 'runtime.now') to now-value
 move 'runtime.ui.productionFrenzyTotalMs' to frenzy-path
 move 'runtime.golden.productionFrenzyEndsAt' to frenzy-end-path
 move 'state.resources.frenzyProductionMultiplier' to frenzy-multiplier-path
 perform frenzy-duration
 move 'runtime.ui.clickFrenzyTotalMs' to frenzy-path
 move 'runtime.golden.clickFrenzyEndsAt' to frenzy-end-path
 move 'state.resources.frenzyClickMultiplier' to frenzy-multiplier-path
 perform frenzy-duration
 call static 'j_get_into' using by value context-node by reference z'events' events-node end-call
 call static 'j_size' using by value events-node by reference x'00' returning event-count end-call
 perform varying event-index from 0 by 1 until event-index >= event-count
 call static 'j_at_into' using by value events-node event-index by reference event-node end-call
 move function J-STR(event-node, 'name') to event-name
 evaluate event-name
 when 'ACHIEVEMENT_UNLOCKED'
 call static 'j_get_into' using by value event-node by reference z'payload.achievement' item-node end-call
 call static 'j_clone_into' using by value item-node by reference copy-node end-call
 call static 'j_set' using by value context-node by reference z'runtime.ui.achievementNotice' by value copy-node end-call
 compute number-value = now-value + 1300
 call static 'j_set_number' using by value context-node by reference z'runtime.ui.achievementNoticeUntil' number-value end-call
 move function concatenate('Achievement unlocked: ', function trim(function J-STR(event-node, 'payload.achievement.name'))) to notice-text
 perform notice
 when 'GOLDEN_BUFO_COLLECTED'
 call static 'j_get_into' using by value event-node by reference z'payload' item-node end-call
 call static 'j_clone_into' using by value item-node by reference copy-node end-call
 call static 'j_set' using by value context-node by reference z'runtime.ui.goldenReward' by value copy-node end-call
 compute number-value = now-value + 3000
 call static 'j_set_number' using by value context-node by reference z'runtime.ui.goldenRewardUntil' number-value end-call
 move function concatenate(function trim(function J-STR(event-node, 'payload.label')), ' ',
 function trim(function J-STR(event-node, 'payload.detail'))) to notice-text
 perform notice
 when 'BOSS_FIGHT_STARTED'
 move 0 to number-value
 call static 'j_set_number' using by value context-node by reference z'runtime.ui.bossMovedAt' number-value end-call
 when 'BOSS_DEFEATED' when 'BOSS_FIGHT_LOST'
 call static 'j_set_string' using by value context-node by reference z'runtime.ui.modal' 'bossResult' by value 10 end-call
 call static 'j_get_into' using by value event-node by reference z'payload' item-node end-call
 call static 'j_clone_into' using by value item-node by reference copy-node end-call
 call static 'j_set' using by value context-node by reference z'runtime.ui.bossResult' by value copy-node end-call
 if event-name = 'BOSS_DEFEATED' move 1 to flag else move 0 to flag end-if
 call static 'j_set_boolean' using by value context-node by reference z'runtime.ui.bossWon' by value flag end-call
 compute number-value = now-value + 800
 call static 'j_set_number' using by value context-node by reference z'runtime.ui.inputLockedUntil' number-value end-call
 move 1 to save-flag
 end-evaluate
 end-perform
 if save-flag = 1
 call static 'j_object_into' using by reference child-request end-call
 call static 'j_object_into' using by reference child-response end-call
 call static 'j_set_string' using by value child-request by reference z'operation' 'save' by value 4 end-call
 call static 'j_set_boolean' using by value child-request by reference z'args.auto' by value 1 end-call
 call static 'BUFO-SAVE' using by value child-request context-node child-response end-call
 call static 'j_boolean' using by value child-response by reference z'ok' returning flag end-call
 if flag = 0 move function J-STR(child-response, 'error') to notice-text perform notice end-if
 call static 'j_delete' using by value child-request end-call
 call static 'j_delete' using by value child-response end-call
 end-if
 call static 'j_has' using by value context-node by reference z'runtime.boss.fight' returning flag end-call
 if flag = 1 and now-value - function J-NUM(context-node, 'runtime.ui.bossMovedAt') >= 3000
 call static 'BUFO-RANDOM' using by value request-node context-node by reference random-value end-call
 compute number-value = 10 + random-value * 75
 call static 'j_set_number' using by value context-node by reference z'runtime.ui.bossX' number-value end-call
 call static 'BUFO-RANDOM' using by value request-node context-node by reference random-value end-call
 compute number-value = 15 + random-value * 65
 call static 'j_set_number' using by value context-node by reference z'runtime.ui.bossY' number-value end-call
 call static 'j_set_number' using by value context-node by reference z'runtime.ui.bossMovedAt' now-value end-call
 end-if
 call static 'j_boolean' using by value response-node by reference z'ok' returning flag end-call
 if flag = 1 and function J-NUM(response-node, 'offline.cappedProduction') > 0
 move function J-NUM(response-node, 'offline.cappedProduction') to number-value
 call static 'BUFO-FORMAT-NUMBER' using number-value formatted end-call
 move function concatenate('Welcome back! Your frogs earned ',function trim(formatted),' bufos while you were away.') to notice-text
 perform notice end-if
 goback.
frenzy-duration.
 compute number-value = function J-NUM(context-node, frenzy-end-path) - now-value
 if number-value > 0 and function J-NUM(context-node, frenzy-multiplier-path) > 1
 call static 'j_has' using by value context-node by reference
 function concatenate(function trim(frenzy-path), x'00') returning flag end-call
 if flag = 0
 call static 'j_set_number' using by value context-node by reference
 function concatenate(function trim(frenzy-path), x'00') number-value end-call
 end-if
 else
 call static 'j_remove' using by value context-node by reference
 function concatenate(function trim(frenzy-path), x'00') end-call
 end-if.
notice.
 call static 'j_set_string' using by value context-node by reference z'runtime.ui.notice' notice-text
 by value function length(function trim(notice-text)) end-call
 compute number-value = now-value + 6000
 call static 'j_set_number' using by value context-node by reference z'runtime.ui.noticeUntil' number-value end-call.
end program BUFO-PRESENTATION.
