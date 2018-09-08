    .inesprg 1      ; 1x 16KB bank of PRG code
    .ineschr 1      ; 1x 8KB bank of CHR data
    .inesmap 0      ; mapper 0 = NROM, no bank swapping
    .inesmir 1      ; background mirroring (ignore for now)

; TODO:
;   Game states (title, game, game over)
;       draw game over
;           reset to title on start pushed
;   pause on start pressed
;       write "PAUSE" on screen
;   improve collision detection
;   fix scores
;       counting above 9 or 19 is borked

    .include "ram.asm"

    ; Main code
    .bank 0
    .org $8000
RESET:
    sei         ; Disable IRQs
    cld         ; Disable decimal mode

    ldx #$40
    stx $4017   ; Disable APU frame IRQ

    ldx #$FF
    txs         ; Setup new stack

    inx         ; Now X = 0

    stx $2000   ; disable NMI
    stx $2001   ; disable rendering
    stx $4010   ; disable DMC IRQs

vblankwait1:   ; First wait for VBlank to make sure PPU is ready.
    BIT $2002   ; test this bit with ACC
    BPL vblankwait1 ; Branch on result plus

clrmem:
    lda #$00
    sta $0000, x
    sta $0100, x
    sta $0200, x
    sta $0300, x
    sta $0400, x
    sta $0500, x
    sta $0600, x
    sta $0700, x

    inx
    bne clrmem  ; loop if != 0

vblankwait2:    ; Second wait for vblank.  PPU is ready after this
    bit $2002
    bpl vblankwait2

    lda #%10010000
    sta $2000   ; enable NMI, sprites from pattern table 0


; Load the palettes
    ldx #$00
LoadPaletteLoop:
    lda PaletteData, x  ; Load data from address (PaletteData + X)
    sta CurrentPalette, x
    inx
    cpx #32    ; Each Palette is four bytes.  Eight Palettes total.  4 * 8 = 32 bytes.
    bne LoadPaletteLoop
    ;jsr UpdatePalette

    lda #GS_TITLE
    sta GameState
    jsr UpdateGameState

DoFrame:
    jsr ReadControllers
    lda GameState
    cmp #GS_GAME
    bcc frameGameOver
    beq frameGameplay

frameTitle:
    jsr UpdateTitle
    jmp frameEnd

frameGameplay:
    lda GamePaused
    bne framePaused

    jsr UpdatePlayers
    jsr UpdateBall
    jmp frameEnd

framePaused:
    jsr CheckPause
    jmp frameEnd

frameGameOver:
    jmp frameEnd

frameEnd:
    lda GSUpdateNeeded
    beq WaitFrame
    jsr UpdateGameState

; Wait for next VBlank to be done
WaitFrame:
    INC sleeping
WaitLoop:
    lda sleeping
    bne WaitLoop
    jmp DoFrame

CheckPause:
    lda #BUTTON_START
    sta btnPressedMask
    jsr ButtonPressedP1
    bne uPauseToggle
    rts

uPauseToggle:
    lda GamePaused
    beq uSetPause

    lda #0
    sta GamePaused

    ldx #$00
uUnPauseLoop:
    lda PaletteData, x
    sta CurrentPalette, x
    inx
    cpx #32
    bne uUnPauseLoop
    rts

uSetPause:
    lda #1
    sta GamePaused

    ldx #$00
uSetPauseLoop:
    lda PausedPalette, x
    sta CurrentPalette, x
    inx
    cpx #32
    bne uSetPauseLoop
    rts

; ---------------------------
; Get updates for title screen
; ---------------------------
UpdateTitle:
    jsr titleSelect

    lda #BUTTON_START
    sta btnPressedMask
    jsr ButtonPressedP1
    bne utitle_stc
    rts

; start pressed this frame
utitle_stc:
    lda #GS_GAME
    sta GameState
    lda #1
    sta GSUpdateNeeded
    rts

titleSelect:
    ; prev frame = 0
    ; this frame = 1
    ; do thing
    lda #BUTTON_SELECT
    sta btnPressedMask
    jsr ButtonPressedP1
    bne utitle_c
    rts

; button was pressed
utitle_c:
    lda TitleSelected
    beq utitle_sel_2p

    ; vs comp
    lda #$00
    sta TitleSelected
    lda #$7F
    sta TitleCursor
    rts

; 2 player game mode selected
utitle_sel_2p:
    ; 2 player
    lda #$01
    sta TitleSelected
    lda #$8F
    sta TitleCursor
    rts

; vblank triggered
NMI:
    ; Backup registers
    PHA
    TXA
    PHA
    TYA
    PHA

    lda $2002   ; read PPU status to reset high/low latch to high
    ; Transfer sprite data
    LDA #$00
    STA $2003
    LDA #$02
    STA $4014

    ; load the palette
    lda #$3F
    sta $2006   ; Write high byte of $3F00 address
    lda #$00
    sta $2006   ; Write low byte of $3F00 address

    ldx #0
uPaletteLoop:
    lda CurrentPalette, x
    sta $2007
    inx
    cpx #32    ; Each Palette is four bytes.  Eight Palettes total.  4 * 8 = 32 bytes.
    bne uPaletteLoop

    LDA bg_ready
    BEQ NMI_END

    jsr UpdateBackground
    jsr DrawScores
    jsr UpdateAttributeData

NMI_END:
    ; Reset scroll
    bit $2002
    lda #$00
    sta $2005
    sta $2005

    LDA #0
    STA sleeping

    ; Restore registers
    pla
    tay
    pla
    tax
    pla

    rti

UpdateAttributeData:
    lda dirty_flags
    and #D_ATTRIBUTE
    bne uattr_Ok
    rts

uattr_Ok:
    ; turn off dirty attribute flag
    lda dirty_flags
    and #%11111110
    sta dirty_flags

    bit $2002
    lda #$23
    sta $2006
    lda #$C0
    sta $2006

    ldx #0
uAttrDataLoop:
    lda CurrentAttributes, x
    sta $2007
    inx
    cpx #64
    bne uAttrDataLoop
    rts

UpdateBackground:
    ; start at the beginning of queue
    ; low byte first
    lda #$00
    sta dcQueuePointer

    lda #$03
    sta dcQueuePointer+1

    bit $2002

ubOuterLoop:
    ldy #0
    ; packet length
    lda [dcQueuePointer], Y
    sta dcPacketLength

    bne ubContinue
    rts

ubContinue:
    ; PPU Addresses
    iny
    lda [dcQueuePointer], Y
    sta $2006

    iny
    lda [dcQueuePointer], Y
    sta $2006

    ; flags
    iny
    lda [dcQueuePointer], Y
    sta dcFlags
    bit dcFlags
    bmi ubRunLength

ubDataLoop:
   iny
   lda [dcQueuePointer], Y
   sta $2007
   dec dcPacketLength
   bne ubDataLoop
   ; TODO update dcQueuePointer
   tya
   clc
   adc #4
   adc dcQueuePointer
   sta dcQueuePointer

   lda dcQueuePointer+1
   adc #0
   sta dcQueuePointer+1

   jmp ubOuterLoop

ubRunLength:
    iny
    ldx dcPacketLength
    lda [dcQueuePointer], Y

ubRunLengthLoop:
    sta $2007
    dex
    bne ubRunLengthLoop
    ; TODO updateQueuePointer
    lda dcQueuePointer
    clc
    adc #5
    sta dcQueuePointer

    lda dcQueuePointer+1
    adc #0
    sta dcQueuePointer+1
    jmp ubOuterLoop

DrawScores:
    lda GameState
    cmp #GS_TITLE
    bne draw_ok
    rts

draw_ok:
; Draw Scores
; P1 $2064
; P2 $207A
    LDA #$20
    STA $2006
    LDA #$64
    STA $2006

    LDA p1Score
    cmp #10
    bcc draw_p1_zero

    ; draw leading '1'
    LDA #'1'
    STA $2007
    jmp draw_p1_digit

draw_p1_zero:
    ; draw leading '0'
    LDA #'0'
    STA $2007

draw_p1_digit:
    LDA p1Score
    CLC
    ADC #$30
    STA $2007

; draw p2
    LDA #$20
    STA $2006
    LDA #$7A
    STA $2006

    LDA p2Score
    cmp #10
    bcc draw_p2_zero

    ; draw leading '1'
    LDA #'1'
    STA $2007
    jmp draw_p2_digit

draw_p2_zero:
    ; draw leading '0'
    LDA #'0'
    STA $2007

draw_p2_digit:
    LDA p2Score
    CLC
    ADC #$30
    STA $2007
    rts


UpdatePlayers:
    jsr CheckPause

    ; Player 1
    LDA #BUTTON_UP
    BIT controller1
    BEQ p1BtnDown   ; branch on not pressed

    ;LDA P1Top
    LDA P1_TOP
    CMP #WALL_TOP_PADDLE
    BCC p1BtnDown   ; branch when at top

    jsr P1MoveUp

p1BtnDown:
    LDA #BUTTON_DOWN
    BIT controller1
    BEQ p1BtnDone   ; branch on not pressed

    ;LDA P1Top
    LDA P1_TOP
    CMP #WALL_BOTTOM_PADDLE
    BCS p1BtnDone   ; branch when at top

    jsr P1MoveDown

p1BtnDone:
    ; Player 2
    LDA #BUTTON_UP
    BIT controller2
    BEQ p2BtnDown   ; branch on not pressed

    ;LDA P1Top
    LDA P2_TOP
    CMP #WALL_TOP_PADDLE
    BCC p2BtnDown   ; branch when at top

    jsr P2MoveUp

p2BtnDown:
    LDA #BUTTON_DOWN
    BIT controller2
    BEQ p2BtnDone   ; branch on not pressed

    ;LDA P1Top
    LDA P2_TOP
    CMP #WALL_BOTTOM_PADDLE
    BCS p2BtnDone   ; branch when at top

    jsr P2MoveDown

p2BtnDone:
    RTS

; Move player's paddle
P1MoveUp:
    SEC
    SBC #PADDLE_SPEED
    ;STA $0204
    STA P1_TOP

    ;LDA $0208
    LDA P1_TOP+4
    SEC
    SBC #PADDLE_SPEED
    ;STA $0208
    STA P1_TOP+4

    LDA $020C
    SEC
    SBC #PADDLE_SPEED
    STA $020C

    LDA $0210
    SEC
    SBC #PADDLE_SPEED
    STA $0210
    rts

P1MoveDown:
    CLC
    ADC #PADDLE_SPEED
    STA $0204

    LDA $0208
    CLC
    ADC #PADDLE_SPEED
    STA $0208

    LDA $020C
    CLC
    ADC #PADDLE_SPEED
    STA $020C

    LDA $0210
    CLC
    ADC #PADDLE_SPEED
    STA $0210
    rts

; Move player 2's paddle
P2MoveUp:
    SEC
    SBC #PADDLE_SPEED
    STA $0214

    LDA $0218
    SEC
    SBC #PADDLE_SPEED
    STA $0218

    LDA $021C
    SEC
    SBC #PADDLE_SPEED
    STA $021C

    LDA $0220
    SEC
    SBC #PADDLE_SPEED
    STA $0220
    rts

P2MoveDown:
    CLC
    ADC #PADDLE_SPEED
    STA $0214

    LDA $0218
    CLC
    ADC #PADDLE_SPEED
    STA $0218

    LDA $021C
    CLC
    ADC #PADDLE_SPEED
    STA $021C

    LDA $0220
    CLC
    ADC #PADDLE_SPEED
    STA $0220
    rts

; Was a button pressed this frame?
ButtonPressedP1:
    lda controller1
    and btnPressedMask
    sta controllerTmp

    lda controller1Old
    and btnPressedMask

    cmp controllerTmp
    bne btnPress_stb

    ; no button change
    rts

btnPress_stb:
    ; button released
    lda controllerTmp
    bne btnPress_stc
    rts

btnPress_stc:
    ; button pressed
    lda #1
    rts

    .include "ball.asm"
    .include "countdown.asm"
    ;.include "countdown_lookup.asm"
    .include "input.asm"
    .include "states.asm"

; --------
    .bank 1
    .org $E000

Countdown_Table:
    .word cd_reset-1
    .word cd_00-1
    .word cd_01-1
    .word cd_02-1
    .word cd_03-1

GameState_Table:
    .word gsDed-1
    .word gsGame-1
    .word gsTitle-1

CountdownData_Table:
    .word CountdownData
    .word CountdownData_start
    .word CountdownData_01
    .word CountdownData_02
    .word CountdownData_03

CountdownData:
    .db $05, $20, $AE, $80, $00, $00

CountdownData_start:
    .db $06, $20, $AE, $00, 'S', 'T', 'A', 'R', 'T', '!', $00

CountdownData_01:
    .db $02, $20, $AE, $00, '0', '1', $00

CountdownData_02:
    .db $02, $20, $AE, $00, '0', '2', $00

CountdownData_03:
    .db $02, $20, $AE, $00, '0', '3', $00

PaletteData:
    .db $0F,$34,$14,$0F, $0F,$15,$0F,$05, $0F,$0A,$0A,$0A, $0F,$11,$11,$11
    .db $0F,$10,$00,$30, $0F,$05,$05,$05, $0F,$0A,$0A,$0A, $0F,$11,$11,$11

PausedPalette:
    .db $0F,$14,$04,$0F, $0F,$15,$0F,$05, $0F,$0A,$0A,$0A, $0F,$01,$01,$01
    .db $0F,$00,$2D,$10, $0F,$05,$05,$05, $0F,$0A,$0A,$0A, $0F,$11,$11,$11

AttributeData:
    .db $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F
    .db $00, $00, $00, $00, $00, $00, $00, $00

    .db $00, $00, $00, $00, $00, $00, $00, $00
    .db $00, $00, $00, $00, $00, $00, $00, $00

    .db $00, $00, $00, $00, $00, $00, $00, $00
    .db $00, $00, $00, $00, $00, $00, $00, $00

    .db $00, $00, $00, $00, $00, $00, $00, $00
    .db $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F

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

titleSpriteData:
    .db $7F, $05, $00, $66

; Vectors (interupts?)
    .org $FFFA  ; first of three vectors starts here
    .dw NMI     ; When an NMI happens (start of VBlank) the processor will jump
                ; to the label NMI:

    .dw RESET   ; When the prossor first turns on or is reset, it will jump to
                ; the label RESET:

    .dw 0       ; external interupt IRQ.  ignored for now.

    ; CHR data
    .bank 2
    .org $0000
    .incbin "pong.chr"
