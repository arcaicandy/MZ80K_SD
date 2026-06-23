# Patch to Make MZ-700 S-BASIC 1Z-007B Compatible with MZ-80K_SD

　S-BASIC 1Z-007B does not call MONITOR 1Z-009A or 1Z-009B, so a patch must be applied to make it compatible with MZ-80K_SD.

　I don't have a full understanding of the S-BASIC specifications, but after a lot of trial and error, it appears to be working correctly with MZ-80K_SD, so I am releasing it.

　It may only be working by chance, so please make a backup before use.

#### 2023.2.24: Since this circuit is originally designed for the 80K, when the MZ-700's RAM bank comes forward it will conflict with the ROM output. If using this patch with S-BASIC, please be aware that it places stress on the MZ-700 hardware.

#### 2024.6.29: Previously the SD access routine was placed by overwriting the CIRCLE instruction of the plotter, but it has been moved to unused gaps in the keyword table. As a result, all plotter-related instructions are now usable.

## About the Patch Program

　Two files, SBASIC_patch1.bin and SBASIC_patch2.bin, are applied to the S-BASIC MZT file.

　Replace bytes 00A1H through 00AFH of the MZT file (actual addresses 0021H–002FH) with SBASIC_patch1.bin.

　Replace bytes 2E80H through 2FE3H of the MZT file (actual addresses 2E00H–2F63H) with SBASIC_patch2.bin.

　~~Replace bytes 5184H through 52E7H of the MZT file (actual addresses 5104H–5267H) with SBASIC_patch2.bin.~~

　Save the patched file under a filename that identifies it as patched, such as "S-BASIC SD.MZT."

　~~The CIRCLE instruction of the plotter has been overwritten. Whether this affects other plotter instructions has not been verified, but please assume that plotter-related instructions cannot be used.~~

## About Filenames

　As per the original, filenames are up to 16 characters, but half-width katakana cannot be used as the Arduino does not recognise it, and some symbols cannot be entered from the MZ-700 keyboard.

　In exchange for not supporting long filenames, the LOAD command uses the same input method as the original, and the entered name becomes the DOS filename directly.

Example)

　SAVE "TEST.BAS" : Saved with DOS filename TEST.BAS.MZT

　SAVE "TEST"     : Saved with DOS filename TEST.MZT

　LOAD "TEST.BAS" : Loads the file with DOS filename TEST.BAS.MZT

　LOAD "TEST"     : Loads the file with DOS filename TEST.MZT

　If the DOS filename is "TEST SBASIC EIGHT.MZT", entering LOAD "TEST SBASIC EIGHT" will not work because it will look for a DOS file named "TEST SBASIC EIGH.MZT" (truncated to 16 characters).

## How to Use
　Load the patched S-BASIC.MZT using the FD command. There is no need to patch MONITOR 1Z-009A or 1Z-009B, so running FT.MZT is also unnecessary.

## Updates
2021.12.26

　Fixed a bug in error handling.

2024.6.29

　Moved the SD access routine to unused space in the keyword table gaps.
