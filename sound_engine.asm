Sound_Init:
    lda #$0F
    sta $4015

    lda #$30
    sta $4000   ; set square 1 volume to 0
    sta $4004   ; set square 2 volume to 0
    sta $400C   ; set noise volume to 0

    ; silence triangle
    lda #$80
    sta $4008

    ; clear flags
    lda #0
    sta sfx_disabled
    sta sfx_frame
    sta sfx_playing
    sta sfx_index
    rts

Sound_Disable:
    lda #$00
    sta $4015
    lda #$01
    sta sfx_disabled
    rts

Sound_Load:
    ; set playing flag
    lda #$01
    sta sfx_playing

    ; reset index and counter
    lda #$00
    sta sfx_index
    sta sfx_frame
    rts

Sound_PlayFrame:
    ; don't advance if disabled
    lda sfx_disabled
    bne .done

    ; don't advance if not playing
    lda sfx_playing
    beq .done

    ; update one every X frames
    inc sfx_frame
    lda sfx_frame
    cmp #$08        ; TODO: make this a constant?
    bne .done

    ldy sfx_index
    lda sfx_data, y

    ; data is $FF terminated
    cmp #$FF
    bne .note

    ; stop sound and return
    lda #$30
    sta $4000

    lda #$00
    sta sfx_playing
    sta sfx_frame
    rts

.note
    ; get index (mult by two; table is a list of words)
    asl a
    tay

    ; low byte
    lda note_table, y
    sta $4002

    ; high byte
    lda note_table+1, y
    sta $4003

    ; ducy cycle 01; volume F
    lda #$7F
    sta $4000

    ; set negate flag so low squares aren't silenced
    lda #$08
    sta $4001

    inc sfx_index
    lda #0
    sta sfx_frame

.done
    rts

sfx_data:
    .byte C3, D3, Ds3, G3, C4, D4, Ds4, G4
    .byte C5, D5, Ds5, G5, C6, D6, Ds6, G6, C7, $FF     ;Cm/9
