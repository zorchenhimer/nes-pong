credits_metadata:
    ; length of nametable
    .byte credits_nametable_end - credits_name_table

credits_name_table:
    .word credits_name01, credits_name02, credits_name03, credits_name04
    .word credits_name05, credits_name06
credits_nametable_end:

credits_name01:
    .byte $0B
    .byte "notoriouspu"

credits_name02:
    .byte $09
    .byte "SleepyMia"

credits_name03:
    .byte $09
    .byte "KimiMoons"

credits_name04:
    .byte $0C
    .byte "chaos111gamer"

credits_name05:
    .byte $08
    .byte "Gappajin"

credits_name06:
    .byte $08
    .byte "jojoa1997"
