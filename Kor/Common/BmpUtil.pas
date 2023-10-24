{The Delpi Games Creator - Beta 5
 --------------------------------
 Copyright 1996 John Pullen, Paul Bearne, Jeff Kurtz

 This unit is part of the freeware Delphi Games Creator. This unit is
 completely free to use for personal or commercial use. The code is
 supplied with no guarantees on performance or stabilibty and must be
 used at your own risk.
}

unit BmpUtil;

interface

uses Classes, SysUtils, Windows, Graphics;

type
  TEffect = (None,SlideRight,SlideLeft,SlideDown,SlideUp,ZoomOpen,
             Curtains,Shutters,Quarters,VerticalLines,HorizontalLines,
             UpDownLines,LeftRightLines,Scrollright,Scrollleft,ScrollUp,ScrollDown,
             Drip,HorizontalOpenOut,VerticalOpenOut,DiagonalTopLeft,DiagonalTopRight,
             DiagonalBottomleft,DiagonalBottomRight,VerticalStripes,HorizontalStripes,
             LargeVerticalStripes,LargeHorizontalStripes,FollowMe);
  //Color Match
  TColorMatch = (cmExact, cmAdd, cmNearest);

  //Image Bank Colour
  TImgLibColor = packed record
        Red: Byte;
        Green: Byte;
        Blue: Byte;
        Used: Boolean;
  end;

  //Image Structure
  TImgLibImage = packed record
       Width: Integer;
       Height: Integer;
       Name: String[8];
       Bits: PByte;
  end;
  PImgLibImage = ^TImgLibImage;
  TImgLibImageList = array[0..0] of TImgLibImage;
  PImgLibImageList = ^TImgLibImageList;

  //Intro Structure
  TIntroLibImage = packed record
       Effect:TEffect;
       Speed:Integer;
       Hold:Integer;
       Width: Integer;
       Height: Integer;
       Name: String[8];
       Bits: PByte;
  end;
  PIntroLibImage = ^TIntroLibImage;
  TIntroLibImageList = array[0..0] of TIntroLibImage;
  PIntroLibImageList = ^TIntroLibImageList;

  //Image Bank Palette
  TImgLibPalette = array[0..255] of TImgLibColor;

  //Image Library Header Structure
  TImgLibHeader = packed record
       IDent: array[0..3] of Char;
       ImageCount: Integer;
       TransparentColor: Integer;
       Palette: TImgLibPalette;
  end;

  //T256Palette Entry
  T256PaletteEntry = array[0..255] of TPaletteEntry;


// Function Prototypes
//====================

//Calculate Width in bytes of image (image width must be alligned to DWORD boundry)
function WidthBytes(w: Integer): Integer;

//Load and create DIB returning a pointer to the BmpInfoHeader and Bits
procedure LoadDIB256(FileName: String; var BmpInfo: PBitMapInfo; var Bits: PByte;
             var HeaderSize, ImageSize: Integer);

//Create a DIB using Bits Bits and Bitmap info provided updating the Supplied bitmap
//procedure CreateDIB256(Can: TCanvas; BmpInfo: PBitmapInfo; Bits: PByte);

//Return the index of the colour in the specified palette.
function GetPaletteIndex(var ImgPalette: TImgLibPalette; ImgColor: TImgLibColor;
                         var Match: TColorMatch): Byte;

//Clear the specified palette to a black palette adding system colors if specified
procedure ClearPalette(var ImgPalette: TImgLibPalette; AddSysCols: Boolean);

//Create Palette from Bitmap Info Header
function PaletteFromBmpInfo(BmpInfo: PBitmapInfo): HPalette;

//Create a DIB from the specified bits and bitmap info. Assign to TBitmap
procedure CreateDIB256(Bmp: TBitmap; BmpInfo: PBitmapInfo; Bits: PByte);

//Get Nearest Color from Palette
function GetNearestRGB(var Palette: TImgLibPalette; Color: TImgLibColor): Byte;

//Draw Palette
procedure DrawPalette(Canvas: TCanvas; x, y, w: Integer; var Palette: TImgLibPalette);

//Convert and Image Lib Palette to a Bitmap Info Palette
procedure BmpInfoToImgLibPal(var Palette: TImgLibPalette; BmpInfo: PBitmapInfo);

//Convert and Bitmap Info Palette to ImageLib Palette
procedure ImgLibPalToBmpInfo(var Palette: TImgLibPalette; BmpInfo: PBitmapInfo);

//Flip bits for bottom up images
procedure FlipBits(Bits: PByte; WBytes, Height: Integer);


// Packed Bitmap
type
   TBitmapFilePackHeader = packed record
      Ident: array[0..3] of char;   // 'BMPP'
      FileCount: integer;
   end;

   TBitmapPackItem = packed record
      rFileName: string[19];
      rSize: integer;
      rPosition: integer;
   end;
   PBitmapItemList = ^TBitmapItemList;
   TBitmapItemList = array[0..1023] of TBitmapPackItem;

procedure BP_SetPackFileCount(nCount: integer);
procedure BP_WriteHeader(stream: TStream);
procedure BP_WriteItemHeader(stream: TStream);
function  BP_SetItem(index: integer; aFileName: string; aSize, aPosition: integer): integer;
procedure BP_SetGlobalBitmapPack(const AFileName: string);
procedure BP_LoadGlobalBitmapPack(const AFileName: string);
function  BP_GetFileCount: integer;
function  BP_GetFileName(index: integer): string;
function  BP_GetFileSize(index: integer): integer;
function  BP_FindFileName(aFileName: string): integer;

implementation

// Packed Bitmap

var
   GlobalBitmapPackFile: string = '';
   BitmapPackHeader: TBitmapFilePackHeader;
   pBitmapPackItem: PBitmapItemList = nil;

procedure BP_SetPackFileCount(nCount: integer);
begin
   with BitmapPackHeader do begin
      Ident[0] := 'B'; Ident[1] := 'M';
      Ident[2] := 'P'; Ident[3] := 'P';
      FileCount := nCount;
   end;
   ReallocMem(pBitmapPackItem, sizeof(TBitmapPackItem)*nCount);
end;

procedure BP_WriteHeader(stream: TStream);
begin
   stream.Write(BitmapPackHeader, sizeof(TBitmapFilePackHeader));
end;

procedure BP_WriteItemHeader(stream: TStream);
begin
   stream.Write(pBitmapPackItem^, Sizeof(TBitmapPackItem) * BitmapPackHeader.FileCount);
end;

function BP_SetItem(index: integer; aFileName: string; aSize, aPosition: integer): integer;
begin
   Result := -1;
   if (index < 0) or (BitmapPackHeader.FileCount <= index) then exit;

   pBitmapPackItem^[index].rFileName := aFileName;
   pBitmapPackItem^[index].rSize     := aSize;
   pBitmapPackItem^[index].rPosition := aPosition;
   Result := 0;
end;

procedure BP_SetGlobalBitmapPack(const AFileName: string);
begin
   if FileExists(AFileName) then
      GlobalBitmapPackFile := AFileName;
end;

procedure BP_LoadGlobalBitmapPack(const AFileName: string);
var
   stream: TFileStream;
begin
   if not FileExists(AFileName) then exit;
   GlobalBitmapPackFile := '';

   stream := TFileStream.Create(AFileName, fmOpenRead or fmShareDenyWrite);
   try
      stream.Read(BitmapPackHeader, sizeof(TBitmapFilePackHeader));

      with BitmapPackHeader do
         if (Ident[0] <> 'B') or (Ident[1] <> 'M') or
            (Ident[2] <> 'P') or (Ident[3] <> 'P') then begin
            FileCount := 0;
            exit;
         end;

      ReallocMem(pBitmapPackItem, sizeof(TBitmapPackItem) * BitmapPackHeader.FileCount);

      stream.Read(pBitmapPackItem^, sizeof(TBitmapPackItem) * BitmapPackHeader.FileCount);

      GlobalBitmapPackFile := AFileName;
   finally
      stream.Free;
   end;
end;

function  BP_GetFileCount: integer;
begin
   Result := 0;
   if GlobalBitmapPackFile = '' then exit;

   Result := BitmapPackHeader.FileCount;
end;

function  BP_GetFileName(index: integer): string;
begin
   Result := '';
   if GlobalBitmapPackFile = '' then exit;
   if (index < 0) or (BitmapPackHeader.FileCount <= index) then exit;

   Result := pBitmapPackItem^[index].rFileName;
end;

function  BP_GetFileSize(index: integer): integer;
begin
   Result := 0;
   if GlobalBitmapPackFile = '' then exit;
   if (index < 0) or (BitmapPackHeader.FileCount <= index) then exit;

   Result := pBitmapPackItem^[index].rSize;
end;

function  BP_FindFileName(aFileName: string): integer;
var
   i: integer;
begin
   Result := -1;
   if GlobalBitmapPackFile = '' then exit;
   for i := 0 to BitmapPackHeader.FileCount-1 do begin
      if CompareText(pBitmapPackItem^[i].rFileName, aFileName) = 0 then begin
         Result := i;
         exit;
      end;
   end;
end;

//function implementation
//=======================

//Calculate Width in bytes of image (image width must be alligned to DWORD boundry)
function WidthBytes(w: Integer): Integer;
begin
     Result := (((w * 8) + 31) div 32) * 4;
end;

//CreateDIB From File
procedure LoadDIB256(FileName: String; var BmpInfo: PBitMapInfo; var Bits: PByte;
             var HeaderSize, ImageSize: Integer);
var
   Stream: TFileStream;
   Header: TBitmapFileHeader;
   NbrCols: Integer;
   BmpHeight: Integer;
   BmpWidth: Integer;
   i: integer;
   ShortFileName: string;
   SeekStep: Cardinal;
begin
   //Initialise and open file
   SeekStep := 0;
   if FileExists(FileName) then begin
      Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
   end else if FileExists(GlobalBitmapPackFile) then begin
      Stream := TFileStream.Create(GlobalBitmapPackFile, fmOpenRead or fmShareDenyWrite);
      ShortFileName := ExtractFileName(FileName);
      for i := 0 to BitmapPackHeader.FileCount-1 do begin
         if CompareText(ShortFileName, pBitmapPackItem^[i].rFileName) = 0 then begin
            SeekStep := pBitmapPackItem^[i].rPosition;
            Stream.Seek(SeekStep, soFromBeginning);
            break;
         end;
      end;
      if SeekStep = 0 then begin
         raise Exception.Create(Format('%s File not Found', [FileName]));
         exit;
      end;
   end else begin
      raise Exception.Create(Format('%s File not Found', [FileName]));
      exit;
   end;

   try
      //Read file Header
      Stream.ReadBuffer(Header, SizeOf(Header));
      if Header.bfType <> $4D42 then
         raise Exception.Create('Not a valid bitmap file');
      //Allocate memory for Bitmapinfoheader
      HeaderSize := SizeOf(TBitmapInfo) + (256 * SizeOf(TRGBQuad));
      BmpInfo := AllocMem(HeaderSize);
      if BmpInfo = nil then
         raise Exception.Create('Could not allocate memory for TBitmapInfo');
      try
         //Read bitmap info header and validate
         Stream.ReadBuffer(BmpInfo^, SizeOf(TBitmapInfoHeader));
         if BmpInfo^.bmiHeader.biBitCount <> 8 then
            raise Exception.Create('The image must be an 8bpp (256 color) image');
         if BmpInfo^.bmiHeader.biCompression <> BI_RGB then
            raise Exception.Create('The image must be uncompressed (RGB encoded)');
         NbrCols := BmpInfo^.bmiHeader.biClrUsed;
         if NbrCols = 0 then
            NbrCols := 256;
         BmpWidth := WidthBytes(BmpInfo^.bmiHeader.biWidth);
         BmpHeight := Abs(BmpInfo^.bmiHeader.biHeight);
         ImageSize := BmpWidth * BmpHeight;
         //Load Color Table
         ZeroMemory(@BmpInfo^.bmiColors[0], NbrCols * SizeOf(TRGBQuad));
         Stream.ReadBuffer(BmpInfo^.bmiColors, NbrCols * SizeOf(TRGBQuad));
         //Load Bits
         Stream.Seek(SeekStep + Header.bfOffBits, soFromBeginning);
         Bits := AllocMem(ImageSize);
         if Bits = nil then
            raise Exception.Create('Could not allocate memory for bitmap bits');
         try
            Stream.ReadBuffer(Bits^, LongInt(ImageSize));
         except
               FreeMem(Bits, ImageSize);
               Bits := nil;
               raise;
         end;
      except
            FreeMem(BmpInfo, HeaderSize);
            BmpInfo := nil;
            raise;
      end;
   except
         Stream.Free;
         raise;
   end;
   //If the code gets this far the bitmap has been loaded okay
   Stream.Free;

   //if the height is positive the bitmap is Bottom up so flip it.
   if BmpInfo^.bmiHeader.biHeight > 0 then
   begin
        FlipBits(Bits, BmpWidth, BmpHeight);
        BmpInfo^.bmiHeader.biHeight := -BmpInfo^.bmiHeader.biHeight;
   end;

end;


//This function will match a color in the Image Library Palette. If a color is
//matched then the index is returned. If a color is not matched then it is added
//to the palette, otherwise a nearest match is returned;
function GetPaletteIndex(var ImgPalette: TImgLibPalette; ImgColor: TImgLibColor;
                         var Match: TColorMatch): Byte;
var
   n: Byte;
   PalCol: TImgLibColor;
   MatchColor: Byte;
   UnusedColor: Integer;
   ColDif: Integer;
   MinDif: Integer;
begin
     //Check for exact match
     UnusedColor := -1;
     //Start at 1 to ignore transparent colour
     for n:= 1 to 255 do
     begin
          PalCol := ImgPalette[n];
          if PalCol.Used then
          begin
               if (PalCol.Red = ImgColor.Red) and
                  (PalCol.Green = ImgColor.Green) and
                  (PalCol.Blue = ImgColor.Blue) then
                  begin
                       Match := cmExact;
                       Result := n;
                       exit;
                  end;
          end
          else
              if UnusedColor = -1 then
                 UnusedColor := n;
     end;

     //Add Color
     if UnusedColor <> - 1 then
     begin
          PalCol.Red := ImgColor.Red;
          PalCol.Green := ImgColor.Green;
          PalCol.Blue := ImgColor.Blue;
          PalCol.Used := True;
          ImgPalette[UnusedColor] := PalCol;
          Match := cmAdd;
          Result := UnusedColor;
          exit;
     end;

     //Match Nearest Color
     MinDif := 768;
     MatchColor := 0;
     //Start at 1 to ignore transparent colour
     for n := 1 to 255 do
     begin
          PalCol := ImgPalette[n];
          ColDif := Abs(PalCol.Red - ImgColor.Red) +
                    Abs(PalCol.Green - ImgColor.Green) +
                    Abs(PalCol.Blue - ImgColor.Blue);
          if ColDif < MinDif then
          begin
               MinDif := ColDif;
               MatchColor := n;
          end;
     end;
     Match := cmNearest;
     Result := MatchColor;
end;

//Clear the specified palette to a black palette adding system colors if specified
procedure ClearPalette(var ImgPalette: TImgLibPalette; AddSysCols: Boolean);
var
   n: Integer;
   SysCols: array[0..9] of TPaletteEntry;
   dc: HDC;
   Handle: Hwnd;
begin
     //First Blat everything
     FillChar(ImgPalette, SizeOf(ImgPalette), 0);

     //Get System Colors?
     if not AddSysCols then exit;
     Handle := GetFocus;
     dc := GetDC(Handle);
     ImgPalette[0].Used := True;
     GetSystemPaletteEntries(dc, 0, 10, SysCols);
     for n := 0 to 9 do
     begin
          with ImgPalette[n] do
          begin
               Red := SysCols[n].peRed;
               Blue := SysCols[n].peBlue;
               Green := SysCols[n].peGreen;
               Used := True;
          end;
     end;
     GetSystemPaletteEntries(dc,246, 10, SysCols);
     for n := 0 to 9 do
     begin
          with ImgPalette[n + 246] do
          begin
               Red := SysCols[n].peRed;
               Blue := SysCols[n].peBlue;
               Green := SysCols[n].peGreen;
               Used := True;
          end;
     end;
     ReleaseDC(Handle, dc);
end;

//Create Palette from Bitmap Info Header
function PaletteFromBmpInfo(BmpInfo: PBitmapInfo): HPalette;
var
   PalSize, n: Integer;
   Palette: PLogPalette;
begin
     //Allocate Memory for Palette
     PalSize := SizeOf(TLogPalette) + (256 * SizeOf(TPaletteEntry));
     Palette := AllocMem(PalSize);

     //Fill in structure
     with Palette^ do
     begin
          palVersion := $300;
          palNumEntries := 256;
          for n := 0 to 255 do
          begin
               palPalEntry[n].peRed := BmpInfo^.bmiColors[n].rgbRed;
               palPalEntry[n].peGreen := BmpInfo^.bmiColors[n].rgbGreen;
               palPalEntry[n].peBlue := BmpInfo^.bmiColors[n].rgbBlue;
               palPalEntry[n].peFlags := 0;
          end;
     end;
     Result := CreatePalette(Palette^);
     FreeMem(Palette, PalSize);
end;

//Create a DIB from the specified bits and bitmap info. Assign to TBitmap
procedure CreateDIB256(Bmp: TBitmap; BmpInfo: PBitmapInfo; Bits: PByte);
var
   Focus: hWnd;
   dc: HDC;
   OldPal: HPalette;
begin
     //First Release Handle and Palette from BMP
     DeleteObject(Bmp.ReleaseHandle);
     DeleteObject(Bmp.ReleasePalette);

     Focus := GetFocus;
     dc := GetDC(Focus);
     Bmp.Palette := PaletteFromBmpInfo(BmpInfo);
     OldPal := SelectPalette(dc, Bmp.Palette, False);
     RealizePalette(dc);

     Bmp.Handle := CreateDIBitmap(dc, BmpInfo^.bmiHeader, CBM_INIT,
               Pointer(Bits), BmpInfo^, DIB_RGB_COLORS);
     SelectPalette(dc, OldPal, True);
     ReleaseDC(Focus, DC);
     if Bmp.Handle = 0 then
        Exception.Create('CreateDIBitmap failed');
end;

//Get Nearest Color from Palette
function GetNearestRGB(var Palette: TImgLibPalette; Color: TImgLibColor): Byte;
var
   MinDif, ColDif, n: Integer;
   MatchColor: Byte;
   PalCol: TImgLibColor;
begin
     //Match Nearest Color
     MinDif := 768;
     MatchColor := 0;
     //Start at 1 to ignore transparent colour
     for n := 0 to 255 do
     begin
          PalCol := Palette[n];
          ColDif := Abs(PalCol.Red - Color.Red) +
                    Abs(PalCol.Green - Color.Green) +
                    Abs(PalCol.Blue - Color.Blue);
          if ColDif < MinDif then
          begin
               MinDif := ColDif;
               MatchColor := n;
          end;
     end;
     Result := MatchColor;
end;

//Draw Palette
procedure DrawPalette(Canvas: TCanvas; x, y, w: Integer; var Palette: TImgLibPalette);
var
   xc, yc, xp, yp: Integer;
   LogPal: PLogPalette;
   ColIdx: Integer;
   PalCol: TImgLibColor;
   NewPal, OldPal: HPalette;
begin
     //Create, Select and Realize Logical Palette
     GetMem(LogPal, SizeOf(TLogPalette) + (256 * SizeOf(TPaletteEntry)));
     with LogPal^ do
     begin
          palVersion := $300;
          palNumEntries := 256;
          for ColIdx := 0 to 255 do
          begin
               PalCol := Palette[ColIdx];
               palPalEntry[ColIdx].peRed := PalCol.Red;
               palPalEntry[ColIdx].peGreen := PalCol.Green;
               palPalEntry[ColIdx].peBlue := PalCol.Blue;
               palPalEntry[ColIdx].peFlags := 0;
          end;
     end;
     NewPal := CreatePalette(LogPal^);
     OldPal := SelectPalette(Canvas.Handle, NewPal, False);
     RealizePalette(Canvas.Handle);

     ColIdx := 0;
     for yc := 0 to 15 do
     begin
          for xc := 0 to 15 do
          begin
               xp := x + (w * xc);
               yp := y + (w * yc);
               PalCol := Palette[ColIdx];
               Canvas.Brush.Color := PALETTERGB(PalCol.Red, PalCol.Green, PalCol.Blue);
               Canvas.FillRect(Rect(xp, yp, xp + (w - 2), yp + (w - 2)));
               Inc(ColIdx);
          end;                     
     end;
     SelectPalette(Canvas.Handle, OldPal, True);
     FreeMem(LogPal, SizeOf(TLogPalette) + (256 * SizeOf(TPaletteEntry)));
end;

//Convert and Image Lib Palette to a Bitmap Info Palette
procedure BmpInfoToImgLibPal(var Palette: TImgLibPalette; BmpInfo: PBitmapInfo);
var
   n: Integer;
   Col: TRGBQuad;
begin
     for n := 0 to 255 do
     begin
          Col := BmpInfo^.bmiColors[n];
          Palette[n].Red := Col.rgbRed;
          Palette[n].Green := Col.rgbGreen;
          Palette[n].Blue := Col.rgbBlue;
     end;
end;

//Convert and Bitmap Info Palette to ImageLib Palette
procedure ImgLibPalToBmpInfo(var Palette: TImgLibPalette; BmpInfo: PBitmapInfo);
var
   n: Integer;
   Col: TImgLibColor;
begin
     // start at 1 as index is for transparency
     for n := 0 to 255 do
     begin
          Col := Palette[n];
          with BmpInfo^.bmiColors[n] do
          begin
               rgbRed := Col.Red;
               rgbGreen := Col.Green;
               rgbBlue := Col.Blue;
          end;
     end;
end;

//Flip bits for bottom up images
procedure FlipBits(Bits: PByte; WBytes, Height: Integer);
var
   TempBits, TempPtr: PByte;
   Size: Integer;
   n: Integer;
begin
     //Allocate memory and take a copy of image
     Size := WBytes * Height;
     GetMem(TempBits, Size);
     Move(Bits^, TempBits^, Size);
     //Now copy back in reverse order
     TempPtr := TempBits; //Set TempPtr to Last line of Imagee
     Inc(TempPtr, Size - WBytes);
     for n := 1 to Height do
     begin
          Move(TempPtr^, Bits^, WBytes);
          Dec(TempPtr, WBytes);
          Inc(Bits, WBytes);
     end;
     //Free Memory
     FreeMem(TempBits, Size);
end;

end.
