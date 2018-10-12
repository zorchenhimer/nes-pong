Credits_Init:
    ; - Clear backgound for both nametables
    ; - Update palettes

    jsr ClearSprites

    ;lda #1
    ;sta idx_palette
    ;jsr LoadPalettes
    jsr credits_LoadPalette

    lda #$00
    sta $2001

    lda #$20
    sta $2006
    lda #$00
    sta $2006
    jsr credits_ClearNametable

    ;lda #$28
    ;sta $2006
    ;lda #$00
    ;sta $2006
    ;jsr credits_ClearNametable

    jsr credits_Header
    jsr credits_DrawNames

    ; reset scroll
    bit $2001
    lda #$00
    sta $2005
    sta $2005

    lda #%00011110
    sta $2001
    rts

credits_LoadPalette:
    ldx #0
@loop:
    lda CreditsPalette, x
    sta PaletteRAM, x
    inx
    cpx #32
    bne @loop
    rts

credits_ClearNametable:
    ldx #0
    ldy #0
    lda #$40
@loop2:
    sta $2007
    inx
    cpx #$20
    bne @loop2

    iny
    ldx #0
    cpy #$1E
    bne @loop2

    lda #$55
    sta $2007
    sta $2007

    lda #$11
    sta $2007

    ldx #6
    lda #$00
@loopAttr1:
    stx $2007
    dex
    bne @loopAttr1

    lda #$55
    sta $2007
    lda #$11
    sta $2007

    ldx #52
    lda #$00
@loopAttr:
    sta $2007
    dex
    bne @loopAttr
    rts

credits_Header:
    ; First row of twitch logo
    bit $2002
    lda #$20
    sta $2006
    lda #$46
    sta $2006

    lda #$10
    sta $2007
    lda #$11
    sta $2007
    lda #$12
    sta $2007

    ; Second row
    lda #$20
    sta $2006
    lda #$66
    sta $2006

    lda #$13
    sta $2007
    lda #$14
    sta $2007
    lda #$15
    sta $2007

    ; Third row
    lda #$20
    sta $2006
    lda #$86
    sta $2006

    lda #$16
    sta $2007
    lda #$17
    sta $2007
    lda #$18
    sta $2007

    ; top text: "twitch.tv/"
    lda #$20
    sta $2006
    lda #$4A
    sta $2006

    ;ldx #0
    ldy #$0A
@loop1:
    ;lda credits_header01, x
    sty $2007
    iny
    cpy #$10
    bne @loop1

    ; top half: "zorchenhimer"
    lda #$20
    sta $2006
    lda #$6A
    sta $2006

    ldx #0
    ldy #$80
@loop2:
    sty $2007
    iny
    cpy #$8F
    bne @loop2

    ; Bottom half: "Zorchenhimer"
    lda #$20
    sta $2006
    lda #$8A
    sta $2006

    ldx #0
    ldy #$90
@loop3:
    sty $2007
    iny
    cpy #$9F
    bne @loop3

    lda #$20
    sta $2006
    lda #$CA
    sta $2006

    ldx #0
@loop4:
    lda credits_header03, x
    sta $2007
    inx
    cpx #10
    bne @loop4
    rts

credits_DrawNames:
    ; load up name metadata
    lda credits_metadata
    lsr a   ; divide by two
    sta cr_nameCount

    lda #0
    ;sta cr_nameIdx
    sta cr_nameCurrent

    lda #$21
    sta cr_ppuAddr

    lda #$2A
    sta cr_ppuAddr+1

; table loop
@outer:
    bit $2002
    lda cr_ppuAddr
    sta $2006
    lda cr_ppuAddr+1
    sta $2006

    lda cr_nameCurrent
    asl a
    tax

    lda credits_name_table, x
    sta cr_nameAddress

    lda credits_name_table+1, x
    sta cr_nameAddress+1

; name loop
    ldy #0
    lda (cr_nameAddress), y
    sta cr_nameLength
    inc cr_nameLength   ; to fix an off-by-one error
    iny

@inner:
    lda (cr_nameAddress), y
    sta $2007
    iny
    cpy cr_nameLength
    bne @inner

    ; move on to the next name
    dec cr_nameCount
    bne @next
    rts

@next:
    inc cr_nameCurrent
    lda cr_ppuAddr+1
    clc
    adc #64
    sta cr_ppuAddr+1

    lda cr_ppuAddr
    adc #0
    sta cr_ppuAddr
    jmp @outer

credits_header03:
    .byte "THANK YOU!"

    .include "credits_data.i"
