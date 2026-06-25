# MZ80K SD Card ROM Files

This folder contains the following files:

## Combined ROM
- **FD_rom.bin** - Concatenation of `FD_rom1.<language>.bin` and `FD_rom2.<language>.bin`. Use this file to write to an 8K EPROM.

> If you are using a 4K EPROM you can just use `FD_rom1.<language>.bin`

## ROM1 - SD Card Access (lower half of 28C64)

| File | Description |
|------|-------------|
| `FD_rom1.english.asm` | Source of the SD card access code, commented in English, with minor changes |
| `FD_rom1.english.bin` | Binary of the SD card access code |
| `FD_rom1.english.prn` | Assembler listing output |
| `FD_rom1.japanese.asm` | Unchanged source of the SD card access code, commented in Japanese |
| `FD_rom1.japanese.bin` | Binary of the original SD card access code |
| `FD_rom1.japanese.prn` | Assembler listing output |

## ROM2 - MONITOR CMT Restore (upper half of 28C64)

| File | Description |
|------|-------------|
| `FD_rom2.english.asm` | Source of the MONITOR TO CMT code, commented in English |
| `FD_rom2.english.bin` | Binary of the MONITOR TO CMT code |
| `FD_rom2.english.prn` | Assembler listing output |
| `FD_rom2.japanese.asm` | Unchanged source of the MONITOR TO CMT code, commented in Japanese |
| `FD_rom2.japanese.bin` | Binary of the original MONITOR TO CMT code |
| `FD_rom2.japanese.prn` | Assembler listing output |
