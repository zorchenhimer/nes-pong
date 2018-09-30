;
; Gamestate management
;

; ---------------------------
; Gamestate change dispatch
; subroutine
; ---------------------------
UpdateGameState:
    inc SkipNMI

    lda #0
    sta GSUpdateNeeded

    jsr ClearSprites

    lda GameState   ; load gamestate
    asl a           ; multiply by two
    tax             ; use it as an index

    ; low byte first
    lda GameState_Table+1, x
    pha

    ; then high byte
    lda GameState_Table, x
    pha

    ; Jump to sub-subroutine
    rts

; -------------------------
; Load Title gamestate
; -------------------------
gsTitle:
    lda #0
    sta TitleSelected

    ;lda #0
    ;sta $2000

    ldx #0
.loop
    lda PaletteData, x
    sta PaletteRAM, x
    inx
    cpx #$20
    bne .loop

    lda BGData_Lookup
    sta bgPointer

    lda BGData_Lookup+1
    sta bgPointer+1

    lda #$FF
    sta bgUpdateFlags
    jsr UpdateBackground

; Load sprites
    ldx #$00
titleSpriteLoop:
    lda titleSpriteData, X
    sta $0200, x
    inx
    cpx #$04         ; one sprite, four bytes per sprite
    bne titleSpriteLoop

    ; Turn PPU back on
    lda #PPU_ON
    sta $2001

    ;lda FrameUpdates
    ;ora #%11000000
    ;sta FrameUpdates
    ;lda #%10010000
    ;sta $2000   ; enable NMI, sprites from pattern table 0
    dec SkipNMI
    rts

; -------------------------
; Load Gameplay gamestate
; -------------------------
gsGame:
    ; General INIT stuff
    lda #$00
    sta p1Score
    sta p2Score
    ;sta $2000

    jsr ResetBall

    lda BGData_Lookup+2
    sta bgPointer

    lda BGData_Lookup+3
    sta bgPointer+1

    lda #$FF
    sta bgUpdateFlags
    jsr UpdateBackground

; Load sprites
    ldx #$00
SpriteLoop:
    lda SpriteData, X
    sta $0200, x
    inx
    cpx #36         ; one sprite, four bytes per sprite
    bne SpriteLoop

    ; Turn PPU back on
    lda #PPU_ON
    sta $2001

    lda #$01
    sta start_ticks
    ;lda #%10010000
    ;sta $2000   ; enable NMI, sprites from pattern table 0
    dec SkipNMI
    rts

; -------------------------
; Load Game Over gamestate
; -------------------------
gsDed:
    ; 2 - deterimine winner
    ; 3 - write winner to screen
    ;   Player One
    ;   Player Two
    ;   Computer Player
    ;   "Wins"

    lda p1Score
    cmp p2Score
    bcc p2Won

    ; P1 Won
    lda DedBG_Table
    sta bgPointer

    lda DedBG_Table+1
    sta bgPointer+1
    jmp gsDedEnd

p2Won:
    lda TitleSelected
    beq compWon

    lda DedBG_Table+2
    sta bgPointer

    lda DedBG_Table+3
    sta bgPointer+1
    jmp gsDedEnd

compWon:
    lda DedBG_Table+4
    sta bgPointer

    lda DedBG_Table+5
    sta bgPointer+1

gsDedEnd:
    lda #$FF
    sta bgUpdateFlags
    jsr UpdateBackground

    dec SkipNMI
    rts

ClearSprites:
    ldx #$00
ClearSpriteLoop:
    lda #$00
    sta $0200, x
    inx
    cpx #$00         ; one sprite, four bytes per sprite
    bne ClearSpriteLoop
    rts

BGData_Lookup:
    .word TitleBGData
    .word GameBGData

GameState_Table:
    .word gsDed-1
    .word gsGame-1
    .word gsTitle-1

TitleBGData:
    ; Flag byte
    ;   %1000 0000  RLE
    ;   %0100 0000  Skip PPU Address

    ; blank background to start of box
    .db $AA, $80, $20, $00, $01

    ; box top
    .db $01, $40, $06   ; left corner
    .db $0B, $C0, $02   ; top line
    .db $01, $40, $07   ; right corner
    .db $14, $C0, $01   ; blank until start of logo

    ; logo top row
    .db $0B, $40, $A0, $A1, $A2, $A3, $A4
    .db $A5, $A6, $A7, $A8, $A9, $AA

    .db $15, $C0, $01   ; black until 2nd row of logo

    ; logo bottom row
    .db $0B, $40, $B0, $B1, $B2, $B3, $B4
    .db $B5, $B6, $B7, $B8, $B9, $BA

    .db $14, $C0, $01   ; blank until start of bottom box
    .db $01, $40, $08   ; left corner
    .db $0B, $C0, $03   ; bottom line
    .db $01, $40, $09   ; right corner

    ; blank until menu start
    .db $F6, $C0, $01
    ;.db $17, $C0, $01

    .db $07, $40
    .db "VS COMP"

    .db $39, $C0, $01

    .db $08, $40
    .db "2 PLAYER"

    .db $38, $C0, $01

    .db $0A, $40
    .db "SOUND TEST"

    .db $FF, $C0, $01
    .db $2A, $C0, $01

    ; attribute data
    .db $20, $C0, $55
    .db $20, $C0, $AA
    .db $00

titleSpriteData:
    .db $7F, $05, $00, $5E

GameBGData:
    .db $64, $80, $20, $00, $00
    .db $02, $C0, '0'   ; should be at $2064
    .db $14, $C0, $00
    .db $02, $C0, '0'   ; should be at $207A
    .db $FF, $C0, $00
    .db $FF, $C0, $00
    .db $FF, $C0, $00
    .db $47, $C0, $00

    ; attribute data
    .db $08, $C0, $0F
    .db $30, $C0, $00
    .db $08, $C0, $0F

    ; 2nd nametable - Game Over
    .db $FF, $80, $24, $00, $01
    .db $0A, $C0, $01

    ; 8 tiles in
    .db $0B, $40    ; address $2509
    .db $C0, $C1, $C2, $C3, $C4, $C5, $C6, $C7
    .db $C8, $C9, $CA

    .db $15, $C0, $01

    .db $0B, $40    ; address $2529
    .db $D0, $D1, $D2, $D3, $D4, $D5, $D6, $D7
    .db $D8, $D9, $DA

    .db $18, $C0, $01

    .db $0B, $40    ; address $254C
    .db $E0, $E1, $E2, $E3, $E4, $E5, $E6, $E7
    .db $E8, $E9, $EA

    .db $15, $C0, $01

    .db $0B, $00, $25, $6C
    .db $F0, $F1, $F2, $F3, $F4, $F5, $F6, $F7
    .db $F8, $F9, $FA

    .db $FF, $80, $25, $77, $01
    .db $FF, $C0, $01
    .db $4B, $C0, $01

    ; attribute data
    .db $18, $80, $27, $C0, $55
    .db $28, $C0, $AA
    .db $00

SpriteData:
    ; Sprite Attribute Stuff
    ; %1000 0000    Flip horizontally
    ; %0100 0000    Flip vertically
    ; %0010 0000    Priority (0 front of BG; 1 behind BG)
    ; %0000 1100    Ignored
    ; %0000 0011    Palette

    ;   Y,   Idx, Attr, X
    .db $80, $01, %00000000, $80    ; Ball

    ; Player 1
    .db $80, $02, %00000000, $08    ; Paddle top
    .db $88, $04, %00000000, $08    ; Paddle middle A
    .db $8F, $04, %00000000, $08    ; Paddle middle A
    .db $94, $03, %00000000, $08    ; Paddle bottom

    ; Player 2
    .db $80, $02, %00000000, $F0    ; Paddle top
    .db $88, $04, %00000000, $F0    ; Paddle middle A
    .db $8F, $04, %00000000, $F0    ; Paddle middle A
    .db $94, $03, %00000000, $F0    ; Paddle bottom

DedBG_Table:
    .word DedBGOne
    .word DedBGTwo
    .word DedBGComp

; player 1
DedBGOne:
    .db $0A, $00, $25, $CB
    .db "PLAYER ONE"
    .db $04, $00, $25, $ED
    .db "WINS"
    .db $00

; player 2
DedBGTwo:
    .db $0A, $00, $25, $CB
    .db "PLAYER TWO"
    .db $04, $00, $25, $ED
    .db "WINS"
    .db $00

; computer player
DedBGComp:
    .db $0F, $00, $25, $C9
    .db "COMPUTER PLAYER"
    .db $04, $00, $25, $ED
    .db "WINS"
    .db $00
