; ---------------------------
; Update the ball, incl bounce
; ---------------------------
UpdateBall:
    ; Are we counting down?
    LDA start_count
    bne DoCountdown_jmp
    ; nope
    jmp updateBall_ok

; Countdown is active, don't move ball
DoCountdown_jmp:
    cmp #ST_0
    bcs ub_doCountdown
    jsr DoCountdown
    jmp updateBall_ok

ub_doCountdown:
    jmp DoCountdown

; "Start" is displayed, but ball is moving.
;update_ball_start_check:
;    LDA start_count
;    CMP #ST_1
;    BCS jmp_BallUpdateDone
;    jmp updateBall_ok
;
;jmp_BallUpdateDone:
;    jmp BallUpdateDone

; Normal ball movement
updateBall_ok:
    lda BallUp
    beq MoveBallDown    ; ballup == 0; moving down

    ; Move Up
    lda BallY
    sec
    sbc BallSpeedY
    sta BallY

    lda ballFaster
    bne ubNotFasterUp

    lda frameOdd
    bne ubNotFasterUp

    dec BallY

ubNotFasterUp:

    lda BallY
    ; Check bounce
    cmp #WALL_TOP
    bcs UpdateBallHoriz

    lda #0
    sta BallUp

    jmp UpdateBallHoriz

MoveBallDown:
    ; Move Down
    lda BallY
    clc
    adc BallSpeedY
    sta BallY

    lda ballFaster
    bne ubNotFasterDn

    lda frameOdd
    bne ubNotFasterDn

    inc BallY

ubNotFasterDn:

    lda BallY
    cmp #WALL_BOTTOM
    bcc UpdateBallHoriz

    lda #1
    sta BallUp

UpdateBallHoriz:
    ; Moving right or left?
    lda BallLeft
    beq MoveBallRight

    ; Move Left
    lda BallX
    sec
    sbc BallSpeedX
    sta BallX

; Colission below

    ;if BallY < P1_TOP - ball above paddle
    lda BallY
    clc
    adc #8
    cmp P1_TOP
    bcc BallCheckLeftWall   ; above paddle

    ; if BallY > (P1_Bottom + 8) - ball lower than paddle
    lda BallY
    sec
    sbc #8
    cmp P1_BOTTOM
    bne ballycheck1
    jmp BallCheckLeftWall
ballycheck1:
    bcs BallCheckLeftWall
    ; ball is in vertical box

    lda BallX
    ;clc
    ;adc #4
    cmp P1_LEFT
    ; BallX < collision plane (behind paddle)
    bcc BallCheckLeftWall
    ;bne ballxcheck3
    ;jmp BallCheckLeftWall

;ballxcheck3:
;    bcs ballxcheck4
;    jmp BallCheckLeftWall

ballxcheck4:
    lda P1_LEFT
    clc
    adc #8      ; right edge of paddle
    cmp BallX
    ;beq p1Bounce
    bcs p1Bounce

    jmp BallUpdateDone
    ;bcc noP1Bounce

p1Bounce:
    ; ball is in collision box
    lda #$02
    sta sfx_id
    jsr Sound_Load

    lda #0
    sta BallLeft

;noP1Bounce:
;    jmp BallUpdateDone

BallCheckLeftWall:
    lda BallX
    cmp #WALL_LEFT
    bcs BallUpdateDone

    inc p2Score
    jsr ResetBall
    lda #0
    sta BallLeft

    jmp UpdateScores

    jmp BallUpdateDone

MoveBallRight:
    ; Move right
    lda BallX
    clc
    adc BallSpeedX
    sta BallX

    ; if bally < P2_Top - ball is above paddle
    lda BallY
    clc
    adc #8
    cmp P2_TOP
    bcc BallCheckRightWall ; no paddle

    ; if BallY > (P2_Bottom + 8) - ball lower than paddle
    sec
    sbc #16
    cmp P2_BOTTOM
    bne ballycheck2
    jmp BallCheckRightWall
ballycheck2:
    bcs BallCheckRightWall

    ; ball is in vertical box
    lda P2_LEFT
    sec
    sbc #8
    cmp BallX
    bcc ballp2bounce    ; Bounce off paddle if less ballx < (P2_left - 8)
    jmp BallCheckRightWall

    ; ball is in paddle
ballp2bounce:
    lda #$02
    sta sfx_id
    jsr Sound_Load

    lda #1
    sta BallLeft
    jmp BallUpdateDone

BallCheckRightWall:
    lda BallX
    cmp #WALL_RIGHT
    bcc BallUpdateDone

    inc p1Score
    jsr ResetBall
    lda #1
    sta BallLeft

    jmp UpdateScores

BallUpdateDone:
    rts

; ---------------------------
; Put the ball back in the
; center of the playfield
; ---------------------------
ResetBall:
    lda #$00
    ;STA BallUp
    sta BallLeft

    lda #$02
    sta BallSpeedX
    sta BallSpeedY

    lda #0
    sta ballFaster

    lda frameOdd
    beq rbNotOdd
    lda #1
    sta ballFaster

rbNotOdd:
    lda #$78
    sta BallX
    sta BallY

    ; Start a countdown
    lda #ST_3
    sta start_count
    lda #1
    sta start_ticks
    rts
