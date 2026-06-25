# Adding SD Card Load/Save Functionality to the MZ-80 Series

![MZ-80K_SD](https://github.com/yanataka60/MZ80K_SD/blob/main/JPEG/MZ-80K_SD.jpg)

This repo is a fork of yanataka60/MZ80K_SD.

I have translated the readme and much of the source code (using Claude AI) to make it easier for English speaking users.

When built this project places the contents of the 2764/2732 EPROM on the PCB at address F000H in the MZ80K memory. You can then use the FD command that is normally available when an external floppy disk drive is connected to the MZ-80 series but instead of a floppy disk drive, this project uses an SD card.

The project uses the code in the EPROM to talk to an Arduino Pro Mini which provides the actual SD Card read/write functionality from/to the SD Card module. There is a BOM further below.

The PCB can be built via JCBPLC using the zip file MZ80K_SD\KiCad\MZ80k_SD\PCB\MZ80k_SD.zip. I used this file without modification and the PCBs received worked fine.

All soldering is through hole.

I would estimate the cost of this PCB/build including a ribbon cable is less than 50UKP as of  June 26 (not including any postage).    

I have made updates to the Arduino code to get it to work for me and minor changes to the PCB eprom code (spelling etc..)

I also provide a OneRom config JSON and roms that will allow you to replace the MZ80K stock Monitor rom with a patched version for MZ80K-SD as well as a very useful ram test. Rather than programming eproms I highly recommend you use OneRom as you dont need an eprom programmer and its much more flexible and faster to dev with than eproms. https://onerom.org/ 

I would also suggest using a OneRom for the Eprom on the PCB unless you already have a programmer and EPROMS you can use.

OneRoms can be purchased from Piers or others but his github includes everything you need to get them made yourself at a lower cost.

When soldering the Arduino DO NOT forget the 2 pins inside the outer pins next to A2 and A3. These are SCL(A5) and SDA (A4). It won't work if you forget. Ask me how I know. :-)

A Youtube video of the MZ80K-SD in use can be seen here - https://www.youtube.com/watch?v=CxEJVfKVjyo&t=81s

#### Added 2025.7.31: Works with the MZ-80K, MZ-80K2, MZ-80K2E, MZ-80C, MZ-1200, and MZ-700. Note that MZ-700_SD, which supports RAM switching, is also available for the MZ-700.

Simply connecting the adapter makes BASIC SP-5030 launchable in about 4 seconds, making it convenient to use as an application launcher. By patching MONITOR SP-1002, not only BASIC SP-5030 but most MZ-80K applications become SD card compatible.

### We have released a Windows tool "CMT2SD_CHECK" that patches applications for SD support without replacing the system ROM with a patched MONITOR SP-1002. (2022.6.29)

### See README.md in the CMT2SD_CHECK folder for details.

The MZ-700 similarly supports SD cards for MZ-80K applications, but since the bundled S-BASIC and Hu-BASIC do not use the CMT routines of MONITOR 1Z-009A or 1Z-009B, simply patching those monitors does not enable SD card support — after booting, CMT operation is used instead.

#### (Added 2021.12.14: A patch to enable SD card support for S-BASIC has been released.)

#### (Added 2024.6.29: Previously, the CIRCLE instruction of the legacy plotter was overwritten to place the SD access routine, but it has been moved to unused gaps in the keyword table.)

Basically, consider the MZ-700 usable as an MZ-80K compatible machine.

The MZ-700 also supports FDx commands, so it can be used as an MZ-700 application launcher, but MZ-700 applications that require a full 64K RAM (not advertised as MZ-80K compatible) may not load.

If you have performed the "ROM disconnect switch modification" on a Rev1.5.5 or Rev1.5.3 board, after launching a MZ-700 application, switch the switch to the "700" side. Don't forget to switch back to "80K" when booting from SD again.

Note that some MZ-80K software requires NZ-700, the MZ-700-compatible version of SP-1002 published in the 0h!MZ special edition ADVANCED MZ-700, in order to run on the MZ-700.

#### (Added 2024.10.10: To prevent the MZ-80K_SD ROM from conflicting with the MZ-700's RAM when running MZ-700 applications on MZ-700+MZ-80K_SD, Rev1.5.5 boards incorporate a "ROM disconnect switch." An MZ-700_SD board that does this automatically is also available. However, obtaining a GAL16V8 is required to build MZ-700_SD.

https://github.com/yanataka60/MZ-700_SD

#### Note)

Stable operation has been confirmed, but since data files saved to the SD card by SAVE operations could potentially be lost, please back up your files.

Separate equipment is required for writing to Arduino and ROM.

## Schematic

See MZ80K_SD.pdf in the KiCad folder.

[Schematic](https://github.com/yanataka60/MZ80K_SD/blob/main/KiCad/MZ80k_SD/MZ80K_SD.pdf)
![Schematic](https://github.com/yanataka60/MZ80K_SD/blob/main/JPEG/MZ-80K_SD_schematic.jpg)

Now at Rev1.5.5, incorporating the "ROM disconnect switch modification" described later.

## Parts

| Number | Part Name                                                                         | Quantity | Notes                                                                                                                        |
| ------ | --------------------------------------------------------------------------------- | -------- | ---------------------------------------------------------------------------------------------------------------------------- |
| U1     | 74LS04                                                                            | 1        |                                                                                                                              |
| U2     | 2764 or 28C64                                                                     | 1        | See notes below regarding ROM compatibility                                                                                  |
| U3     | 8255                                                                              | 1        |                                                                                                                              |
| U4     | Arduino_Pro_Mini_5V                                                               | 1        | Use the ATmega328 version; the 168 version is not compatible. (Note 1)                                                       |
| U5 U6  | 74LS30                                                                            | 2        |                                                                                                                              |
|        | Either J2 or J5                                                                   |          |                                                                                                                              |
| J2     | Micro SD Card Kit or equivalent                                                   | 1        | Akizuki Denshi AE-microSD-LLCNV (Note 2) (Note 3)                                                                            |
| J5     | MicroSD Card Adapter                                                              | 1        | Must support 5V power as used with Arduino etc. (Note 3)                                                                     |
| C1-C5  | Multilayer ceramic capacitor 0.1uF                                                | 5        |                                                                                                                              |
| C6     | Electrolytic capacitor 16V 100uF                                                  | 1        |                                                                                                                              |
| S1 S2  | 3-position slide switch                                                           | 2        | Akizuki Denshi SS12D01G4, etc.                                                                                               |
| S3     | 3-position slide switch                                                           | 1        | Can be replaced with a jumper fixed to the 80K side if not used with MZ-700                                                  |
| R1     | Carbon resistor 10kΩ                                                              | 1        | Not needed if jumpering S3 fixed to the 80K side                                                                             |
| J4     | DC jack                                                                           | 1        |                                                                                                                              |
| J3     | 2-pin connector                                                                   | 1        | If substituting with a pin header, use only 1 pin for 5V to avoid confusing it with GND                                      |
| J1     | 50-pin connector                                                                  | 1        |                                                                                                                              |
|        | 50-pin cable                                                                      | 1        |                                                                                                                              |
|        | Pin headers                                                                       | 2 pins   | The Arduino Pro Mini does not come with pin headers for A4 and A5, so source them separately — e.g. Akizuki Denshi PH-1x40SG |
|        | A short cable if drawing 5V from inside the system                                |          |                                                                                                                              |
|        | An adapter for inserting 27C32 etc. into a 2532 socket if patching the system ROM |          |                                                                                                                              |
|        | Pin sockets (optional)                                                            | 26 pins  | Obtain if you want the Arduino Pro Mini to be removable — e.g. Akizuki Denshi FHU-1x42SG                                     |

　　　Note 1) The Arduino Pro Mini also uses pins A4 and A5.

　　　Note 2) Short the J1 jumper on the Akizuki Denshi AE-microSD-LLCNV.

　　　Note 3) Install either J2 or J5 — not both.

### Using a MicroSD Card Adapter (Rev1.5.3 and later)

Install at J5.

The most reliable method is to remove the pin headers from the MicroSD Card Adapter and solder it directly, but you can also press the adapter firmly into the J5 holes and flow solder in from the back. When using this method, confirm continuity with a tester to make sure the solder joints are solid.

If you are not confident in your soldering, use the Akizuki Denshi AE-microSD-LLCNV at J2. The AE-microSD-LLCNV includes a power LED and access LED.

![MicroSD Card Adapter1](https://github.com/yanataka60/MZ80K_SD/blob/main/JPEG/MicroSD%20Card%20Adapter(1).JPG)

![MicroSD Card Adapter2](https://github.com/yanataka60/MZ80K_SD/blob/main/JPEG/MicroSD%20Card%20Adapter(2).JPG)

![MicroSD Card Adapter3](https://github.com/yanataka60/MZ80K_SD/blob/main/JPEG/MicroSD%20Card%20Adapter(3).JPG)

![MicroSD Card Adapter4](https://github.com/yanataka60/MZ80K_SD/blob/main/JPEG/MicroSD%20Card%20Adapter(4).JPG)

### Using a MicroSD Card Adapter (Rev1.5.2)

Refer to the following pin numbers and adapt the wiring via a conversion board as appropriate.
| AE-microSD-LLCNV Pin No. | MicroSD Card Adapter Pin No. | Signal Name |
| ---------------------- | -------------------------- | ---- |
|1|2|5V|
|4|1|GND|
|5|5|SCK|
|6|3|MISO|
|7|4|MOSI|
|8|6|CS|

![MicroSD Card Adapter](https://github.com/yanataka60/MZ80K_SD/blob/main/JPEG/MicroSD%20Card%20Adapter.jpg)

## About the ROM Program

Note: All of the following is accurate for this fork but there are 2 versions of the ROMS. Japanese (the orginals) and English.

The Z80 folder contains three files: FD_rom1.bin, FD_rom2.bin, and FD_rom.bin. FD_rom1.bin is the program for SD card access (placed in the lower half of 28C64), FD_rom2.bin restores MONITOR to CMT operation (placed in the upper half of 28C64), and FD_rom.bin combines both.

Use a ROM writer (such as TL866II Plus) to write FD_rom.bin to a 2764 or 28C64.

Writing FD_rom.bin to a 28C64 allows switching between SD and CMT via a slide switch.

However, switching while running may cause the MZ-80K to crash depending on timing. As a rule, switch only with the power off.

There is also 4023 bytes of free space in the FD_rom2 area, which you are welcome to use freely.

When using MZ-700 with MONITOR 1Z-009A or 1Z-009B patched for MZ-80K_SD, switching to the CMT side still allows use of Kōcha Yōkan's "Transferring Data Between MZ and PC (USB Version)" without issue.

## ROM Compatibility

While not every scenario has been tested, there are reports suggesting that some ROM units may have compatibility issues.

Below are examples of ROMs confirmed to work without issue and ROMs where non-working units have been reported.

If you are sourcing a ROM, it is advisable to choose from the "confirmed working" list where possible.

| Confirmed Working ROMs |
| ---------------------- |
| AT28C64B               |
| CAT28C64BP             |
| M2764A                 |

| ROMs with Reported Non-Working Units |
| ------------------------------------ |
| HN484764G                            |
| M27C64A                              |
| TMM2764D                             |
| TMS2764                              |
| D28C64ACZ                            |

## Arduino Program

Note: I have built the ino code using SDFat 2.2.2.

Use the Arduino IDE to write MZ-80K_SD.ino from the Arduino folder.

This uses the SdFat library, so open the Library Manager from the Arduino IDE menu and install "SdFat."

Searching for "SdFat" will find it. Both "SdFat" and "SdFat - Adafruit Fork" will appear — use "SdFat."

Note) If the Arduino is soldered directly to the board, when writing the Arduino program, disconnect from the MZ-80K system and remove the 74LS04 before writing.

## Connecting to the MZ-80K

The pin numbers of schematic J1 do not match the MZ-80K external expansion connector pin numbers. The pin layout does match, so use the flat cable referring to "Rev1.5.1+MZ-80K Series(6).JPG" in the JPG folder.

The MZ-700 external expansion connector has the same pin layout as the MZ-80K, but uses a card edge connector rather than a pin connector.

![Connection 1](https://github.com/yanataka60/MZ80K_SD/blob/main/JPEG/Rev1.5.5%2BMZ-80K%20Series(1).JPG)

![Connection 2](https://github.com/yanataka60/MZ80K_SD/blob/main/JPEG/Rev1.5.5%2BMZ-80K%20Series(6).JPG)

![Connection 3](https://github.com/yanataka60/MZ80K_SD/blob/main/JPEG/Rev1.5.5%2BMZ-80K%20Series(5).JPG)

![Connection 4](https://github.com/yanataka60/MZ80K_SD/blob/main/JPEG/Rev1.5.5%2BMZ-700.JPG)

## Power Supply

Since the MZ-80K bus does not supply +5V, the original plan was to supply external power via the DC jack, but having the system and power supply together seemed more convenient, so two options are provided: a connector for drawing +5V from inside the system, and the DC jack for external power.

The easiest way to obtain 5V from inside the MZ-80K is to tap it from the adapter used to insert a 27C32 etc. into a 2532 socket.

Note) With the Rev1.5.1 board, startup may occasionally fail when running on external power. Internal power is recommended, but if the FDL command etc. does not respond when running on external power, start up using the following procedure:

　　Power on MZ-80K_SD → Power on MZ-80K → Reset the Arduino.

The Rev1.5.1 board can be brought to Rev1.5.2 equivalence by cutting one trace and adding two wires. See the KAIZOUU folder for details.

Even with the Rev1.5.2 board, some units may occasionally fail to start on power-on. Resetting the system will resolve this, but if it bothers you, try changing "delay(1000)" on line 74 of the Arduino program to something like "delay(1500)."

## Replacing the MONITOR ROM

Note: There is a patched version of the SP-1002 ROM in the OneRom/bin folder.

Apply the following patches to MONITOR SP-1002, MONITOR 1Z-009A, and 1Z-009B.

　0437 : D5 → C3
　0438 : C5 → 04
　0439 : E5 → F0

　0476 : D5 → C3
　0477 : C5 → 07
　0478 : E5 → F0

　04D9 : D5 → C3
　04DA : C5 → 0A
　04DB : E5 → F0

　04F9 : D5 → C3
　04FA : C5 → 0D
　04FB : E5 → F0

　0589 : D5 → C3
　058A : C5 → 10
　058B : E5 → F0

For MZ-700 MONITOR 1Z-009A and 1Z-009B, "FT.MZT" has been created so that patching a RAM copy of MONITOR eliminates the need to replace the ROM.

Place "FT.MZT" in the root of the SD card and execute FD FT[CR] to transfer control to the RAM MONITOR.

A new FDZ command has been added that performs the same function as "FT.MZT." With FDZ, "FT.MZT" is no longer needed.

Also, if you have applied the MZTrans patch for Kōcha Yōkan's "Transferring Data Between MZ and PC (USB Version)" to MONITOR 1Z-009A or 1Z-009B, the F command will be unavailable. Apply the following patch to disable the '#' command and restore the 'F' command.

　00D2 : 23 → 46

　00D4 : 86 → 21

Alternatively, place Kōcha Yōkan's "TR.MZT" in the root of the SD card and execute "FD TR" to use MZTrans.

## BASIC SP-5030 Version Differences

There are reportedly three versions of BASIC SP-5030: old, new, and VER1.0A. The new and VER1.0A versions require patches. If the following addresses point to 4049H and 4069H, it is one of the new or VER1.0A versions and must be corrected as follows.

Addresses are MZT file addresses. Actual addresses are shown in parentheses.

　18C5(1845) : 49 → 27

　18C6(1846) : 40 → 00

　1939(18B9) : 69 → 2A

　193A(18BA) : 40 → 00

　19EA(196A) : 69 → 2A

　19EB(196B) : 40 → 00

　1AE0(1A60) : 69 → 2A

　1AE1(1A60) : 40 → 00

## SD Card

Preferably use an SD card of 8GB or less.

The Arduino SdFat library supports the SD standard (up to 2GB) and SDHC standard (2GB–32GB), but does not support SDXC (32GB–2TB).

Even among SDHC cards, 32GB and 16GB cards may not work due to compatibility issues.

FAT16 and FAT32 are recognized. NTFS is not recognized.

Only MZT files placed in the root directory are recognized. (Other file types and folders are displayed but will not be targeted by LOAD.)

File names may be up to 32 characters excluding ".MZT," however half-width katakana and some symbols are not recognized by the Arduino and cannot be used. When naming files on a PC, use alphabetical characters, numbers, and spaces.

## How to Use

The following commands are available from the MONITOR command prompt. Note that the floppy disk drive launch command for MZ-700 is originally a single character 'F', but for consistency the operation uses 'FD' throughout.

In the following, file names given to files on the SD card are referred to as DOS file names, and file names in the information block of MZT format files are referred to as IBF file names.

### FD[CR]

FD alone loads and executes the DOS file named "0000.MZT."

"0000.MZT" can be created by renaming and copying BASIC SP-5030 etc. on a PC, or it can be created using the FDA command.

### FD　DOS filename[CR]

Loads and executes the binary file specified by DOS filename.

".MZT" may be omitted.

Can be used as a substitute for the MONITOR LOAD command. Note that the LOAD command also works, but is treated the same as a LOAD from an application.

Example

FD　TEST[CR]

### FD/DOS filename[CR] or FD/　DOS filename[CR]

Loads the binary file specified by DOS filename without executing it.

　".MZT" may be omitted.

Example

FD/TEST[CR]

FD/　TEST[CR]

### FDL[CR]

Displays a list of files in the SD card root directory. After displaying 20 entries it waits for input; press SHIFT+BREAK or ↑ to stop, B to go back to the previous 20 entries, or any other key to show the next 20 entries.

Each entry is displayed with "*FD" prepended, so you can move the cursor to the desired file and press [CR] to LOAD and execute it.

Files are displayed in registration order; sorting alphabetically by filename is not possible.

### FDL　x[CR]

Displays a list of files whose names begin with x. After displaying 20 entries it waits for input; press SHIFT+BREAK or ↑ to stop, B to go back to the previous 20 entries, or any other key to show the next 20 entries.

x is a string of up to 32 characters that can be entered from the MZ keyboard (digits, symbols, alphabetical characters).

Example

FDL S[CR]

FDL SP[CR]

FDL BASIC S[CR]

### FDA　DOS filename[CR]

Renames and copies the specified file to "0000.MZT."

Select a file displayed by FDL using the cursor, then simply append "A" to the leading "*FD" and press [CR].

### FDS　SAVE start address　SAVE end address　Execution start address　DOS filename[CR]

Saves from SAVE start address to SAVE end address under the specified DOS filename.

SAVE start address, SAVE end address, and execution start address are specified as 4-digit hexadecimal. ".MZT" in the DOS filename may be omitted.

Example

FDS　1200　2FFF　1200　TEST[CR]

### FDC　DOS filename[CR]

Copies the specified file.

Select a file displayed by FDL using the cursor, then simply append "C" to the leading "*FD" and press [CR].

Enter the DOS filename and press [CR]; it will prompt "NEW NAME:", so enter the new DOS filename and press [CR].

If the new DOS filename already exists, the copy is aborted.

Example

FDC　TEST[CR]

NEW NAME:TEST2[CR]

### FDR　DOS filename[CR]

Renames the specified file.

Select a file displayed by FDL using the cursor, then simply append "R" to the leading "*FD" and press [CR].

Enter the DOS filename and press [CR]; it will prompt "NEW NAME:", so enter the new DOS filename and press [CR].

If the new DOS filename already exists, the rename is aborted.

Example

FDR　TEST[CR]

NEW NAME:TEST2[CR]

### FDD　DOS filename[CR]

Deletes the specified file.

Select a file displayed by FDL using the cursor, then simply append "D" to the leading "*FD" and press [CR].

Enter the DOS filename and press [CR]; it will prompt "FILE DELETE?(Y:OK ELSE:CANSEL)". Press Y to delete, or any other key to cancel.

### FDP　DOS filename[CR]

Dumps the contents of the specified file.

Select a file displayed by FDL using the cursor, then simply append "P" to the leading "*FD" and press [CR].

Enter the DOS filename and press [CR]; the file contents are displayed 128 bytes per screen.

After displaying one screen, "NEXT:ANY BACK:B BREAK:SHIFT+BREAK" is shown and it waits for input. Press B to show the previous 128 bytes, SHIFT+BREAK to stop, or any other key to show the next 128 bytes.

If the file size is not divisible by 128 bytes, the last page is padded with 00H to fill 128 bytes.

File contents cannot be modified.

### FDM　Start address[CR]

Displays MZ-80K memory contents starting at the specified address, 128 bytes per screen.

After displaying one screen, "NEXT:ANY BACK:B BREAK:SHIFT+BREAK" is shown and it waits for input. Press B to show the previous 128 bytes, SHIFT+BREAK to stop, or any other key to show the next 128 bytes.

You can also press SHIFT+BREAK at any time during display to stop.

### FDW　Start address　1-byte (2-digit hex) data[CR]

Writes 2-digit hex data to MZ-80K memory starting at the specified address.

After the start address, enter the data bytes in 2-digit hex and press [CR]. Spaces between data are ignored, so they are optional.

You may enter as many bytes as fit on one line.

After pressing [CR] to write the data, the next address is displayed so you can continue entering data.

You can also correct the address to go back and modify data or write to a different address.

To stop writing, press [CR] at the displayed address without entering data.

If non-hex characters are entered and [CR] is pressed, all valid data up to that point is written and the next address is displayed.

Example

*FDW　1200　01　02　03　04　05　06　07　08[CR]

*FDW　1200　0102030405060708[CR]

*FDW　1200[CR]　(to stop)

*FDW　1200　12　34　5/[CR]　(12 and 34 are written)

### FDZ[CR]

[MZ-700 only] Performs the same function as "FT.MZT" created for the MZ-700. Copies MONITOR 1Z-009A or 1Z-009B to the back RAM, applies patches, and starts the MONITOR on the back RAM.

If executed on an MZ-80K, it performs a RESET.

### FDU[CR]

[MZ-700 only, only when RESET after operating with back RAM MONITOR] Switches to back RAM and starts the MONITOR on the back RAM.

Note: Executing this without a MONITOR in back RAM will cause a crash.

If executed on an MZ-80K, it performs a RESET.

### LOAD from Applications

After the command specified by the application (L, LOAD, etc.), an IBF filename can optionally be specified, but press [CR] with just the command (L, LOAD, etc.) without specifying one.

Where a CMT would prompt you to press the PLAY button, "DOS FILE:" is displayed and the system waits for line input, so enter the DOS filename and press [CR]. ".MZT" may be omitted.

DOS filenames may be up to 32 characters excluding ".MZT," however half-width katakana and some symbols are not recognized by the Arduino and cannot be used. When naming files on a PC, use alphabetical characters, numbers, and spaces.

Example (In BASIC SP-5030):

× LOAD "TEST"[CR]

○ LOAD[CR]

　DOS FILE:TEST[CR]

○ LOAD[CR]

　DOS FILE:TEST.MZT[CR]

** Reference **

When using S-OS SWORD, enter "DV S:" immediately after booting to set the device as the respective SYSTEM device.

With FUZZY BASIC at least (may not apply to others), it was not possible to omit the IBF filename in the LOAD command when using the common format device.

#### Special Commands During LOAD

The following special commands are available when "DOS FILE:" is displayed waiting for input.

##### *FDL[CR]

##### *FDL x[CR]

The same file listing function as FDL and FDL x from the MONITOR command prompt is available.

Search results are displayed with "DOS FILE:" prepended, so move the cursor to the file you want to LOAD and press [CR] to load it.

Some applications return to "DOS FILE:" when you search with "*FDL" and try to load by selecting with the cursor, but pressing [CR] again with the cursor on the file will load it.

### SAVE from Applications

Enter the filename etc. using the input method and rules specified by the application, as you would with CMT.

However, half-width katakana cannot be used as the Arduino does not recognize it. Use alphabetical characters, numbers, and spaces.

During SAVE, the entered filename is applied as both the IBF filename and DOS filename.

".MZT" is automatically appended as the DOS filename extension.

Example (In BASIC SP-5030):

○ SAVE "TEST"[CR]

## Operating Notes

　~~If "SD-CARD INITIALIZE ERROR" is displayed, remove the SD card and reinsert it, then reset the Arduino.~~

　~~If the SD card is removed while power is on and not being accessed, then reinserted and accessed, "SD-CARD INITIALIZE ERROR" may occur. Always reset the Arduino before accessing the SD card after reinsertion.~~

　~~It is safer to insert and remove the SD card with the power off.~~

(2024.3.10) Fixed an issue where removing the SD card while power was on and it was not being accessed prevented the SD card from being accessed again after reinsertion. (Please rewrite the Arduino to the latest version.)

After reinserting the SD card, accessing it about 3 times via FDL, LOAD, SAVE etc. will restore functionality.

If you press [CR] without specifying a DOS filename when saving to SD card, a DOS file named ".MZT" is created. This ".MZT" will be loaded if [CR] is pressed without specifying a DOS filename when LOADing from an application, potentially causing unexpected behavior, so it is advisable to delete it if created.

Note that ".MZT" is currently not recognized by the FDR or FDD commands, so delete it from a Windows PC.

## Results of Testing SD Card Read/Write

Successfully read and written (alphabetical order)

　　BASE-80 Ver35 [I/O April 1981]

　　BASIC SP-5030 (some versions require a patch)

　　CAP-X Interpreter [I/O May 1980]

　　EDASM V1.2B [Oh!MZ January 1985]

　　FORM VER1.0 (Note 3) [I/O June 1980]

　　FORTRAN-MZ V.1 [I/O January 1981]

　　GAME-MZ80K V.1 (Note 1) [ASCII October 1979]

　　HU-BASIC V1.3

　　KM-BASIC ver 0.8.3-beta (Note 2)

　　LSI Assembler (Note 1) [ASCII November 1979]

　　M-FORTH/MZ V1.1 (Note 1) [I/O March 1981]

　　micro PASCAL-MZ VER 2.2 [ASCII June 1980]

　　MONIOS [Monthly Microcomputer February 1982]

　　PALL [I/O December 1979]

　　S-OS SWORD (including S-OS applications) [Oh!MZ February 1986] [Reprinted Oh!MZ March 1987]

　　SELF RELOCATABLE DEBUGGER [I/O November 1980]

　　SP-2101 Z80 ASSEMBLER

　　SP-2201 TEXT EDITOR

　　SP-2301 RELOCATE LOADER

　　SP-2401 SYMB DEBUGGER

　　TL/1 (Note 1) (Note 3) [ASCII May 1981]

　　TTL VERSION 1.1 [Oh!MZ October 1984]

　　WICS INTERPRETER VER 1.1 (Note 3) [I/O October 1981]

　　8080 Text Editor & Assembler [I/O September 1980]

　　Machine Language Monitor [I/O October 1979] [I/O Compilation: MZ-80 Utilization Research]

　　Integer BASIC Compiler for MZ-80K/C, MZ-1200 (Note 1) (Note 3) [Suwa Kobo]

Note 1) This application does not support the MZ-700. To run on the MZ-700, NZ-700, the MZ-700-compatible version of SP-1002 published in the 0h!MZ special edition ADVANCED MZ-700, is required. By applying the same MZ-80K_SD patches to NZ-700 as to SP-1002, LOAD and SAVE become available on the MZ-700 as well.

Note 2) It appears that a filename cannot be specified with the SAVE command. Using SAVE[CR] saved the file with the filename "KMB-FILE VER 1.0."

Note 3) When searching from the LOAD command with "*FDL," selecting with the cursor, and trying to load, it returns to "DOS FILE:", but pressing [CR] again with the cursor on the file will load it.

　Could not read or write

　　EDAS FOR MZ-1200 VER 1.2 [I/O November 1982]

　　EXIT MONITOR [ASCII June 1981]

## Programs Confirmed to Boot for MZ-700

　　S-BASIC 1Z-007B (a patch to enable SD support for LOAD and SAVE has been released)

　　S-OS SWORD (to use SD card with MZ-700 SWORD, the MONITOR ROM must be rewritten. Even executing "FT.MZT" or FDZ without rewriting the MONITOR ROM, LOAD and SAVE after booting will use CMT)

　　HUBASIC VERSION 2.0A (LOAD and SAVE after booting use CMT)

　　tiny XEVIOUS mz-700

　　Time Secret (all programs must be saved as separate files)

　　Time Tunnel (all programs must be saved as separate files)

　　TS-700 (published in "I/O Special Edition: WICS/BASE Program Collection"; see TS-700 folder)

　　SuperBASE-700 (published in "I/O Special Edition: WICS/BASE Program Collection"; see TS-700 folder)

　　WICS Interpreter, Compiler (published in "I/O Special Edition: WICS/BASE Program Collection"; see TS-700 folder)

Note that even applications not confirmed to boot may be launchable via the FD command.

## Specifying a DOS Filename to Load from MZ-80K_SD in a Custom Application

When adding a process to load binary data (data files, machine language programs, etc.) from MZ-80K_SD in a custom MZ-80K application, you call F00Ah (MLHED) to input the DOS filename and then call F00Dh (MLDAT) to load the data, so it is not possible to specify the DOS filename within the application itself.

By incorporating and calling the following machine language in your application, you can specify the DOS filename from within the application.

After that, call F00DH to execute the LOAD from SD.

| Code                  |
| --------------------- |
| MLHED:　　LD　　　DE,FNAME |
| DI                    |
| PUSH　　DE              |
| PUSH　　BC              |
| PUSH　　HL              |
| CALL　　F082H           |
| PUSH　　DE              |
| XOR　　　A               |
| LD　　　DE,0000H         |
| CALL　　0033H           |
| POP　　　DE              |
| JP　　　F85BH            |
| FNAME:                |
| DB　　　'TEST',0DH       |

#### Specifying a DOS Filename to Load from MZ-80K_SD within a BASIC SP-5030 Program

When using with BASIC SP-5030, place the following machine language at a suitable address and call it from BASIC.

Since it is only a small amount of machine language, it is convenient to put it in DATA statements within the BASIC program, reserve a machine language area with the LIMIT statement, read it with READ statements, and write it to memory with POKE statements.

| Code          |
| ------------- |
| MLHED:　　DI    |
| PUSH　　DE      |
| PUSH　　BC      |
| PUSH　　HL      |
| CALL　　F082H   |
| PUSH　　DE      |
| XOR　　　A       |
| LD　　　DE,0000H |
| CALL　　0033H   |
| POP　　　DE      |
| JP　　　F85BH    |

DATA 243,213,197,229,205,130,240,213,175,017,000,000,205,051,000,209

DATA 195,091,248

##### Calling from BASIC SP-5030

| Code          | Notes                                                                                                                                                                                                        |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| G$="TEST"     | Assign the DOS filename string to a string variable                                                                                                                                                          |
| USR($C000,G$) | Execute the USR function with the address where the machine language is placed and the string variable containing the DOS filename (in SP-5030, the string assigned to a string variable has 0Dh at the end) |
| USR($F00D)    | LOAD data from SD                                                                                                                                                                                            |

#### Specifying a DOS Filename for MZ-700

For applications running on MONITOR 1Z-009A(B), if bank switching to the ROM from F000h (OUT (E3h),A) is taken into account, it should be possible to specify the filename by calling machine language in the same way as for MZ-80K.

Specifying a DOS filename from S-BASIC requires resolving, in addition to bank switching, differences such as the string assigned to a string variable ending with 00h and the position of the information block (IFB) differing from MONITOR 1Z-009A(B); it may be a high hurdle for those who cannot work through these differences.

## MZ-80K_SD Compatibility Patch for the MZ-700 Version of Ropoko

Ropoko for MZ-80K supports MZ-80K_SD, but the original MZ-700 version of Ropoko does not.

Author Tookato has released Ropoko Version 1.2.2, which includes an uncompressed version of Ropoko. A patch has been created to make it MZ-80K_SD compatible, and is now being released.

#### 2024.7.31: Made compatible with MZ-1500_SD as well. If you are only using MZ-700+MZ-80K_SD, you do not need to re-download.

### How to Use

Obtain Ropoko Version 1.2.2.

After extracting, you will find ROPOKO-PR.MZT, ROPOKO-AR.MZT, and ROPOKO-BR.MZT in the "Uncompressed" folder; copy these to the SD card.

Copy "ROPOKO-SD.MZT" from the "ROPOKO" folder in this GitHub MZ80K_SD repository to the SD card.

Use the FDL or FD command to execute "ROPOKO-SD.MZT" copied to the SD card.

ROPOKO-PR.MZT is automatically read in, the SD-compatible patch is applied, and Ropoko starts.

#### 2024.8.2: Tookato has reported that when Ropoko successfully boots from SD on MZ-700+MZ-80K_SD, you should switch the S2 switch from SD to CMT before starting the game. Continuing with SD may cause garbled characters.

To load a scenario, for example select Scenario A, and after "Please set the tape" is displayed, press CR once; "DOS FILE:" is displayed, so enter "ROPOKO-AR" correctly and press CR to begin loading.

For data save/load, press F3, select S:Save or L:Load, and you will be prompted for a filename. Use filenames starting with "SA-" for the A side and "SB-" for the B side, giving different names such as "SA-1/2/3...", the same as the original.

However, if you specify an existing filename during SAVE, it will be overwritten, so please be careful.

### ROM Disconnect Switch Modification

MZ-80K_SD was only designed for MZ-700 use to the extent of operating as an MZ-80K compatible machine, so as reported by Tookato, playing the MZ-700 version of Ropoko with the MZ-80K_SD compatibility patch causes garbled characters due to conflicts with RAM.

This can be avoided by switching the S2 switch from SD to CMT after Ropoko boots from SD before starting the game, but once the game has started it is even safer to disconnect the ROM entirely.

The following pattern cut and slide switch addition allows ROM disconnection.

#### Incorporated as standard in Rev1.5.5.

![rom_discon1](https://github.com/yanataka60/MZ80K_SD/blob/main/JPEG/rom_discon1.jpg)

Cut the trace running just to the left of pin 6 of U5 LS30. Take care not to damage the trace running one further to the left. There is no trace on the pin 6 side, so cutting just to the left of pin 6 is sufficient.

![rom_discon2](https://github.com/yanataka60/MZ80K_SD/blob/main/JPEG/rom_discon2.jpg)

Connect ROM pin 20 and pin 28 with a 10k resistor to pull up pin 20.

Connect ROM pin 20 and U5 LS30 pin 8 to a slide switch.

With the switch ON the ROM is connected; with it OFF the ROM is disconnected.

First set the slide switch to the ROM-connected side and start Ropoko. Once Ropoko has started, set the slide switch to the ROM-disconnected side before starting the game.

![rom_discon3](https://github.com/yanataka60/MZ80K_SD/blob/main/JPEG/rom_discon3.jpg)

This is how it looks from the component side.

## MZ-80K_SD Compatibility Patch for Ropoko (Trial Version)

A patch has also been created for the Ropoko trial version, similar to the MZ-700 version.

### How to Use

Obtain the Ropoko trial version.

After extracting, you will find ROPOKO-TR.mzt in the "Uncompressed" folder; copy it to the SD card.

Copy "ROPOKO-T-SD.MZT" from the "ROPOKO-TRIAL" folder in this GitHub MZ80K_SD repository to the SD card.

Use the FDL or FD command to execute "ROPOKO-T-SD.MZT" copied to the SD card.

ROPOKO-TR.mzt is automatically read in, the SD-compatible patch is applied, and the Ropoko trial version starts.

For data save/load, press F3, select S:Save or L:Load, and you will be prompted for a filename. Use filenames starting with "SA-" for the A side and "SB-" for the B side, giving different names such as "SA-1/2/3...", the same as the original.

However, if you specify an existing filename during SAVE, it will be overwritten, so please be careful.

## Dedicated Tray

A dedicated tray for MZ-80K_SD to place over the cassette section has been released.

https://yanataka.booth.pm/items/6058283

For MZ-1200, see here:

https://yanataka.booth.pm/items/6069703

## Acknowledgements

The following data was used in creating the board. Thank you very much.

Arduino Pro Mini

　https://github.com/g200kg/kicad-lib-arduino

AE-microSD-LLCNV

　https://github.com/kuninet/PC-8001-SD-8kRAM

In adding MZ-700 support, Kōcha Yōkan's "Transferring Data Between MZ and PC (USB Version)" was very helpful. Thank you very much.

The following people provided cooperation and advice in resolving unstable operation. Thank you very much. (Alphabetical order)

　　EIJ

　　hlide fremen

　　junk_suga

　　retrogamer128

A report was received of a build using a MicroSD Card Adapter compatible with the 5V power used with Arduino etc. Thank you very much.

　　𝕊𝕖ñ𝕠𝕣 𝔼𝕤𝕥𝕖𝕓𝕒𝕟

## Updates

2021.12.12

Realized that if you only want to use the MZ-700 as a substitute for the MZ-80K, starting NZ-700 first means you don't need to burn a patched ROM. Setting up the FD command to start NZ-700 may actually make the MZ-700 a lower-hurdle option.

2021.12.12

Created "FT.MZT" for the MZ-700.

2021.12.13

Updated schematic MZ80K_SD.pdf in KiCad\MZ80k_SD folder to Rev1.1.

2021.12.13

Identified the cause of an issue where, when trying to LOAD an application from S-OS SWORD on the MZ-80K, only the very first attempt would stall at reading the information block and required pressing a key to continue: FLGET's DEBUG had accidentally included MZ-700-specific corrections. Reverting this resolved the issue.

2021.12.14

Released a patch to enable SD card support for S-BASIC.

2021.12.18 2021.12.19 2021.12.21

(Depending on the MZ-80K's power conditions, internal power may cause instability. If unstable behavior occurs, try external power.)

The instability noted yesterday was not due to power but because the 28C64 was a defective unit or had individual variation causing it to be affected by the CRT's magnetic field.

Although individual variation in 28C64 is suspected, there was a bug in the program that should have absorbed this, which has been fixed.

2021.12.20

To support 27C64, connected pin 1 of the ROM to VCC and updated the board to Rev1.2.

2021.12.24

Decided to add pull-up resistors to improve stability. Planning to release once verification of the schematic and board data is complete. Also found a bug in the error handling, which will also be released after testing.

2021.12.26

Fixed the error handling bug. Circuit fix to follow at a later date.

2021.12.29

Obtained MZ-700 MONITOR 1Z-009A and confirmed there are no operational issues.

2022.1.19

GAL was identified as the likely cause of instability and has been replaced with TTL. In the test environment it has been very stable so far.

Issues previously attributed to instability — internal vs. external power, individual differences in 28C64, CRT magnetic effects, pull-up resistors, etc. — have all been resolved by switching to TTL.

2022.1.23

Fixed a bug in the alternative processing for 04D8H MONITOR Read Information. Resolved errors that occurred during LOAD of HU-BASIC V1.3 and the 8080 Text Editor & Assembler.

2022.1.24

Moved trailing-space handling for SAVE filenames from the Arduino side to the MZ-80K side.

Reviewed comparison operator descriptions in Arduino code.

2022.1.25

Removed 8255 initialization from 0475H MONITOR Write Data alternative processing and 04F8H MONITOR Read Data alternative processing.

Removed delay() on each command receive on the Arduino side.

2022.1.26

Removed the restriction that only file type code 0x01 was loadable via the FD command.

2022.1.28

Added new FDZ and FDU commands that perform the same function as "FT.MZT" for MZ-700.

2022.1.29

Removed interrupt enable (EI) on return from CMT substitute processing that was causing applications to freeze during LOAD/SAVE in certain environments.

Fixed an issue where display became corrupted when going back to the previous page with the FDP command.

2022.1.30

FDL command spec change: when using FDL A–Z, only entries whose first character matches are output.

2022.1.31

FDL command spec change: removed page specification by FDL n. FDL x now performs prefix matching on all characters enterable from the keyboard. Added ability to go back to the previous 20 entries with the B key.

Fixed an issue where machine/app operation would freeze after executing the FD command.

2022.2.2

Fixed FDL x search to work even when DOS filenames contain lowercase alphabetical characters.

2022.2.4

Added MZ-1200 countermeasure to Arduino.

2022.2.9

FDL command spec change: comparison string for FDL x limited to 32 characters or fewer.

2022.2.10

Added notes on ROM compatibility.

Implemented the ability to use the FDL command from within an application's LOAD command.

2022.2.11

Fixed a bug where the ability to use the FDL command from within an application's LOAD command did not work under MZ-700 MONITOR 1Z-009A or 1Z-009B.

2022.2.15

Added instructions for dealing with startup failures on external power.

2022.2.26

Updated board to Rev1.5.2. Addressed issue of startup failures when running on external power. Published modification method to bring Rev1.5.1 up to Rev1.5.2 equivalence.

2022.3.27

Fixed orientation of silkscreen on board.

Added notes on behavior when saving from an application without specifying a DOS filename.

2022.3.28

Typo correction: "FDC and FDD commands" → "FDR and FDD commands."

2022.4.8

Even with the Rev1.5.2 board, some units may occasionally fail to start on power-on. Resetting the system will resolve this, but if it bothers you, try changing "delay(1000)" on line 74 of the Arduino program to something like "delay(1500)."

2022.4.24

Fixed constants in KiCad Library.

2022.5.31

Fixed a misleading expression.

Before: "If you press [CR] without specifying a DOS filename,"

After: "If you press [CR] without specifying a DOS filename when saving to SD card,"

2022.6.29

Released the Windows tool "CMT2SD_CHECK" for patching applications to enable SD load/save.

Added net labels to the schematic.

2022.6.30

Replaced "FD_rom.BIN" in the Z80 folder with the new version.

When using applications patched with "CMT2SD_CHECK," replacement with the new "FD_rom.BIN" is required.

2022.8.4

Added a note about precautions when writing the Arduino program if the Arduino is soldered directly to the board.

2022.9.11

Added a terminal for MicroSD Card Adapter and updated board to Rev1.5.3.

2023.6.19

Modified the Arduino program due to an additional boot method for MZ-2000_SD. No impact on MZ-80K_SD.

2023.9.20

Added support for TS-700, SuperBASE-700, WICS Interpreter, and Compiler published in "I/O Special Edition: WICS/BASE Program Collection."

2023.9.23

Added "D28C64ACZ," reported by Tookato, to the list of ROMs with reported non-working units.

2024.1.15

Added a note that SD cards of 8GB or less are preferable.

2024.3.4

Added the section "Specifying a DOS Filename to Load from MZ-80K_SD in a Custom Application."

2024.3.10

Fixed an issue where removing the SD card while power was on prevented the SD card from being accessed again after reinsertion.

2024.7.29

Released a patch to make Tookato's MZ-700 Ropoko Version 1.2.2 compatible with MZ-80K_SD.

2024.7.31

Made the MZ-700 Ropoko Version 1.2.2 compatibility patch shared with MZ-1500_SD.

2024.8.2

At Tookato's suggestion, added a note that when playing Ropoko on MZ-700+MZ-80K_SD, the S2 switch must be switched from SD to CMT after booting from SD.

2024.8.8

Added instructions for installing the ROM disconnect switch.

2024.9.1

Released the dedicated tray.

2024.10.10

Added descriptions of the Rev1.5.5 board with the ROM disconnect switch as standard, and MZ-700_SD with automatic switching.

2025.7.31

Added notes on operation with the MZ-80 series.

2025.12.4

kuran_kuran discovered a bug in the Arduino program. Upon investigation, it was found to be caused by unnecessary processing being included, which has been removed. There is no actual harm if left unpatched. Thank you, kuran_kuran.