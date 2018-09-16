;
; Gamestate management
;

; ---------------------------
; Gamestate change dispatch
; subroutine
; ---------------------------
UpdateGameState:
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

    ;lda #0
    ;sta $2000

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
    rts

; -------------------------
; Load Game Over gamestate
; -------------------------
gsDed:
    ; 1 - write "GAME OVER" text
    ; 2 - deterimine winner
    ; 3 - write winner to screen
    ; 4 - (not here) wait for start button -> title
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
    .db $0B, $40, $60, $61, $62, $63, $64
    .db $65, $66, $67, $68, $69, $6A

    .db $15, $C0, $01   ; black until 2nd row of logo

    ; logo bottom row
    .db $0B, $40, $70, $71, $72, $73, $74
    .db $75, $76, $77, $78, $79, $7A

    .db $14, $C0, $01   ; blank until start of bottom box
    .db $01, $40, $08   ; left corner
    .db $0B, $C0, $03   ; bottom line
    .db $01, $40, $09   ; right corner

    ; blank until menu start
    .db $F6, $C0, $01
    ;.db $17, $C0, $01

    .db $07, $40, 'V', 'S', ' ', 'C', 'O', 'M', 'P'
    .db $39, $C0, $01
    .db $08, $40, '2', ' ', 'P', 'L', 'A', 'Y', 'E', 'R'
    .db $FF, $C0, $01
    .db $6C, $C0, $01

    ; attribute data
    .db $40, $C0, $55
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

    ; 2nd nametable 
    .db $02, $00, $24, $64, '0', '0'   ; should be at $2064
    .db $02, $00, $24, $7A, '0', '0'   ; should be at $2064

    .db $01, $00, $25, $8C, $06     ; left corner
    .db $06, $C0, $02       ; top line
    .db $01, $40, $07       ; right corner

    .db $01, $00, $25, $AC, $04
    .db $06, $40, 'P', 'A', 'U', 'S', 'E', 'D'
    ;.db $06, $C0, $01       ; box bg
    .db $01, $40, $05

    .db $01, $00, $25, $CC, $04
    .db $06, $C0, $01       ; box bg
    .db $01, $40, $05

    .db $01, $00, $25, $EC, $08     ; left corner
    .db $06, $C0, $03       ; bottom line
    .db $01, $40, $09       ; right corner

    ; attribute data
    .db $08, $80, $27, $C0, $0F
    .db $02, $80, $27, $DB, $55
    .db $08, $80, $27, $F8, $0F
    .db $00

    ; attribute data
    ;.db $08, $C0, $0F
    ;.db $30, $C0, $00
    ;.db $08, $C0, $0F
    ;.db $00

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

