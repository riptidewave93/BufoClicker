identification division.
program-id. BUFO-UI-DETAILS.
environment division.
configuration section.
repository. function J-NUM function J-STR function all intrinsic.
data division.
local-storage section.
01 item-node usage pointer.
01 catalog-node usage pointer.
01 component-node usage pointer.
01 detail-request usage pointer.
01 detail-response usage pointer.
01 data-node usage pointer.
01 copy-node usage pointer.
01 index-value binary-long.
01 count-value binary-long.
01 item-id pic x(256).
01 item-name pic x(1024).
01 action-name pic x(64).
01 kind-name pic x(32).
01 detail-html pic x(32768).
linkage section.
01 request-node usage pointer.
01 context-node usage pointer.
01 response-node usage pointer.
procedure division using by value request-node context-node response-node.
 move function J-STR(request-node,'args.id') to item-id
 move function J-STR(request-node,'args.action') to action-name
 if action-name = 'upgradeInfo'
   move 'UpgradeItem' to kind-name
   call static 'j_get_into' using by value context-node by reference z'catalog.upgrades' catalog-node end-call
   call static 'j_size' using by value catalog-node by reference x'00' returning count-value end-call
   perform varying index-value from 0 by 1 until index-value >= count-value
     call static 'j_at_into' using by value catalog-node index-value by reference item-node end-call
     if item-id = function J-STR(item-node,'id') exit perform end-if
     move null to item-node
   end-perform
 else
   move 'ShopItem' to kind-name
   if function J-STR(request-node,'args.kind') = 'owned' move 'GeneratorItem' to kind-name end-if
   call static 'j_get_into' using by value context-node
     by reference function concatenate('state.generators.',function trim(item-id),x'00') item-node end-call
 end-if
 if item-node = null
   call static 'j_set_boolean' using by value response-node by reference z'ok' by value 0 end-call
   call static 'j_set_string' using by value response-node by reference z'error' z'Unknown item' by value 12 end-call
   goback
 end-if
 move function J-STR(item-node,'name') to item-name
 call static 'j_object_into' using by reference detail-request end-call
 call static 'j_object_into' using by reference detail-response end-call
 call static 'j_object_into' using by reference component-node end-call
 call static 'j_set_string' using by value component-node by reference z'kind' kind-name
   by value function length(function trim(kind-name)) end-call
 call static 'j_clone_into' using by value item-node by reference copy-node end-call
 if kind-name = 'ShopItem'
   call static 'j_object_into' using by reference data-node end-call
   call static 'j_set' using by value data-node by reference z'generator' by value copy-node end-call
 else move copy-node to data-node end-if
 call static 'j_set' using by value component-node by reference z'data' by value data-node end-call
 call static 'j_set' using by value detail-request by reference z'component' by value component-node end-call
 call static 'j_set_string' using by value detail-request by reference z'method' z'generateTooltipContent' by value 22 end-call
 call static 'BUFO-COMPONENT-RENDER' using by value detail-request context-node detail-response end-call
 move function J-STR(detail-response,'result') to detail-html
 call static 'j_set_string' using by value context-node by reference z'runtime.ui.customTitle' item-name
   by value function length(function trim(item-name)) end-call
 call static 'j_set_string' using by value context-node by reference z'runtime.ui.customContent' detail-html
   by value function length(function trim(detail-html trailing)) end-call
 call static 'j_set_string' using by value context-node by reference z'runtime.ui.modal' z'custom' by value 6 end-call
 call static 'j_remove' using by value context-node by reference z'runtime.ui.customOptions' end-call
 call static 'j_set_boolean' using by value context-node by reference z'runtime.ui.modalRendered' by value 0 end-call
 call static 'j_set_boolean' using by value response-node by reference z'ok' by value 1 end-call
 call static 'j_delete' using by value detail-request end-call
 call static 'j_delete' using by value detail-response end-call
 goback.
end program BUFO-UI-DETAILS.
