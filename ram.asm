
    .segment "ZEROPAGE"
; Moving up or left?
BallUp:     .res 1
BallLeft:   .res 1

BallSpeedX: .res 1
BallSpeedY: .res 1

p1Score:    .res 1
p2Score:    .res 1

sleeping:   .res 1

controller1:    .res 1
controller2:    .res 1
controller1Old: .res 1
controller2Old: .res 1

controllerTmp:  .res 1
compController: .res 1
frameOdd:       .res 1

ballFaster:     .res 1

PauseOn:    .res 1
PauseOff:   .res 1

; countdown timer for ball
start_count:.res 1
ST_3        = 5
ST_2        = 4
ST_1        = 3
ST_0        = 2
ST_CLEAR    = 1
ST_RUNNING  = 0
ST_LENGTH   = 45;$1E

start_ticks:.res 1
start_addr: .res 2

flag_tmp:   .res 1

; 2 - Title
; 1 - Game
; 0 - Game Over
GameState:      .res 1
GSUpdateNeeded: .res 1
;NewGameState    .res 1

TitleSelected:  .res 1
GamePaused:     .res 1
title_sound:    .res 1

btnPressedMask:     .res 1   ; the button to check
;btnPressedReturn    .res 1   ; return value


;dcPacketLength  .res 1
;dcQueuePointer  .res 2
;dcFlags         .res 1
;CountdownDataAddress .res 2

bgUpdateFlags:  .res 1
bgLength:       .res 1
bgFlags:        .res 1
bgPointer:      .res 2
bgQueue:        .res 2
bgSkipQueueReset:   .res 1
bgWrites:       .res 1
;bgDataAddress   .res 2

; use this one, i think?
D_ATTRIBUTE     = %10000000
D_BACKGROUND    = %01000000
FrameUpdates:   .res 1

score_tens:     .res 1
score_ones:     .res 1

SkipNMI:        .res 1
sfx_playing:    .res 1
sfx_index:      .res 1
sfx_frame:      .res 1
sfx_disabled:   .res 1
sfx_id:         .res 1
sfx_address:    .res 2

    .include "credits_ram.asm"

.segment "OAM"
SpriteRAM:      .res 256

.segment "BSS"
PaletteRAM:     .res 32
AttributeRAM:   .res 64

    ;.rsset $0400
; this might explode everywhere
bgBuffer:       .res 256

; ---------------------------
; Constants
; ---------------------------
MAX_SCORE   = 5

GS_CREDITS  = 3
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

P1_ATTR     = $020A

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
