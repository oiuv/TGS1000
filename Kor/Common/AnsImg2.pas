unit AnsImg2;

interface

uses
  Windows, SysUtils, Classes, Graphics, BmpUtil, Autil32;

const
     ImageLibID = 'ATZ0';
     ImageLibID1 = 'ATZ1';
     ImageLibID2 = 'ATZ2';

type
  TVARGBFunction = procedure (n:word; var r, g, b: word) of object;
  TARGBFunction = function (r, g, b: word):word of object;

  TAns2Color = word;

  PTAns2Color = ^TAns2Color;

  TAns2ImageFileHeader = record
       Width: Integer;
       Height: Integer;
       px, py : Integer;
       none : Integer;
  end;

  TAns2ImageLibHeader = record
       IDent: array[0..3] of Char;
       ImageCount: Integer;
       TransparentColor: Integer;
       Palette: TImgLibPalette;
  end;

  TAns2Image = class
  	private
      function LARGB (r, g, b: word): word;
      procedure LVARGB (n:word; var r, g, b: word);
      function LARGB16 (r, g, b: word): word;
      procedure LVARGB16 (n:word; var r, g, b: word);
   protected
   public
      Bitflag15 : Boolean;
      ARGB : TARGBFunction;
      VARGB : TVARGBFunction;

      Name : string;
      px, py : integer;
    	Width, Height: Integer;
      Bits : PTAns2Color;
      TransparentColor : Integer;
		constructor Create(AWidth, AHeight, Apx, Apy:Integer);
    	destructor Destroy; override;
      function  ARGBDEC (n:word; d: byte): word;
      procedure GetImage  (AnsImage: TAns2Image; x, y: Integer);
      procedure DrawImage (AnsImage: TAns2Image; x, y: Integer; aTrans: Boolean);
      procedure DrawImageGreenConvert (AnsImage: TAns2Image; x, y: Integer; acol, defaultadd: word);
      procedure DrawImageKeyColor (AnsImage: TAns2Image; x, y: Integer; col:word; ptable: pword);
//      procedure DrawImageKeyColorBitMask (AnsImage: TAns2Image; x, y: Integer; col:word; ptable: pword; BitImage: TAns2Image);
      procedure DrawImageOveray (AnsImage: TAns2Image; x, y: Integer; Weight: integer);
      procedure Clear ( Color: word);
      procedure EraseRect ( R: TRect; Color: word);
      procedure hLine (x, y, w: Integer; Col:word);
      procedure vLine (x, y, h: Integer; Col:word);
      procedure Resize ( aWidth, aheight: Integer);
		procedure SaveToFile(FileName: String);
		procedure LoadFromFile (FileName: String);
      procedure LoadFromFileTrueColor (FileName: String);
      procedure Optimize;
      procedure BitConvert;
   published
  end;

  TAns2ImageLib = class
  	private
      FTag : integer;
      ImageList : TList;
		function  GetAns2Image (Idx: Integer):TAns2Image;
		function  GetCount : Integer;
   protected
   public
      TransparentColor : word;
		constructor Create;
    	destructor Destroy; override;
		procedure Clear;
		procedure AddImage (AImage: TAns2Image);
		procedure InsertImage (Idx: Integer; AImage: TAns2Image);
		procedure DeleteImage (Idx: Integer);
    	procedure LoadFromFile (FileName: String);
      procedure SaveToFile(FileName: String);
		function  GetByName (aName:string): TAns2Image;
    	property  Images[Index: Integer]: TAns2Image read GetAns2Image; default;
    	property  Count : Integer read GetCount;
      property  Tag : integer read FTag write FTag;
   published
  end;


procedure AnsDraw2Image(Canvas: TCanvas; X, Y: Integer; ansImage:TAns2Image);
procedure AnsPaletteDataToAns2Image (Ans2Image: TAns2Image; Palette: TImgLibPalette; pb : Pbyte);
procedure AnsStretchDraw2Image (Canvas: TCanvas; Rect: TRect; ansImage:TAns2Image);
function  MakeSelectedImage ( AnsImage:TAns2Image; Col:word):TAns2Image;
procedure AnsTrueDataToAns2Image (Ans2Image: TAns2Image; pb : pbyte);


function  WinRGB (r, g, b: word): word;
procedure WinVRGB (n:word; var r, g, b: word);
//procedure SetAnsImageBitFlag (abo: Boolean);

var
   Error : integer;
   darkentbl : array [0..65535] of word;
   ColorImage : TAns2Image;

implementation

var
   BitFlag : Boolean = TRUE;
{
procedure SetAnsImageBitFlag (abo: Boolean);
begin
   bitFlag := abo;
end;
}
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


function TAns2Image.LARGB (r, g, b: word): word;
begin
   Result  := b + (g shl 5) + (r shl 10);
end;

procedure TAns2Image.LVARGB (n:word; var r, g, b: word);
begin
   b := n and $1F;
   g := (n shr 5) and $1F;
   r := (n shr 10) and $1F;
end;

function TAns2Image.LARGB16 (r, g, b: word): word;
begin
   Result  := b + (g shl 6) + (r shl 11);
end;

procedure TAns2Image.LVARGB16 (n:word; var r, g, b: word);
begin
   b := n and $1F;
   g := (n shr 6) and $1F;
   r := (n shr 11) and $1F;
end;

function TAns2Image.ARGBDEC (n:word; d: byte): word;
var r,g,b: word;
begin
   VARGB (n, r, g, b);
   if b > d then b := b - d
   else b := 0;
   if g > d then g := g - d
   else g := 0;
   if r > d then r := r - d
   else r := 0;
   Result := ARGB(r,g,b);
end;

//////////////////////////////////////
//         TAns2Image            //
//////////////////////////////////////

procedure TAns2Image.BitConvert;
   procedure VARGBSelf (n:word; var r, g, b: word);
   begin
      b := n and $1F;
      g := (n shr 5) and $1F;
      r := (n shr 10) and $1F;
   end;
var
   i : integer;
   p : PTAns2Color;
   w, r, g, b : word;
begin
   P := Bits;

   for i := 0 to Width * Height -1 do begin
      w := p^;
      VARGBSelf (w, r, g, b);
      p^ := ARGB (r, g, b);
      inc (p);
   end;
end;

constructor TAns2Image.Create(AWidth, AHeight, Apx, Apy: Integer);
begin
   Bitflag15 := bitflag;

   if BitFlag then begin
      VARGB := LVARGB;
      ARGB := LARGB;
   end else begin
      VARGB := LVARGB16;
      ARGB := LARGB16;
   end;


	TransparentColor := 0;
	Width := WidthBytes (AWidth); Height := AHeight;
   px := Apx;                   py := Apy;
	Bits := nil;
	GetMem (Bits, Width*Height*Sizeof(TAns2Color));
   if Bits = nil then raise Exception.Create('TAns2Image: GemMem Failed for Bits');
   FillChar (Bits^, Width*Height*Sizeof(TAns2Color), 0)
end;

destructor TAns2Image.Destroy;
begin
   if Bits <> nil then FreeMem ( Bits, Width*Height*sizeof(TAns2Color));
	inherited Destroy;
end;

procedure TAns2Image.Clear ( Color: word);
var
   i : integer;
   pcol : PTAns2Color;
begin
   pcol := Bits;
   for i := 0 to Width * Height -1 do begin
      pcol^ := Color;
      inc (pcol);
   end;
end;

procedure TAns2Image.EraseRect ( R: TRect; Color: word);
var
	dpb, TempDD : PTAns2Color;
   i, j : integer;
   ir, sr, dr: TRect;
begin
   //do clipping

   sr := Rect(R.Left, R.Top, R.Right-1, R.Bottom-1);
   dr := Rect(0, 0, Width-1, Height-1);

   if not IntersectRect(ir, sr, dr) then exit;

   dpb := Bits;
   inc (dpb, (ir.left+ir.top*Width));

   for i := ir.Top to ir.Bottom do begin
      TempDD := dpb;
      for j := ir.left to ir.right do begin
         TempDD^ := Color;
         Inc (TempDD);
      end;
      inc (dpb, Width);
   end;
end;

procedure TAns2Image.hLine (x, y, w: Integer; Col:word);
var
   i : integer;
   pb : PTAns2Color;
begin
   if x < 0 then exit;
   if x+w >= Width then exit;
   if y < 0 then exit;
   if y >= Height then exit;
   pb := Bits;
   inc (pb, x + y * Width);
   for i := 0 to w-1 do begin
      pb^ := Col;
      inc (pb);
   end;
end;

procedure TAns2Image.vLine (x, y, h: Integer; Col:word);
var
   i : integer;
   pb : PTAns2Color;
begin
   if x < 0 then exit;
   if x >= Width then exit;
   if y < 0 then exit;
   if y + h >= Height then exit;
   pb := Bits;
   inc (pb, x + y * Width);
   for i := 0 to h-1 do begin
      pb^ := Col;
      inc (pb, width);
   end;
end;

procedure TAns2Image.GetImage  (AnsImage: TAns2Image; x, y: Integer);
var
	spb, dpb : PTAns2Color;
   i: integer;
   ir, sr, dr: TRect;
begin
   //do clipping
   dr := Rect(x,y, x+AnsImage.Width-1, y+AnsImage.Height-1);
   sr := Rect(0,0, Width-1, Height-1);

   if not IntersectRect(ir, sr, dr) then exit;

   spb := Bits;
   inc (spb, ir.left+ir.top*Width);

   dpb := AnsImage.Bits;
   inc (dpb, (ir.left-x)+(ir.top-y)*AnsImage.Width);

   for i := 0 to ir.Bottom-ir.Top do begin
   	move (spb^,dpb^, (ir.right-ir.left+1) * 2);
      inc (spb, Width);
      inc (dpb, AnsImage.Width);
   end;
end;

procedure TAns2Image.DrawImageGreenConvert (AnsImage: TAns2Image; x, y: Integer; acol, defaultadd: word);
var
	spb, dpb, TempSS, TempDD : PTAns2Color;
   i, j : integer;
   n, r, g, b, ar, ag, ab : word;
   ir, sr, dr: TRect;
begin
   if AnsImage = nil then exit;

   WinVRGB (acol, ar, ag, ab);

   //do clipping

   sr := Rect(x, y, x+AnsImage.Width-1, y+AnsImage.Height-1);
   dr := Rect(0, 0, Width-1, Height-1);

   if not IntersectRect(ir, sr, dr) then exit;

   spb := AnsImage.Bits;
   inc (spb, ((ir.left-x)+(ir.top-y)*AnsImage.Width));

   dpb := Bits;
   inc (dpb, (ir.left+ir.top*Width));

   for i := ir.Top to ir.Bottom do begin
      TempSS := spb; TempDD := dpb;
      for j := ir.left to ir.right do begin
         if TempSS^ <> AnsImage.TransparentColor then begin
            WinVRGB ( TempSS^, r, g, b);
            if (r=0) and (b=0) then begin
               n := g;
               r := n * ar div 31 + defaultadd;
               g := n * ag div 31 + defaultadd;
               b := n * ab div 31 + defaultadd;
               if r > 31 then r := 31;
               if g > 31 then g := 31;
               if b > 31 then b := 31;

               TempDD^ := WinRGB ( r, g, b);
               if TempDD^ = 0 then TempDD^ := 1;
            end else TempDD^ := TempSS^;
         end;
         inc (TempSS); Inc (TempDD);
      end;
      inc (spb, AnsImage.Width);
      inc (dpb, Width);
   end;
end;

procedure TAns2Image.DrawImage (AnsImage: TAns2Image; x, y: Integer; aTrans: Boolean);
var
	spb, dpb, TempSS, TempDD : PTAns2Color;
   i, j : integer;
   ir, sr, dr: TRect;
begin
   if AnsImage = nil then begin
//      Error := 1;
      exit;
   end;
   //do clipping

   sr := Rect(x, y, x+AnsImage.Width-1, y+AnsImage.Height-1);
   dr := Rect(0, 0, Width-1, Height-1);

   if not IntersectRect(ir, sr, dr) then exit;

   spb := AnsImage.Bits;
   inc (spb, ((ir.left-x)+(ir.top-y)*AnsImage.Width));

   dpb := Bits;
   inc (dpb, (ir.left+ir.top*Width));

   if aTrans = FALSE then begin
      for i := ir.Top to ir.Bottom do begin
         move (spb^, dpb^, (ir.right-ir.left+1) * sizeof(TAns2Color));
         inc (spb, AnsImage.Width);
         inc (dpb, Width);
      end;
   end else begin
      for i := ir.Top to ir.Bottom do begin
      	TempSS := spb; TempDD := dpb;
      	for j := ir.left to ir.right do begin
            if TempSS^ <> AnsImage.TransparentColor then TempDD^ := TempSS^;
            inc (TempSS); Inc (TempDD);
         end;
         inc (spb, AnsImage.Width);
         inc (dpb, Width);
      end;
   end;
end;

procedure TAns2Image.Resize ( aWidth, aheight: Integer);
var
   OldBits, spb, dpb : PTAns2Color;
   i, j, x, y, Oldwidth, Oldheight: integer;
begin
   OldWidth := Width;
   OldHeight := Height;
   OldBits := Bits;

   Width := aWidth;
   Height := aHeight;
	GetMem (Bits, Width*Height*Sizeof(TAns2Color));
   FillChar (Bits^, Width*Height*Sizeof(TAns2Color), 0);

   for j := 0 to Height - 1 do begin
      for i := 0 to Width -1 do begin
         x := i * OldWidth div Width;
         y := j * OldHeight div Height;
         spb := OldBits;
         inc (spb, x + y * OldWidth);
         dpb := Bits;
         inc (dpb, i + j * Width);
         dpb^ := spb^;
      end;
   end;
   px := px * Width div OldWidth;
   py := py * Height div OldHeight;
   FreeMem (OldBits);
end;

{
procedure TAns2Image.DrawImageKeyColorBitMask (AnsImage: TAns2Image; x, y: Integer; col:word; ptable: pword; BitImage: TAns2Image);
var
	spb, dpb, TempSS, TempDD : PTAns2Color;

	maskspb, MaskTempSS : PTAns2Color;

   i, j : integer;
   ir, sr, dr: TRect;
   ptemp : pword;

   r,g,b,r1,g1,b1: word;
begin
   if AnsImage = nil then exit;

   //do clipping
   sr := Rect(x, y, x+AnsImage.Width-1, y+AnsImage.Height-1);
   dr := Rect(0, 0, Width-1, Height-1);

   if not IntersectRect(ir, sr, dr) then exit;

   spb := AnsImage.Bits;
   inc (spb, ((ir.left-x)+(ir.top-y)*AnsImage.Width));

   maskspb := BitImage.Bits;
   inc (maskspb, ((ir.left-x)+(ir.top-y)*BitImage.Width));

   dpb := Bits;
   inc (dpb, (ir.left+ir.top*Width));

   for i := ir.Top to ir.Bottom do begin
      TempSS := spb; TempDD := dpb;
      MaskTempSs := maskspb;

      for j := ir.left to ir.right do begin
         if TempSS^ <> AnsImage.TransparentColor then begin
            if MaskTempSs^ = 0 then begin
               if TempSS^ = col then begin
                  ptemp := ptable;
                  inc (ptemp, TempDD^);
                  TempDD^ := ptemp^;
               end else begin
                  TempDD^ := TempSS^;
               end;
            end else begin

               VARGB (TempDD^, r1, g1, b1);
               VARGB (TempSS^, r, g, b);

               r1 := (r1 + r*2) div 3;
               g1 := (g1 + g*2) div 3;
               b1 := (b1 + b*2) div 3;

               TempDD^ := ARGB (r1,g1,b1);
            end;
         end;
         inc (TempSS); Inc (TempDD);
         inc (MaskTempSS);
      end;
      inc (spb, AnsImage.Width);
      inc (maskspb, BitImage.Width);
      inc (dpb, Width);
   end;
end;
}


procedure TAns2Image.DrawImageKeyColor (AnsImage: TAns2Image; x, y: Integer; col:word; ptable: pword);
var
	spb, dpb, TempSS, TempDD : PTAns2Color;
   i, j : integer;
   ir, sr, dr: TRect;
   ptemp : pword;
begin
   if AnsImage = nil then exit;
   
   //do clipping
   sr := Rect(x, y, x+AnsImage.Width-1, y+AnsImage.Height-1);
   dr := Rect(0, 0, Width-1, Height-1);

   if not IntersectRect(ir, sr, dr) then exit;

   spb := AnsImage.Bits;
   inc (spb, ((ir.left-x)+(ir.top-y)*AnsImage.Width));

   dpb := Bits;
   inc (dpb, (ir.left+ir.top*Width));

   for i := ir.Top to ir.Bottom do begin
      TempSS := spb; TempDD := dpb;
      for j := ir.left to ir.right do begin
         if TempSS^ <> AnsImage.TransparentColor then begin
            if TempSS^ = col then begin
               ptemp := ptable;
               inc (ptemp, TempDD^);
               TempDD^ := ptemp^;
//               TempDD^ := Darkentbl[Tempdd^];
            end else begin
               TempDD^ := TempSS^;
            end;
         end;
         inc (TempSS); Inc (TempDD);
      end;
      inc (spb, AnsImage.Width);
      inc (dpb, Width);
   end;
end;

procedure TAns2Image.DrawImageOveray (AnsImage: TAns2Image; x, y: Integer; weight: integer);
var
	spb, dpb, TempSS, TempDD : PTAns2Color;
   i, j : integer;
   ir, sr, dr: TRect;
   r,g,b,r1,g1,b1: word;
begin
   if AnsImage = nil then begin
//      Error := 3;
      exit;
   end;

   //do clipping
   if weight > 100 then weight := 100;
   if weight < 0 then weight := 0;
   sr := Rect(x, y, x+AnsImage.Width-1, y+AnsImage.Height-1);
   dr := Rect(0, 0, Width-1, Height-1);

   if not IntersectRect(ir, sr, dr) then exit;

   spb := AnsImage.Bits;
   inc (spb, ((ir.left-x)+(ir.top-y)*AnsImage.Width));

   dpb := Bits;
   inc (dpb, (ir.left+ir.top*Width));

   for i := ir.Top to ir.Bottom do begin
      TempSS := spb; TempDD := dpb;
      for j := ir.left to ir.right do begin
         if (TempSS^ <> AnsImage.TransparentColor) and (TempSs^ <> 31) then begin
            VARGB (TempDD^, r1, g1, b1);
            VARGB (TempSS^, r, g, b);

            if r > r1 then begin
              r := r * (100-weight);
              r1 := r1 * weight;
              r1 := (r1 + r) div 100;
            end else begin
            end;

            if g > g1 then begin
               g := g * (100-weight);
               g1 := g1 * weight;
               g1 := (g1 + g) div 100;
            end else begin
            end;

            if b > b1 then begin
               b := b * (100-weight);
               b1 := b1 * weight;
               b1 := (b1 + b) div 100;
            end else begin
            end;

            TempDD^ := ARGB (r1,g1,b1);
//            TempDD^ := TempSS^;
         end;
         inc (TempSS); Inc (TempDD);
      end;
      inc (spb, AnsImage.Width);
      inc (dpb, Width);
   end;
end;

procedure TAns2Image.Optimize;
var
   x, y, minx, maxx, miny, maxy, w, h : Integer;
   i, j: Integer;
   pb, TempBits: PTAns2Color;
   pcs, pcd : PTAns2Color;
begin
   minx := width-1; maxx := 0; miny := height-1; maxy := 0;

   pb := Bits;
   for i := 0 to (width * height)-1 do begin
      if pb^ <> TransParentColor then begin
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
      FreeMem ( Bits, Width * Height * sizeof(TAns2Color));
      Width := 4; Height := 4;
      GetMem (Bits, Width*Height*sizeof(TAns2Color));
      FillChar (Bits^, Width*Height*sizeof(TAns2Color), 0);
   end else begin
      w := WidthBytes (Maxx - Minx +1);
      h := Maxy - Miny +1;

      GetMem ( TempBits, w * h * sizeof(TAns2Color));
      pcs := Bits;
      inc (pcs, (minx+miny * Width) );
      pcd := TempBits;
      for j := 0 to h -1 do begin
         move ( pcs^, pcd^, w * sizeof(TAns2Color));
         inc (pcs, Width);
         inc (pcd, w);
      end;

      FreeMem (Bits, Width*Height*sizeof(TAns2Color));
      Width := w; Height := h;
      Bits := TempBits;
      px := px + Minx;
      py := py + Miny;
   end;
end;

//Load DIB ot File
procedure TAns2Image.LoadFromFile (FileName: String);
var
	BmpInfo : PBitMapInfo;
   Bmpbits : Pbyte;
   headerSize, ImageSize : Integer;
   Palette : TImgLibPalette;
begin

	BmpInfo := nil; BmpBits := nil;

	LoadDIB256 ( FileName, BmpInfo, BmpBits, HeaderSize, ImageSize);
   if (BmpInfo = nil) or (BmpBits = nil) then exit;

   if Bits <> nil then FreeMem ( Bits, Width*Height*Sizeof(TAns2Color));

   Width := BmpInfo^.bmiHeader.biWidth;
   Height := Abs(BmpInfo^.bmiHeader.biHeight);
	BmpInfoToImgLibPal(Palette, BmpInfo);

	GetMem (Bits, Width*Height*Sizeof(TAns2Color));
   if Bits = nil then raise Exception.Create('TAns2Image: GemMem Failed for Bits');
   FillChar (Bits^, Width*Height*sizeof(TAns2Color), 0);

   AnsPaletteDataToAns2Image (Self, Palette, BmpBits);

   FreeMem ( Bmpbits);
   FreeMem ( BmpInfo);
end;

procedure TAns2Image.LoadFromFileTrueColor (FileName: String);
var
//   i, j : integer;
   Stream: TFileStream;
   Header: TBitmapFileHeader;
   BmpInfo : PBitMapInfo;
   HeaderSize: Integer;
   buffer : pbyte;
begin
	//Initialise and open file
   HeaderSize := SizeOf(TBitmapInfoHeader);
   BmpInfo := AllocMem(HeaderSize);
   Stream := TFileStream.Create(FileName, fmOpenRead);
   //Read file Header
   Stream.ReadBuffer(Header, SizeOf(Header));
   //Read bitmap info header and validate
   Stream.ReadBuffer(BmpInfo^, SizeOf(TBitmapInfoHeader));

   with BmpInfo^.bmiHeader do begin
      if biBitCount <> 24 then begin
	      Stream.Free;
         FreeMem ( BmpInfo);
         raise Exception.Create('TAns2Image: Not TrueColor');
         exit;
      end;
   end;

   Width := BmpInfo^.bmiHeader.biWidth;
   Height := BmpInfo^.bmiHeader.biHeight;

   if Bits <> nil then FreeMem ( Bits, Width*Height*Sizeof(TAns2Color));
	GetMem (Bits, Width*Height*2);
	GetMem (Buffer, Width*Height*3);

   //Load Bits
   //Stream.Seek(Header.bfOffBits, soFromBeginning);
   Stream.ReadBuffer(Buffer^, LongInt(width * height * 3));
   FlipBits (Buffer, Width*3, Height);

   AnsTrueDataToAns2Image (Self, Buffer);

     //If the code gets this far the bitmap has been loaded okay
	Stream.Free;
   FreeMem ( BmpInfo);
   FreeMem ( Buffer);
end;


//Save DIB ot File
procedure TAns2Image.SaveToFile(FileName: String);
var
   Stream: TFileStream;
   Header: TBitmapFileHeader;
   BmpInfo : PBitMapInfo;
   HeaderSize, fh: Integer;
begin
     HeaderSize := SizeOf(TBitmapInfo);
     BmpInfo := AllocMem(HeaderSize);

     with BmpInfo^.bmiHeader do
     begin
          biSize := SizeOf(TBitmapInfoHeader);
          biWidth := Width;
          biHeight := -Height;
          biPlanes := 1;
          biBitCount := 16; //always convert to 8 bit image
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

	fh := FileCreate(FileName);
   FileClose(fh);

	//Initialise and open file
   Stream := TFileStream.Create(FileName, fmOpenWrite);
   //Read file Header
   Stream.WriteBuffer(Header, SizeOf(Header));
   //Read bitmap info header and validate
   Stream.WriteBuffer(BmpInfo^, SizeOf(TBitmapInfoHeader));

   //Load Bits
   //Stream.Seek(Header.bfOffBits, soFromBeginning);
   Stream.WriteBuffer(Bits^, LongInt(width * height * 2));
     //If the code gets this far the bitmap has been loaded okay
	Stream.Free;
   FreeMem ( BmpInfo);
end;

//////////////////////////////////////
//        TAns2ImageLib             //
//////////////////////////////////////

constructor TAns2ImageLib.Create;
begin
   TransparentColor :=0;
   FTag := 0;
	ImageList := TList.Create;
end;

destructor TAns2ImageLib.Destroy;
var i : integer;
begin
	for i := 0 to ImageList.Count - 1 do TAns2Image(ImageList.items[i]).Free;
	ImageList.Free;
	inherited Destroy;
end;

procedure ImageConv (var Bmp: TBitMap; AnsImage: TAns2Image; aCanvas: TCanvas);
var
   BmpInfo: PBitmapInfo;
   HeaderSize: Integer;
begin
   HeaderSize := SizeOf(TBitmapInfo) + (256 * SizeOf(TRGBQuad));
   BmpInfo := AllocMem(HeaderSize);

   with BmpInfo^.bmiHeader do begin
      biSize := SizeOf(TBitmapInfoHeader);
      biWidth := AnsImage.Width;
      biHeight := -AnsImage.Height;
      biPlanes := 1;
      biBitCount := 16;
      biCompression := BI_RGB;
      biSizeImage := 0;
      biClrUsed := 0;
      biClrImportant := 0;
   end;

   Bmp.Handle := CreateDIBitmap(aCanvas.Handle, BmpInfo^.bmiHeader, 0,
               Pointer(0), BmpInfo^, DIB_PAL_COLORS);

   SetDIBits( aCanvas.Handle, Bmp.Handle, 0, AnsImage.Height, AnsImage.Bits, BmpInfo^, 0);
   if Bmp.Handle = 0 then
      raise Exception.Create('CreateDIBitmap failed');

   FreeMem(BmpInfo, HeaderSize);
end;

function  TAns2ImageLib.GetByName (aName:string): TAns2Image;
var
   i : integer;
   AnsImage: TAns2Image;
begin
   Result := nil;

   for i := 0 to Imagelist.Count -1 do begin
      AnsImage := ImageList[i];
      if AnsImage.Name = aName then begin
         Result := AnsImage;
         exit;
      end;
   end;
end;


function  TAns2ImageLib.GetCount : Integer;
begin
	Result := ImageList.Count;
end;

function  TAns2ImageLib.GeTAns2Image (Idx: Integer):TAns2Image;
begin
	if (Idx < ImageList.Count) and (Idx >= 0)  then Result := ImageList.items[Idx]
	else Result := nil;
end;

procedure TAns2ImageLib.Clear;
var i : Integer;
	AnsImage : TAns2Image;
begin
	for i := 0 to ImageList.Count-1 do begin
   	AnsImage := ImageList.Items[i];
      AnsImage.Free;
   end;
   ImageList.Clear;
end;

procedure TAns2ImageLib.AddImage (AImage: TAns2Image);
begin
	ImageList.add (AImage);
end;

procedure TAns2ImageLib.DeleteImage (Idx: Integer);
begin
	if Idx < ImageList.Count then begin
   	TAns2Image(ImageList.items[Idx]).Free;
		ImageList.Delete (Idx);
	end;
end;

procedure TAns2ImageLib.InsertImage (Idx: Integer; AImage: TAns2Image);
begin
	ImageList.Insert ( Idx, AImage);
   AImage.TransParentColor := TransParentColor;
end;

procedure TAns2ImageLib.LoadFromFile (FileName: String);
var
   Stream: TFileStream;
//   fh : integer;
   n: Integer;
   AnsImage : TAns2Image;
   ImgHeader: TAns2ImageLibHeader;
  	FAnsHdr : TAns2ImageFileHeader;
   pbuf : pbyte;
   showbuf : array [0..64] of byte;
begin
   if FileExists (FileName) = FALSE then begin
      StrPcopy (@ShowBuf, FileName+'이 없습니다.');
      Windows.MessageBox( 0, @ShowBuf, '마지막 왕국', 0);
      exit;
   end;

   Stream := TFileStream.Create(FileName, fmOpenRead);
//   fh := FileOpen (FileName, fmOpenRead);

   for n := 0 to ImageList.Count - 1 do TAns2Image(ImageList.items[n]).Free;
   ImageList.Clear;

   Stream.ReadBuffer(ImgHeader, SizeOf(ImgHeader));
//   FileRead (fh, ImgHeader, SizeOf(ImgHeader));
   if StrLIComp(PChar(ImageLibID), ImgHeader.Ident, 4) = 0 then begin
      for n := 0 to ImgHeader.ImageCount - 1 do begin
         Stream.ReadBuffer(FAnsHdr, SizeOf(TAns2ImageFileHeader));
//         FileRead (fh, FAnsHdr, SizeOf(TAns2ImageFileHeader));
         AnsImage := TAns2Image.Create ( FAnsHdr.Width, FAnsHdr.Height, FAnsHdr.px, FAnsHdr.py);

         if AnsImage = nil then
            raise Exception.Create('TAns2Image: GemMem Failed ');
         GetMem (pbuf, AnsImage.Width * AnsImage.Height);
         Stream.ReadBuffer(pbuf^, AnsImage.Width * AnsImage.Height);
//         FileRead (fh, pbuf^, AnsImage.Width * AnsImage.Height);

         AnsPaletteDataToAns2Image (AnsImage, ImgHeader.Palette, pbuf);

         FreeMem (pbuf, AnsImage.Width * AnsImage.Height);

         AnsImage.TransparentColor := TransParentColor;
         AddImage ( AnsImage);
      end;
   end else begin
      if StrLIComp(PChar(ImageLibID1), ImgHeader.Ident, 4) = 0 then begin
         for n := 0 to ImgHeader.ImageCount - 1 do begin
            Stream.ReadBuffer(FAnsHdr, SizeOf(TAns2ImageFileHeader));
//            FileRead (fh, FAnsHdr, SizeOf(TAns2ImageFileHeader));
            AnsImage := TAns2Image.Create ( FAnsHdr.Width, FAnsHdr.Height, FAnsHdr.px, FAnsHdr.py);
            if AnsImage = nil then
               raise Exception.Create('TAns2Image: GemMem Failed ');
            Stream.ReadBuffer(AnsImage.Bits^, AnsImage.Width * AnsImage.Height * 2);
//            FileRead (fh, AnsImage.Bits^, AnsImage.Width * AnsImage.Height * 2);
            AnsImage.TransparentColor := TransParentColor;

            if BitFlag = FALSE then AnsImage.BitConvert;

            AddImage ( AnsImage);
         end;
      end else raise Exception.Create('Not a valid Image Library File');
   end;
   Stream.Free;
//   FileClose (fh);
end;

procedure TAns2ImageLib.SaveToFile(FileName: String);
var
   Stream: TFileStream;
   n: Integer;
   AnsImage : TAns2Image;
   fAnsHdr: TAns2ImageFileHeader;
   ImgHeader: TImgLibHeader;
begin
   Stream  := TFileStream.Create(FileName, fmCreate);
   with ImgHeader do begin
   	Ident := 'ATZ1';
   	ImageCount := ImageList.Count;
      TransparentColor := Self.TransparentColor;
//      Palette := Self.Palette;
   end;

   Stream.WriteBuffer(ImgHeader, SizeOf(ImgHeader));
   for n := 0 to ImgHeader.ImageCount - 1 do begin
      AnsImage := ImageList.items[n];
      fAnsHdr.Width := AnsImage.Width;
      fAnsHdr.Height := AnsImage.Height;
      fAnsHdr.Px := AnsImage.Px;
      fAnsHdr.Py := AnsImage.Py;
      Stream.WriteBuffer(fAnsHdr, SizeOf(TAns2ImageFileHeader));
      Stream.WriteBuffer(AnsImage.Bits^, AnsImage.Width * AnsImage.Height*2);
   end;

   Stream.Free;
end;


procedure AnsDraw2Image(Canvas: TCanvas; X, Y: Integer; ansImage:TAns2Image);
var
   HeaderSize : integer;
   dc : HDC;
   bmpInfo : PBitmapInfo;
begin
   if not assigned (AnsImage) then exit;
   HeaderSize := Sizeof(TBitmapInfo) + (256 * Sizeof(TRGBQuad));
   BmpInfo := AllocMem(HeaderSize);
   if BmpInfo = nil then raise Exception.Create('TNoryImage: Failed to allocate a DIB');
   with BmpInfo^.bmiHeader do begin
      biSize        := SizeOf(TBitmapInfoHeader);
      biWidth       := AnsImage.Width;
      biHeight      := -AnsImage.Height;
      biPlanes      := 1;
      biBitCount    := 16;
      biCompression := BI_RGB;
      biClrUsed     := 0;
      biClrImportant:= 0;
   end;
   dc := canvas.Handle;
   SetDIBitsToDevice(dc, x, y, AnsImage.Width, AnsImage.Height, 0, 0, 0, AnsImage.Height, AnsImage.Bits, BmpInfo^, DIB_RGB_COLORS);
   FreeMem(BmpInfo, HeaderSize);
end;

{
procedure AnsDraw2Image(Canvas: TCanvas; X, Y: Integer; ansImage:TAns2Image);
var
   BmpInfo: PBitmapInfo;
   HeaderSize: Integer;
   Bmp: TBitmap;
   Focus: hWnd;
   dc: HDC;
begin

   if not assigned (AnsImage) then exit;

   Bmp := TBitmap.Create;
   HeaderSize := SizeOf(TBitmapInfo) + (256 * SizeOf(TRGBQuad));
   BmpInfo := AllocMem(HeaderSize);

   with BmpInfo^.bmiHeader do begin
      biSize := SizeOf(TBitmapInfoHeader);
      biWidth := AnsImage.Width;
      biHeight := -AnsImage.Height;
      biPlanes := 1;
      biBitCount := 16;
      biCompression := BI_RGB;
      biSizeImage := 0;
      biClrUsed := 0;
      biClrImportant := 0;
   end;

   Focus := GetFocus;
   dc := GetDC(Focus);

   Bmp.Handle := CreateDIBitmap(dc, BmpInfo^.bmiHeader, 0, Pointer(0), BmpInfo^, DIB_PAL_COLORS);

   SetDIBits( dc, Bmp.Handle, 0, AnsImage.Height, AnsImage.Bits, BmpInfo^, 0);

   ReleaseDC(Focus, DC);
   if Bmp.Handle = 0 then
      raise Exception.Create('CreateDIBitmap failed');

   FreeMem(BmpInfo, HeaderSize);
   Canvas.Draw(x,y, Bmp);
   Bmp.Free;
end;
}

procedure AnsPaletteDataToAns2Image (Ans2Image: TAns2Image; Palette: TImgLibPalette; pb : pbyte);
var
   i, j: integer;
   db : PTAns2Color;
   sb: pbyte;
   col8, r, g, b, t: word;
   wcol : word;
begin
   sb := pb; db := Ans2Image.Bits;

   for j := 0 to Ans2Image.Height -1 do begin
      for i := 0 to Ans2Image.Width -1 do begin
         col8 := sb^;
         r := Palette[col8].Red;
         g := Palette[col8].Green;
         b := Palette[col8].Blue;

         t := r shr 3;
         if (r <> 0) and (t = 0) then r := 1
         else r := t;

         t := g shr 3;
         if (g <> 0) and (t = 0) then g := 1
         else g := t;

         t := b shr 3;
         if (b <> 0) and (t = 0) then b := 1
         else b := t;

         wcol := Ans2Image.ARGB (r, g, b);

         db^ := wcol;

         inc (sb);
         inc (db);
      end;
   end;
end;

procedure AnsTrueDataToAns2Image (Ans2Image: TAns2Image; pb : pbyte);
var
   i, j: integer;
   db : PTAns2Color;
   sb: pbyte;
   r, g, b, t: word;
   wcol : word;
begin
   sb := pb; db := Ans2Image.Bits;

   for j := 0 to Ans2Image.Height -1 do begin
      for i := 0 to Ans2Image.Width -1 do begin
         b := sb^; inc (sb);
         g := sb^; inc (sb);
         r := sb^; inc (sb);

         t := r shr 3;
         if (r <> 0) and (t = 0) then r := 1
         else r := t;

         t := g shr 3;
         if (g <> 0) and (t = 0) then g := 1
         else g := t;

         t := b shr 3;
         if (b <> 0) and (t = 0) then b := 1
         else b := t;

         wcol := Ans2Image.ARGB (r, g, b);

         db^ := wcol;

         inc (db);
      end;
   end;
end;

procedure AnsStretchDraw2Image(Canvas: TCanvas; Rect: TRect; ansImage:TAns2Image);
var
   BmpInfo: PBitmapInfo;
   HeaderSize: Integer;
   Bmp: TBitmap;
   Focus: hWnd;
   dc: HDC;
begin
   if not assigned (AnsImage) then exit;

   Bmp := TBitmap.Create;
   HeaderSize := SizeOf(TBitmapInfo) + (256 * SizeOf(TRGBQuad));
   BmpInfo := AllocMem(HeaderSize);

   with BmpInfo^.bmiHeader do begin
      biSize := SizeOf(TBitmapInfoHeader);
      biWidth := AnsImage.Width;
      biHeight := -AnsImage.Height;
      biPlanes := 1;
      biBitCount := 16; //always convert to 8 bit image
      biCompression := BI_RGB;
      biClrUsed := 0;
      biClrImportant := 0;
   end;

   Focus := GetFocus;
   dc := GetDC(Focus);
   Bmp.Handle := CreateDIBitmap(dc, BmpInfo^.bmiHeader, 0,
               Pointer(0), BmpInfo^, DIB_RGB_COLORS);

   SetDIBits( dc, Bmp.Handle, 0, AnsImage.Height, AnsImage.Bits, BmpInfo^, 0);

   ReleaseDC(Focus, DC);
   if Bmp.Handle = 0 then
      raise Exception.Create('CreateDIBitmap failed');

   FreeMem(BmpInfo, HeaderSize);
   Canvas.StretchDraw(Rect, Bmp);
   Bmp.Free;
end;

function  MakeSelectedImage ( AnsImage:TAns2Image; Col:word):TAns2Image;
const
   SelImage : TAns2Image = nil;
var
   j, i : Integer;
   bpri, bcur, bnext : PTAns2Color;
   sbpri, sbcur, sbnext : PTAns2Color;
begin

   if SelImage <> nil then begin
      SelImage.Free;
      SelImage := nil;
   end;

   if SelImage = nil then begin
      SelImage := TAns2Image.Create(AnsImage.Width, AnsImage.Height, AnsImage.px, AnsImage.py);
   end;

   SelImage.Clear(0);
   SelImage.DrawImage(AnsImage, 0, 0, FALSE);

   bnext := SelImage.Bits;

   bpri := bnext;
   inc (bnext, 1);
   bcur := bnext;
   inc ( bnext, 1);

   sbpri := bpri;
   sbcur := bcur;
   sbnext := bnext;

   for j := 0 to AnsImage.Height-1 do begin
      bpri := sbpri;
      bcur := sbcur;
      bnext := sbnext;
      for i := 0 to AnsImage.Width-1 do begin
         if (bcur^ = 0) and (bcur^ <> Col) then begin
            if (bnext^ <> 0) and (bnext^ <> Col) then bcur^ := Col;
            if (bpri^ <> 0) and (bpri^ <> Col) then bcur^ := Col;
         end;
         inc (bpri, 1);
         inc (bcur, 1);
         inc (bnext, 1);
      end;
      inc (sbpri, SelImage.Width);
      inc (sbcur, SelImage.Width);
      inc (sbnext, SelImage.Width);
   end;

   Result := SelImage;
end;

var
   BitStream : TFileStream;
   Tempi : integer;

Initialization
begin
   if FileExists ('bitmask.dat') then begin
      BitStream := TFileStream.Create ('bitmask.dat', fmOpenRead);
      BitStream.ReadBuffer (BitFlag, sizeof(BitFlag));
      BitStream.Free;
   end;
   // 마왕2에서는 BitFlag가 FASLE;
   BitFlag := TRUE;

   ColorImage := TAns2Image.Create ( 4, 4, 0, 0);
   for tempi := 0 to 65535 do darkentbl[tempi] := ColorImage.ARGBDEC (tempi, 4);
end;

Finalization
begin
   ColorImage.Free;
end;

end.
