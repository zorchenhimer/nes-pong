; Writes to ram
DoCountdown:
    dec start_ticks
    bne cdNoChange

    lda start_count
    asl a
    tax
    lda CountdownData_Table, x
    sta bgPointer

    lda CountdownData_Table+1, x
    sta bgPointer+1

    lda #$00
    sta bgUpdateFlags

    jsr LoadBackgroundData

    ; Figure out which sfx to play
    lda start_count
    cmp #$02
    beq @sndStart
    bcc @sndEnd ; clear screen.  don't play sfx

    ; "03" doesn't get a sfx.  it'll override the scoring sfx.
    cmp #$05
    beq @sndEnd

    ; Play sfx for "02" and "01"
    lda #$05
    sta sfx_id
    jsr Sound_Load
    jmp @sndEnd

@sndStart:
    ; play sfx for "START"
    lda #$06
    sta sfx_id
    jsr Sound_Load

@sndEnd:
    lda FrameUpdates
    ora #%01000000
    sta FrameUpdates

    lda start_count
    beq cdNoChange

    lda #ST_LENGTH
    sta start_ticks
    dec start_count

cdNoChange:
    rts

; Data
CountdownData_Table:
    .word $FFFF
    .word CountdownData
    .word CountdownData_start
    .word CountdownData_01
    .word CountdownData_02
    .word CountdownData_03

CountdownData:
    .byte $06, $80, $20, $AE, $00, $00

CountdownData_start:
    .byte $06, $00, $20, $AE, 'S', 'T', 'A', 'R', 'T', '!', $00

CountdownData_01:
    .byte $02, $00, $20, $AE, '0', '1', $00

CountdownData_02:
    .byte $02, $00, $20, $AE, '0', '2', $00

CountdownData_03:
    .byte $02, $00, $20, $AE, '0', '3', $00

