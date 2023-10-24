unit A2Img;

interface

uses
  Windows, SysUtils, Classes, Graphics, BmpUtil, Autil32, Math, uXDibA;

const
  ImageLibID = 'ATZ0';
  ImageLibID1 = 'ATZ1';
  ImageLibID2 = 'ATZ2';

  Alpha_TransParent = 1;
  Alpha_Screen_ColorDodge = 2;
  Alpha_Screen = 3;
  Alpha_Screen_Lighten = 4;

  {A$}
type
  TAns2Color = word;
  PTAns2Color = ^TAns2Color;
  TColorTable5x5 = array[0..31, 0..31] of word;
  PTColorTable5x5 = ^TColorTable5x5;

  TA2ImageFileHeader = record
    Width: Integer;
    Height: Integer;
    px, py: Integer;
    none: Integer;
  end;

  TA2ImageLibHeader = record
    IDent: array[0..3] of Char;
    ImageCount: Integer;
    TransparentColor: Integer;
    Palette: TImgLibPalette;
  end;

  TInSpaceData = record
    spb, dpb: Pbyte;
    R: TRect;
  end;

  TA2Image = class
  private
    FClientRect: TRect;
  protected
    function GetInSpace(AImage: TA2Image; x, y: integer; var InSpaceData:
      TInSpaceData): Boolean;
    procedure DrawFont(AImage: TA2Image; x, y, aColor: Integer);
    procedure DrawFontKeyColor(AnsImage: TA2Image; x, y, aColor: integer;
      ptable: pword);

  public
    Name: string;
    px, py: integer;
    Width, Height: Integer;
    Bits: PTAns2Color;
    TransparentColor: Integer;
    constructor Create(AWidth, AHeight, Apx, Apy: Integer);
    destructor Destroy; override;
    procedure GetImage(AnsImage: TA2Image; x, y: Integer);
    procedure DrawImage(AnsImage: TA2Image; x, y: Integer; aTrans: Boolean);
    procedure DrawImageDestKey(AnsImage: TA2Image; x, y: Integer);
    procedure DrawImageDither(AnsImage: TA2Image; x, y, adither: integer;
      aTrans: Boolean);
    procedure DrawImageGreenConvert(AnsImage: TA2Image; x, y: Integer; acol,
      defaultadd: word);
    //      procedure DrawImageGreenConvert2(AnsImage: TA2Image; x, y: Integer; acol: byte);
    procedure DrawImageKeyColor(AnsImage: TA2Image; x, y: Integer; col: word;
      ptable: pword);
    procedure DrawImageOveray(AnsImage: TA2Image; x, y: Integer; Weight:
      integer);
    procedure DrawImageEffect(AnsImage: TA2Image; x, y: Integer; etable:
      TColorTable5x5);
    procedure DrawEffect(xDib: TXDib; x, y: Integer; etable: TColorTable5x5);
    procedure DrawDib(xDib: TXDib; x, y: Integer; aShadow: Boolean);
    procedure MakeImageScale(AnsImage: TA2Image); // minds 011217

    procedure DrawRefractive(AnsImage: TA2Image; x, y, Refracrange, overValue:
      Integer); // ankudo 010118

    procedure DrawImageAdd(AnsImage: TA2Image; x, y: Integer);
    procedure Clear(Color: word);
    procedure EraseRect(R: TRect; Color: word);
    procedure hLine(x, y, w: Integer; Col: word);
    procedure vLine(x, y, h: Integer; Col: word);
    procedure Resize(aWidth, aheight: Integer);
    procedure SaveToFile(FileName: string);

    procedure LoadFromFile(FileName: string);
    procedure LoadFromFileTrueColor(FileName: string);
    procedure Optimize;
    procedure OptimizeWidth;
  published
  end;

  TA2ImageLib = class
  private
    FTag: integer;
    ImageList: TList;
    function GeTA2Image(Idx: Integer): TA2Image;
    function GetCount: Integer;
  protected
  public
    TransparentColor: word;
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure AddImage(AImage: TA2Image);
    procedure InsertImage(Idx: Integer; AImage: TA2Image);
    procedure DeleteImage(Idx: Integer);
    procedure LoadFromFile(FileName: string);
    procedure SaveToFile(FileName: string);
    procedure SaveToFileHeader(const FileName: string);
    //      procedure SaveToFile8(const FileName: String);
    function GetByName(aName: string): TA2Image;
    property Images[Index: Integer]: TA2Image read GeTA2Image; default;
    property Count: Integer read GetCount;
    property Tag: integer read FTag write FTag;
  published
  end;

  TA2FontClass = class
  private
    FontA2ImageList: array[0..65536 - 1] of integer;
    FBitMap: TBitmap;
    function BmpToA2Image(aBmp: TBitMap; aImage: TA2Image): integer;
    function GetFontImage(n: Integer): TA2Image;
    function GetFontImageEx(AChar: Integer; AFontName: string; AFontSize:
      Integer; AFontStyle: TFontStyles): TA2Image;
  public
    constructor Create;
    destructor Destroy; override;
    procedure SetFont(afont: string);
  end;

procedure ATextOut(A2Image: TA2Image; x, y, FontColorIndex: integer; atext:
  string);
procedure ATextOutEx(AA2Image: TA2Image; AX, AY, AFontColorIndex: Integer;
  AText: string; AFontName: string; AFontSize: Integer; AFontStyle: TFontStyles;
  AStyle: Integer; ASpace: Integer; aParam: Integer);
function ATextWidth(atext: string): integer;
function ATextHeight(atext: string): integer;
procedure GetMaxTextWH(var W, H: integer; aStringList: TStringList);

procedure A2DrawImage(Canvas: TCanvas; X, Y: Integer; ansImage: TA2Image);
procedure AnsPaletteDataToAns2Image(Ans2Image: TA2Image; Palette:
  TImgLibPalette; pb: Pbyte);
procedure AnsTrueDataToAns2Image(Ans2Image: TA2Image; pb: pbyte);

procedure A2SetFontName(aFontName: string);
procedure A2TextOut(aImage: TA2Image; FontSize, x, y: integer; astr: string);
function A2TextWidth(astr: string): integer;
function A2TextHeight(astr: string): integer;
procedure A2SetFontColor(aColor: integer);

function A2GetCanvas: TCanvas;
procedure A2DrawCanvas(aImage: TA2Image; x, y, sw, sh: integer; aTrans:
  Boolean);

function WinRGB(r, g, b: word): word;
procedure WinVRGB(n: word; var r, g, b: word);

function CutLengthString(var SourceStr: string; aWidth: integer): string;
function GetStringLength(AText: string): Integer;

var
  Error: integer;
  darkentbl: array[0..65535] of word;
  Bubbletbl: array[0..65535] of word;
  DECRGBdarkentbl: array[0..65535] of word;

  bShadowDraw: Boolean = True;

  EffectScreen: TColorTable5x5;
  EffectColorDodge: TColorTable5x5;
  EffectLighten: TColorTable5x5;
  EffectScreenDark: TColorTable5x5;

  A2FontClass: TA2FontClass;

  BitMapFontName: string = 'Arial';

  CellCheckImg: TA2Image;

function GetPBitmapInfo(aWidth, aHeight, aBitCount: integer): PBitMapInfo;

implementation

{$O+}

function CutLengthString(var SourceStr: string; aWidth: integer): string;
var
  i, n: integer;
  str: Widestring;
begin
  Result := '';
  if (SourceStr = '') or (aWidth < 1) then
    exit;
  n := 0;
  str := SourceStr;
  for i := 1 to Length(Str) do
  begin
    n := n + ATextWidth(Str[i]) + 1;
    if n > aWidth then
    begin
      SourceStr := Copy(str, i, Length(str));
      exit;
    end;
    Result := Result + Str[i];
  end;
  Result := SourceStr;
  SourceStr := '';
end;

function GetCurrentChar(atext: string; var curPos, rValue: integer): Boolean;
var
  buf: array[0..2] of char;
begin
  Result := FALSE;
  if Length(atext) < curpos then
    exit;

  if byte(atext[curpos]) < 128 then
  begin
    buf[0] := atext[curpos];
    buf[1] := char(0);
    inc(curPos);
    rValue := PWORD(@Buf)^;
  end
  else
  begin
    buf[0] := atext[curpos];
    inc(curpos);
    buf[1] := atext[curpos];
    inc(curpos);
    rValue := PWORD(@Buf)^;
  end;
  Result := TRUE;
end;

function GetStringLength(AText: string): Integer;
var
  Len, curpos, rValue: Integer;
begin
  Len := 0;
  curpos := 1;
  rValue := 0;
  while True do
  begin
    if not GetCurrentChar(AText, curpos, rValue) then
      Break;
    Inc(Len);
  end;
  Result := Len;
end;

procedure ATextOut(A2Image: TA2Image; x, y, FontColorIndex: Integer; atext:
  string);
var
  FontImage: TA2Image;
  curpos, rValue: Integer;
begin
  if atext = '' then
    exit;
  curpos := 1;
  rValue := 0;
  while TRUE do
  begin
    if not GetCurrentChar(atext, curpos, rValue) then
      Break;
    FontImage := A2FontClass.GetFontImage(rValue);
    if FontImage <> nil then
    begin
      A2Image.DrawFont(FontImage, x, y, FontColorIndex);
      x := x + FontImage.Width + 1;
    end;
  end;
end;

//Author:Steven Date: 2005-01-05 17:54:50
//Note:AStyle是横向和纵向参数, ASpace是间隔参数, aParam是字体个数参数
procedure ATextOutEx(AA2Image: TA2Image; AX, AY, AFontColorIndex: Integer;
  AText: string; AFontName: string; AFontSize: Integer; AFontStyle: TFontStyles;
  AStyle: Integer; ASpace: Integer; aParam: Integer);
var
  FontImage: TA2Image;
  curpos, rValue: Integer;
  Len: Integer;
begin
  if AText = '' then
    Exit;
  Len := GetStringLength(AText);
  curpos := 1;
  rValue := 0;
  while TRUE do
  begin
    if not GetCurrentChar(atext, curpos, rValue) then
      Break;
    FontImage := A2FontClass.GetFontImageEx(rValue, AFontName, AFontSize,
      AFontStyle);
    if FontImage <> nil then
    begin
      //将文字按参数平均分配，10为调整参数
      if AStyle = 0 then
        AX := AX + (aParam * FontImage.Width + (aParam - 1) * ASpace + 10) div Len
          div 2 - FontImage.Width div 2
      else
        AY := AY + (aParam * FontImage.Height + (aParam - 1) * ASpace + 10) div Len
          div 2 - FontImage.Height div 2;
      AA2Image.DrawFont(FontImage, AX, AY, AFontColorIndex);
      if AStyle = 0 then
        AX := AX + FontImage.Width + ASpace
      else
        AY := AY + FontImage.Height + ASpace;
    end;
    FontImage.Free;
  end;
end;

function ATextWidth(atext: string): integer;
var
  FontImage: TA2Image;
  w, curpos, rValue: integer;
begin
  Result := 0;
  if atext = '' then
    exit;
  curpos := 1;
  rValue := 0;
  w := 0;
  while TRUE do
  begin
    if w <> 0 then
      w := w + 1;
    if not GetCurrentChar(atext, curpos, rValue) then
      break;
    FontImage := A2FontClass.GetFontImage(rValue);
    if FontImage <> nil then
      w := w + FontImage.Width;
  end;
  Result := w;
end;

function ATextHeight(atext: string): integer;
var
  FontImage: TA2Image;
  h, curpos, rValue: integer;
begin
  Result := 0;
  if atext = '' then
    exit;

  curpos := 1;
  rValue := 0;
  h := 0;
  while TRUE do
  begin
    if not GetCurrentChar(atext, curpos, rValue) then
      break;
    FontImage := A2FontClass.GetFontImage(rValue);
    if FontImage <> nil then
      if h < FontImage.Height then
        h := FontImage.Height;
  end;
  Result := h;
end;

procedure GetMaxTextWH(var W, H: integer; aStringList: TStringList);
var
  xx, yy, i: integer;
begin
  W := 0;
  H := 0;
  for i := 0 to aStringList.Count - 1 do
  begin
    xx := ATextWidth(aStringList[i]);
    yy := ATextHeight(aStringList[i]);
    if W < xx then
      W := xx;
    if H < yy then
      H := yy;
  end;
end;

////////////////////////////////////////////////////////////////////////////////
//                      TA2FontClass
////////////////////////////////////////////////////////////////////////////////

constructor TA2FontClass.Create;
var
  DC: HDC;
  Focus: hWnd;
  p: PBitMapinfo;
begin
  FBitMap := TBitMap.Create;
  p := GetPBitmapInfo(64, 64, 16);
  Focus := GetFocus;
  dc := GetDC(Focus);
  FBitMap.Handle := CreateDIBitmap(GetDC(GetFocus), p^.bmiHeader, 0, Pointer(0),
    p^, 0);
  ReleaseDC(Focus, DC);
  if FBitMap.Handle = 0 then
    raise Exception.Create('CreateDIBitmap failed');
  FBitMap.Canvas.Font.Name := 'Arial';
  //   FBitMap.Canvas.Font.Name := '奔覆';
  FBitMap.Canvas.Font.Size := 9;
  FBitMap.Canvas.Font.Color := clWhite;
  FBitMap.Canvas.Brush.Color := clBlack;
  FillChar(FontA2ImageList, sizeof(FontA2ImageList), 0);
end;

destructor TA2FontClass.Destroy;
var
  i: integer;
begin
  for i := 0 to 65536 - 1 do
    if FontA2ImageList[i] <> 0 then
      TA2Image(FontA2ImageList[i]).Free;
  FBitMap.Free;
  inherited destroy;
end;

function TA2FontClass.BmpToA2Image(aBmp: TBitMap; aImage: TA2Image): integer;
var
  p: PBitMapinfo;
begin
  p := GetPBitmapInfo(aImage.Width, aImage.Height, 16);
  Result := GetDIBits(aBmp.Canvas.Handle, aBmp.Handle, 0, aImage.Height,
    aImage.Bits, p^, DIB_PAL_COLORS);
end;

function TA2FontClass.GetFontImage(n: integer): TA2Image;
var
  str: string;
  w, h: integer;
  buf: array[0..3] of char;
  TempImage, TempImage2: TA2Image;
begin
  Result := nil;
  if n = 0 then
    exit;
  if FontA2ImageList[n] = 0 then
  begin
    move(n, buf, 2);
    buf[2] := char(0);
    str := StrPas(@buf);
    if str = '' then
    begin
      FontA2ImageList[n] := 0;
      exit;
    end;
    //Author:Steven Date: 2004-12-20 17:34:56
    //Note:
    with FBitMap.Canvas do
    begin
      Font.Name := '宋体';
      Font.Size := 9;
      Font.Style := [];
    end;

    //=======================================
    FBitMap.Canvas.FillRect(Rect(0, 0, 64, 64));
    FBitMap.Canvas.TextOut(0, 0, str);
    TempImage := TA2Image.Create(64, 64, 0, 0);
    if BmpToA2Image(FBitMap, TempImage) <= 0 then
    begin
      FontA2ImageList[n] := 0;
      exit;
    end;
    w := FBitMap.Canvas.TextWidth(str);
    h := FBitMap.Canvas.TextHeight(str);
    if (w <= 0) or (h <= 0) then
    begin
      FontA2ImageList[n] := 0;
      exit;
    end;
    TempImage2 := TA2Image.Create(w, h, 0, 0);
    TempImage2.DrawImage(TempImage, 0, 0, FALSE);
    TempImage.Free;

    TempImage2.OptimizeWidth;
    FontA2ImageList[n] := Integer(TempImage2);
  end;
  Result := TA2Image(FontA2ImageList[n]);
end;

//Author:Steven Date: 2005-01-05 20:34:45
//Note:

function TA2FontClass.GetFontImageEx(AChar: Integer; AFontName: string;
  AFontSize:
  Integer; AFontStyle: TFontStyles): TA2Image;
var
  Str: string;
  W, H: Integer;
  Buf: array[0..3] of char;
  TempImage, TempImage2: TA2Image;
begin
  //..
  Result := nil;
  Move(AChar, Buf, 2);
  Buf[2] := Char(0);
  Str := StrPas(@Buf);
  if Str = '' then
    Exit;

  with FBitMap.Canvas do
  begin
    Font.Name := AFontName;
    Font.Size := AFontSize;
    Font.Style := AFontStyle;

    FillRect(Rect(0, 0, 64, 64));
    TextOut(0, 0, Str);
  end;
  TempImage := TA2Image.Create(64, 64, 0, 0);
  if BmpToA2Image(FBitMap, TempImage) <= 0 then
    Exit;
  W := FBitMap.Canvas.TextWidth(Str);
  H := FBitMap.Canvas.TextHeight(Str);
  if (w <= 0) or (h <= 0) then
    Exit;
  TempImage2 := TA2Image.Create(W, H, 0, 0);
  TempImage2.DrawImage(TempImage, 0, 0, FALSE);
  TempImage.Free;
  TempImage2.OptimizeWidth;
  Result := TempImage2;
end;

procedure TA2FontClass.SetFont(afont: string);
begin
  FBitMap.Canvas.Font.Name := afont;
end;

function WinRGB(r, g, b: word): word;
begin
  Result := b + (g shl 5) + (r shl 10);
end;

procedure WinVRGB(n: word; var r, g, b: word);
begin
  b := n and $1F;
  g := (n shr 5) and $1F;
  r := (n shr 10) and $1F;
end;

// 100%鳖瘤父'

function WinDECRGB(n: word; d: byte): word;
var
  r, g, b: word;
begin
  WinVRGB(n, r, g, b);
  if b > d then
    b := b - d
  else
    b := 0;
  if g > d then
    g := g - d
  else
    g := 0;
  if r > d then
    r := r - d
  else
    r := 0;
  Result := WinRGB(r, g, b);
end;

function WinOpercity(n: word; OperN: byte): word;
var
  r, g, b: word;
begin
  WinVRGB(n, r, g, b);
  b := (b * OperN div 100);
  g := (g * OperN div 100);
  r := (r * OperN div 100);
  Result := WinRGB(r, g, b);
end;

const
  Contrast = 5;

function WinOpercityForCl1000(n: word; OperN: byte): word;
var
  r, g, b: word;
  i: integer;
begin
  WinVRGB(n, r, g, b);
  i := (r + g + b) div 3;
  i := i + i div 10;
  if r > i then
  begin
    r := r * (100 + Contrast) div 100;
    if r > 31 then
      r := 31;
  end
  else
  begin
    r := r * (100 - Contrast) div 100;
  end;
  if g > i then
  begin
    g := g * (100 + Contrast) div 100;
    if g > 31 then
      g := 31;
  end
  else
  begin
    g := g * (100 - Contrast) div 100;
  end;
  if b > i then
  begin
    b := b * (100 + Contrast) div 100;
    if b > 31 then
      b := 31;
  end
  else
  begin
    b := b * (100 - Contrast) div 100;
  end;

  b := (b * OperN div 100);
  g := (g * OperN div 100);
  r := (r * OperN div 100);
  Result := WinRGB(r, g, b);
end;

//////////////////////////////////////
//         TA2Image            //
//////////////////////////////////////

constructor TA2Image.Create(AWidth, AHeight, Apx, Apy: Integer);
begin
  TransparentColor := 0;
  Width := WidthBytes(AWidth);
  Height := AHeight;
  px := Apx;
  py := Apy;
  Bits := nil;
  GetMem(Bits, Width * Height * Sizeof(TAns2Color));
  if Bits = nil then
    raise Exception.Create('TA2Image: GemMem Failed for Bits');
  FillChar(Bits^, Width * Height * Sizeof(TAns2Color), 0);
  FClientRect := Rect(0, 0, Width - 1, Height - 1);
end;

destructor TA2Image.Destroy;
begin
  if Bits <> nil then
    FreeMem(Bits, Width * Height * sizeof(TAns2Color));
  inherited Destroy;
end;

procedure TA2Image.Clear(Color: word);
var
  i: integer;
  pcol: PTAns2Color;
begin
  pcol := Bits;
  for i := 0 to Width * Height - 1 do
  begin
    pcol^ := Color;
    inc(pcol);
  end;
end;

procedure TA2Image.EraseRect(R: TRect; Color: word);
var
  dpb, TempDD: PTAns2Color;
  i, j: integer;
  ir, sr, dr: TRect;
begin
  //do clipping

  sr := Rect(R.Left, R.Top, R.Right - 1, R.Bottom - 1);
  dr := Rect(0, 0, Width - 1, Height - 1);

  if not IntersectRect(ir, sr, dr) then
    exit;

  dpb := Bits;
  inc(dpb, (ir.left + ir.top * Width));

  for i := ir.Top to ir.Bottom do
  begin
    TempDD := dpb;
    for j := ir.left to ir.right do
    begin
      TempDD^ := Color;
      Inc(TempDD);
    end;
    inc(dpb, Width);
  end;
end;

procedure TA2Image.hLine(x, y, w: Integer; Col: word);
var
  i: integer;
  pb: PTAns2Color;
begin
  if x < 0 then
    exit;
  if x + w >= Width then
    exit;
  if y < 0 then
    exit;
  if y >= Height then
    exit;
  pb := Bits;
  inc(pb, x + y * Width);
  for i := 0 to w - 1 do
  begin
    pb^ := Col;
    inc(pb);
  end;
end;

procedure TA2Image.vLine(x, y, h: Integer; Col: word);
var
  i: integer;
  pb: PTAns2Color;
begin
  if x < 0 then
    exit;
  if x >= Width then
    exit;
  if y < 0 then
    exit;
  if y + h >= Height then
    exit;
  pb := Bits;
  inc(pb, x + y * Width);
  for i := 0 to h - 1 do
  begin
    pb^ := Col;
    inc(pb, width);
  end;
end;

function TA2Image.GetInSpace(AImage: TA2Image; x, y: integer; var InSpaceData:
  TInSpaceData): Boolean;
var
  sr: TRect;
begin
  Result := FALSE;
  if AImage = nil then
    exit;
  sr := Rect(x, y, x + AImage.Width - 1, y + AImage.Height - 1);
  if not IntersectRect(InSpaceData.R, sr, FClientRect) then
    exit;

  InSpaceData.spb := pbyte(AImage.Bits);
  inc(InSpaceData.spb, ((InSpaceData.R.left - x) + (InSpaceData.R.top - y) *
    AImage.Width));

  InSpaceData.dpb := pbyte(Bits);
  inc(InSpaceData.dpb, (InSpaceData.R.left + InSpaceData.R.top * Width));
  Result := TRUE;
end;

procedure TA2Image.GetImage(AnsImage: TA2Image; x, y: Integer);
var
  spb, dpb: PTAns2Color;
  i: integer;
  ir, sr, dr: TRect;
begin
  //do clipping
  dr := Rect(x, y, x + AnsImage.Width - 1, y + AnsImage.Height - 1);
  sr := Rect(0, 0, Width - 1, Height - 1);

  if not IntersectRect(ir, sr, dr) then
    exit;

  spb := Bits;
  inc(spb, ir.left + ir.top * Width);

  dpb := AnsImage.Bits;
  inc(dpb, (ir.left - x) + (ir.top - y) * AnsImage.Width);

  for i := 0 to ir.Bottom - ir.Top do
  begin
    move(spb^, dpb^, (ir.right - ir.left + 1) * 2);
    inc(spb, Width);
    inc(dpb, AnsImage.Width);
  end;
end;

procedure TA2Image.DrawFont(AImage: TA2Image; x, y, aColor: Integer);
var
  spb, dpb, TempSS, TempDD: PTAns2Color;
  i, j: integer;
  ir, sr, dr: TRect;
  //   r,g,b : Word;
begin
  if AImage = nil then
    exit;

  sr := Rect(x, y, x + AImage.Width - 1, y + AImage.Height - 1);
  dr := Rect(0, 0, Width - 1, Height - 1);

  if not IntersectRect(ir, sr, dr) then
    exit;

  spb := AImage.Bits;
  inc(spb, ((ir.left - x) + (ir.top - y) * AImage.Width));

  dpb := Bits;
  inc(dpb, (ir.left + ir.top * Width));

  for i := ir.Top to ir.Bottom do
  begin
    TempSS := spb;
    TempDD := dpb;
    for j := ir.left to ir.right do
    begin
      if TempSS^ <> 0 then
        TempDD^ := aColor;
      inc(TempSS);
      Inc(TempDD);
    end;
    inc(spb, AImage.Width);
    inc(dpb, Width);
  end;
end;

procedure TA2Image.DrawFontKeyColor(AnsImage: TA2Image; x, y, aColor: Integer;
  ptable: pword);
var
  spb, dpb, TempSS, TempDD: PTAns2Color;
  i, j: integer;
  ir, sr, dr: TRect;
  ptemp: pword;
  //   tempi, starti, endi : integer;
begin
  if AnsImage = nil then
    exit;

  //do clipping
  sr := Rect(x, y, x + AnsImage.Width - 1, y + AnsImage.Height - 1);
  dr := Rect(0, 0, Width - 1, Height - 1);

  if not IntersectRect(ir, sr, dr) then
    exit;

  spb := AnsImage.Bits;
  inc(spb, ((ir.left - x) + (ir.top - y) * AnsImage.Width));

  dpb := Bits;
  inc(dpb, (ir.left + ir.top * Width));

  for i := ir.Top to ir.Bottom do
  begin
    TempSS := spb;
    TempDD := dpb;
    for j := ir.left to ir.right do
    begin
      if TempSS^ <> 0 then
      begin
        TempDD^ := aColor;
      end
      else
      begin
        ptemp := ptable;
        inc(ptemp, TempDD^);
        TempDD^ := ptemp^;
      end;
      inc(TempSS);
      Inc(TempDD);
    end;
    inc(spb, AnsImage.Width);
    inc(dpb, Width);
  end;
end;

procedure TA2Image.DrawImageGreenConvert(AnsImage: TA2Image; x, y: Integer;
  acol, defaultadd: word);
var
  spb, dpb, TempSS, TempDD: PTAns2Color;
  i, j: integer;
  n, r, g, b, ar, ag, ab: word;
  ir, sr, dr: TRect;
begin
  if AnsImage = nil then
    exit;

  WinVRGB(acol, ar, ag, ab);

  //do clipping

  sr := Rect(x, y, x + AnsImage.Width - 1, y + AnsImage.Height - 1);
  dr := Rect(0, 0, Width - 1, Height - 1);

  if not IntersectRect(ir, sr, dr) then
    exit;

  spb := AnsImage.Bits;
  inc(spb, ((ir.left - x) + (ir.top - y) * AnsImage.Width));

  dpb := Bits;
  inc(dpb, (ir.left + ir.top * Width));

  for i := ir.Top to ir.Bottom do
  begin
    TempSS := spb;
    TempDD := dpb;
    for j := ir.left to ir.right do
    begin
      if TempSS^ <> AnsImage.TransparentColor then
      begin
        WinVRGB(TempSS^, r, g, b);
        if (r = 0) and (b = 0) then
        begin
{$IFNDEF _COLOR}
          n := g + 1;
          r := n * ar div 32 + defaultadd;
          g := n * ag div 32 + defaultadd;
          b := n * ab div 32 + defaultadd;
          if r > 31 then
            r := 31;
          if g > 31 then
            g := 31;
          if b > 31 then
            b := 31;
          TempDD^ := WinRGB(r, g, b);
          if TempDD^ = 0 then
            TempDD^ := 1;
{$ELSE}
          n := g + 1 + defaultadd;
          r := min(31, n * ar div 32);
          g := min(31, n * ag div 32);
          b := min(31, n * ab div 32);
          TempDD^ := WinRGB(r, g, b);
{$ENDIF}

        end
        else
          TempDD^ := TempSS^;
      end;
      inc(TempSS);
      Inc(TempDD);
    end;
    inc(spb, AnsImage.Width);
    inc(dpb, Width);
  end;
end;
{
const
   ColorTableX: array[0..7] of byte = (0, 7, 13, 19, 25, 31, 31, 31);

procedure TA2Image.DrawImageGreenConvert2 (AnsImage: TA2Image; x, y: Integer; acol: byte);
var
 spb, dpb, TempSS, TempDD : PTAns2Color;
   i, j : integer;
   n, r, g, b, ar, ag, ab, fr, fg, fb: word;
   ir, sr, dr: TRect;
begin
   if AnsImage = nil then exit;

   fr := acol div 36;
   fg := acol mod 36 div 6;
   fb := acol mod 6;

   ar := ColorTableX[fr];
   ag := ColorTableX[fg];
   ab := ColorTableX[fb];
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

               n := g+1;
               r := n * ar div 32;
               g := n * ag div 32;
               b := n * ab div 32;

//               n := g+1;
//               r := n * ar div 32 + fr;// + defaultadd;
//               g := n * ag div 32 + fg;// + defaultadd;
//               b := n * ab div 32 + fb;// + defaultadd;
//               if r > 31 then r := 31;
//               if g > 31 then g := 31;
//               if b > 31 then b := 31;

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
}

procedure TA2Image.DrawImage(AnsImage: TA2Image; x, y: Integer; aTrans:
  Boolean);
var
  spb, dpb, TempSS, TempDD: PTAns2Color;
  i, j: integer;
  ir, sr, dr: TRect;
begin
  if AnsImage = nil then
    exit;

  sr := Rect(x, y, x + AnsImage.Width - 1, y + AnsImage.Height - 1);
  dr := Rect(0, 0, Width - 1, Height - 1);

  if not IntersectRect(ir, sr, dr) then
    exit;

  spb := AnsImage.Bits;
  inc(spb, ((ir.left - x) + (ir.top - y) * AnsImage.Width));

  dpb := Bits;
  inc(dpb, (ir.left + ir.top * Width));

  if aTrans = FALSE then
  begin
    try
      for i := ir.Top to ir.Bottom do
      begin
        move(spb^, dpb^, (ir.right - ir.left + 1) * sizeof(TAns2Color));
        inc(spb, AnsImage.Width);
        inc(dpb, Width);
      end;
    except
      exit;
    end;
  end
  else
  begin
    try
      for i := ir.Top to ir.Bottom do
      begin
        TempSS := spb;
        TempDD := dpb;
        for j := ir.left to ir.right do
        begin
          if TempSS^ <> 0 {AnsImage.TransparentColor} then
          begin
            TempDD^ := TempSS^;
          end;
          inc(TempSS);
          Inc(TempDD);
        end;
        inc(spb, AnsImage.Width);
        inc(dpb, Width);
      end;
    except
      exit;
    end;
  end;
end;

procedure TA2Image.DrawImageDestKey(AnsImage: TA2Image; x, y: Integer);
var
  spb, dpb, TempSS, TempDD: PTAns2Color;
  i, j: integer;
  ir, sr, dr: TRect;
begin
  if AnsImage = nil then
    exit;

  sr := Rect(x, y, x + AnsImage.Width - 1, y + AnsImage.Height - 1);
  dr := Rect(0, 0, Width - 1, Height - 1);

  if not IntersectRect(ir, sr, dr) then
    exit;

  spb := AnsImage.Bits;
  inc(spb, ((ir.left - x) + (ir.top - y) * AnsImage.Width));

  dpb := Bits;
  inc(dpb, (ir.left + ir.top * Width));

  try
    for i := ir.Top to ir.Bottom do
    begin
      TempSS := spb;
      TempDD := dpb;
      for j := ir.left to ir.right do
      begin
        if (TempSS^ <> 0) and (TempDD^ = 0) then
          TempDD^ := TempSS^;
        inc(TempSS);
        Inc(TempDD);
      end;
      inc(spb, AnsImage.Width);
      inc(dpb, Width);
    end;
  except
    exit;
  end;
end;

procedure TA2Image.DrawImageDither(AnsImage: TA2Image; x, y, adither: integer;
  aTrans: Boolean);
var
  spb, dpb, TempSS, TempDD: PTAns2Color;
  i, j, n: integer;
  ir, sr, dr: TRect;
begin
  if AnsImage = nil then
    exit;
  case adither of
    0:
      begin
        DrawImage(AnsImage, x, y, aTrans);
        exit;
      end;
    1: adither := 2;
    2: adither := 4;
    3: adither := 8;
  else
    exit;
  end;

  //do clipping

  sr := Rect(x, y, x + AnsImage.Width - 1, y + AnsImage.Height - 1);
  dr := Rect(0, 0, Width - 1, Height - 1);

  if not IntersectRect(ir, sr, dr) then
    exit;

  spb := AnsImage.Bits;
  inc(spb, ((ir.left - x) + (ir.top - y) * AnsImage.Width));

  dpb := Bits;
  inc(dpb, (ir.left + ir.top * Width));

  if adither = 4 then
  begin
    inc(spb);
    inc(dpb);
  end;

  for i := ir.Top to ir.Bottom do
  begin
    TempSS := spb;
    TempDD := dpb;

    if (i mod adither) = 0 then
    begin

      if (i mod (adither * 2)) = 0 then
      begin
        inc(TempSS, adither div 2);
        inc(TempDD, adither div 2);
      end;

      n := (ir.right - ir.left) div adither;
      for j := 0 to n - 1 do
      begin
        TempDD^ := TempSS^;
        inc(TempSS, adither);
        Inc(TempDD, adither);
      end;
    end;
    inc(spb, AnsImage.Width);
    inc(dpb, Width);
  end;
end;

procedure TA2Image.Resize(aWidth, aheight: Integer);
var
  OldBits, spb, dpb: PTAns2Color;
  i, j, x, y, Oldwidth, Oldheight: integer;
begin
  OldWidth := Width;
  OldHeight := Height;
  OldBits := Bits;

  Width := aWidth;
  Height := aHeight;
  GetMem(Bits, Width * Height * Sizeof(TAns2Color));
  FillChar(Bits^, Width * Height * Sizeof(TAns2Color), 0);

  for j := 0 to Height - 1 do
  begin
    for i := 0 to Width - 1 do
    begin
      x := i * OldWidth div Width;
      y := j * OldHeight div Height;
      spb := OldBits;
      inc(spb, x + y * OldWidth);
      dpb := Bits;
      inc(dpb, i + j * Width);
      dpb^ := spb^;
    end;
  end;
  px := px * Width div OldWidth;
  py := py * Height div OldHeight;
  FreeMem(OldBits);
end;

procedure TA2Image.DrawImageKeyColor(AnsImage: TA2Image; x, y: Integer; col:
  word; ptable: pword);
var
  spb, dpb, TempSS, TempDD: PTAns2Color;
  i, j: integer;
  ir, sr, dr: TRect;
  ptemp: pword;
  //   tempi, starti, endi : integer;
begin
  if AnsImage = nil then
    exit;

  //do clipping
  sr := Rect(x, y, x + AnsImage.Width - 1, y + AnsImage.Height - 1);
  dr := Rect(0, 0, Width - 1, Height - 1);

  if not IntersectRect(ir, sr, dr) then
    exit;

  spb := AnsImage.Bits;
  inc(spb, ((ir.left - x) + (ir.top - y) * AnsImage.Width));

  dpb := Bits;
  inc(dpb, (ir.left + ir.top * Width));

  if bShadowDraw then
  begin
    for i := ir.Top to ir.Bottom do
    begin
      TempSS := spb;
      TempDD := dpb;
      for j := ir.left to ir.right do
      begin
        if TempSS^ <> AnsImage.TransparentColor then
        begin
          if TempSS^ = col then
          begin
            ptemp := ptable;
            inc(ptemp, TempDD^);
            TempDD^ := ptemp^;
            //               TempDD^ := Darkentbl[Tempdd^];
          end
          else
          begin
            TempDD^ := TempSS^;
          end;
        end;
        inc(TempSS);
        Inc(TempDD);
      end;
      inc(spb, AnsImage.Width);
      inc(dpb, Width);
    end;
  end
  else
  begin
    for i := ir.Top to ir.Bottom do
    begin
      TempSS := spb;
      TempDD := dpb;
      for j := ir.left to ir.right do
      begin
        if (TempSS^ <> 0) and (TempSS^ <> 31) then
        begin
          TempDD^ := TempSS^;
        end;
        inc(TempSS);
        Inc(TempDD);
      end;
      inc(spb, AnsImage.Width);
      inc(dpb, Width);
    end;
  end;
end;

// add by minds 20011210

procedure TA2Image.MakeImageScale(AnsImage: TA2Image);
var
  spb, dpb, TempSS, TempDD: PTAns2Color;
  i, j, ii, jj, scale: integer;
  XScale, YScale: array of byte;
begin
  if AnsImage = nil then
    exit;

  SetLength(XScale, AnsImage.Width);
  SetLength(YScale, AnsImage.Height);

  spb := AnsImage.Bits;
  dpb := Bits;

  scale := Width * 256 div AnsImage.Width;
  //   px := (AnsImage.px+32) * scale div 256 - 32;
  for i := 0 to AnsImage.Width - 1 do
    XScale[i] := scale * (i + 1) div 256 - scale * i div 256;

  scale := Height * 256 div AnsImage.Height;
  py := (AnsImage.Height + AnsImage.py) - Height;
  for i := 0 to AnsImage.Height - 1 do
    YScale[i] := scale * (i + 1) div 256 - scale * i div 256;
  //(((i+1)*scale + 50) div 100) - ((i * scale + 50) div 100);

  for i := 0 to AnsImage.Height - 1 do
  begin
    for ii := 1 to YScale[i] do
    begin
      TempSS := spb;
      TempDD := dpb;
      for j := 0 to AnsImage.Width - 1 do
      begin
        for jj := 1 to XScale[j] do
        begin
          TempDD^ := TempSS^;
          inc(TempDD);
        end;
        inc(TempSS);
      end;
      inc(dpb, Width);
    end;
    inc(spb, AnsImage.Width);
  end;
end;

procedure TA2Image.DrawEffect(xDib: TXDib; x, y: Integer; etable:
  TColorTable5x5);
var
  spb, dpb, TempSS, TempDD: PTAns2Color;
  i, j: integer;
  ir, sr, dr: TRect;
  r, g, b, r1, g1, b1: word;
begin
  if xDib = nil then
    exit;

  sr := Rect(x, y, x + xDib.Width - 1, y + xDib.Height - 1);
  dr := Rect(0, 0, Width - 1, Height - 1);

  if not IntersectRect(ir, sr, dr) then
    exit;

  spb := PTAns2Color(xDib.Bits);
  inc(spb, ((ir.left - x) + (ir.top - y) * xDib.Width));

  dpb := Bits;
  inc(dpb, (ir.left + ir.top * Width));

  for i := ir.Top to ir.Bottom do
  begin
    TempSS := spb;
    TempDD := dpb;
    for j := ir.left to ir.right do
    begin
      if (TempSS^ <> 0) or (TempDD^ = 31) then
      begin
        WinVRGB(TempDD^, r, g, b);
        WinVRGB(TempSS^, r1, g1, b1);

        r := etable[r][r1];
        g := etable[g][g1];
        b := etable[b][b1];

        TempDD^ := WinRGB(r, g, b);
      end;
      inc(TempSS);
      Inc(TempDD);
    end;
    inc(spb, xDib.Width);
    inc(dpb, Width);
  end;

end;

procedure TA2Image.DrawDib(xDib: TXDib; x, y: Integer; aShadow: Boolean);
var
  spb, dpb, TempSS, TempDD: PTAns2Color;
  i, j: integer;
  ir, sr, dr: TRect;
begin
  if xDib = nil then
    exit;

  sr := Rect(x, y, x + xDib.Width - 1, y + xDib.Height - 1);
  dr := Rect(0, 0, Width - 1, Height - 1);

  if not IntersectRect(ir, sr, dr) then
    exit;

  spb := PTAns2Color(xDib.Bits);
  inc(spb, ((ir.left - x) + (ir.top - y) * xDib.Width));

  dpb := Bits;
  inc(dpb, (ir.left + ir.top * Width));

  if aShadow then
  begin
    for i := ir.Top to ir.Bottom do
    begin
      TempSS := spb;
      TempDD := dpb;
      for j := ir.left to ir.right do
      begin
        if TempSS^ <> 0 then
          TempDD^ := Darkentbl[Tempdd^];
        inc(TempSS);
        Inc(TempDD);
      end;
      inc(spb, xDib.Width);
      inc(dpb, Width);
    end;
  end
  else
  begin
    for i := ir.Top to ir.Bottom do
    begin
      TempSS := spb;
      TempDD := dpb;
      for j := ir.left to ir.right do
      begin
        if TempSS^ <> 0 then
          TempDD^ := TempSS^;
        inc(TempSS);
        Inc(TempDD);
      end;
      inc(spb, xDib.Width);
      inc(dpb, Width);
    end;
  end;
end;

procedure TA2Image.DrawImageEffect(AnsImage: TA2Image; x, y: Integer; etable:
  TColorTable5x5);
var
  spb, dpb, TempSS, TempDD: PTAns2Color;
  i, j: integer;
  ir, sr, dr: TRect;
  r, g, b, r1, g1, b1: word;
begin
  if AnsImage = nil then
    exit;

  sr := Rect(x, y, x + AnsImage.Width - 1, y + AnsImage.Height - 1);
  dr := Rect(0, 0, Width - 1, Height - 1);

  if not IntersectRect(ir, sr, dr) then
    exit;

  spb := AnsImage.Bits;
  inc(spb, ((ir.left - x) + (ir.top - y) * AnsImage.Width));

  dpb := Bits;
  inc(dpb, (ir.left + ir.top * Width));

  for i := ir.Top to ir.Bottom do
  begin
    TempSS := spb;
    TempDD := dpb;
    for j := ir.left to ir.right do
    begin
      WinVRGB(TempDD^, r, g, b);
      WinVRGB(TempSS^, r1, g1, b1);

      r := etable[r][r1];
      g := etable[g][g1];
      b := etable[b][b1];

      TempDD^ := WinRGB(r, g, b);

      inc(TempSS);
      Inc(TempDD);
    end;
    inc(spb, AnsImage.Width);
    inc(dpb, Width);
  end;
end;

procedure TA2Image.DrawImageOveray(AnsImage: TA2Image; x, y: Integer; weight:
  integer);
var
  spb, dpb, TempSS, TempDD: PTAns2Color;
  i, j: integer;
  ir, sr, dr: TRect;
  r, g, b, r1, g1, b1: word;
  CompWeight: integer;
begin
  if AnsImage = nil then
  begin
    //      Error := 3;
    exit;
  end;

  //do clipping
  if weight > 100 then
    weight := 100;
  if weight < 0 then
    weight := 0;
  sr := Rect(x, y, x + AnsImage.Width - 1, y + AnsImage.Height - 1);
  dr := Rect(0, 0, Width - 1, Height - 1);

  if not IntersectRect(ir, sr, dr) then
    exit;

  spb := AnsImage.Bits;
  inc(spb, ((ir.left - x) + (ir.top - y) * AnsImage.Width));

  dpb := Bits;
  inc(dpb, (ir.left + ir.top * Width));

  CompWeight := (weight shl 16) div 100;

  for i := ir.Top to ir.Bottom do
  begin
    TempSS := spb;
    TempDD := dpb;
    for j := ir.left to ir.right do
    begin
      if (TempSS^ <> AnsImage.TransparentColor) and (TempSS^ <> 31) then
      begin
        WinVRGB(TempDD^, r1, g1, b1);
        WinVRGB(TempSS^, r, g, b);

        if r > r1 then
          r1 := ((r1 - r) * CompWeight) shr 16 + r;
        if g > g1 then
          g1 := ((g1 - g) * CompWeight) shr 16 + g;
        if b > b1 then
          b1 := ((b1 - b) * CompWeight) shr 16 + b;
        {
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
        }
        TempDD^ := WinRGB(r1, g1, b1);
        //            TempDD^ := TempSS^;
      end;
      inc(TempSS);
      Inc(TempDD);
    end;
    inc(spb, AnsImage.Width);
    inc(dpb, Width);
  end;
end;

procedure TA2Image.DrawRefractive(AnsImage: TA2Image; x, y, Refracrange,
  overValue: Integer);
var
  spb, dpb, TempSS, TempDD, TempDD_1: PTAns2Color;
  i, j: integer;
  ir, sr, dr: TRect;
begin
  if AnsImage = nil then
    exit;

  //do clipping
  sr := Rect(x, y, x + AnsImage.Width - 1, y + AnsImage.Height - 1);
  dr := Rect(0, 0, Width - 1, Height - 1);

  if not IntersectRect(ir, sr, dr) then
    exit;

  spb := AnsImage.Bits;
  inc(spb, ((ir.left - x) + (ir.top - y) * AnsImage.Width));

  dpb := Bits;
  inc(dpb, (ir.left + ir.top * Width));

  for i := ir.Top to ir.Bottom do
  begin
    TempSS := spb;
    TempDD := dpb;
    TempDD_1 := dpb;
    inc(TempDD_1, Refracrange);
    for j := ir.left to ir.right do
    begin
      if (TempSS^ <> AnsImage.TransparentColor) and (TempSS^ <> 31) then
      begin
        TempDD^ := TempDD_1^ + overValue;
      end;
      inc(TempSS);
      Inc(TempDD);
      Inc(TempDD_1);
    end;
    inc(spb, AnsImage.Width);
    inc(dpb, Width);
  end;
end;

procedure TA2Image.DrawImageAdd(AnsImage: TA2Image; x, y: Integer);
var
  spb, dpb, TempSS, TempDD: PTAns2Color;
  i, j: integer;
  ir, sr, dr: TRect;
  r, g, b, r1, g1, b1: word;
begin
  if AnsImage = nil then
    exit;

  //do clipping
  sr := Rect(x, y, x + AnsImage.Width - 1, y + AnsImage.Height - 1);
  dr := Rect(0, 0, Width - 1, Height - 1);

  if not IntersectRect(ir, sr, dr) then
    exit;

  spb := AnsImage.Bits;
  inc(spb, ((ir.left - x) + (ir.top - y) * AnsImage.Width));

  dpb := Bits;
  inc(dpb, (ir.left + ir.top * Width));

  for i := ir.Top to ir.Bottom do
  begin
    TempSS := spb;
    TempDD := dpb;
    for j := ir.left to ir.right do
    begin
      if (TempSS^ <> AnsImage.TransparentColor) and (TempSS^ <> 31) then
      begin
        WinVRGB(TempDD^, r1, g1, b1);
        WinVRGB(TempSS^, r, g, b);

        r1 := r1 + r;
        g1 := g1 + g;
        b1 := b1 + b;
        if r1 > 31 then
          r1 := 31;
        if g1 > 31 then
          g1 := 31;
        if b1 > 31 then
          b1 := 31;

        TempDD^ := WinRGB(r1, g1, b1);
      end;
      inc(TempSS);
      Inc(TempDD);
    end;
    inc(spb, AnsImage.Width);
    inc(dpb, Width);
  end;
end;

procedure TA2Image.Optimize;
var
  x, y, minx, maxx, miny, maxy, w, h: Integer;
  i, j: Integer;
  pb, TempBits: PTAns2Color;
  pcs, pcd: PTAns2Color;
begin
  minx := width - 1;
  maxx := 0;
  miny := height - 1;
  maxy := 0;

  pb := Bits;
  for i := 0 to (width * height) - 1 do
  begin
    if pb^ <> TransParentColor then
    begin
      x := i mod width;
      y := i div width;
      if minx > x then
        minx := x;
      if miny > y then
        miny := y;

      if maxx < x then
        maxx := x;
      if maxy < y then
        maxy := y;
    end;
    inc(pb);
  end;

  if (minx >= maxx) and (miny >= maxy) then
  begin
    FreeMem(Bits, Width * Height * sizeof(TAns2Color));
    Width := 4;
    Height := 4;
    GetMem(Bits, Width * Height * sizeof(TAns2Color));
    FillChar(Bits^, Width * Height * sizeof(TAns2Color), 0);
  end
  else
  begin
    w := WidthBytes(Maxx - Minx + 1);
    h := Maxy - Miny + 1;

    GetMem(TempBits, w * h * sizeof(TAns2Color));
    pcs := Bits;
    inc(pcs, (minx + miny * Width));
    pcd := TempBits;
    for j := 0 to h - 1 do
    begin
      move(pcs^, pcd^, w * sizeof(TAns2Color));
      inc(pcs, Width);
      inc(pcd, w);
    end;

    FreeMem(Bits, Width * Height * sizeof(TAns2Color));
    Width := w;
    Height := h;
    Bits := TempBits;
    px := px + Minx;
    py := py + Miny;
  end;
end;

procedure TA2Image.OptimizeWidth;
var
  x, minx, maxx, w: Integer;
  i, j: Integer;
  pb, TempBits: PTAns2Color;
  pcs, pcd: PTAns2Color;
begin
  minx := width - 1;
  maxx := 0;

  pb := Bits;
  for i := 0 to (width * height) - 1 do
  begin
    if pb^ <> 0 then
    begin
      x := i mod width;
      if minx > x then
        minx := x;
      if maxx < x then
        maxx := x;
    end;
    inc(pb);
  end;

  if minx > 1 then
    minx := minx - 1;
  if maxx < Width - 1 then
    maxx := maxx + 1;

  if (minx >= maxx) then
  begin
    FreeMem(Bits, Width * Height * sizeof(TAns2Color));
    Width := 4;
    Height := 4;
    GetMem(Bits, Width * Height * sizeof(TAns2Color));
    FillChar(Bits^, Width * Height * sizeof(TAns2Color), 0);
  end
  else
  begin
    w := Maxx - Minx + 1;

    GetMem(TempBits, w * Height * sizeof(TAns2Color));
    pcs := Bits;
    inc(pcs, (minx));
    pcd := TempBits;
    for j := 0 to Height - 1 do
    begin
      move(pcs^, pcd^, w * sizeof(TAns2Color));
      inc(pcs, Width);
      inc(pcd, w);
    end;

    FreeMem(Bits, Width * Height * sizeof(TAns2Color));
    Width := w;
    Bits := PTAns2Color(TempBits);
    px := px + Minx;
  end;
  FClientRect := Rect(0, 0, Width - 1, Height - 1);
end;

//Load DIB ot File

procedure TA2Image.LoadFromFile(FileName: string);
var
  BmpInfo: PBitMapInfo;
  Bmpbits: Pbyte;
  headerSize, ImageSize: Integer;
  Palette: TImgLibPalette;
begin

  BmpInfo := nil;
  BmpBits := nil;

  LoadDIB256(FileName, BmpInfo, BmpBits, HeaderSize, ImageSize);
  if (BmpInfo = nil) or (BmpBits = nil) then
    exit;

  if Bits <> nil then
    FreeMem(Bits, Width * Height * Sizeof(TAns2Color));

  Width := BmpInfo^.bmiHeader.biWidth;
  Height := Abs(BmpInfo^.bmiHeader.biHeight);
  BmpInfoToImgLibPal(Palette, BmpInfo);

  GetMem(Bits, Width * Height * Sizeof(TAns2Color));
  if Bits = nil then
    raise Exception.Create('TA2Image: GemMem Failed for Bits');
  FillChar(Bits^, Width * Height * sizeof(TAns2Color), 0);

  AnsPaletteDataToAns2Image(Self, Palette, BmpBits);

  FreeMem(Bmpbits);
  FreeMem(BmpInfo);
end;

procedure TA2Image.LoadFromFileTrueColor(FileName: string);
var
  //   i, j : integer;
  Stream: TFileStream;
  Header: TBitmapFileHeader;
  BmpInfo: PBitMapInfo;
  HeaderSize: Integer;
  buffer: pbyte;
begin
  //Initialise and open file
  HeaderSize := SizeOf(TBitmapInfoHeader);
  BmpInfo := AllocMem(HeaderSize);
  buffer := nil;
  Stream := nil;
  try
    Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    //Read file Header
    Stream.ReadBuffer(Header, SizeOf(Header));
    //Read bitmap info header and validate
    Stream.ReadBuffer(BmpInfo^, SizeOf(TBitmapInfoHeader));

    with BmpInfo^.bmiHeader do
    begin
      if biBitCount <> 24 then
      begin
        Stream.Free;
        FreeMem(BmpInfo);
        raise Exception.Create('TA2Image: Not TrueColor');
        exit;
      end;
    end;

    Width := BmpInfo^.bmiHeader.biWidth;
    Height := BmpInfo^.bmiHeader.biHeight;

    if Bits <> nil then
      FreeMem(Bits, Width * Height * Sizeof(TAns2Color));
    GetMem(Bits, Width * Height * 2);
    GetMem(Buffer, Width * Height * 3);

    //Load Bits
    //Stream.Seek(Header.bfOffBits, soFromBeginning);
    Stream.ReadBuffer(Buffer^, LongInt(width * height * 3));
    FlipBits(Buffer, Width * 3, Height);

    AnsTrueDataToAns2Image(Self, Buffer);

    //If the code gets this far the bitmap has been loaded okay
    Stream.Free;
    FreeMem(Buffer);
  except
    if Stream <> nil then
      Stream.Free;
    if Buffer <> nil then
      FreeMem(Buffer);
    if Bits <> nil then
      FreeMem(Bits);
    Bits := nil;
  end;
  if BmpInfo <> nil then
    FreeMem(BmpInfo);
end;

//Save DIB ot File

procedure TA2Image.SaveToFile(FileName: string);
var
  Stream: TFileStream;
  Header: TBitmapFileHeader;
  BmpInfo: PBitMapInfo;
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
  if BmpInfo^.bmiHeader.biHeight < 0 then
  begin
    FlipBits(PByte(Bits), Width * 2, Height);
    BmpInfo^.bmiHeader.biHeight := -BmpInfo^.bmiHeader.biHeight;
  end;

  FillChar(Header, sizeof(TBitmapFileHeader), 0);
  with Header do
  begin
    bfType := $4D42;
    bfSize := 1078 + Width * Height * 2 - 1024;
    bfOffBits := 1078 - 1024;
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
  FreeMem(BmpInfo);
end;

//////////////////////////////////////
//        TA2ImageLib             //
//////////////////////////////////////

constructor TA2ImageLib.Create;
begin
  TransparentColor := 0;
  FTag := 0;
  ImageList := TList.Create;
end;

destructor TA2ImageLib.Destroy;
var
  i: integer;
begin
  for i := 0 to ImageList.Count - 1 do
    TA2Image(ImageList.items[i]).Free;
  ImageList.Free;
  inherited Destroy;
end;

function TA2ImageLib.GetByName(aName: string): TA2Image;
var
  i: integer;
  AnsImage: TA2Image;
begin
  Result := nil;

  for i := 0 to Imagelist.Count - 1 do
  begin
    AnsImage := ImageList[i];
    if AnsImage.Name = aName then
    begin
      Result := AnsImage;
      exit;
    end;
  end;
end;

function TA2ImageLib.GetCount: Integer;
begin
  Result := ImageList.Count;
end;

function TA2ImageLib.GeTA2Image(Idx: Integer): TA2Image;
begin
  if (Idx < ImageList.Count) and (Idx >= 0) then
    Result := ImageList.items[Idx]
  else
    Result := nil;
end;

procedure TA2ImageLib.Clear;
var
  i: Integer;
  AnsImage: TA2Image;
begin
  for i := 0 to ImageList.Count - 1 do
  begin
    AnsImage := ImageList.Items[i];
    AnsImage.Free;
  end;
  ImageList.Clear;
end;

procedure TA2ImageLib.AddImage(AImage: TA2Image);
begin
  ImageList.add(AImage);
end;

procedure TA2ImageLib.DeleteImage(Idx: Integer);
begin
  if Idx < ImageList.Count then
  begin
    TA2Image(ImageList.items[Idx]).Free;
    ImageList.Delete(Idx);
  end;
end;

procedure TA2ImageLib.InsertImage(Idx: Integer; AImage: TA2Image);
begin
  ImageList.Insert(Idx, AImage);
  AImage.TransParentColor := TransParentColor;
end;

procedure TA2ImageLib.LoadFromFile(FileName: string);
var
  Stream: TFileStream;
  //   fh : integer;
  n: Integer;
  AnsImage: TA2Image;
  ImgHeader: TA2ImageLibHeader;
  FAnsHdr: TA2ImageFileHeader;
  pbuf: pbyte;
  showbuf: array[0..64] of byte;
begin
  if FileExists(FileName) = FALSE then
  begin
    StrPcopy(@ShowBuf, 'File Not Found : ' + FileName);
    Windows.MessageBox(0, @ShowBuf, 'Error', 0);
    exit;
  end;
  Stream := nil;
  try
    Stream := TFileStream.Create(FileName, fmOpenRead or fmShareDenyWrite);
    //   fh := FileOpen (FileName, fmOpenRead);

    for n := 0 to ImageList.Count - 1 do
      TA2Image(ImageList.items[n]).Free;
    ImageList.Clear;

    Stream.ReadBuffer(ImgHeader, SizeOf(ImgHeader));
    //   FileRead (fh, ImgHeader, SizeOf(ImgHeader));
    if StrLIComp(PChar(ImageLibID), ImgHeader.Ident, 4) = 0 then
    begin
      for n := 0 to ImgHeader.ImageCount - 1 do
      begin
        Stream.ReadBuffer(FAnsHdr, SizeOf(TA2ImageFileHeader));
        //         FileRead (fh, FAnsHdr, SizeOf(TA2ImageFileHeader));
        AnsImage := TA2Image.Create(FAnsHdr.Width, FAnsHdr.Height, FAnsHdr.px,
          FAnsHdr.py);

        if AnsImage = nil then
          raise Exception.Create('TA2Image: GemMem Failed ');
        GetMem(pbuf, AnsImage.Width * AnsImage.Height);
        Stream.ReadBuffer(pbuf^, AnsImage.Width * AnsImage.Height);
        //         FileRead (fh, pbuf^, AnsImage.Width * AnsImage.Height);

        AnsPaletteDataToAns2Image(AnsImage, ImgHeader.Palette, pbuf);

        FreeMem(pbuf, AnsImage.Width * AnsImage.Height);

        AnsImage.TransparentColor := TransParentColor;
        AddImage(AnsImage);
      end;
    end
    else
    begin
      if StrLIComp(PChar(ImageLibID1), ImgHeader.Ident, 4) = 0 then
      begin
        for n := 0 to ImgHeader.ImageCount - 1 do
        begin
          Stream.ReadBuffer(FAnsHdr, SizeOf(TA2ImageFileHeader));
          //            FileRead (fh, FAnsHdr, SizeOf(TA2ImageFileHeader));
          AnsImage := TA2Image.Create(FAnsHdr.Width, FAnsHdr.Height, FAnsHdr.px,
            FAnsHdr.py);
          if AnsImage = nil then
            raise Exception.Create('TA2Image: GemMem Failed ');
          Stream.ReadBuffer(AnsImage.Bits^, AnsImage.Width * AnsImage.Height *
            2);
          //            FileRead (fh, AnsImage.Bits^, AnsImage.Width * AnsImage.Height * 2);
          AnsImage.TransparentColor := TransParentColor;

          AddImage(AnsImage);
        end;
      end
      else
        raise Exception.Create('Not a valid Image Library File');
    end;
    Stream.Free;
  except
    if Stream <> nil then
      Stream.Free;
  end;
  //   FileClose (fh);
end;

procedure TA2ImageLib.SaveToFile(FileName: string);
var
  Stream: TFileStream;
  n: Integer;
  AnsImage: TA2Image;
  fAnsHdr: TA2ImageFileHeader;
  ImgHeader: TImgLibHeader;
begin
  Stream := TFileStream.Create(FileName, fmCreate);
  with ImgHeader do
  begin
    Ident := 'ATZ1';
    ImageCount := ImageList.Count;
    TransparentColor := Self.TransparentColor;
    //      Palette := Self.Palette;
  end;

  Stream.WriteBuffer(ImgHeader, SizeOf(ImgHeader));
  for n := 0 to ImgHeader.ImageCount - 1 do
  begin
    AnsImage := ImageList.items[n];
    fAnsHdr.Width := AnsImage.Width;
    fAnsHdr.Height := AnsImage.Height;
    fAnsHdr.Px := AnsImage.Px;
    fAnsHdr.Py := AnsImage.Py;
    Stream.WriteBuffer(fAnsHdr, SizeOf(TA2ImageFileHeader));
    Stream.WriteBuffer(AnsImage.Bits^, AnsImage.Width * AnsImage.Height * 2);
  end;

  Stream.Free;
end;

procedure TA2ImageLib.SaveToFileHeader(const fileName: string);
var
  Stream: TFileStream;
  ImgHeader: TA2ImageLibHeader;
  FAnsHdr: TA2ImageFileHeader;
  AnsImage: TA2Image;
  i, nByte: integer;
  pstr: PChar;
begin
  if FileExists(FileName) = FALSE then
  begin
    pstr := PChar('File Not Found : ' + FileName);
    Windows.MessageBox(0, pstr, 'Error', 0);
    exit;
  end;
  Stream := nil;

  try
    Stream := TFileStream.Create(FileName, fmOpenReadWrite or fmShareExclusive);
    Stream.ReadBuffer(ImgHeader, SizeOf(ImgHeader));

    nByte := IfThen((StrLIComp(PChar(ImageLibID), ImgHeader.Ident, 4) = 0), 1,
      2);

    for i := 0 to ImageList.Count - 1 do
    begin
      AnsImage := ImageList[i];

      fAnsHdr.Width := AnsImage.Width;
      fAnsHdr.Height := AnsImage.Height;
      fAnsHdr.Px := AnsImage.Px;
      fAnsHdr.Py := AnsImage.Py;
      Stream.WriteBuffer(fAnsHdr, SizeOf(TA2ImageFileHeader));
      Stream.Seek(AnsImage.Width * AnsImage.Height * nByte, soFromCurrent)
    end;
  finally
    Stream.Free;
  end;
end;

{
procedure TA2ImageLib.SaveToFile8(const FileName: string);
var
   Palette16: PTAns2Color;
   ColorCount: integer;
   ImgHeader: TImgLibHeader;
   fAnsHdr: TA2ImageFileHeader;
   AnsImage : TA2Image;
   AnsBits: PTAns2Color;
   IndexBits, PtrBits: PByte;
   n, m, ImgSize: integer;
   Stream: TFileStream;

   function FindIndex(Bits: TAns2Color; Palette: PTAns2Color; cc: integer): integer;
   var
      i: integer;
   begin
      Result := cc;
      for i:=0 to cc-1 do begin
         if Bits = Palette^ then begin
            Result := i; exit;
         end;
      end;
   end;
begin
   GetMem(Palette16, SizeOf(TAns2Color)*256);
   GetMem(IndexBits, 200*200);
   FillChar(Palette16^, 0, SizeOf(TAns2Color)*256);
   ColorCount := 1;
   //----------
   Stream  := TFileStream.Create(FileName, fmCreate or fmShareExclusive);
   with ImgHeader do begin
    Ident := 'ATZ1';
    ImageCount := ImageList.Count;
      TransparentColor := Self.TransparentColor;
//      Palette := Self.Palette;
   end;

   Stream.WriteBuffer(ImgHeader, SizeOf(ImgHeader));
   for n := 0 to ImageList.Count-1 do begin
      AnsImage := ImageList.items[n];

      fAnsHdr.Width := AnsImage.Width;
      fAnsHdr.Height := AnsImage.Height;
      fAnsHdr.Px := AnsImage.Px;
      fAnsHdr.Py := AnsImage.Py;
      Stream.WriteBuffer(fAnsHdr, SizeOf(TA2ImageFileHeader));

      ImgSize := AnsImage.Width * AnsImage.Height;
      FillChar(IndexBits^, ImgSize, 0);

      AnsBits := AnsImage.Bits;
      PtrBits := IndexBits;
      for m := 0 to ImgSize-1 do begin

         inc(AnsBits);
         inc(PtrBits);
      end;
   end;

   Stream.Free;
   //----------
   FreeMem(IndexBits);
   FreeMem(Palette16);
end;
}

procedure A2DrawImage(Canvas: TCanvas; X, Y: Integer; ansImage: TA2Image);
var
  bmpInfo: PBitmapInfo;
  HeaderSize: integer;
  dc: HDC;
begin
  if not assigned(AnsImage) then
    exit;
  HeaderSize := Sizeof(TBitmapInfo) + (256 * Sizeof(TRGBQuad));
  BmpInfo := AllocMem(HeaderSize);

  if BmpInfo = nil then
    raise Exception.Create('TNoryImage: Failed to allocate a DIB');
  with BmpInfo^.bmiHeader do
  begin
    biSize := SizeOf(TBitmapInfoHeader);
    biWidth := AnsImage.Width;
    biHeight := -AnsImage.Height;
    biPlanes := 1;
    biBitCount := 16;
    biCompression := BI_RGB;
    biClrUsed := 0;
    biClrImportant := 0;
  end;
  dc := canvas.Handle;
  SetDIBitsToDevice(dc, x, y, AnsImage.Width, AnsImage.Height, 0, 0, 0,
    AnsImage.Height, AnsImage.Bits, BmpInfo^, DIB_RGB_COLORS);
  FreeMem(BmpInfo, HeaderSize);
end;

procedure AnsPaletteDataToAns2Image(Ans2Image: TA2Image; Palette:
  TImgLibPalette; pb: pbyte);
var
  i, j: integer;
  db: PTAns2Color;
  sb: pbyte;
  col8, r, g, b, t: word;
  wcol: word;
begin
  sb := pb;
  db := Ans2Image.Bits;

  for j := 0 to Ans2Image.Height - 1 do
  begin
    for i := 0 to Ans2Image.Width - 1 do
    begin
      col8 := sb^;
      r := Palette[col8].Red;
      g := Palette[col8].Green;
      b := Palette[col8].Blue;

      t := r shr 3;
      if (r <> 0) and (t = 0) then
        r := 1
      else
        r := t;

      t := g shr 3;
      if (g <> 0) and (t = 0) then
        g := 1
      else
        g := t;

      t := b shr 3;
      if (b <> 0) and (t = 0) then
        b := 1
      else
        b := t;

      wcol := WinRgb(r, g, b);

      db^ := wcol;

      inc(sb);
      inc(db);
    end;
  end;
end;

procedure AnsTrueDataToAns2Image(Ans2Image: TA2Image; pb: pbyte);
var
  i, j: integer;
  db: PTAns2Color;
  sb: pbyte;
  r, g, b, t: word;
  wcol: word;
begin
  sb := pb;
  db := Ans2Image.Bits;

  for j := 0 to Ans2Image.Height - 1 do
  begin
    for i := 0 to Ans2Image.Width - 1 do
    begin
      r := sb^;
      inc(sb);
      g := sb^;
      inc(sb);
      b := sb^;
      inc(sb);

      t := r shr 3;
      if (r <> 0) and (t = 0) then
        r := 1
      else
        r := t;

      t := g shr 3;
      if (g <> 0) and (t = 0) then
        g := 1
      else
        g := t;

      t := b shr 3;
      if (b <> 0) and (t = 0) then
        b := 1
      else
        b := t;

      wcol := WinRgb(r, g, b);

      db^ := wcol;

      inc(db);
    end;
  end;
end;

////////////////////////////////////////////
//     迄飘 免仿阑 困茄 傈开 BitMap
////////////////////////////////////////////
var
  Gbmpinfo: PBitmapinfo;
  GBitMap: TBitMap;
  TextImage: TA2Image;

  pTempBmpinfo: PBitmapinfo;

procedure CreateGBitMap(aBitMap: TBitMap; aImage: TA2Image);
var
  HeaderSize: Integer;
  Focus: hWnd;
  dc: HDC;
begin
  HeaderSize := SizeOf(TBitmapInfo) + (256 * SizeOf(TRGBQuad));
  GBmpinfo := AllocMem(HeaderSize);

  with GBmpinfo^.bmiHeader do
  begin
    biSize := SizeOf(TBitmapInfoHeader);
    biWidth := aImage.Width;
    biHeight := -aImage.Height;
    biPlanes := 1;
    biBitCount := 16;
    biCompression := BI_RGB;
    biSizeImage := 0;
    biClrUsed := 0;
    biClrImportant := 0;
  end;

  Focus := GetFocus;
  dc := GetDC(Focus);
  aBitMap.Handle := CreateDIBitmap(dc, GBmpinfo^.bmiHeader, 0, Pointer(0),
    GBmpinfo^, DIB_PAL_COLORS);
  ReleaseDC(Focus, DC);
  if aBitMap.Handle = 0 then
    raise Exception.Create('CreateDIBitmap failed');

  aBitMap.Canvas.Font.Name := BitMapFontName;
  aBitMap.Canvas.Font.Size := 9;
  aBitMap.Canvas.Font.Color := clWhite;
  aBitMap.Canvas.Brush.Color := 0;

  pTempBmpInfo := AllocMem(HeaderSize);
  with pTempBmpInfo^.bmiHeader do
  begin
    biSize := SizeOf(TBitmapInfoHeader);
    biWidth := aImage.Width;
    biHeight := -aImage.Height;
    biPlanes := 1;
    biBitCount := 16;
    biCompression := BI_RGB;
    biSizeImage := 0;
    biClrUsed := 0;
    biClrImportant := 0;
  end;
end;

function A2TextWidth(astr: string): integer;
begin
  Result := GBitMap.Canvas.TextWidth(aStr);
end;

function A2TextHeight(astr: string): integer;
begin
  Result := GBitMap.Canvas.TextHeight(aStr);
end;

procedure A2SetFontColor(aColor: integer);
begin
  GBitMap.Canvas.Font.Color := aColor;
end;

function A2GetCanvas: TCanvas;
begin
  Result := GBitMap.Canvas;
end;

procedure A2DrawCanvas(aImage: TA2Image; x, y, sw, sh: integer; aTrans:
  Boolean);
var
  Temp: TA2Image;
  ww, hh: integer;
begin
  ww := sw;
  hh := sh;
  //   sw := 640; sh := 256;
  sw := 640;
  textImage.Width := sw;
  TextImage.Height := sh;

  pTempBmpInfo^.bmiHeader.biWidth := sw;
  pTempBmpInfo^.bmiHeader.biHeight := -sh;

  GetDIBits(GBitMap.Canvas.Handle, GBitMap.Handle, 0, TextImage.Height,
    TextImage.Bits, pTempBmpInfo^, 0);

  Temp := TA2Image.Create(ww, hh, 0, 0);
  Temp.DrawImage(TextImage, 0, 0, FALSE);

  aImage.DrawImage(temp, x, y, aTrans);
  //   aImage.DrawImage (TextImage, x, y, aTrans);

  Temp.Free;
  {
     textImage.Width := sw;
     TextImage.Height := sh;

     pTempBmpInfo^.bmiHeader.biWidth := sw;
     pTempBmpInfo^.bmiHeader.biWidth := sw;
     pTempBmpInfo^.bmiHeader.biHeight := -sh;

     GetDIBits(GBitMap.Canvas.Handle, GBitMap.Handle, 0, TextImage.Height, TextImage.Bits, pTempBmpInfo^, 0);
     aImage.DrawImage (TextImage, x, y, aTrans);
  }
end;

procedure A2SetFontName(aFontName: string);
begin
  BitMapFontName := aFontName;
  ;
  GBitMap.Canvas.Font.Name := BitMapFontName;
end;

procedure A2TextOut(aImage: TA2Image; FontSize, x, y: integer; astr: string);
var
  Temp: TA2Image;
  ww, hh: integer;
  w, h: integer;
  r: TRect;
  oldFontSize: integer;
begin
  if astr = '' then
    exit;
  GBitMap.Canvas.Font.Name := BitMapFontName;
  oldFontSize := GBitMap.Canvas.Font.Size;
  GBitMap.Canvas.Font.Size := FontSize;

  w := WidthBytes(GBitMap.Canvas.TextWidth(astr));
  h := GBitMap.Canvas.TextHeight(astr);

  ww := w;
  hh := h;

  w := 640; //h := 256;

  r := RECT(0, 0, w, h);
  GBitMap.Canvas.FillRect(r);

  GBitMap.Canvas.TextOut(0, 0, astr);

  textImage.Width := w;
  TextImage.Height := h;

  pTempBmpInfo^.bmiHeader.biWidth := w;
  pTempBmpInfo^.bmiHeader.biHeight := -h;

  GetDIBits(GBitMap.Canvas.Handle, GBitMap.Handle, 0, TextImage.Height,
    TextImage.Bits, pTempBmpInfo^, 0);

  Temp := TA2Image.Create(ww, hh, 0, 0);
  Temp.DrawImage(TextImage, 0, 0, FALSE);

  aImage.DrawImage(temp, x, y, TRUE);

  GBitMap.Canvas.Font.Size := oldFontSize;
  Temp.Free;
end;

{
procedure A2TextOut (aImage: TA2Image; x, y: integer; astr: string);
var r : TRect;
begin
   r := RECT ( 0, 0, GBitMap.Width, GBitMap.Height);
   GBitMap.Canvas.FillRect ( r);
   TextImage.Clear(0);
   GBitMap.Canvas.TextOut (x, y, astr);
   GetDIBits(GBitMap.Canvas.Handle, GBitMap.Handle, 0, TextImage.Height, TextImage.Bits, GBmpinfo^, 0);
   aImage.DrawImage (TextImage, x, y, TRUE);
end;
}

////////////////////////////////
//     GetBmpInfo
////////////////////////////////

function GetPBitmapInfo(aWidth, aHeight, aBitCount: integer): PBitMapInfo;
var
  LocalBmpInfo: PBitmapInfo;
  HeaderSize: integer;
begin
  HeaderSize := Sizeof(TBitmapInfo) + (256 * Sizeof(TRGBQuad));
  LocalBmpInfo := AllocMem(HeaderSize);
  if LocalBmpInfo = nil then
    raise Exception.Create('TNoryImage: Failed to allocate a DIB');

  //   ImgLibPalToBmpInfo(GPalette, LocalBmpInfo);
  with LocalBmpInfo^.bmiHeader do
  begin
    biSize := SizeOf(TBitmapInfoHeader);
    biWidth := aWidth;
    biHeight := -aHeight;
    biPlanes := 1;
    biBitCount := aBitCount;
    biCompression := BI_RGB;
    biClrUsed := 0;
    biClrImportant := 0;
  end;
  Result := LocalBmpInfo;
end;

var
  i: integer;
  j: integer;
  temp: integer;

initialization
  begin
    TextImage := TA2Image.Create(640, 256, 0, 0);
    GBitMap := TBitmap.Create;

    CreateGBitMap(GBitMap, TextImage);

    // 弊覆磊侩
    for i := 0 to 65535 do
      darkentbl[i] := WinOpercity(i, 85);
    for i := 0 to 65535 do
      darkentbl[i] := WinDECRGB(darkentbl[i], 3);
    // bubble 侩
    for i := 0 to 65535 do
      bubbletbl[i] := WinDECRGB(i, 4);

    for i := 0 to 65535 do
      DECRGBdarkentbl[i] := WinDECRGB(i, 5);

    // effect侩 Screen, Color Dodge Table  from minds 20011215
    for i := 0 to 31 do
      for j := 0 to 31 do
      begin
        EffectScreen[i][j] := max(i, j) + floor((32 - max(i, j)) * min(i, j) /
          32.0);
        temp := min((32 * i) div (32 - j), 31);
        EffectColorDodge[i][j] := max(temp, j) + (31 - max(temp, j)) * min(temp,
          j) div 31;
        //         temp := max(i, j);
        //         if i>j then EffectLighten[i][j] := i
        //                else
        EffectLighten[i][j] := max(EffectScreen[i][j], j);
        //max(temp,j) + (31-max(temp,j))*min(temp,j) div 31;
        EffectScreenDark[i][j] := EffectScreen[i][j * 2 div 3]; // * 32 div 48;
      end;

    A2FontClass := TA2FontClass.Create;
    CellCheckImg := TA2Image.Create(32, 24, -16, -12);
    CellCheckImg.Clear(16912);
  end;

finalization
  begin
    CellCheckImg.Free;

    A2FontClass.Free;

    GBitMap.Free;
    TextImage.Width := 640;
    TextImage.Height := 128;
    TextImage.Free;
  end;

end.

