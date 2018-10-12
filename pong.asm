    .include "nes2header.inc"

nes2mapper 0
nes2prg 1 * 16 * 1024
nes2chr 1 * 8 * 1024
nes2mirror 'V'
.ifdef PAL
nes2tv 'P'
.else
nes2tv 'N'
.endif
nes2end


    .include "ram.asm"

.segment "VECTORS"
    .word NMI
    .word RESET
    .word IRQ

.segment "TILES"
    .incbin "pong.chr"

.segment "PAGE0"
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
    lda #%11010000
    cmp controller1
    bne @selectionCheck

    lda #GS_CREDITS
    sta GameState
    jmp Credits_Init

@selectionCheck:
    lda TitleSelected
    cmp #$02
    bne titleStartGame


    ; "Sound Test" menu item.  Loop through all the SFX.
    inc title_sound
    lda title_sound
    cmp #$08
    bcc @nowrap
    lda #0
    sta title_sound
@nowrap:

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

; select button was pressed
utitle_c:

    ; SFX for menu item change
    lda #$07
    sta sfx_id
    jsr Sound_Load

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
    .byte $7F, $8F, $9F

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
    lda #<bgBuffer
    sta bgQueue
    lda #>bgBuffer
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

nmi_DED:
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

    .include "credits.asm"

IRQ:
    ; just sit here... in theory
    jmp IRQ

; --------
    ;.bank 1
    ;.org $E000

;.segment "PAGE1"
PaletteData:
    .byte $0F,$34,$14,$0F, $0F,$15,$0F,$05, $0F,$15,$0F,$0F, $0F,$11,$11,$11
    .byte $0F,$10,$00,$30, $0F,$05,$05,$05, $0F,$0A,$0A,$0A, $0F,$11,$11,$11

PausedPalette:
    .byte $0F,$14,$04,$0F, $0F,$15,$0F,$05, $0F,$0A,$0A,$0A, $0F,$01,$01,$01
    .byte $0F,$00,$2D,$10, $0F,$05,$05,$05, $0F,$0A,$0A,$0A, $0F,$11,$11,$11

CreditsPalette:
    .byte $0F,$30,$0F,$0F, $0F,$0F,$0F,$13, $0F,$0A,$1A,$0F, $0F,$11,$21,$0F
    .byte $0F,$30,$13,$0F, $0F,$05,$15,$0F, $0F,$0A,$1A,$0F, $0F,$11,$21,$0F

PauseTable:
    .word PausedAttributes
    .word UnPausedAttributes

PausedAttributes:
    ; "PAUSED" box
    ;.byte $01, $00, $21, $8C, $06     ; left corner
    ;.byte $06, $C0, $02       ; top line
    ;.byte $01, $40, $07       ; right corner
    .byte $08, $00, $21, $8C, $06, $02, $02, $02, $02, $02, $02, $07

    ;.byte $01, $00, $21, $AC, $04
    ;.byte $06, $C0, $01       ; box bg
    ;.byte $01, $40, $05
    .byte $08, $00, $21, $AC, $04
    ;.byte "PAUSED"
    .byte $24, $25, $26, $27, $28, $29
    .byte $05

    ;.byte $01, $00, $21, $CC, $04
    ;.byte $06, $C0, $01       ; box bg
    ;.byte $01, $40, $05
    .byte $08, $00, $21, $CC, $04, $01, $01, $01, $01, $01, $01, $05

    ;.byte $01, $00, $21, $EC, $08     ; left corner
    ;.byte $06, $C0, $02       ; top line
    ;.byte $01, $40, $09       ; right corner
    .byte $08, $00, $21, $EC, $08, $03, $03, $03, $03, $03, $03, $09

    ; attribute data
    .byte $02, $80, $23, $DB, $55
    .byte $00

UnPausedAttributes:
    ; clear "PAUSED" box
    .byte $08, $80, $21, $8C, $00 ; top row
    .byte $08, $80, $21, $AC, $00
    .byte $08, $80, $21, $CC, $00
    .byte $08, $80, $21, $EC, $00

    ; attribute data
    .byte $02, $80, $23, $DB, $00
    .byte $00
    ;.byte $08, $80, $0F
    ;.byte $30, $C0, $00
    ;.byte $08, $C0, $0F
    ;.byte $00


    .ifdef PAL
    .include "note_table_pal.i"
    .else
    .include "note_table.i"
    .endif
