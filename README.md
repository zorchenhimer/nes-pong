# Pong.nes

I wrote Pong for the NES on stream!

## Building
### Requirements
- GNU Make
- [cc65](https://cc65.github.io/)
- Perl (for converting debugging labels)

### How Do

```
$ git clone https://github.com/zorchenhimer/nes-pong.git
$ cd nes-pong
$ make
```

Make sure to check the path for ca65 and ld65 and change them if needed in the `Makefile`.  If you don't want to install Perl, and don't mind not having labels in your emulator's debugger, `bin/$(NAME).mlb` can be removed from the `all` target.

After running `make` you'll have a `bin/` folder that has a bunch of files including the rom, symbols files, and object file.

## What?

### How do I get to the credits screen?

Hold down `A` and `B` then press `Start` on the title screen.

### Why is there a credits screen?

I wanted to have something to say "Thank You" to the viewers that supported me while working on this project on [Twitch](https://www.twitch.tv/zorchenhimer).

## License

BSD 3-Clause license.  See `LICENSE.txt` for the full text of the license.

