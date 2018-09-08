@echo off
..\..\nesasm\nesasm.exe .\pong.asm && perl ..\..\nes-symbols.pl pong.fns

REM l:\fceux\fceux.exe pong.nes

rem c:\code\nes\Mesen\Mesen.exe pong.nes

