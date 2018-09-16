
    .rsset $0000
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

PauseOn     .rs 1
PauseOff    .rs 1

; countdown timer for ball
start_count .rs 1
ST_3        = 5
ST_2        = 4
ST_1        = 3
ST_0        = 2
ST_CLEAR    = 1
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


;dcPacketLength  .rs 1
;dcQueuePointer  .rs 2
;dcFlags         .rs 1
;CountdownDataAddress .rs 2

bgUpdateFlags   .rs 1
bgLength        .rs 1
bgFlags         .rs 1
bgPointer       .rs 2
bgQueue         .rs 2
bgSkipQueueReset    .rs 1
;bgDataAddress   .rs 2

; use this one, i think?
D_ATTRIBUTE     = %10000000
D_BACKGROUND    = %01000000
FrameUpdates    .rs 1

score_tens      .rs 1
score_ones      .rs 1

    .rsset $0200
SpriteRAM      .rs 256
PaletteRAM      .rs 32
AttributeRAM    .rs 64

    .rsset $0400
bgBuffer        .rs 256

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
;BG_QUEUE    = $0300

; Button Constants
BUTTON_A        = 1 << 7
BUTTON_B        = 1 << 6
BUTTON_SELECT   = 1 << 5
BUTTON_START    = 1 << 4
BUTTON_UP       = 1 << 3
BUTTON_DOWN     = 1 << 2
BUTTON_LEFT     = 1 << 1
BUTTON_RIGHT    = 1 << 0

PPU_ON          = %00011110
PPU_OFF         = %00000110
