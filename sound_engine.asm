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
    sta sfx_playing
    sta sfx_index
    sta sfx_frame

    sta sfx_address
    sta sfx_address+1
    rts

Sound_Disable:
    lda #$00
    sta $4015
    lda #$01
    sta sfx_disabled
    rts

Sound_Load:
    lda sfx_id
    asl a
    tay

    lda table_sfx, y
    sta sfx_address

    lda table_sfx+1, y
    sta sfx_address+1

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
    cmp #$06
    bne .done

    ldy sfx_index
    lda [sfx_address], y

    ; $FE = "no change" or just keep playing the last note.
    cmp #$FE
    beq .cont

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

.cont
    inc sfx_index
    lda #0
    sta sfx_frame

.done
    rts

table_sfx:
    .dw sfx_test,       sfx_pause,      sfx_bounce,         sfx_score
    .dw sfx_gameOver,   sfx_countdown,  sfx_countdownStart, sfx_title

sfx_test:   ; sound test
    ;    $0F,$11
    .byte C3, D3, Ds3, G3, C4, D4, Ds4, G4
    .byte C5, D5, Ds5, G5, C6, D6, Ds6, G6, C7, $FF     ;Cm/9

sfx_pause:
    ;    $3F,$3A
    .byte C7, G6, C7, G6, $FF

sfx_bounce:
    .byte C2, $FF

sfx_score:
    .byte C4, D4, Ds4, $FF

sfx_gameOver:
    .byte C5, $FE, D5, $FE, Ds5, $FE, $FF

sfx_countdown:
    .byte D5, $FE, $FF

sfx_countdownStart:
    .byte G5, $FE, $FE, $FE, $FF

sfx_title:
    .byte C3, $FF
