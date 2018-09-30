credits_metadata:
    ; length of nametable
    .db credits_nametable_end - credits_name_table

credits_name_table:
    .dw credits_name01, credits_name02, credits_name03, credits_name04
    .dw credits_name05
credits_nametable_end:

credits_name01:
    .db $0B
    .db "notoriouspu"

credits_name02:
    .db $09
    .db "SleepyMia"

credits_name03:
    .db $09
    .db "KimiMoons"

credits_name04:
    .db $0C
    .db "chaos111gamer"

credits_name05:
    .db $08
    .db "Gappajin"
