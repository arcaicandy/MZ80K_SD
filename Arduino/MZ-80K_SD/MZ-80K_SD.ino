// 2022. 1.24 Moved the process for correcting trailing 0x20 padding in filenames to 0x0D from the Arduino side to the MZ-80K side
//            Revised comparison operator descriptions
// 2022. 1.25 Removed delay() calls when receiving each command
// 2022. 1.26 Lifted the restriction that only file type code 0x01 was loadable via the FD command
// 2022. 1.29 Fixed bug in FDP command
// 2022. 1.30 FDL command spec change: when FDL A–Z is used, only files whose first character matches are output
// 2022. 1.31 FDL command spec change: when FDL x is used, only files whose first character matches are output
//            Press B key to display the previous 20 entries
// 2022. 2. 2 Fixed FDL x search to work even when DOS filenames are in lowercase
// 2022. 2. 4 MZ-1200 countermeasure: added delay(1000) during initialization
// 2022. 2. 8 FDL command spec change: when FDL x is used, comparison expanded from first 1 character up to 32 characters of filename
// 2023. 6.19 Added BOOT LOADER loading due to addition of MZ-2000_SD boot method. No impact on MZ-80K_SD.
// 2024. 3. 4 Added initialization process for SD card re-insertion
// 2025.12. 4 Removed unnecessary appendmzt call that was present in mon_ldata processing
// 2026.06.23 AJ - Translated - Reworked card handling, added removable debug messages. Fixed issues with endian, general performance/efficiancy improvements
// 2026.06.23 AJ - Tested only with v2.2.2 of SDFAT

#include "SdFat.h"
#include <SPI.h>

#define DEBUG 0  // Set to 0 to disable all debug output

#if DEBUG
  #define DBG_PRINT(x) Serial.print(x)
  #define DBG_PRINTLN(x) Serial.println(x)
  #define DBG_PRINTFMT(x, fmt) Serial.print(x, fmt)
#else
  #define DBG_PRINT(x)
  #define DBG_PRINTLN(x)
  #define DBG_PRINTFMT(x, fmt)
#endif

#define INIT_DELAY_MS   1500

#define SD_SCK_FREQUENCY (4)

#define CABLESELECTPIN  (10)
#define CHKPIN          (15)
#define FLGPIN          (14)

#define PB0PIN          (2)
#define PB1PIN          (3)
#define PB2PIN          (4)
#define PB3PIN          (5)
#define PB4PIN          (6)
#define PB5PIN          (7)
#define PB6PIN          (8)
#define PB7PIN          (9)

#define PA0PIN          (16)
#define PA1PIN          (17)
#define PA2PIN          (18)
#define PA3PIN          (19)

SdFat SD;

unsigned long m_lop=128;
byte s_data[260];
char m_name[40];
char f_name[40];
char c_name[40];
char new_name[40];

boolean sdinit(void){

  DBG_PRINTLN(F("Initialising SD Card"));

  // SD initialization
  if (SD.begin(SdSpiConfig(CABLESELECTPIN, DEDICATED_SPI, SD_SCK_MHZ(SD_SCK_FREQUENCY)))) {

    DBG_PRINTLN(F("SD Initialised successfully"));
    
    return true;
    
  } else {

    DBG_PRINTLN(F("SD Initialisation failed"));

    return false;
  }
}

void setup(){

  #if DEBUG
    Serial.begin(115200);
  #endif
  
  DBG_PRINTLN(F("Setup start..."));

  pinMode(CABLESELECTPIN,OUTPUT);
  
  pinMode( CHKPIN,INPUT);         // CHK

  pinMode( PB0PIN,OUTPUT);        // Transmit data
  pinMode( PB1PIN,OUTPUT);        // Transmit data
  pinMode( PB2PIN,OUTPUT);        // Transmit data
  pinMode( PB3PIN,OUTPUT);        // Transmit data
  pinMode( PB4PIN,OUTPUT);        // Transmit data
  pinMode( PB5PIN,OUTPUT);        // Transmit data
  pinMode( PB6PIN,OUTPUT);        // Transmit data
  pinMode( PB7PIN,OUTPUT);        // Transmit data
  
  pinMode( FLGPIN,OUTPUT);        // FLG
  
  pinMode( PA0PIN,INPUT_PULLUP);  // Receive data
  pinMode( PA1PIN,INPUT_PULLUP);  // Receive data
  pinMode( PA2PIN,INPUT_PULLUP);  // Receive data
  pinMode( PA3PIN,INPUT_PULLUP);  // Receive data
  
  digitalWrite(PB0PIN,LOW);
  digitalWrite(PB1PIN,LOW);
  digitalWrite(PB2PIN,LOW);
  digitalWrite(PB3PIN,LOW);
  digitalWrite(PB4PIN,LOW);
  digitalWrite(PB5PIN,LOW);
  digitalWrite(PB6PIN,LOW);
  digitalWrite(PB7PIN,LOW);
  digitalWrite(FLGPIN,LOW);

  delay(INIT_DELAY_MS);

  DBG_PRINTLN(F("Setup complete."));
}

//Receive 4 bits
byte rcv4bit(void){
  
  //Loop until HIGH
  while(digitalRead(CHKPIN) != HIGH){
  }
  
  //Receive
  byte j_data = digitalRead(PA0PIN)+digitalRead(PA1PIN)*2+digitalRead(PA2PIN)*4+digitalRead(PA3PIN)*8;

  //Set FLG
  digitalWrite(FLGPIN,HIGH);

  //Loop until LOW
  while(digitalRead(CHKPIN) == HIGH){
  }
  
  //Reset FLG
  digitalWrite(FLGPIN,LOW);
  
  return(j_data);
}

//Receive 1 byte
byte rcv1byte(void){
  
  byte i_data = 0;

  i_data = rcv4bit() * 16;
  i_data = i_data + rcv4bit();
  
  return(i_data);
}

// Transmit 1 byte
void snd1byte(byte i_data) {
  
  //Set 8 bits starting from the least significant bit
  digitalWrite(PB0PIN,(i_data)&0x01);
  digitalWrite(PB1PIN,(i_data>>1)&0x01);
  digitalWrite(PB2PIN,(i_data>>2)&0x01);
  digitalWrite(PB3PIN,(i_data>>3)&0x01);
  digitalWrite(PB4PIN,(i_data>>4)&0x01);
  digitalWrite(PB5PIN,(i_data>>5)&0x01);
  digitalWrite(PB6PIN,(i_data>>6)&0x01);
  digitalWrite(PB7PIN,(i_data>>7)&0x01);
  digitalWrite(FLGPIN,HIGH);

  //Loop until HIGH
  while(digitalRead(CHKPIN) != HIGH){
  }
  
  digitalWrite(FLGPIN,LOW);

//Loop until LOW
  while(digitalRead(CHKPIN) == HIGH){
  }
}
/*
// Lowercase -> Uppercase
char upper(char c){
  
  if('a' <= c && c <= 'z'){
    c = c - ('a' - 'A');
  }
  return c;
}
*/

//****************************************************
// Append ".mzt" if f_name does not already end with it
//****************************************************
void appendmzt(char *f_name){
  
  unsigned int lp1=0;

  while (f_name[lp1] != 0x0D){
    lp1++;
  }
  
  if (f_name[lp1-4]!='.' ||
    ( f_name[lp1-3]!='M' &&
      f_name[lp1-3]!='m' ) ||
    ( f_name[lp1-2]!='Z' &&
      f_name[lp1-2]!='z' ) ||
    ( f_name[lp1-1]!='T' &&
      f_name[lp1-1]!='t' ) ){
         f_name[lp1++] = '.';
         f_name[lp1++] = 'm';
         f_name[lp1++] = 'z';
         f_name[lp1++] = 't';
  }
  
  f_name[lp1] = 0x00;
}

//****************************************************
// SD card file directory - 
//   FDL
//   FDL <searchspec>
//****************************************************
void dirlist(void){

  DBG_PRINTLN(F("SD Card directory..."));

  // Get requested comparison string entered on the MZ80K (up to 32+1 characters)
  // The string received will be everything after FDL including the required space
  for (unsigned int lp1 = 0; lp1 <= 32; lp1++){
    c_name[lp1] = rcv1byte();
  }

  DBG_PRINT(F("Search string : ["));
  DBG_PRINT(c_name);
  DBG_PRINTLN(F("]"));

  // Open the root directory of the SD Card
  File file = SD.open( "/" );

  // Get the first file entry
  File entry = file.openNextFile();
  
  unsigned int cntl2 = 0;
  unsigned int br_chk = 0;
  unsigned int page = 1;

  // For full output, pause after every 20 entries; key input selects continue or abort
  while (br_chk == 0) {

    // Got a file entry from SD Card
    if (entry){

      // Get its file name (max 36 chars)
      entry.getName(f_name, 36);

      unsigned int lp1 = 0;

      // Compare filename against comparison string
      //
      if (f_match(f_name, c_name + 1)){

        DBG_PRINT(F("Matching file : ["));
        DBG_PRINT(f_name);
        DBG_PRINTLN(F("]"));

        // Matches so send one entry to MZ80K
        while (lp1<=36 && f_name[lp1]!=0x00){
          snd1byte(toupper((unsigned char) f_name[lp1]));
          lp1++;
        }
        
        snd1byte(0x0D);
        snd1byte(0x00);

        cntl2++;
      }
    }
    
    if (!entry || cntl2 > 19){
      
      //Request continue/abort selection
      snd1byte(0xfe);

      //Receive selection (0: continue, B: previous page, other: abort)
      br_chk = rcv1byte();

      //Previous page processing
      if (br_chk == 0x42){

        // Go to first file
        file.rewindDirectory();

        //Update entry value
        entry =  file.openNextFile();

        // Go to first file again
        file.rewindDirectory();
        
        // If current page is 1 or 2, go back to page 1
        if(page <= 2){
          
          page = 0;
          
        // If current page is 3 or later, skip files up to two pages back
        } else {

          page = page - 2;
          cntl2=0;

          while(cntl2 < page*20){
            
            if (entry) entry.close();
            
            entry =  file.openNextFile();
            
            if (f_match(f_name, c_name + 1)){
              cntl2++;
            }
          }
        }
        
        br_chk=0;
      }
      
      page++;
      cntl2 = 0;
    }

    // If more files remain, read the next one; otherwise signal abort
    if (entry){
      entry.close();
      entry = file.openNextFile();
    }else{
      br_chk=1;
    }

    // If FDL results are fewer than 20 entries, end without requesting continue
    if (!entry && cntl2 < 20 && page ==1){
      break;
    }
  }

  if (entry) entry.close();

  // Signal end of processing
  snd1byte(0xFF);
  snd1byte(0x00);
}

//****************************************************
// Load from SD card 
//   FD <filename>, 
//   FD/<filename>   (Load but dont execute)
//****************************************************
void f_load(void) {
  
  // Get filename
  for (unsigned int lp1 = 0;lp1 <= 32;lp1++){
    f_name[lp1] = rcv1byte();
  }

  appendmzt(f_name);

  DBG_PRINT(F("Loading : "));
  DBG_PRINTLN(f_name);

  // If file does exist
  if (SD.exists(f_name) == true) {

    DBG_PRINTLN(F("File exists"));

    // Open file
    File file = SD.open(f_name, FILE_READ);
    
    if( true == file ) {
      
      DBG_PRINTLN(F("File opened"));
      
      // Send status code (OK)
      snd1byte(0x00);

      int wk1 = 0;

      // Get file type (1st byte)
      wk1 = file.read();
      DBG_PRINT(F("File type: "));
      DBG_PRINTLN(wk1);

      // Get file name (17 bytes)
      for (unsigned int lp1 = 1; lp1 <= 17; lp1++){
        wk1 = file.read();
        snd1byte(wk1);
      }

      // Get file size (2 bytes little endian)
      file.seek(0x12);
      unsigned int f_length1 = file.read();
      unsigned int f_length2 = file.read();
      unsigned int f_length = (f_length2 * 256) + f_length1;

      DBG_PRINT(F("File length: "));
      DBG_PRINTFMT(f_length, HEX);
      DBG_PRINTLN(F(""));

      // Get start address (2 bytes little endian)
      file.seek(0x14);
      unsigned int s_adrs1 = file.read();
      unsigned int s_adrs2 = file.read();
      unsigned int s_adrs = (s_adrs2 * 256) + s_adrs1;

      DBG_PRINT(F("Start address: "));
      DBG_PRINTFMT(s_adrs, HEX);
      DBG_PRINTLN(F(""));

      //Get execution address (2 bytes little endian)
      file.seek(0x16);
      unsigned int g_adrs1 = file.read();
      unsigned int g_adrs2 = file.read();
      unsigned int g_adrs = (g_adrs2 * 256) + g_adrs1;
      
      DBG_PRINT(F("Execution address: "));
      DBG_PRINTFMT(g_adrs, HEX);
      DBG_PRINTLN(F(""));

      snd1byte(s_adrs1);
      snd1byte(s_adrs2);
      snd1byte(f_length1);
      snd1byte(f_length2);
      snd1byte(g_adrs1);
      snd1byte(g_adrs2);

      // Send actual code (Starts at 0x80)
      DBG_PRINTLN(F("Sending file contents to MZ80K"));

      file.seek(128);
        
      for (unsigned int lp1 = 0; lp1 < f_length; lp1++){
        byte i_data = file.read();
        snd1byte(i_data);
      }

      file.close();
      DBG_PRINTLN(F("File closed"));

    // File didnt open
    } else {
      //Send status code (ERROR)
      DBG_PRINTLN(F("Failed to open file"));
      snd1byte(0xFF);
    }  
  // File does not exist
  //Send status code (FILE NOT FIND ERROR)
  } else {
    DBG_PRINTLN(F("File not found"));
    snd1byte(0xF1);
  }
}

//****************************************************
// Save to SD card - FDS SSSS EEEE XXXX NNNNNNNNNNN
//****************************************************
void f_save(void){
  
  char p_name[20];

  // Get save filename
  for (unsigned int lp1 = 0;lp1 <= 32;lp1++){
    f_name[lp1] = rcv1byte();
  }

  appendmzt(f_name);

  DBG_PRINT(F("Saving: "));
  DBG_PRINTLN(f_name);

  // Get program name
  for (unsigned int lp1 = 0;lp1 <= 16;lp1++){
    p_name[lp1] = rcv1byte();
  }
  
  p_name[15] =0x0D;
  p_name[16] =0x00;

  DBG_PRINT(F("Program name: "));
  DBG_PRINTLN(p_name);

  // Get start address
  int s_adrs1 = rcv1byte();
  int s_adrs2 = rcv1byte();
  unsigned int s_adrs = s_adrs1+s_adrs2*256;

  DBG_PRINT(F("Start address: "));
  DBG_PRINTFMT(s_adrs, HEX);
  DBG_PRINTLN(F(""));

  // Get end address
  int e_adrs1 = rcv1byte();
  int e_adrs2 = rcv1byte();
  unsigned int e_adrs = e_adrs1+e_adrs2*256;

  DBG_PRINT(F("End address: "));
  DBG_PRINTFMT(e_adrs, HEX);
  DBG_PRINTLN(F(""));

  // Get execution address
  int g_adrs1 = rcv1byte();
  int g_adrs2 = rcv1byte();
  unsigned int g_adrs = g_adrs1+g_adrs2*256;

  DBG_PRINT(F("Execution address: "));
  DBG_PRINTFMT(g_adrs, HEX);
  DBG_PRINTLN(F(""));

  // Calculate file size
  unsigned int f_length = e_adrs - s_adrs;
  unsigned int f_length1 = f_length % 256;
  unsigned int f_length2 = f_length / 256;

  DBG_PRINT(F("File size: "));
  DBG_PRINTFMT(f_length, HEX);
  DBG_PRINTLN(F(""));

  // Delete file if it already exists
  if (SD.exists(f_name) == true){
    SD.remove(f_name);
    DBG_PRINTLN(F("Existing file deleted."));
  }
  
  // Open file
  File file = SD.open( f_name, FILE_WRITE );

  if( true == file ){
    
    DBG_PRINTLN(F("File opened"));

    //Send status code (OK)
    snd1byte(0x00);

    // Set file mode (01)
    file.write(char(0x01));
    
    // Program name
    file.write(p_name);
    file.write(char(0x00));

    // File size
    file.write(f_length1);
    file.write(f_length2);

    // Start address
    file.write(s_adrs1);
    file.write(s_adrs2);

    // Execution address
    file.write(g_adrs1);
    file.write(g_adrs2);
    
    // Pad with 0x00 up to 0x7F
    for (unsigned int lp1 = 0;lp1 <= 103;lp1++){
      file.write(char(0x00));
    }
    
    // Actual data
    long lp1 = 0;
    
    while (lp1 <= f_length-1){
      
      int i=0;

      while(i<=255 && lp1<=f_length-1){
        s_data[i]=rcv1byte();
        i++;
        lp1++;
      }
      
      file.write(s_data,i);
    }
    
    file.close();

    DBG_PRINTLN(F("File written"));

   } else {

    DBG_PRINTLN(F("Failed to open file"));

    //Send status code (ERROR)
    snd1byte(0xF1);
  }
}

/*
// Compare f_name and c_name until 0x00 appears in c_name
//FILENAME COMPARE
boolean f_match(char *f_name,char *c_name){
  
  boolean flg1 = true;
  unsigned int lp1 = 0;
  
  while (lp1 <= 32 && c_name[0] != 0x00 && flg1 == true){

    if (toupper((unsigned char) f_name[lp1]) != c_name[lp1+1]){
      flg1 = false;
    }
    
    lp1++;

    if (c_name[lp1+1]==0x00){
      break;
    }
  }

  return flg1;
}
*/

// Compare f_name (uppercased) against c_name until null terminator in c_name
boolean f_match(const char *f_name, const char *c_name) {
  
  const char *cp = c_name;

  unsigned int i  = 0;

  while (i < 32 && *cp != '\0') {
    
    if (toupper((unsigned char) f_name[i]) != *cp) {
      return false;
    }
    
    i++;
    cp++;
  }

  return true;
}

//FILE DELETE
void f_del(void){
//Get filename
  for (unsigned int lp1 = 0;lp1 <= 32;lp1++){
    f_name[lp1] = rcv1byte();
  }
  appendmzt(f_name);
//ERROR if file does not exist
  if (SD.exists(f_name) == true){
//Send status code (OK)
    snd1byte(0x00);
//Receive operation selection (0: proceed with DELETE, other: CANCEL)
    if (rcv1byte() == 0x00){
      if (SD.remove(f_name) == true){
//Send status code (OK)
        snd1byte(0x00);
      }else{
//Send status code (Error)
        snd1byte(0xf1);
      }
    } else{
//Send status code (Cancel)
      snd1byte(0x01);
    }
  }else{
//Send status code (Error)
        snd1byte(0xf1);
  }
}

//FILE RENAME
void f_ren(void){
//Get current filename
  for (unsigned int lp1 = 0;lp1 <= 32;lp1++){
    f_name[lp1] = rcv1byte();
  }
  appendmzt(f_name);
//ERROR if file does not exist
  if (SD.exists(f_name) == true){
//Send status code (OK)
    snd1byte(0x00);
//Get new filename
    for (unsigned int lp1 = 0;lp1 <= 32;lp1++){
      new_name[lp1] = rcv1byte();
    }
    appendmzt(new_name);
//Send status code (OK)
    snd1byte(0x00);
    File file = SD.open( f_name, FILE_WRITE );
    if( true == file ){
      if (file.rename(new_name)){
 //Send status code (OK)
         snd1byte(0x00);
        } else {
 //Send status code (OK)
          snd1byte(0xff);
        }
      file.close();
    }else{
//Send status code (Error)
      snd1byte(0xf1);
    }
  }else{
//Send status code (Error)
      snd1byte(0xf1);
  }
}

//FILE DUMP
void f_dump(void){
unsigned int br_chk =0;
//Get filename
  for (unsigned int lp1 = 0;lp1 <= 32;lp1++){
    f_name[lp1] = rcv1byte();
  }
  appendmzt(f_name);
//ERROR if file does not exist
  if (SD.exists(f_name) == true){
//Send status code (OK)
    snd1byte(0x00);
//Open file
    File file = SD.open( f_name, FILE_READ );
      if( true == file ){
//Send actual data (1 screen: 128 bytes)
        unsigned int f_length = file.size();
        long lp1 = 0;
        while (lp1 <= f_length-1){
//Send screen start address
          snd1byte(lp1 % 256);
          snd1byte(lp1 / 256);
          int i=0;
//Send actual data
          while(i<128 && lp1<=f_length-1){
            snd1byte(file.read());
            i++;
            lp1++;
          }
//If the file end is less than 128 bytes, pad the remaining bytes with 0x00
          while(i<128){
            snd1byte(0x00);
            i++;
          }
//Wait for instruction
          br_chk=rcv1byte();
//If BREAK, set pointer to FILE END
          if (br_chk==0xff){
            lp1 = f_length; 
          }
//If B (BACK) received, rewind pointer by 256 bytes; if at first screen, reset to 0 and redisplay
          if (br_chk==0x42){
            if(lp1>255){
              if (lp1 % 128 == 0){
                lp1 = lp1 - 256;
              } else {
                lp1 = lp1 - 128 - (lp1 % 128);
              }
              file.seek(lp1);
            } else{
              lp1 = 0;
              file.seek(0);
            }
          }
        }
//If FILE END or BREAK, send termination code 0xFFFF as address
        if (lp1 > f_length-1){
          snd1byte(0xff);
          snd1byte(0xff);
        };
        file.close();
//Send status code (OK)
        snd1byte(0x00);
      } else {
//Send status code (ERROR)
      snd1byte(0xF1);
    }
  }else{
//Send status code (Error)
        snd1byte(0xf1);
  }
}

//FILE COPY
void f_copy(void){
//Get current filename
  for (unsigned int lp1 = 0;lp1 <= 32;lp1++){
    f_name[lp1] = rcv1byte();
  }
  appendmzt(f_name);
//ERROR if file does not exist
  if (SD.exists(f_name) == true){
//Send status code (OK)
    snd1byte(0x00);
//Get new filename
    for (unsigned int lp1 = 0;lp1 <= 32;lp1++){
      new_name[lp1] = rcv1byte();
    }
    appendmzt(new_name);
//ERROR if a file with the same name as the new filename already exists
    if (SD.exists(new_name) == false){
//Send status code (OK)
        snd1byte(0x00);
//Open file
    File file_r = SD.open( f_name, FILE_READ );
    File file_w = SD.open( new_name, FILE_WRITE );
      if( true == file_r ){
//Copy actual data
        unsigned int f_length = file_r.size();
        long lp1 = 0;
        while (lp1 <= f_length-1){
          int i=0;
          while(i<=255 && lp1<=f_length-1){
            s_data[i]=file_r.read();
            i++;
            lp1++;
          }
          file_w.write(s_data,i);
        }
        file_w.close();
        file_r.close();
//Send status code (OK)
        snd1byte(0x00);
      }else{
//Send status code (Error)
      snd1byte(0xf1);
    }
      }else{
//Send status code (Error)
        snd1byte(0xf3);
    }
  }else{
//Send status code (Error)
      snd1byte(0xf1);
  }
}

//Substitute process for MONITOR Write Information at 0x0436H, triggered by 0x91
void mon_whead(void){
  char m_info[130];
//Receive information block
  for (unsigned int lp1 = 0;lp1 < 128;lp1++){
    m_info[lp1] = rcv1byte();
  }
//S-OS SWORD sends filenames with trailing 0x20 padding, so 0x0D is appended
//The 8080 text editor & assembler also sends 0x20 after the filename, corrected to 0x0D
//Handled on the MZ-80K side
//  int lp2 = 17;
//  while (lp2>0 && (m_info[lp2] ==0x20 || m_info[lp2] ==0x0d)){
//    m_info[lp2]=0x0d;
//    lp2--;
//  }
//Extract filename
  for (unsigned int lp1 = 0;lp1 < 17;lp1++){
    m_name[lp1] = m_info[lp1+1];
  }
//Append .MZT for DOS filename
  appendmzt(m_name);
  m_info[16] = 0x0d;
//Delete file if it already exists
  if (SD.exists(m_name) == true){
    SD.remove(m_name);
  }
//Open file
  File file = SD.open( m_name, FILE_WRITE );
  if( true == file ){
//Send status code (OK)
    snd1byte(0x00);
//Write information block
    for (unsigned int lp1 = 0;lp1 < 128;lp1++){
      file.write(m_info[lp1]);
    }
    file.close();
  } else {
//Send status code (ERROR)
    snd1byte(0xF1);
  }
}

//Substitute process for MONITOR Write Data at 0x0475H, triggered by 0x92
void mon_wdata(void){
//Get file size
  int f_length1 = rcv1byte();
  int f_length2 = rcv1byte();
//Calculate file size
  unsigned int f_length = f_length1+f_length2*256;
//Open file
  File file = SD.open( m_name, FILE_WRITE );
  if( true == file ){
//Send status code (OK)
    snd1byte(0x00);
//Actual data
    long lp1 = 0;
    while (lp1 <= f_length-1){
      int i=0;
      while(i<=255 && lp1<=f_length-1){
        s_data[i]=rcv1byte();
        i++;
        lp1++;
      }
      file.write(s_data,i);
    }
    file.close();
  } else {
//Send status code (ERROR)
    snd1byte(0xF1);
  }
}

//Substitute process for MONITOR Read Information at 0x04D8H
void mon_lhead(void){
//Clear read data pointer
  m_lop=128;
//Get filename
  for (unsigned int lp1 = 0;lp1 <= 32;lp1++){
    m_name[lp1] = rcv1byte();
  }
  appendmzt(m_name);
//ERROR if file does not exist
  if (SD.exists(m_name) == true){
    snd1byte(0x00);
//Open file
    File file = SD.open( m_name, FILE_READ );
    if( true == file ){
      snd1byte(0x00);
      for (unsigned int lp1 = 0;lp1 < 128;lp1++){
          byte i_data = file.read();
          snd1byte(i_data);
      }
      file.close();
      snd1byte(0x00);
    } else {
//Send status code (ERROR)
      snd1byte(0xFF);
    }  
  } else {
//Send status code (FILE NOT FIND ERROR)
    snd1byte(0xF1);
  }
}

//Substitute process for MONITOR Read Data at 0x04F8H
void mon_ldata(void){
// 2025.12.4 Removed appendmzt as it was an unnecessary operation
//  appendmzt(m_name);
//ERROR if file does not exist
  if (SD.exists(m_name) == true){
    snd1byte(0x00);
//Open file
    File file = SD.open( m_name, FILE_READ );
    if( true == file ){
      snd1byte(0x00);
      file.seek(m_lop);
//Get read size
      int f_length2 = rcv1byte();
      int f_length1 = rcv1byte();
      unsigned int f_length = f_length1*256+f_length2;
      for (unsigned int lp1 = 0;lp1 < f_length;lp1++){
        byte i_data = file.read();
        snd1byte(i_data);
      }
      file.close();
      m_lop=m_lop+f_length;
      snd1byte(0x00);
    } else {
//Send status code (ERROR)
      snd1byte(0xFF);
    }  
  } else {
//Send status code (FILE NOT FIND ERROR)
    snd1byte(0xF1);
  }
}

//BOOT process (MZ-2000_SD only)
void boot(void){

  //Get filename
  for (unsigned int lp1 = 0;lp1 <= 32;lp1++){
    m_name[lp1] = rcv1byte();
  }
  
////  DBG_PRINT("m_name:");
////  DBG_PRINTLN(m_name);

  //ERROR if file does not exist
  if (SD.exists(m_name) == true){
    
    snd1byte(0x00);

    //Open file
    File file = SD.open( m_name, FILE_READ );
    if( true == file ){
    snd1byte(0x00);
//Send file size
      unsigned long f_length = file.size();
      unsigned int f_len1 = f_length / 256;
      unsigned int f_len2 = f_length % 256;
      snd1byte(f_len2);
      snd1byte(f_len1);
////  DBG_PRINTFMT(f_length,HEX);
////  DBG_PRINTFMT(f_len2,HEX);
////  DBG_PRINTFMT(f_len1,HEX);
//Send actual data
      for (unsigned long lp1 = 1;lp1 <= f_length;lp1++){  // SHould this start from 0???
         byte i_data = file.read();
         snd1byte(i_data);
      }
    } else {
//Send status code (ERROR)
      snd1byte(0xFF);
    }  
  } else {
//Send status code (FILE NOT FIND ERROR)
    snd1byte(0xF1);
  }
}

//ASTART: Copy the specified file as "0000.mzt"
void astart(void){
  char w_name[]="0000.mzt";
//Get filename
  for (unsigned int lp1 = 0;lp1 <= 32;lp1++){
    f_name[lp1] = rcv1byte();
  }
  appendmzt(f_name);
//ERROR if file does not exist
  if (SD.exists(f_name) == true){
//Delete 0000.mzt if it already exists
    if (SD.exists(w_name) == true){
      SD.remove(w_name);
    }
//Open file
    File file_r = SD.open( f_name, FILE_READ );
    File file_w = SD.open( w_name, FILE_WRITE );
      if( true == file_r ){
//Actual data
        unsigned int f_length = file_r.size();
        long lp1 = 0;
        while (lp1 <= f_length-1){
          int i=0;
          while(i<=255 && lp1<=f_length-1){
            s_data[i]=file_r.read();
            i++;
            lp1++;
          }
          file_w.write(s_data,i);
        }
        file_w.close();
        file_r.close();
//Send status code (OK)
        snd1byte(0x00);
      } else {
//Send status code (ERROR)
      snd1byte(0xF1);
    }
  } else {
//Send status code (ERROR)
    snd1byte(0xF1);
  }  
}

//****************************************************
// Loop
//****************************************************
void loop(){

  boolean sdStatus = false;
  
  digitalWrite(PB0PIN,LOW);
  digitalWrite(PB1PIN,LOW);
  digitalWrite(PB2PIN,LOW);
  digitalWrite(PB3PIN,LOW);
  digitalWrite(PB4PIN,LOW);
  digitalWrite(PB5PIN,LOW);
  digitalWrite(PB6PIN,LOW);
  digitalWrite(PB7PIN,LOW);
  digitalWrite(FLGPIN,LOW);

  // Wait for command
  DBG_PRINT(F("cmd:"));
  byte cmd = rcv1byte();
  DBG_PRINTFMT(cmd,HEX);

  // Check card is inserted and initialised.
  sdStatus = sdinit();

  // SD Card initialised ok
  if (sdStatus){

    DBG_PRINTLN(F("Switch on command..."));

    switch(cmd) {
      
      //0x80: Save to SD card
      case 0x80:
        DBG_PRINTLN(F("SAVE START"));
        //Send status code (OK)
        snd1byte(0x00);
        f_save();
        break;

      //0x81: Load from SD card
      case 0x81:
        DBG_PRINTLN(F("LOAD START"));
        //Send status code (OK)
        snd1byte(0x00);
        f_load();
        break;
        
      //0x82: Rename-copy the specified file as 0000.mzt
      case 0x82:
        DBG_PRINTLN(F("ASTART START"));
        //Send status code (OK)
        snd1byte(0x00);
        astart();
        break;
        
      //0x83: Output file list - 10000011  - CF = 11001111
      case 0x83:
        DBG_PRINTLN(F("FILE LIST START"));
        //Send status code (OK)
        snd1byte(0x00);
        dirlist();
        break;
        
      //0x84: Delete file
      case 0x84:
        DBG_PRINTLN(F("FILE Delete START"));
        //Send status code (OK)
        snd1byte(0x00);
        f_del();
        break;
        
      //0x85: Rename file
      case 0x85:
        DBG_PRINTLN(F("FILE Rename START"));
        //Send status code (OK)
        snd1byte(0x00);
        f_ren();
        break;
        
      //0x86: File dump
      case 0x86:  
        DBG_PRINTLN(F("FILE Dump START"));
        //Send status code (OK)
        snd1byte(0x00);
        f_dump();
        break;
        
      //0x87: File copy
      case 0x87:  
        DBG_PRINTLN(F("FILE Copy START"));
        //Send status code (OK)
        snd1byte(0x00);
        f_copy();
        break;
        
      //0x91: Substitute process for MONITOR Write Information at 0x0436H
      case 0x91:
        DBG_PRINTLN(F("0436H START"));
        //Send status code (OK)
        snd1byte(0x00);
        mon_whead();
        break;
        
      //0x92: Substitute process for MONITOR Write Data at 0x0475H
      case 0x92:
        DBG_PRINTLN(F("0475H START"));
        //Send status code (OK)
        snd1byte(0x00);
        mon_wdata();
        break;
        
      //0x93: Substitute process for MONITOR Read Information at 0x04D8H
      case 0x93:
        DBG_PRINTLN(F("04D8H START"));
        //Send status code (OK)
        snd1byte(0x00);
        mon_lhead();
        break;
        
      //0x94: Substitute process for MONITOR Read Data at 0x04F8H
      case 0x94:
        DBG_PRINTLN(F("04F8H START"));
        //Send status code (OK)
        snd1byte(0x00);
        mon_ldata();
        break;
        
      //0x95: BOOT LOAD (MZ-2000_SD only)
      case 0x95:
        DBG_PRINTLN(F("BOOT LOAD START"));
        //Send status code (OK)
        snd1byte(0x00);
        boot();
        break;
        
      default:
        //Send status code (CMD ERROR)
        DBG_PRINTLN(F("Unknown command."));
        snd1byte(0xF4);
    }

    // Done with card for now
    SD.end();
    
  // Card did not initialise
  } else {

    DBG_PRINTLN(F("Error: SD Card missing or failed to initialise"));

    //Send status code (ERROR)
    snd1byte(0xF0);
  }
}