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
    LDA $2002   ; read PPU status to reset high/low latch to high
    LDA #$3F
    STA $2006   ; Write high byte of $3F00 address
    LDA #$00
    STA $2006   ; Write low byte of $3F00 address

    ; Turn off PPU until the background is ready
    LDA #$00
    STA $2001

    ; 0 = BG not ready
    LDA #$00
    STA bg_ready

    ; --------
    ; Load up the background
    LDY #$20
    LDX #$00    ; Start at address $2000
tLoadBGTopLoop:
    LDA $2002   ; read PPU status to reset high/low latch
    TYA         ; Load Y into high byte
    STA $2006   ; write high byte of $YY00 address
    TXA         ; Load X into low byte
    STA $2006   ; write low byte of $YY00 address

tLoadBackgroundLoop:
    LDA #$01    ; sprite $24 is a blank sprite
    STA $2007   ; write to PPU
    INX

    ; Check for low byte of last row's last sprite ($23BF)
    CPX #$C0
    BNE tCheckIncHigh

    ; Check for the last row
    CPY #$23    ; compare Y to $23, which is the high byte
                ; of the last sprite on screen ($239F)
    BEQ tBGLoopDone

tCheckIncHigh:
    ; Increment high byte?
    cpx #$00
    beq tIncHighByte

    jmp tLoadBackgroundLoop

; Increment high byte and goto top
tIncHighByte
    ;ldx #$00
    iny
    jmp tLoadBGTopLoop

tBGLoopDone:
    lda #$20
    sta $2006
    lda #$AB
    sta $2006

    ldx #$60
    txa
titleDraw:
    sta $2007
    inx
    txa
    cmp #$6B
    bne titleDraw

    lda #$20
    sta $2006
    lda #$CB
    sta $2006

    ldx #$70
    txa
titleDraw2:
    sta $2007
    inx
    txa
    cmp #$7B
    bne titleDraw2

    ; draw box top
    lda #$20
    sta $2006
    lda #$8A
    sta $2006

    lda #$06    ; upper left corner
    sta $2007

    ; loop for line
    lda #$02
    ldx #$0B
titleBoxTop:
    sta $2007
    dex
    bne titleBoxTop

    lda #$07    ; upper right corner
    sta $2007

    ; draw box bottom
    lda #$20
    sta $2006
    lda #$EA
    sta $2006

    lda #$08
    sta $2007

    lda #$03
    ldx #$0B
titleBoxBottom:
    sta $2007
    dex
    bne titleBoxBottom

    lda #$09
    sta $2007

    ; Write "VS COMP" and "2 Player"
    lda #$22
    sta $2006
    lda #$0E
    sta $2006

    lda #'V'
    sta $2007

    lda #'S'
    sta $2007

    lda #' '
    sta $2007

    lda #'C'
    sta $2007

    lda #'O'
    sta $2007

    lda #'M'
    sta $2007

    lda #'P'
    sta $2007

    lda #$22
    sta $2006
    lda #$4E
    sta $2006

    lda #'2'
    sta $2007

    lda #' '
    sta $2007

    lda #'P'
    sta $2007

    lda #'L'
    sta $2007

    lda #'A'
    sta $2007

    lda #'Y'
    sta $2007

    lda #'E'
    sta $2007

    lda #'R'
    sta $2007

    ;lda #$23
    ;sta $2006
    ;lda #$C0
    ;sta $2006

    ldx #0
titleLoadAttrLoop:
    ;lda AttributeData, x
    lda #$55
    ;sta $2007
    sta CurrentAttributes, x
    inx
    cpx #64
    bne titleLoadAttrLoop

; Load sprites
    ldx #$00
titleSpriteLoop:
    lda titleSpriteData, X
    sta $0200, x
    inx
    cpx #$04         ; one sprite, four bytes per sprite
    bne titleSpriteLoop

    bit $2002
    lda #$00
    sta $2005
    sta $2005

    ; Turn PPU back on
    lda #%00011110
    sta $2001

    lda #1
    sta bg_ready
    rts

; -------------------------
; Load Gameplay gamestate
; -------------------------
gsGame:
    ; General INIT stuff
    lda #$00
    sta p1Score
    sta p2Score
    jsr ResetBall

    lda #ST_3
    sta start_count

    ; Turn off PPU until the background is ready
    lda #$00
    sta $2001

    ; 0 = BG not ready
    lda #$00
    sta bg_ready

    ; --------
    ; Load up the background
    ldy #$20
    ldx #$00    ; Start at address $2000
LoadBGTopLoop:
    lda $2002   ; read PPU status to reset high/low latch
    tya         ; Load Y into high byte
    sta $2006   ; write high byte of $YY00 address
    txa         ; Load X into low byte
    sta $2006   ; write low byte of $YY00 address

LoadBackgroundLoop:
    lda #$00    ; sprite $24 is a blank sprite
    sta $2007   ; write to PPU
    inx

    ; Check for low byte of last row's last sprite ($23BF)
    cpx #$C0
    bne CheckIncHigh

    ; Check for the last row
    cpy #$23    ; compare Y to $23, which is the high byte of the last sprite on screen ($239F)
    beq BGLoopDone

CheckIncHigh:
    ; Increment high byte?
    cpx #$00
    beq IncHighByte

    jmp LoadBackgroundLoop

; Increment high byte and goto top
IncHighByte
    ;ldx #$00
    iny
    jmp LoadBGTopLoop

BGLoopDone:
    ;rts

; Load Attributes
;LoadAttribute:
    ;lda $2002   ; read PPU status to reset high/low latch
    ;lda #$23
    ;sta $2006   ; write high byte of $23C0 address
    ;lda #$C0
    ;sta $2006   ; write low byte of $23C0 address

    ldx #$00
LoadAttrLoop:
    lda AttributeData, x
    ;lda #$00
    ;sta $2007
    sta CurrentAttributes, x
    inx
    cpx #64
    bne LoadAttrLoop

    lda dirty_flags
    ora #D_ATTRIBUTE
    sta dirty_flags

; Load sprites
    ldx #$00
SpriteLoop:
    lda SpriteData, X
    sta $0200, x
    inx
    cpx #36         ; one sprite, four bytes per sprite
    bne SpriteLoop

    ; Turn PPU back on
    lda #%00011110
    sta $2001

    lda #$01
    sta bg_ready
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
