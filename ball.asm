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
    jmp DoCountdown

; "Start" is displayed, but ball is moving.
update_ball_start_check:
    LDA start_count
    CMP #ST_1
    BCS jmp_BallUpdateDone
    jmp updateBall_ok

jmp_BallUpdateDone:
    jmp BallUpdateDone

; Normal ball movement
updateBall_ok:
    LDA BallUp
    BEQ MoveBallDown

    ; Move Up
    LDA BallY
    SEC
    SBC BallSpeedY
    STA BallY

    ; Check bounce
    CMP #WALL_TOP
    BCS UpdateBallHoriz

    LDA #0
    STA BallUp

    JMP UpdateBallHoriz

MoveBallDown:
    ; Move Down
    LDA BallY
    CLC
    ADC BallSpeedY
    STA BallY

    CMP #WALL_BOTTOM
    BCC UpdateBallHoriz

    LDA #1
    STA BallUp

UpdateBallHoriz:
    LDA BallLeft
    BEQ MoveBallRight

    ; Move Left
    LDA BallX
    SEC
    SBC BallSpeedX
    STA BallX

    ;if BallY < P1_TOP - ball above paddle
    LDA BallY
    CLC
    ADC #8
    CMP P1_TOP
    BCC BallCheckLeftWall   ; no paddle

    ; if BallY > (P1_Bottom + 8) - ball lower than paddle
    SEC
    SBC #16
    CMP P1_BOTTOM
    BNE ballycheck1
    JMP BallCheckLeftWall
ballycheck1:
    BCS BallCheckLeftWall
    ; ball is in vertical box

    LDA P1_LEFT
    CLC
    ADC #8
    CMP BallX
    BNE ballxcheck3
    JMP BallCheckLeftWall
ballxcheck3:
    BCS ballxcheck4
    JMP BallCheckLeftWall
ballxcheck4:
    ; ball is in paddle
    LDA #0
    STA BallLeft
    JMP BallUpdateDone

BallCheckLeftWall:
    LDA BallX
    CMP #WALL_LEFT
    BCS BallUpdateDone

    INC p2Score
    JSR ResetBall
    LDA #0
    STA BallLeft

    JMP BallUpdateDone

MoveBallRight:
    ; Move right
    LDA BallX
    CLC
    ADC BallSpeedX
    STA BallX

    ; if bally < P2_Top - ball is above paddle
    LDA BallY
    CLC
    ADC #8
    CMP P2_TOP
    BCC BallCheckRightWall ; no paddle

    ; if BallY > (P2_Bottom + 8) - ball lower than paddle
    SEC
    SBC #16
    CMP P2_BOTTOM
    BNE ballycheck2
    JMP BallCheckRightWall
ballycheck2:
    BCS BallCheckRightWall

    ; ball is in vertical box
    LDA P2_LEFT
    SEC
    SBC #8
    CMP BallX
    BCC ballp2bounce    ; Bounce off paddle if less ballx < (P2_left - 8)
    JMP BallCheckRightWall

    ; ball is in paddle
ballp2bounce:
    LDA #1
    STA BallLeft
    JMP BallUpdateDone

BallCheckRightWall:
    LDA BallX
    CMP #WALL_RIGHT
    BCC BallUpdateDone

    INC p1Score
    JSR ResetBall
    LDA #1
    STA BallLeft

BallUpdateDone:
    RTS

; ---------------------------
; Put the ball back in the
; center of the playfield
; ---------------------------
ResetBall:
    LDA #$00
    ;STA BallUp
    STA BallLeft

    LDA #$02
    STA BallSpeedX
    STA BallSpeedY

    LDA #$78
    STA BallX
    STA BallY

    ; Start a countdown
    LDA #ST_3
    STA start_count
    LDA #ST_LENGTH
    STA start_ticks
    rts
