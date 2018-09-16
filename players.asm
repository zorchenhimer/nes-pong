
UpdatePlayers:
    jsr CheckPause

    ; Player 1
    lda #BUTTON_UP
    bit controller1
    beq p1BtnDown   ; branch on not pressed

    lda P1_TOP
    cmp #WALL_TOP_PADDLE
    bcc p1BtnDown   ; branch when at top

    jsr P1MoveUp

p1BtnDown:
    lda #BUTTON_DOWN
    bit controller1
    beq p1BtnDone   ; branch on not pressed

    lda P1_TOP
    cmp #WALL_BOTTOM_PADDLE
    bcs p1BtnDone   ; branch when at top

    jsr P1MoveDown

p1BtnDone:
    ; Player 2
    lda #BUTTON_UP
    bit controller2
    beq p2BtnDown   ; branch on not pressed

    lda P2_TOP
    cmp #WALL_TOP_PADDLE
    bcc p2BtnDown   ; branch when at top

    jsr P2MoveUp

p2BtnDown:
    lda #BUTTON_DOWN
    bit controller2
    beq p2BtnDone   ; branch on not pressed

    lda P2_TOP
    cmp #WALL_BOTTOM_PADDLE
    bcs p2BtnDone   ; branch when at top

    jsr P2MoveDown

p2BtnDone:
    rts

; Move player's paddle
P1MoveUp:
    sec
    sbc #PADDLE_SPEED
    sta P1_TOP

    ;ldA $0208
    lda P1_TOP+4
    sec
    sbc #PADDLE_SPEED
    sta P1_TOP+4

    lda $020C
    sec
    sbc #PADDLE_SPEED
    sta $020C

    lda $0210
    sec
    sbc #PADDLE_SPEED
    sta $0210
    rts

P1MoveDown:
    clc
    adc #PADDLE_SPEED
    sta $0204

    lda $0208
    clc
    adc #PADDLE_SPEED
    sta $0208

    lda $020C
    clc
    adc #PADDLE_SPEED
    sta $020C

    lda $0210
    clc
    adc #PADDLE_SPEED
    sta $0210
    rts

; Move player 2's paddle
P2MoveUp:
    sec
    sbc #PADDLE_SPEED
    sta $0214

    lda $0218
    sec
    sbc #PADDLE_SPEED
    sta $0218

    lda $021C
    sec
    sbc #PADDLE_SPEED
    sta $021C

    lda $0220
    sec
    sbc #PADDLE_SPEED
    sta $0220
    rts

P2MoveDown:
    clc
    adc #PADDLE_SPEED
    sta $0214

    lda $0218
    clc
    adc #PADDLE_SPEED
    sta $0218

    lda $021C
    clc
    adc #PADDLE_SPEED
    sta $021C

    lda $0220
    clc
    adc #PADDLE_SPEED
    sta $0220
    rts
