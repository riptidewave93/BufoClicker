 01 op pic x(96).
 01 method-name pic x(64).
 01 args usage pointer.
 01 arg-table.
 02 a usage pointer occurs 8.
 01 string-table.
 02 s pic x(32768) occurs 8.
 01 number-table.
 02 n usage comp-2 occurs 8.
 01 bool-table.
 02 b usage binary-long occurs 8.
 01 kind pic x(64).
 01 command usage pointer.
 01 answer usage pointer.
 01 result-node usage pointer.
 01 target usage pointer.
 01 temp usage pointer.
 01 item usage pointer.
 01 list-node usage pointer.
 01 lib usage pointer.
 01 obj usage pointer.
 01 options-node usage pointer.
 01 child usage pointer.
 01 callback-node usage pointer.
 01 key-text pic x(256).
 01 text-value pic x(32768).
 01 value-text pic x(32768).
 01 id-text pic x(256).
 01 formatted pic x(256).
 01 html pic x(262144).
 01 hp usage binary-long value 1.
 01 i usage binary-long.
 01 j usage binary-long.
 01 k usage binary-long.
 01 cnt usage binary-long.
 01 typ usage binary-long.
 01 rc usage binary-long.
 01 yes usage binary-long.
 01 failed usage binary-long value 0.
 01 morph-html usage binary-long value 0.
 01 number-value usage comp-2.
 01 x usage comp-2.
 01 y usage comp-2.
 01 z usage comp-2.
 01 now-ms usage comp-2.

01 deferred-commands usage pointer.
