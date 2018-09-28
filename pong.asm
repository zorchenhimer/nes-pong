    .inesprg 1      ; 1x 16KB bank of PRG code
    .ineschr 1      ; 1x 8KB bank of CHR data
    .inesmap 0      ; mapper 0 = NROM, no bank swapping
    .inesmir 1      ; background mirroring (ignore for now)

; TODO:
;   improve collision detection
;       figure out the math for this
;   sounds
;       menu selection
;       ball bounce
;       game over
;       pause

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

    lda #$00
    sta FrameUpdates

    lda #%10010000
    sta $2000   ; enable NMI, sprites from pattern table 0

    jsr Sound_Init

; Load the palettes
    ldx #$00
LoadPaletteLoop:
    lda PaletteData, x  ; Load data from address (PaletteData + X)
    sta PaletteRAM, x
    inx
    cpx #32    ; Each Palette is four bytes.  Eight Palettes total.  4 * 8 = 32 bytes.
    bne LoadPaletteLoop
    ;jsr UpdatePalette

    lda #GS_TITLE
    sta GameState
    jsr UpdateGameState

    lda #$FF
    sta title_sound

    .include "frame_loop.asm"
    .include "sound_engine.asm"

CheckPause:
    lda #BUTTON_START
    sta btnPressedMask
    jsr ButtonPressedP1
    bne uPauseToggle
    rts

uPauseToggle:
    lda #$01
    sta sfx_id
    jsr Sound_Load

    lda GamePaused
    beq uSetPause

    lda #0
    sta GamePaused
    sta PauseOn

    lda #1
    sta PauseOff

    ldx #$00
uUnPauseLoop:
    lda PaletteData, x
    sta PaletteRAM, x
    inx
    cpx #32
    bne uUnPauseLoop

    lda PauseTable+2
    sta bgPointer

    lda PauseTable+3
    sta bgPointer+1

    jsr LoadBackgroundData

    lda #$FF
    sta FrameUpdates
    rts

uSetPause:
    lda #1
    sta GamePaused
    sta PauseOn
    lda #0
    sta PauseOff

    ldx #$00
uSetPauseLoop:
    lda PausedPalette, x
    sta PaletteRAM, x
    inx
    cpx #32
    bne uSetPauseLoop

    lda PauseTable
    sta bgPointer

    lda PauseTable+1
    sta bgPointer+1

    jsr LoadBackgroundData

    lda #$FF
    sta FrameUpdates
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
    lda TitleSelected
    cmp #$02
    bne titleStartGame

    ; do sound stuff
    inc title_sound
    lda title_sound
    cmp #$04
    bcc .nowrap
    lda #0
    sta title_sound
.nowrap:

    lda title_sound
    sta sfx_id
    jmp Sound_Load
    rts

titleStartGame:
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
    inc TitleSelected
    lda TitleSelected
    cmp #$03
    bne utitleSprite

    lda #0
    sta TitleSelected

utitleSprite:
    tay
    lda TitleSpritePositions, y
    sta TitleCursor
    rts

TitleSpritePositions:
    .db $7F, $8F, $9F

; vblank triggered
NMI:
    ; Backup registers
    pha
    txa
    pha
    tya
    pha

    ; Don't do anything here if we're still
    ; drawing to the background in
    ; UpdateGameState
    lda SkipNMI
    bne nmi_Skip

    ; reset the background queue pointer
    lda #$00
    sta bgQueue
    lda #$04
    sta bgQueue+1

    lda GamePaused
    bne nmi_SkipSprites
    lda $2002   ; read PPU status to reset high/low latch to high
    ; Transfer sprite data
    lda #$00
    sta $2003
    lda #$02
    sta $4014

nmi_SkipSprites:

    ;bit FrameUpdates
    ;bmi nmi_skipPalette

    ; load the palette
    lda #$3F
    sta $2006   ; Write high byte of $3F00 address
    lda #$00
    sta $2006   ; Write low byte of $3F00 address

    ldx #0
uPaletteLoop:
    lda PaletteRAM, x
    sta $2007
    inx
    cpx #32    ; Each Palette is four bytes.  Eight Palettes total.  4 * 8 = 32 bytes.
    bne uPaletteLoop

    bit FrameUpdates
    bvc NMI_END
    jsr UpdateBackground

NMI_END:
    lda #0
    sta FrameUpdates
    sta bgUpdateFlags
    sta PauseOn
    sta PauseOff

    bit $2002
    lda #0
    sta $2005
    sta $2005

    lda GameState
    cmp #GS_DED
    beq nmi_DED

    lda #%10010000
    sta $2000
    jmp nmi_ScrollDone

nmi_DED
    ; bit 0 here adds 256 to X scroll
    lda #%10010001
    ;lda #%10010000
    sta $2000

nmi_ScrollDone:
    ; bits 0 and 1 are scroll high bits, kinda
    lda #0
    sta sleeping

nmi_Skip:
    jsr Sound_PlayFrame
    ; Restore registers
    pla
    tay
    pla
    tax
    pla

    rti

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

    .include "background.asm"
    .include "ball.asm"
    ;.include "countdown.asm"
    .include "countdown_lookup.asm"
    .include "input.asm"
    .include "scores.asm"
    .include "states.asm"
    .include "players.asm"

IRQ:
    ; just sit here... in theory
    jmp IRQ

; --------
    .bank 1
    .org $E000

PaletteData:
    .db $0F,$34,$14,$0F, $0F,$15,$0F,$05, $0F,$0A,$0A,$0A, $0F,$11,$11,$11
    .db $0F,$10,$00,$30, $0F,$05,$05,$05, $0F,$0A,$0A,$0A, $0F,$11,$11,$11

PausedPalette:
    .db $0F,$14,$04,$0F, $0F,$15,$0F,$05, $0F,$0A,$0A,$0A, $0F,$01,$01,$01
    .db $0F,$00,$2D,$10, $0F,$05,$05,$05, $0F,$0A,$0A,$0A, $0F,$11,$11,$11

PauseTable:
    .word PausedAttributes
    .word UnPausedAttributes

PausedAttributes:
    ; "PAUSED" box
    ;.db $01, $00, $21, $8C, $06     ; left corner
    ;.db $06, $C0, $02       ; top line
    ;.db $01, $40, $07       ; right corner
    .db $08, $00, $21, $8C, $06, $02, $02, $02, $02, $02, $02, $07

    ;.db $01, $00, $21, $AC, $04
    ;.db $06, $C0, $01       ; box bg
    ;.db $01, $40, $05
    .db $08, $00, $21, $AC, $04
    .db "PAUSED"
    .db $05

    ;.db $01, $00, $21, $CC, $04
    ;.db $06, $C0, $01       ; box bg
    ;.db $01, $40, $05
    .db $08, $00, $21, $CC, $04, $01, $01, $01, $01, $01, $01, $05

    ;.db $01, $00, $21, $EC, $08     ; left corner
    ;.db $06, $C0, $02       ; top line
    ;.db $01, $40, $09       ; right corner
    .db $08, $00, $21, $EC, $08, $03, $03, $03, $03, $03, $03, $09

    ; attribute data
    .db $02, $80, $23, $DB, $55
    .db $00

UnPausedAttributes:
    ; clear "PAUSED" box
    .db $08, $80, $21, $8C, $00 ; top row
    .db $08, $80, $21, $AC, $00
    .db $08, $80, $21, $CC, $00
    .db $08, $80, $21, $EC, $00

    ; attribute data
    .db $02, $80, $23, $DB, $00
    .db $00
    ;.db $08, $80, $0F
    ;.db $30, $C0, $00
    ;.db $08, $C0, $0F
    ;.db $00

    .include "note_table.i"

; Vectors (interupts?)
    .org $FFFA  ; first of three vectors starts here
    .dw NMI     ; When an NMI happens (start of VBlank) the processor will jump
                ; to the label NMI:

    .dw RESET   ; When the prossor first turns on or is reset, it will jump to
                ; the label RESET:

    .dw IRQ       ; external interupt IRQ.  ignored for now.

    ; CHR data
    .bank 2
    .org $0000
    .incbin "pong.chr"
