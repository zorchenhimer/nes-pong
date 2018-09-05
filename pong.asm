    .inesprg 1      ; 1x 16KB bank of PRG code
    .ineschr 1      ; 1x 8KB bank of CHR data
    .inesmap 0      ; mapper 0 = NROM, no bank swapping
    .inesmir 1      ; background mirroring (ignore for now)

; TODO:
;   Game states (title, game, game over)
;       draw game over
;           reset to title on start pushed
;   pause on start pressed
;       write "PAUSE" on screen
;   improve collision detection

    .rsset $0000
bg_ready    .rs 1   ; When not ready, PPU is off
sp_ready    .rs 1   ; Sprite ready?

; Moving up or left?
BallUp      .rs 1
BallLeft    .rs 1

BallSpeedX  .rs 1
BallSpeedY  .rs 1

p1Score     .rs 1
p2Score     .rs 1

sleeping    .rs 1

controller1     .rs 1
controller2     .rs 1
controller1Old  .rs 1
controller2Old  .rs 1

controllerTmp   .rs 1
compController  .rs 1
frameOdd        .rs 1

; countdown timer for ball
start_count .rs 1
ST_3        = 4
ST_2        = 3
ST_1        = 2
ST_0        = 1
ST_RUNNING  = 0
ST_LENGTH   = 45;$1E

start_ticks .rs 1
start_addr  .rs 2

flag_tmp    .rs 1

; 2 - Title
; 1 - Game
; 0 - Game Over
GameState       .rs 1
GSUpdateNeeded  .rs 1
;NewGameState    .rs 1

TitleSelected   .rs 1
GamePaused      .rs 1

btnPressedMask      .rs 1   ; the button to check
;btnPressedReturn    .rs 1   ; return value

; ---------------------------
; Constants
; ---------------------------
GS_TITLE    = 2
GS_GAME     = 1
GS_DED      = 0

; Ball playfield bounds
WALL_RIGHT  = $F4
WALL_LEFT   = $04
WALL_TOP    = $0F
WALL_BOTTOM = $D6

PADDLE_SPEED        = $04
; Paddle playfield bounds
WALL_TOP_PADDLE     = $13
WALL_BOTTOM_PADDLE  = $C0

; Object Addresses
P1_TOP      = $0204
P1_LEFT     = $0207
P1_BOTTOM   = $0210

P2_TOP      = $0214
P2_LEFT     = $0217
P2_BOTTOM   = $0220

BallX       = $0203
BallY       = $0200

TitleCursor = $0200

; Background tile update queue
BG_QUEUE    = $0300

CurrentPalette      = $0500
CurrentAttributes   = $0520

; Button Constants
BUTTON_A        = 1 << 7
BUTTON_B        = 1 << 6
BUTTON_SELECT   = 1 << 5
BUTTON_START    = 1 << 4
BUTTON_UP       = 1 << 3
BUTTON_DOWN     = 1 << 2
BUTTON_LEFT     = 1 << 1
BUTTON_RIGHT    = 1 << 0

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

    lda #%10010000
    sta $2000   ; enable NMI, sprites from pattern table 0


; Load the palettes
    ldx #$00
LoadPaletteLoop:
    lda PaletteData, x  ; Load data from address (PaletteData + X)
    sta CurrentPalette, x
    inx
    cpx #32    ; Each Palette is four bytes.  Eight Palettes total.  4 * 8 = 32 bytes.
    bne LoadPaletteLoop
    ;jsr UpdatePalette

    lda #GS_TITLE
    sta GameState
    jsr UpdateGameState

DoFrame:
    jsr ReadControllers
    lda GameState
    cmp #GS_GAME
    bcc frameGameOver
    beq frameGameplay

frameTitle:
    jsr UpdateTitle
    jmp frameEnd

frameGameplay:
    lda GamePaused
    bne framePaused

    jsr UpdatePlayers
    jsr UpdateBall
    jmp frameEnd

framePaused:
    jsr CheckPause
    jmp frameEnd

frameGameOver:
    jmp frameEnd

frameEnd:
    lda GSUpdateNeeded
    beq WaitFrame
    jsr UpdateGameState

; Wait for next VBlank to be done
WaitFrame:
    INC sleeping
WaitLoop:
    lda sleeping
    bne WaitLoop
    jmp DoFrame

CheckPause:
    lda #BUTTON_START
    sta btnPressedMask
    jsr ButtonPressedP1
    bne uPauseToggle
    rts

uPauseToggle:
    lda GamePaused
    beq uSetPause

    lda #0
    sta GamePaused

    ldx #$00
uUnPauseLoop:
    lda PaletteData, x
    sta CurrentPalette, x
    inx
    cpx #32
    bne uUnPauseLoop
    rts

uSetPause:
    lda #1
    sta GamePaused

    ldx #$00
uSetPauseLoop:
    lda PausedPalette, x
    sta CurrentPalette, x
    inx
    cpx #32
    bne uSetPauseLoop
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
    lda TitleSelected
    beq utitle_sel_2p

    ; vs comp
    lda #$00
    sta TitleSelected
    lda #$7F
    sta TitleCursor
    rts

; 2 player game mode selected
utitle_sel_2p:
    ; 2 player
    lda #$01
    sta TitleSelected
    lda #$8F
    sta TitleCursor
    rts

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

; vblank triggered
NMI:
    ; Backup registers
    PHA
    TXA
    PHA
    TYA
    PHA

    lda $2002   ; read PPU status to reset high/low latch to high
    ; Transfer sprite data
    LDA #$00
    STA $2003
    LDA #$02
    STA $4014

    lda #$3F
    sta $2006   ; Write high byte of $3F00 address
    lda #$00
    sta $2006   ; Write low byte of $3F00 address

    ldx #0
uPaletteLoop:
    lda CurrentPalette, x
    sta $2007
    inx
    cpx #32    ; Each Palette is four bytes.  Eight Palettes total.  4 * 8 = 32 bytes.
    bne uPaletteLoop


    LDA bg_ready
    BEQ NMI_END

    jsr UpdateBackground
    jsr DrawScores
    jsr UpdateAttributeData

NMI_END:
    ; Reset scroll
    bit $2002
    lda #$00
    sta $2005
    sta $2005

    LDA #0
    STA sleeping

    ; Restore registers
    pla
    tay
    pla
    tax
    pla

    rti

UpdateAttributeData:
    bit $2002
    lda #$23
    sta $2006
    lda #$C0
    sta $2006

    ldx #0
uAttrDataLoop:
    lda CurrentAttributes, x
    sta $2007
    inx
    cpx #64
    bne uAttrDataLoop
    rts

UpdateBackground:
    LDX #0
BG_LOOP:    ; loop once per data packet
    LDA BG_QUEUE, x
    ; 1st Byte is length
    CMP #0
    BEQ BG_LOOP_DONE    ; no tiles to update
    tay ; length in Y

    BIT $2002   ; read PPU status to reset high/low latch

    ; PPU High byte
    inx
    LDA BG_QUEUE, x
    STA $2006

    ; PPU Low byte
    inx
    LDA BG_QUEUE, x
    STA $2006

    ; flags
    inx
    lda BG_QUEUE, x
    STA flag_tmp
    BIT flag_tmp
    BMI BG_Tile_Runlength   ; if bit 7 is set, it's runlength

    inx
; loop through all the tiles in packet
BG_Tile_Loop:
    dey
    LDA BG_QUEUE, x
    STA $2007
    inx
    cpy #$00
    BNE BG_Tile_Loop

    ; go to the next packet
    jmp BG_LOOP

BG_Tile_Runlength:
    inx
    LDA BG_QUEUE, x
bg_runlength_loop:
    dey
    STA $2007
    cpy #$00
    BNE bg_runlength_loop

    ; go to the next packet
    jmp BG_LOOP

BG_LOOP_DONE:
    rts

DrawScores:
    lda GameState
    cmp #GS_TITLE
    bne draw_ok
    rts

draw_ok:
; Draw Scores
; P1 $2064
; P2 $207A
    LDA #$20
    STA $2006
    LDA #$64
    STA $2006

    LDA p1Score
    cmp #10
    bcc draw_p1_zero

    ; draw leading '1'
    LDA #'1'
    STA $2007
    jmp draw_p1_digit

draw_p1_zero:
    ; draw leading '0'
    LDA #'0'
    STA $2007

draw_p1_digit:
    LDA p1Score
    CLC
    ADC #$30
    STA $2007

; draw p2
    LDA #$20
    STA $2006
    LDA #$7A
    STA $2006

    LDA p2Score
    cmp #10
    bcc draw_p2_zero

    ; draw leading '1'
    LDA #'1'
    STA $2007
    jmp draw_p2_digit

draw_p2_zero:
    ; draw leading '0'
    LDA #'0'
    STA $2007

draw_p2_digit:
    LDA p2Score
    CLC
    ADC #$30
    STA $2007
    rts

ReadControllers:
    lda controller1
    sta controller1Old

    lda controller2
    sta controller2Old

    ; Freeze input
    LDA #1
    STA $4016
    LDA #0
    STA $4016

    LDX #$08
ReadJoy1:
    LDA $4016
    LSR A           ; Bit0 -> Carry
    ROL controller1 ; Bit0 <- Carry
    DEX
    BNE ReadJoy1

    LDX #$08
ReadJoy2:
    LDA $4017
    LSR A           ; Bit0 -> Carry
    ROL controller2    ; Bit0 <- Carry
    DEX
    BNE ReadJoy2

    lda TitleSelected
    cmp #0
    bne readJoy_done
    jsr Computer_Move

readJoy_done:
    RTS

UpdatePlayers:
    jsr CheckPause

    ; Player 1
    LDA #BUTTON_UP
    BIT controller1
    BEQ p1BtnDown   ; branch on not pressed

    ;LDA P1Top
    LDA P1_TOP
    CMP #WALL_TOP_PADDLE
    BCC p1BtnDown   ; branch when at top

    jsr P1MoveUp

p1BtnDown:
    LDA #BUTTON_DOWN
    BIT controller1
    BEQ p1BtnDone   ; branch on not pressed

    ;LDA P1Top
    LDA P1_TOP
    CMP #WALL_BOTTOM_PADDLE
    BCS p1BtnDone   ; branch when at top

    jsr P1MoveDown

p1BtnDone:
    ; Player 2
    LDA #BUTTON_UP
    BIT controller2
    BEQ p2BtnDown   ; branch on not pressed

    ;LDA P1Top
    LDA P2_TOP
    CMP #WALL_TOP_PADDLE
    BCC p2BtnDown   ; branch when at top

    jsr P2MoveUp

p2BtnDown:
    LDA #BUTTON_DOWN
    BIT controller2
    BEQ p2BtnDone   ; branch on not pressed

    ;LDA P1Top
    LDA P2_TOP
    CMP #WALL_BOTTOM_PADDLE
    BCS p2BtnDone   ; branch when at top

    jsr P2MoveDown

p2BtnDone:
    RTS

; Move player's paddle
P1MoveUp:
    SEC
    SBC #PADDLE_SPEED
    ;STA $0204
    STA P1_TOP

    ;LDA $0208
    LDA P1_TOP+4
    SEC
    SBC #PADDLE_SPEED
    ;STA $0208
    STA P1_TOP+4

    LDA $020C
    SEC
    SBC #PADDLE_SPEED
    STA $020C

    LDA $0210
    SEC
    SBC #PADDLE_SPEED
    STA $0210
    rts

P1MoveDown:
    CLC
    ADC #PADDLE_SPEED
    STA $0204

    LDA $0208
    CLC
    ADC #PADDLE_SPEED
    STA $0208

    LDA $020C
    CLC
    ADC #PADDLE_SPEED
    STA $020C

    LDA $0210
    CLC
    ADC #PADDLE_SPEED
    STA $0210
    rts

; Move player 2's paddle
P2MoveUp:
    SEC
    SBC #PADDLE_SPEED
    STA $0214

    LDA $0218
    SEC
    SBC #PADDLE_SPEED
    STA $0218

    LDA $021C
    SEC
    SBC #PADDLE_SPEED
    STA $021C

    LDA $0220
    SEC
    SBC #PADDLE_SPEED
    STA $0220
    rts

P2MoveDown:
    CLC
    ADC #PADDLE_SPEED
    STA $0214

    LDA $0218
    CLC
    ADC #PADDLE_SPEED
    STA $0218

    LDA $021C
    CLC
    ADC #PADDLE_SPEED
    STA $021C

    LDA $0220
    CLC
    ADC #PADDLE_SPEED
    STA $0220
    rts

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

; ---------------------------
; Draw the countdown on
; screen
; ---------------------------
; TODO: read the packets from CountdownData labels
DoCountdown:
    LDA start_count
    asl a
    tax
    lda Countdown_Table+1, x

    pha
    lda Countdown_Table, x
    pha
    rts

; clear the text off screen, we're running already
cd_reset:
    ; data length
    LDA #$05
    STA BG_QUEUE

    ; PPU address
    LDA #$20
    STA BG_QUEUE+1
    LDA #$AE
    STA BG_QUEUE+2

    ; flags
    LDA #%10000000
    STA BG_QUEUE+3

    LDA #$00
    STA BG_QUEUE+4

    LDA #ST_RUNNING
    STA start_count
    jmp update_ball_start_check
    rts

; "start" text
cd_00:
    LDA start_ticks
    CMP #1
    BEQ cd_reset

    ; data length
    LDA #$05
    STA BG_QUEUE

    ; PPU address
    LDA #$20
    STA BG_QUEUE+1
    LDA #$AE
    STA BG_QUEUE+2

    ; flags
    LDA #$00
    STA BG_QUEUE+3

    ; the text "03"
    LDA #'S'
    STA BG_QUEUE+4
    LDA #'T'
    STA BG_QUEUE+5
    LDA #'A'
    STA BG_QUEUE+6
    LDA #'R'
    STA BG_QUEUE+7
    LDA #'T'
    STA BG_QUEUE+8

    LDA #0
    STA BG_QUEUE+9

    DEC start_ticks
    LDA start_ticks
    cmp #0
    BNE cd_00_nochange

    LDA #ST_LENGTH
    STA start_ticks
    LDA #ST_RUNNING
    STA start_count

cd_00_nochange:
    jmp update_ball_start_check
    ;rts

; "01" text
cd_01:
    ; data length
    LDA #$02
    STA BG_QUEUE

    ; PPU address
    LDA #$20
    STA BG_QUEUE+1
    LDA #$AE
    STA BG_QUEUE+2

    ; flags
    LDA #$00
    STA BG_QUEUE+3

    ; the text "03"
    LDA #'0'
    STA BG_QUEUE+4
    LDA #'1'
    STA BG_QUEUE+5

    LDA #0
    STA BG_QUEUE+6

    DEC start_ticks
    LDA start_ticks
    cmp #0
    BNE cd_01_nochange

    LDA #ST_LENGTH
    STA start_ticks
    LDA #ST_0
    STA start_count

cd_01_nochange:
    rts

; "02" text
cd_02:
    ; data length
    LDA #$02
    STA BG_QUEUE

    ; PPU address
    LDA #$20
    STA BG_QUEUE+1
    LDA #$AE
    STA BG_QUEUE+2

    ; flags
    LDA #$00
    STA BG_QUEUE+3

    ; the text "03"
    LDA #'0'
    STA BG_QUEUE+4
    LDA #'2'
    STA BG_QUEUE+5

    LDA #0
    STA BG_QUEUE+6

    DEC start_ticks
    LDA start_ticks
    cmp #0
    BNE cd_02_nochange

    LDA #ST_LENGTH
    STA start_ticks
    LDA #ST_1
    STA start_count

cd_02_nochange:
    rts

; "03" text
cd_03:
    ; data length
    LDA #$02
    STA BG_QUEUE

    ; PPU address
    LDA #$20
    STA BG_QUEUE+1
    LDA #$AE
    STA BG_QUEUE+2

    ; flags
    LDA #$00
    STA BG_QUEUE+3

    ; the text "03"
    LDA #'0'
    STA BG_QUEUE+4
    LDA #'3'
    STA BG_QUEUE+5

    LDA #0
    STA BG_QUEUE+6

    DEC start_ticks
    LDA start_ticks
    cmp #0
    BNE cd_03_nochange

    LDA #ST_LENGTH
    STA start_ticks
    LDA #ST_2
    STA start_count

cd_03_nochange:
    rts

ComputerOdd:
    lda compController
    sta controller2

    inc frameOdd
    rts

Computer_Move:
; Move p2's paddle
;   if ball is moving right
;       if ball y < p2_paddle y
;           press "UP" button (mimic the controller)
;       else if ball y > p2_paddle_bottom y
;           press "DOWN" button

    lda frameOdd
    cmp #5
    bne ComputerOdd

    ; Clear controller input
    lda #$00
    sta controller2
    sta compController

    ; Ball moving right?
    lda #1
    cmp BallLeft
    beq Computer_Done

    ; ball past half of screen?
    lda BallX
    cmp #$88
    bcc Computer_Done

    ; if ball y < p2_paddle y
    ; use the inner two sprites to determine movement
    lda P2_TOP
    ;SEC
    ;SBC #8
    cmp BallY
    bcc Computer_MoveDown

    lda P2_BOTTOM
    ;CLC
    ;ADC #8
    cmp BallY
    bcs Computer_MoveUp
    jmp Computer_Done

; Don't move the paddle directly, just press the buttons
Computer_MoveUp:
    lda #BUTTON_UP
    sta controller2
    sta compController
    jmp Computer_Done

Computer_MoveDown:
    lda #BUTTON_DOWN
    sta controller2
    sta compController

Computer_Done:
    ;dec frameOdd
    lda #0
    sta frameOdd
    rts

; ---------------------------
; Gamestate change dispatch
; subroutine
; ---------------------------
UpdateGameState:
    lda #0
    sta GSUpdateNeeded

    jsr ClearSprites

    lda GameState   ; load gamestate
    asl a           ; multiply by two
    tax             ; use it as an index

    ; low byte first
    lda GameState_Table+1, x
    pha

    ; then high byte
    lda GameState_Table, x
    pha

    ; Jump to sub-subroutine
    rts

; -------------------------
; Load Title gamestate
; -------------------------
gsTitle:
    LDA $2002   ; read PPU status to reset high/low latch to high
    LDA #$3F
    STA $2006   ; Write high byte of $3F00 address
    LDA #$00
    STA $2006   ; Write low byte of $3F00 address

    ; Turn off PPU until the background is ready
    LDA #$00
    STA $2001

    ; 0 = BG not ready
    LDA #$00
    STA bg_ready

    ; --------
    ; Load up the background
    LDY #$20
    LDX #$00    ; Start at address $2000
tLoadBGTopLoop:
    LDA $2002   ; read PPU status to reset high/low latch
    TYA         ; Load Y into high byte
    STA $2006   ; write high byte of $YY00 address
    TXA         ; Load X into low byte
    STA $2006   ; write low byte of $YY00 address

tLoadBackgroundLoop:
    LDA #$01    ; sprite $24 is a blank sprite
    STA $2007   ; write to PPU
    INX

    ; Check for low byte of last row's last sprite ($23BF)
    CPX #$C0
    BNE tCheckIncHigh

    ; Check for the last row
    CPY #$23    ; compare Y to $23, which is the high byte
                ; of the last sprite on screen ($239F)
    BEQ tBGLoopDone

tCheckIncHigh:
    ; Increment high byte?
    cpx #$00
    beq tIncHighByte

    jmp tLoadBackgroundLoop

; Increment high byte and goto top
tIncHighByte
    ;ldx #$00
    iny
    jmp tLoadBGTopLoop

tBGLoopDone:
    lda #$20
    sta $2006
    lda #$AB
    sta $2006

    ldx #$60
    txa
titleDraw:
    sta $2007
    inx
    txa
    cmp #$6B
    bne titleDraw

    lda #$20
    sta $2006
    lda #$CB
    sta $2006

    ldx #$70
    txa
titleDraw2:
    sta $2007
    inx
    txa
    cmp #$7B
    bne titleDraw2

    ; draw box top
    lda #$20
    sta $2006
    lda #$8A
    sta $2006

    lda #$06    ; upper left corner
    sta $2007

    ; loop for line
    lda #$02
    ldx #$0B
titleBoxTop:
    sta $2007
    dex
    bne titleBoxTop

    lda #$07    ; upper right corner
    sta $2007

    ; draw box bottom
    lda #$20
    sta $2006
    lda #$EA
    sta $2006

    lda #$08
    sta $2007

    lda #$03
    ldx #$0B
titleBoxBottom:
    sta $2007
    dex
    bne titleBoxBottom

    lda #$09
    sta $2007

    ; Write "VS COMP" and "2 Player"
    lda #$22
    sta $2006
    lda #$0E
    sta $2006

    lda #'V'
    sta $2007

    lda #'S'
    sta $2007

    lda #' '
    sta $2007

    lda #'C'
    sta $2007

    lda #'O'
    sta $2007

    lda #'M'
    sta $2007

    lda #'P'
    sta $2007

    lda #$22
    sta $2006
    lda #$4E
    sta $2006

    lda #'2'
    sta $2007

    lda #' '
    sta $2007

    lda #'P'
    sta $2007

    lda #'L'
    sta $2007

    lda #'A'
    sta $2007

    lda #'Y'
    sta $2007

    lda #'E'
    sta $2007

    lda #'R'
    sta $2007

    ;lda #$23
    ;sta $2006
    ;lda #$C0
    ;sta $2006

    ldx #0
titleLoadAttrLoop:
    ;lda AttributeData, x
    lda #$55
    ;sta $2007
    sta CurrentAttributes, x
    inx
    cpx #64
    bne titleLoadAttrLoop

; Load sprites
    ldx #$00
titleSpriteLoop:
    lda titleSpriteData, X
    sta $0200, x
    inx
    cpx #$04         ; one sprite, four bytes per sprite
    bne titleSpriteLoop

    ; Turn PPU back on
    lda #%00011110
    sta $2001

    lda #1
    sta bg_ready
    rts

; -------------------------
; Load Gameplay gamestate
; -------------------------
gsGame:
    ; General INIT stuff
    lda #$00
    sta p1Score
    sta p2Score
    jsr ResetBall

    lda #ST_3
    sta start_count

    ; Turn off PPU until the background is ready
    lda #$00
    sta $2001

    ; 0 = BG not ready
    lda #$00
    sta bg_ready

    ; --------
    ; Load up the background
    ldy #$20
    ldx #$00    ; Start at address $2000
LoadBGTopLoop:
    lda $2002   ; read PPU status to reset high/low latch
    tya         ; Load Y into high byte
    sta $2006   ; write high byte of $YY00 address
    txa         ; Load X into low byte
    sta $2006   ; write low byte of $YY00 address

LoadBackgroundLoop:
    lda #$00    ; sprite $24 is a blank sprite
    sta $2007   ; write to PPU
    inx

    ; Check for low byte of last row's last sprite ($23BF)
    cpx #$C0
    bne CheckIncHigh

    ; Check for the last row
    cpy #$23    ; compare Y to $23, which is the high byte of the last sprite on screen ($239F)
    beq BGLoopDone

CheckIncHigh:
    ; Increment high byte?
    cpx #$00
    beq IncHighByte

    jmp LoadBackgroundLoop

; Increment high byte and goto top
IncHighByte
    ;ldx #$00
    iny
    jmp LoadBGTopLoop

BGLoopDone:
    ;rts

; Load Attributes
;LoadAttribute:
    ;lda $2002   ; read PPU status to reset high/low latch
    ;lda #$23
    ;sta $2006   ; write high byte of $23C0 address
    ;lda #$C0
    ;sta $2006   ; write low byte of $23C0 address

    ldx #$00
LoadAttrLoop:
    lda AttributeData, x
    ;lda #$00
    ;sta $2007
    sta CurrentAttributes, x
    inx
    cpx #64
    bne LoadAttrLoop

; Load sprites
    ldx #$00
SpriteLoop:
    lda SpriteData, X
    sta $0200, x
    inx
    cpx #36         ; one sprite, four bytes per sprite
    bne SpriteLoop

    ; Turn PPU back on
    lda #%00011110
    sta $2001

    lda #$01
    sta bg_ready
    rts

; -------------------------
; Load Game Over gamestate
; -------------------------
gsDed:
    ; 1 - write "GAME OVER" text
    ; 2 - deterimine winner
    ; 3 - write winner to screen
    ; 4 - (not here) wait for start button -> title
    rts

ClearSprites:
    ldx #$00
ClearSpriteLoop:
    lda #$00
    sta $0200, x
    inx
    cpx #$00         ; one sprite, four bytes per sprite
    bne ClearSpriteLoop
    rts

; Was a button pressed this frame?
ButtonPressedP1:
    ;lda #0
    ;sta btnPressedReturn

    ; read for start
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
    lda #1 ; HERE
    rts
    ;bne btnPressTrue

;btnPressFalse
    ;lda #0
    ;rts

;btnPressTrue:
;    lda #1
;    ;sta btnPressedReturn
;    rts

; --------
    .bank 1
    .org $E000

Countdown_Table:
    .word cd_reset-1
    .word cd_00-1
    .word cd_01-1
    .word cd_02-1
    .word cd_03-1

GameState_Table:
    .word gsDed-1
    .word gsGame-1
    .word gsTitle-1

;CountdownData_Table:
;    .word CountdownData-1
;    .word CountdownData_start-1
;    .word CountdownData_01-1
;    .word CountdownData_02-1
;    .word CountdownData_03-1

CountdownData:
    .db $05, $20, $AE, $80, $00

CountdownData_start:
    .db $05, $20, $AE, $00, 'S', 'T', 'A', 'R', 'T'

CountdownData_01:
    .db $02, $20, $AE, $00, '0', '1'

CountdownData_02:
    .db $02, $20, $AE, $00, '0', '2'

CountdownData_03:
    .db $02, $20, $AE, $00, '0', '3'

PaletteData:
    .db $0F,$34,$14,$0F, $0F,$15,$0F,$05, $0F,$0A,$0A,$0A, $0F,$11,$11,$11
    .db $0F,$10,$00,$30, $0F,$05,$05,$05, $0F,$0A,$0A,$0A, $0F,$11,$11,$11

PausedPalette:
    .db $0F,$14,$04,$0F, $0F,$15,$0F,$05, $0F,$0A,$0A,$0A, $0F,$01,$01,$01
    .db $0F,$00,$2D,$10, $0F,$05,$05,$05, $0F,$0A,$0A,$0A, $0F,$11,$11,$11

AttributeData:
    .db $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F
    .db $00, $00, $00, $00, $00, $00, $00, $00

    .db $00, $00, $00, $00, $00, $00, $00, $00
    .db $00, $00, $00, $00, $00, $00, $00, $00

    .db $00, $00, $00, $00, $00, $00, $00, $00
    .db $00, $00, $00, $00, $00, $00, $00, $00

    .db $00, $00, $00, $00, $00, $00, $00, $00
    .db $0F, $0F, $0F, $0F, $0F, $0F, $0F, $0F

SpriteData:
    ; Sprite Attribute Stuff
    ; %1000 0000    Flip horizontally
    ; %0100 0000    Flip vertically
    ; %0010 0000    Priority (0 front of BG; 1 behind BG)
    ; %0000 1100    Ignored
    ; %0000 0011    Palette

    ;   Y,   Idx, Attr, X
    .db $80, $01, %00000000, $80    ; Ball

    ; Player 1
    .db $80, $02, %00000000, $08    ; Paddle top
    .db $88, $04, %00000000, $08    ; Paddle middle A
    .db $8F, $04, %00000000, $08    ; Paddle middle A
    .db $94, $03, %00000000, $08    ; Paddle bottom

    ; Player 2
    .db $80, $02, %00000000, $F0    ; Paddle top
    .db $88, $04, %00000000, $F0    ; Paddle middle A
    .db $8F, $04, %00000000, $F0    ; Paddle middle A
    .db $94, $03, %00000000, $F0    ; Paddle bottom

titleSpriteData:
    .db $7F, $05, $00, $66

; Vectors (interupts?)
    .org $FFFA  ; first of three vectors starts here
    .dw NMI     ; When an NMI happens (start of VBlank) the processor will jump
                ; to the label NMI:

    .dw RESET   ; When the prossor first turns on or is reset, it will jump to
                ; the label RESET:

    .dw 0       ; external interupt IRQ.  ignored for now.

    ; CHR data
    .bank 2
    .org $0000
    .incbin "pong.chr"
