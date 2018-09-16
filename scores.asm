UpdateScores:
    lda p1Score
    sta score_ones
    jsr ScoreMath

    ldy #$00

    lda #$02
    sta [bgQueue], y

    iny
    lda #$00
    sta [bgQueue], y

    iny
    lda #$20
    sta [bgQueue], y

    iny
    lda #$64
    sta [bgQueue], y

    iny
    lda score_tens
    sta [bgQueue], y

    iny
    lda score_ones
    sta [bgQueue], y

    lda p2Score
    sta score_ones
    jsr ScoreMath

    iny
    lda #$02
    sta [bgQueue], y

    iny
    lda #$00
    sta [bgQueue], y

    iny
    lda #$20
    sta [bgQueue], y

    iny
    lda #$7A
    sta [bgQueue], y

    iny
    lda score_tens
    sta [bgQueue], y

    iny
    lda score_ones
    sta [bgQueue], y

    iny
    lda #$00
    sta [bgQueue], y

    ; increment Queue pointer
    tya
    clc
    adc #1
    adc bgQueue
    sta bgQueue

    lda bgQueue+1
    adc #0
    sta bgQueue+1

    ; set flag to update background
    lda FrameUpdates
    ora #D_BACKGROUND
    sta FrameUpdates
    rts

ScoreMath:
    lda #0
    sta score_tens

us_divLoop:
    lda score_ones
    cmp #10
    bcs us_divNext
    jmp us_divEnd

us_divNext:
    inc score_tens
    lda score_ones
    sec
    sbc #10
    sta score_ones
    jmp us_divLoop

; Decimal -> ASCII
us_divEnd:
    lda score_tens
    clc
    adc #$30
    sta score_tens

    lda score_ones
    clc
    adc #$30
    sta score_ones
    rts
