unit uxDibA;

interface

uses Windows, Classes, Sysutils, graphics;

type
  TImgLibColor = record
    Red, Green, Blue: Byte;
    Used: Boolean;
  end;


  TInSpaceData = record
    spw, dpw: pword;
    R : TRect;
  end;

  TXDib = class
   private
    FWidth, FHeight: integer;
    FBits : pword;
    function  GetEmpty: Boolean;
    function  GetInSpace (Adib: TXDib; x, y: integer; var InSpaceData: TInSpaceData): Boolean;
   public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure ClearbyColor (aColor: word);
    procedure SetSize (aWidth, aHeight: integer);

    procedure DrawImage (x, y: integer; aDib: TXDib; aTrans: Boolean);
    procedure StretchDrawImage (XDib: TXDib);

    Procedure LineTo (x, y, aWidth, aHeight, aColor: integer);

    procedure Assign (aDib: TXDib);
    procedure LoadFromBitmap (aBitmap: TBitmap);

    procedure LoadFromFile (aFileName: string);
    procedure SaveToFile (aFileName: string);
    procedure LoadFromStream (aStream: TStream);
    procedure SaveToStream (aStream: TStream);
    function Optimize: TPoint;

    property Width : integer read FWidth;
    property Height : integer read FHeight;
    property Bits : pword read FBits;
    property Empty : Boolean read GetEmpty;
  end;

  procedure XDibDrawImage (Canvas: TCanvas; X, Y: Integer; aDib:TXDib);
  procedure XDibDrawImageDc (dc: Hdc; X, Y: Integer; aDib:TXDib);
  function GetPBitmapInfo (aWidth, aHeight, aBitCount: integer): PBitMapInfo;

implementation

type
  TImgLibPalette = array[0..255] of TImgLibColor;
  PTImgLibPalette = ^TImgLibPalette;

procedure XDibDrawImage(Canvas: TCanvas; X, Y: Integer; aDib:TXDib);
var dc : HDC;
begin
   dc := canvas.Handle;
   XDibDrawImageDc(dc, X, Y, aDib);
end;

var
   bmpInfo : PBitmapInfo = nil;

procedure XDibDrawImageDc(dc: Hdc; X, Y: Integer; aDib:TXDib);
var
   HeaderSize : integer;
begin
   if not assigned (aDib) then exit;
   HeaderSize := Sizeof(TBitmapInfo) + (256 * Sizeof(TRGBQuad));
   if bmpinfo = nil then BmpInfo := AllocMem(HeaderSize);

   if BmpInfo = nil then raise Exception.Create('TNoryImage: Failed to allocate a DIB');
   with BmpInfo^.bmiHeader do begin
      biSize        := SizeOf(TBitmapInfoHeader);
      biWidth       := aDib.Width;
      biHeight      := -aDib.Height;
      biPlanes      := 1;
      biBitCount    := 16;
      biCompression := BI_RGB;
      biClrUsed     := 0;
      biClrImportant:= 0;
   end;
   SetDIBitsToDevice(dc, x, y, aDib.Width, aDib.Height, 0, 0, 0, aDib.Height, aDib.Bits, BmpInfo^, DIB_RGB_COLORS);
end;



//Convert and Image Lib Palette to a Bitmap Info Palette
procedure BmpInfoToImgLibPal(aColorCount: integer; var Palette: TImgLibPalette; BmpInfo: PBitmapInfo);
var
   n: Integer;
   Col: TRGBQuad;
begin
   if (aColorcount <> 0) and (aColorCount <> 256) then begin
     FillChar (Palette, sizeof (Palette), 0);
     for n := 0 to aColorCount -1 do
     begin
          Col := BmpInfo^.bmiColors[n];
          Palette[n].Red := Col.rgbRed;
          Palette[n].Green := Col.rgbGreen;
          Palette[n].Blue := Col.rgbBlue;
     end;

   end else begin
     for n := 0 to 255 do
     begin
          Col := BmpInfo^.bmiColors[n];
          Palette[n].Red := Col.rgbRed;
          Palette[n].Green := Col.rgbGreen;
          Palette[n].Blue := Col.rgbBlue;
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

function WinRGB (r, g, b: word): word;
begin
   Result  := b + (g shl 5) + (r shl 10);
end;

procedure WinVRGB (n:word; var r, g, b: word);
begin
   b := n and $1F;
   g := (n shr 5) and $1F;
   r := (n shr 10) and $1F;
end;

procedure Change8BitTo16Bit (psour, pdest: pointer; soursize: integer; Palette: TImgLibPalette);
var
   i : integer;
   sb : pbyte;
   db : pword;
   r, g, b, t : Word;
begin
   sb := psour; db := pdest;

   for i := 0 to soursize -1 do begin
      r := Palette[sb^].Red;
      g := Palette[sb^].Green;
      b := Palette[sb^].Blue;
      t := r shr 3;

      if (r <> 0) and (t = 0) then r := 1
      else r := t;

      t := g shr 3;
      if (g <> 0) and (t = 0) then g := 1
      else g := t;

      t := b shr 3;
      if (b <> 0) and (t = 0) then b := 1
      else b := t;

      db^ := WinRGB (r, g, b);
      inc (sb); inc (db);
   end;
   { ¿øº»
   for i := 0 to soursize -1 do begin
      db^ := WinRGB (Palette[sb^].Red div 8, Palette[sb^].Green div 8, Palette[sb^].Blue div 8);
      inc (sb); inc (db);
   end;
   }
end;

procedure Change24BitTo16Bit (psour, pdest: pointer; soursize: integer);
var
   i : integer;
   sb : pbyte;
   db : pword;
   r, g, b : word;
begin
   sb := psour; db := pdest;

   for i := 0 to soursize -1 do begin
      b := sb^ div 8; inc (sb); g := sb^ div 8; inc (sb); r := sb^ div 8; inc (sb);
      db^ := WinRGB (r, g, b);
      inc (db);
   end;
end;

procedure Change16BitTo24Bit (psour, pdest: pointer; soursize: integer);
var
   i: integer;
   pw: pword;
   db : pbyte;
   r, g, b : word;
begin
   pw := psour; db := pdest;

   for i := 0 to soursize -1 do begin
      WinVRGB (pw^, r, g, b);
      db^ := b * 8; inc (db); db^ := g * 8; inc (db); db^ := r * 8; inc (db);
      inc (pw);
   end;
end;

var
   LocalBmpInfo : PBitmapInfo = nil;
   
function GetPBitmapInfo (aWidth, aHeight, aBitCount: integer): PBitMapInfo;
var HeaderSize: integer;
begin
   HeaderSize := Sizeof(TBitmapInfo) + (256 * Sizeof(TRGBQuad));
   if LocalBmpInfo = nil then LocalBmpInfo := AllocMem(HeaderSize);
   if LocalBmpInfo = nil then raise Exception.Create('TNoryImage: Failed to allocate a DIB');
   with LocalBmpInfo^.bmiHeader do begin
      biSize        := SizeOf(TBitmapInfoHeader);
      biWidth       := aWidth;
      biHeight      := -aHeight;
      biPlanes      := 1;
      biBitCount    := aBitCount;
      biCompression := BI_RGB;
      biClrUsed     := 0;
      biClrImportant:= 0;
   end;
   Result := LocalBmpInfo;
end;

///////////////////////////
//
///////////////////////////
constructor TXDib.Create;
begin
   FWidth := 0; FHeight := 0; FBits := nil;
end;

destructor TXDib.Destroy;
begin
   Clear;
   inherited destroy;
end;

function  TXDib.GetEmpty: Boolean;
begin
   Result := FBits = nil;
end;

procedure TXDib.Clear;
begin
   if FBits <> nil then FreeMem (FBits);
   FWidth := 0; FHeight := 0; FBits := nil;
end;

procedure TXDib.ClearbyColor (aColor: word);
var
   i : integer;
   pw : pword;
begin
   if aColor = 0 then begin FillChar (FBits^, FWidth * FHeight * 2, 0); exit; end;

   pw := FBits;
   for i := 0 to Width*Height -1 do begin pw^ := aColor; inc (pw); end;
end;

procedure TXDib.SetSize (aWidth, aHeight: integer);
begin
   if (aWidth <= 0) or (aHeight <= 0) then exit;
   if (aWidth = FWidth) and (aHeight = FHeight) then begin
      FillChar (FBits^, FWidth * FHeight * 2, 0); 
      exit;
   end;

   if FBits <> nil then FreeMem (FBits);
   FWidth := aWidth; FHeight := aHeight;
   GetMem (FBits, FWidth * FHeight * 2);
   FillChar (FBits^, FWidth * FHeight * 2, 0);
end;

procedure TXDib.LoadFromFile (aFileName: string);
var Stream : TFileStream;
begin
   if not FileExists (aFileName) then exit;
   Stream := TFileStream.Create (aFileName, fmOpenRead);
   LoadFromStream (Stream);
   Stream.Free;
end;

procedure TXDib.SaveToFile (aFileName: string);
var Stream : TFileStream;
begin
   Stream := TFileStream.Create (aFileName, fmCreate or fmOpenReadWrite);
   SaveToStream (Stream);
   Stream.Free;
end;

procedure TXDib.LoadFromStream (aStream: TStream);
var
   Header: TBitmapFileHeader;
   BmpInfo : PBitMapInfo;
   HeaderSize, ImageSize: Integer;
   Palette : TImgLibPalette;
   p : pointer;
begin
   Clear;

   aStream.ReadBuffer(Header, SizeOf(Header));
   if header.bfType <> $4D42 then exit;

   HeaderSize := header.bfOffBits - sizeof(BITMAPFILEHEADER);
   GetMem (BmpInfo, HeaderSize);

   aStream.ReadBuffer(BmpInfo^, HeaderSize);

   FWidth := BmpInfo^.bmiHeader.biWidth;
   FHeight := abs (BmpInfo^.bmiHeader.biHeight);

   ImageSize := BmpInfo^.bmiHeader.biSizeImage;

   if ImageSize = 0 then
      ImageSize := (BmpInfo^.bmiHeader.biWidth * BmpInfo^.bmiHeader.biBitCount + 7)
                     div 8 * abs (BmpInfo^.bmiHeader.biHeight);

   GetMem (FBits, ImageSize);
   aStream.ReadBuffer(FBits^, ImageSize);

   case BmpInfo^.bmiHeader.biBitCount of
      8 :
         begin
            p := FBits;
            GetMem (FBits, FWidth * FHeight * 2);
	         BmpInfoToImgLibPal(bmpInfo^.bmiHeader.biClrUsed, Palette, BmpInfo);
            Change8BitTo16Bit (p, FBits, FWidth*FHeight, Palette);
            FreeMem (p);
         end;
      16 :
         begin
         end;
      24 :
         begin
            p := FBits;
            GetMem (FBits, FWidth * FHeight * 2);
            Change24BitTo16Bit (p, FBits, FWidth*FHeight);
            FreeMem (p);
         end;
      else begin
         Clear;
      end;
   end;

   if BmpInfo^.bmiHeader.biHeight > 0 then
      FlipBits (pbyte(FBits), FWidth *2, FHeight);

   FreeMem (BmpInfo);
end;

procedure TXDib.SaveToStream (aStream: TStream);
var
   Header : TBitmapFileHeader;
   BmpInfo : PBitMapInfo;
   HeaderSize : Integer;
begin
   HeaderSize := SizeOf(TBitmapInfo);
   BmpInfo := AllocMem(HeaderSize);

   with BmpInfo^.bmiHeader do begin
      biSize := SizeOf(TBitmapInfoHeader);
      biWidth := Width;
      biHeight := -Height;
      biPlanes := 1;
      biBitCount := 16;
      biCompression := BI_RGB;
      biClrUsed := 0;
      biClrImportant := 0;
   end;

   //if the height is positive the bitmap is Bottom up so flip it.
   if BmpInfo^.bmiHeader.biHeight < 0 then begin
		FlipBits(PByte(Bits), Width*2, Height);
      BmpInfo^.bmiHeader.biHeight := -BmpInfo^.bmiHeader.biHeight;
   end;

   FillChar (Header, sizeof(TBitmapFileHeader), 0);
   with Header do begin
		bfType := $4D42;
      bfSize := 1078+Width*Height*2-1024;
      bfOffBits := 1078-1024;
   end;

   //Write file Header
   aStream.WriteBuffer(Header, SizeOf(Header));
   //Write bitmap info header and validate
   aStream.WriteBuffer(BmpInfo^, SizeOf(TBitmapInfoHeader));

   //Load Bits
   aStream.WriteBuffer(Bits^, LongInt(width * height * 2));
     //If the code gets this far the bitmap has been loaded okay
   FreeMem (BmpInfo);
end;

procedure TXDib.LoadFromBitmap (aBitmap: TBitmap);
var
   mStream : TMemoryStream;
begin
   mStream := TMemoryStream.Create;
   aBitmap.SaveToStream (mStream);
   mStream.Seek (0, 0);
   LoadFromStream (mStream);
   mStream.Free;
end;

procedure TXDib.Assign (aDib: TXDib);
begin
   Clear;
   SetSize (aDib.Width, aDib.Height);
   move (aDib.Bits^, Bits^, aDib.Width*aDib.Height*2);
end;

function  TXDib.GetInSpace (Adib: TXDib; x, y: integer; var InSpaceData: TInSpaceData): Boolean;
var
   sr, FClientRect : TRect;
begin
   Result := FALSE;
   if ADib = nil then exit;

   FClientRect := Rect (0, 0, Width-1, Height-1);

   sr := Rect(x, y, x+ADib.Width-1, y+ADib.Height-1);
   if not IntersectRect(InSpaceData.R, sr, FClientRect) then exit;

   InSpaceData.spw := aDib.Bits;
   inc (InSpaceData.spw, ((InSpaceData.R.left-x)+(InSpaceData.R.top-y)*aDib.Width));

   InSpaceData.dpw := Bits;
   inc (InSpaceData.dpw, (InSpaceData.R.left+InSpaceData.R.top*Width));
   Result := TRUE;
end;

Procedure TXDib.LineTo (x, y, aWidth, aHeight, aColor: integer);
var
   h, w : integer;
   pSour, ps : pWord;
begin
   pSour := FBits;
   inc (pSour, x + y * FWidth);
   for h := 0 to aHeight -1 do begin
      ps := pSour;
      for w := 0 to aWidth -1 do begin
         ps^ := aColor;
         inc (ps);
      end;
      inc (pSour, FWidth);
   end;
end;

procedure TXDib.DrawImage (x, y: integer; aDib: TXDib; aTrans: Boolean);
var
   i, j : integer;
   TempSS, TempDD : pword;
   InSpaceData : TInSpaceData;
begin
   if not GetInSpace (aDib, x, y, InSpaceData) then exit;
   if aTrans = FALSE then begin
      for i := InSpaceData.R.Top to InSpaceData.R.Bottom do begin
         move (InSpaceData.spw^, InSpaceData.dpw^, (InSpaceData.r.right-InSpaceData.r.left+1)*2);
         inc (InSpaceData.spw, aDib.Width);
         inc (InSpaceData.dpw, Width);
      end;
   end else begin
      for i := InSpaceData.r.Top to InSpaceData.r.Bottom do begin
      	TempSS := InSpaceData.spw; TempDD := InSpaceData.dpw;
      	for j := InSpaceData.r.left to InSpaceData.r.right do begin
            if TempSS^ <> 0 then TempDD^ := TempSS^;
            inc (TempSS); Inc (TempDD);
         end;
         inc (InSpaceData.spw, aDib.Width);
         inc (InSpaceData.dpw, Width);
      end;
   end;
end;

procedure TXDib.StretchDrawImage (XDib: TXDib);
var
   i, j, x, y: integer;
   TempSS, TempDD : pword;
   InSpaceData : TInSpaceData;
begin
   if not GetInSpace (XDib, 0, 0, InSpaceData) then exit;
   for j := InSpaceData.r.Top to InSpaceData.r.Bottom do begin
      for i := InSpaceData.r.left to InSpaceData.r.right do begin
         x := i * XDib.Width div Width;
         y := j * XDib.Height div Height;
         TempSS := InSpaceData.spw;
         inc (TempSS, x + y * XDib.Width);
         TempDD := InSpaceData.dpw;
         inc (TempDD, i + j * Width);
         TempDD^ := TempSS^;
      end;
   end;
end;

function TXDib.Optimize: TPoint;
   function WidthBytes(w: Integer): Integer;
   begin
        Result := (((w * 8) + 31) div 32) * 4;
   end;
var
   x, y, minx, maxx, miny, maxy, w, h : Integer;
   i, j: Integer;
   pb, TempBits: pWord;
   pcs, pcd : pWord;
begin
   minx := width-1; maxx := 0; miny := height-1; maxy := 0;

   pb := FBits;
   for i := 0 to (width * height)-1 do begin
      if pb^ <> 0 then begin
         x := i mod width;
         y := i div width;
         if minx > x then minx := x;
         if miny > y then miny := y;

         if maxx < x then maxx := x;
         if maxy < y then maxy := y;
      end;
      inc (pb);
   end;

   if (minx >= maxx) and ( miny >= maxy) then begin
      FreeMem ( FBits, Width * Height * 2);
      FWidth := 4; FHeight := 4;
      GetMem (FBits, Width*Height*2);
      FillChar (FBits^, Width*Height*2, 0);
   end else begin
      w := WidthBytes (Maxx - Minx +1);
      h := Maxy - Miny +1;

      GetMem (TempBits, w * h * 2);
      pcs := FBits;
      inc (pcs, (minx+miny * Width) );
      pcd := TempBits;
      for j := 0 to h -1 do begin
         move ( pcs^, pcd^, w * 2);
         inc (pcs, Width);
         inc (pcd, w);
      end;

      FreeMem (FBits, Width*Height*2);
      FWidth := w; FHeight := h;
      FBits := TempBits;
      Result.x := Minx;
      Result.y := Miny;
   end;
end;

end.
