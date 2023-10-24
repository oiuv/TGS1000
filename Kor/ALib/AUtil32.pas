unit AUtil32;

interface

uses
	Windows, SysUtils, Classes, mmsystem;

const
   WSTRINGSIZE = 1024;
   WSTRINGSIZEALLOW = WSTRINGSIZE-3;

type
   WString = array [0..WSTRINGSIZE-1] of byte;
   PWString = ^WString;

   procedure MoveWS (var Sour, Dest: WString);
   procedure ClearWS (var wstr: WString);
   function  SizeofWS (var wstr: WString): Word;
   function  CompareWS (var S1, S2: WString): integer;
   procedure WScat (var Dest, Sour: WString);
   procedure SetWSpChar (var wstr: WString; pc: pchar);
   procedure GetWSpChar (var wstr: WString; pret: pchar);
   procedure IntToWS (aInt: integer; var wstr: WString);
   function  WsToInt (var wstr: WString): integer;
   procedure CopyWS (var sour: WString; Start, Len: integer; var rws: WString);
   procedure GetValidWS3 (var sour, dest: WString; Divider: Char; var rws: WString);

   function  PosWS (astr: string; var wstr: WString): integer;
   procedure SetWSString (var wstr: WString; str: string);
   function  GetWSString (var wstr: WString): string;
   procedure InverseWString (var wstr: WString);


const
   WORDSTRINGSIZE = 4096;
   WORDSTRINGSIZEALLOW = WORDSTRINGSIZE-3;

type
   TWordString = array[0..WORDSTRINGSIZE-1] of byte;
   PTWordString = ^TWordString;

   procedure SetWordString (var WordString: TWordString; str: string);
   function  GetWordString (var WordString: TWordString): string;
   procedure MoveWordString (var Sour, Dest: TWordString);
   function  SizeofWordString (var WordString: TWordString): Word;
   procedure InverseWordString (var WordString: TWordString);
   function  GetWordStringDataPointer (var WordString: TWordString): Pointer;
   procedure SetWordStringDataSize (var WordString: TWordString; dsize: word);


type
   HIMC = Integer;

   function  WhereIsChar (PCharCur, PCharCenter:PChar; var lpos, cpos, hpos:integer; GapValue:integer):Boolean;

   function  File_Size (const FName: string): Longint;
   // add by minds 020202
   function GetValidStr4(var Str: string; const Divider: string): string;
   function  GetValidStr3 (Str: string; var Dest: string; Divider: Char): string;
   function  GetValidStr2 (Str: string; var Dest: string; Divider1, Divider2: Char): string;
   procedure _strPCopy (buf: PChar; str: string);
   function  GetCPUStartHour: integer;
   function  StringListLoadFromMemory (var StringList: TStringList; apbuf:pbyte; asize: integer): Boolean;
   function  IsNumeric (str:string): Boolean;
   function  IsEnglish (str:string): Boolean;
   function  IsEngNumeric (str:string): Boolean;
   procedure ChangeStr (var str: string; sour, dest:string);
   function  GetSerialNumber : DWORD;
   function  _StrToInt (str: string): Integer;

   function  IpAddrToDWORD (aipaddr: string): DWORD;
   function  DWORDToIpAddr (aParam: DWORD): string;

   procedure GetNearPosition (var xx, yy: integer);

   function  ReverseFormat (const abufferstr, aFormat: string; var astr1, astr2, astr3: string; acnt: integer): Boolean;
   procedure Change4Bit (apb: pbyte; acnt: integer);


   function GetImeMode ( Handle:HWND):DWORD;
   procedure SetImeMode (Handle:HWND; Mode:DWORD);
   function ImmGetContext(hWnd: HWND): HIMC; stdcall;
   function ImmGetConversionStatus(hImc: HIMC; var Conversion, Sentence: DWORD): Boolean; stdcall;
   function ImmSetConversionStatus(hImc: HIMC; Conversion, Sentence: DWORD): Boolean; stdcall;
   function ImmReleaseContext(hWnd: HWND; hImc: HIMC): Boolean; stdcall;

type
   TCallStringFunction = procedure (astr, aFileName: string; line: integer) of object;

   procedure CaptureStringFromFile (afileName: string; aCallFunction: TCallStringFunction);
   function Get10000To100 (avalue: integer): string;
implementation

uses Dialogs;

procedure Change4Bit (apb: pbyte; acnt: integer);
var
   i : integer;
   a,b : byte;
begin
   for i := 0 to acnt -1 do begin
      a := apb^ and $f0;
      b := apb^ and $0f;

      a := a shr 4;
      b := b shl 4;
      apb^ := a+b;
      inc (apb);
   end;
end;

procedure CaptureStringFromFile (afileName: string; aCallFunction: TCallStringFunction);
var
   i : integer;
   line: integer;
   sflag, slashflag : Boolean;
   str, gstr : string;
   StringList : TStringList;
begin
   StringList := TStringList.Create;
   StringList.LoadFromFile (afilename);
   for line := 0 to StringList.Count -1 do begin
      str := StringList[line];
      gstr := '';
      sflag := FALSE;
      slashflag := FALSE;
      for i := 1 to Length(str) do begin
         if slashflag then continue;
         if sflag then begin
            if str[i] = '''' then begin
               if (gstr <> '') and (Length(gstr) >= 2) then begin
                  aCallFunction (gstr, afileName, line);
               end;
               gstr := '';
               sflag := FALSE;
            end;
         end else begin
            if str[i] = '''' then begin
               sflag := TRUE;
               continue;
            end;
         end;
         if sflag then gstr := gstr + str[i]
         else begin
            if (str[i] = '/') and (Length(str) >= i+1) then begin
               if str[i+1] = '/' then slashflag := TRUE;
            end;
         end;
      end;
   end;
   StringList.Free;
end;


function GetValidStr3_1 (Str: string; var Dest: string; Divider: string): string;
var
   cpos: integer;
begin
   cpos := Pos (divider, str);
   if cpos = 0 then begin Result := ''; Dest := str; exit; end;

   Dest := Copy (str, 1, cpos-1);
   Result := Copy (str, cpos+Length(divider), Length(str)-cpos-Length(divider)+1);
end;

function GetValidStr3_2 (Str: string; var Dest: string; Divider1, divider2: string): string;
var
   tempstr: string;
   cpos1, cpos2: integer;
begin
   if Divider1 = '' then cpos1 := 1
   else cpos1 := Pos (divider1, str);

   if cpos1 = 0 then begin Dest := ''; exit; end;

   if Divider2 = '' then cpos2 := -1
   else begin
      tempstr := Copy (Str, cpos1+Length(divider1), Length(Str)-cpos1-Length(divider1)+1);
      cpos2  := Pos (divider2, tempstr) + cpos1 + Length(divider1)-1;
//      cpos2 := Pos (divider2, str);
   end;


   if cpos2 = 0 then begin Result := ''; Dest := ''; exit; end;
   if cpos2 = -1 then begin Result := ''; Dest := Copy (str, cpos1+Length(divider1),Length(str)-cpos1-Length(divider1)+1); exit; end;

   Dest := Copy (str, cpos1+Length(divider1), cpos2-(cpos1+Length(divider1)));
   Result := Copy (str, cpos2, Length(str)-cpos2+1);
end;


function  ReverseFormat (const abufferstr, aFormat: string; var astr1, astr2, astr3: string; acnt: integer): Boolean;
var
   str : string;
   strs : array [0..3] of string;
begin
   Result := FALSE;
   str := aFormat;
   astr1 := ''; astr2 := ''; astr3 := '';

   str := GetValidStr3_1 (str, strs[0], '%s');
   str := GetValidStr3_1 (str, strs[1], '%s');
   strs[3] := GetValidStr3_1 (str, strs[2], '%s');

   str := abufferstr;

   if acnt = 0 then exit;

   str := GetValidStr3_2 (str, astr1, strs[0], strs[1]);
   if astr1 = '' then exit;
   if acnt = 1 then begin Result := TRUE; exit; end;
   str := GetValidStr3_2 (str, astr2, strs[1], strs[2]);
   if astr2 = '' then exit;
   if acnt = 2 then begin Result := TRUE; exit; end;
   str := GetValidStr3_2 (str, astr3, strs[2], strs[3]);
   if astr3 = '' then exit;
   if acnt = 3 then begin Result := TRUE; exit; end;
   Result := TRUE;
end;


function ImmGetContext; external 'imm32.dll' name 'ImmGetContext';
function ImmGetConversionStatus; external 'imm32.dll' name 'ImmGetConversionStatus';
function ImmSetConversionStatus; external 'imm32.dll' name 'ImmSetConversionStatus';
function ImmReleaseContext; external 'imm32.dll' name 'ImmReleaseContext';

function GetImeMode(Handle: HWND):DWORD;
var
  IMC: HIMC;
  Conv, Sent: DWORD;
begin
  Result := 0;
//  exit;                    //////////////////////

  IMC := ImmGetContext(Handle);
  if IMC = 0 then Exit;
  ImmGetConversionStatus(IMC, Conv, Sent);
  Result := Conv;
  ImmReleaseContext(Handle, IMC);
end;

procedure SetImeMode(Handle: HWnd; Mode: DWORD);
var
  IMC: HIMC;
  Conv, Sent: DWORD;
begin
//  exit;                     ////////////////////

  IMC := ImmGetContext(Handle);
  if IMC = 0 then Exit;

  ImmGetConversionStatus(IMC, Conv, Sent);
  Conv := Mode;
  ImmSetConversionStatus(IMC, Conv, Sent);
  ImmReleaseContext(Handle, IMC);
end;

procedure GetNearPosition (var xx, yy: integer);
var n: integer;
begin
   if (xx = 0) and (yy = 0) then begin xx := -1; yy := -1; exit; end;
   n := abs (xx);
   if n < abs (yy) then n := abs(yy);
   if (xx = n) and (yy = n) then begin xx := -n-1; yy := -n-1; exit; end;

   if yy = -n then begin
      if (xx + 1) <= n then begin
         xx := xx + 1;
      end else begin
         xx := -n;
         yy := yy + 1;
      end;
   end else begin
      if yy = n then begin
         xx := xx+1;
      end else begin
         if xx = -n then begin
            xx := n;
         end else begin
            xx := -n;
            yy := yy + 1;
         end;
      end;
   end;
end;


function  IpAddrToDWORD (aipaddr: string): DWORD;
var
   Temp: DWORD;
   str, rdstr: string;
   buf : array [0..3] of byte;
begin
   str := aipaddr;
   str := GetValidStr3 (str, rdstr, '.'); buf[3] := _StrToInt (rdstr);
   str := GetValidStr3 (str, rdstr, '.'); buf[2] := _StrToInt (rdstr);
   str := GetValidStr3 (str, rdstr, '.'); buf[1] := _StrToInt (rdstr);
   str := GetValidStr3 (str, rdstr, '.'); buf[0] := _StrToInt (rdstr);

   move (buf, Temp, 4);
   Result := Temp;
end;

function  DWORDToIpAddr (aParam: DWORD): string;
var buf : array [0..3] of byte;
begin
   move (aparam, buf, 4);
   Result := format ('%d.%d.%d.%d', [buf[3], buf[2], buf[1], buf[0]]);
end;

function  _StrToInt (str: string): Integer;
var
   i : integer;
   flag : Boolean;
begin

   if Length (str ) > 10 then str := '';
   if (Length (str) = 10) then begin
      if (word(str[1]) >= word('2')) and (word(str[2]) >= word('1')) then str := '';
   end;
   if (Length (str) = 1) and (str[1] = '-') then str := '';

   flag := TRUE;
   if str = '' then Result := 0
   else begin
      for i := 1 to Length(str) do if ((str[i] < char('0')) or (str[i] > char('9')))  and (str[i] <> '-') then flag := FALSE;
      for i := 2 to Length(str) do if str[i] = '-' then flag := FALSE;

      if flag then Result := StrToInt (str)
      else Result := 0;
   end;
end;


function GetSerialNumber : DWORD;
var
   VolumeName : array [0..255] of char;
   NameBuffer : array [0..255] of char;
   SerialNumber: dword;
   lpComponentLength : dword;
   lpFileSystemFlags : dword;
   bo : boolean;
begin
   bo := GetVolumeInformation ('c:\', VolumeName, 255, @SerialNumber,
    lpComponentLength,
    lpFileSystemFlags,
    NameBuffer, 255);

   if bo then Result := SerialNumber
   else Result := 0;
end;

procedure ChangeStr (var str: string; sour, dest:string);
var
   n: integer;
   tempstr:string;
begin
   if sour = '' then exit;
   if str = '' then exit;

   while TRUE do begin
      n := Pos (sour, str);
      if n > 0 then begin
         tempstr := Copy (str, 1, n-1);
         tempstr := tempstr + dest + Copy (str, n+Length (sour), Length(str) - (n+Length(sour)) +1);
         str := tempstr;
      end else break;
   end;
end;

function IsEngNumeric (str:string): Boolean;
var i : integer;
begin
   Result := TRUE;
   for i := 1 to Length(str) do begin
      if (str[i] >= 'A') and (str[i] <= 'Z') then continue;
      if (str[i] >= 'a') and (str[i] <= 'z') then continue;
      if (str[i] >= '0') and (str[i] <= '9') then continue;
      Result := FALSE;
      exit;
   end;
end;

function IsNumeric (str: string): Boolean;
var i : integer;
begin
	Result := TRUE;
   for i := 1 to Length(str) do
      if ((str[i] < '0') or (str[i] > '9')) then Result := FALSE;
end;

function IsEnglish (str: string): Boolean;
var i : integer;
begin
   Result := TRUE;
   for i := 1 to Length(str) do begin
      if str[i] < 'A' then Result := FALSE;
      if str[i] > 'z' then Result := FALSE;
      if (str[i] > 'Z') and (str[i] < 'a') then Result := FALSE;
   end;
end;

function StringListLoadFromMemory (var StringList: TStringList; apbuf:pbyte; asize: integer): Boolean;
var
   size: integer;
   str : string;
   pbuf, pb, pstart, plast : Pbyte;
begin
   Result := FALSE;
   size := asize;

   GetMem (pbuf, size+1);
   if pbuf = nil then exit;

   FillChar (pbuf^, size+1, 0);

   move (apbuf^, pbuf^, size);

   StringList.Clear;

   pb := pbuf;
   pstart := pbuf;
   plast := pbuf;
   inc (plast, size);

   while TRUE do begin
      if LongInt (pb) >= LongInt (plast) then break;
      if pb^ = $0D then begin
         pb^ := 0; inc (pb);
         str := StrPas (PCHAR(pstart));
         StringList.Add (str);
         if pb^ = $0A then inc (pb);
         pstart := pb;
      end;
      inc (pb);
   end;

   if LongInt (pstart) <= LongInt(plast) then begin
      str := StrPas (PCHAR(pstart));
      StringList.Add (str);
   end;
   FreeMem (pbuf, size+1);
   Result := TRUE;
end;

function  File_Size (const FName: string): Longint;
var f: file of Byte;
begin
   if FileExists (FName) then begin
     AssignFile(f, FName);
     Reset(f);
     Result  := FileSize(f);
     CloseFile(f);
   end else Result := -1;
end;

function  GetCPUStartHour: integer;
var d : DWORD;
begin
   d := TimeGetTime div 1000;
   Result := (d div 3600);
   if Result < 0 then Result := -Result;
end;

procedure _strPCopy (buf: PChar; str: string);
var i, len: integer;
begin
	len := Length (str);
	for i:=0 to len-1 do buf[i] := str[i+1];
   buf[len] := #0;
end;

function GetValidStr4(var Str: string; const Divider: string): string;
var
   n: integer;
begin
   n := Pos(Divider, Str);
   if n = 0 then begin
      Result := Str;
      Str := '';
   end else begin
      Result := Copy(Str, 1, n-1);
      Delete(Str, 1, n); 
   end;
end;

function GetValidStr3 (Str: string; var Dest: string; Divider: Char): string;
var
   i, cpos, Len: integer;
begin
	Len := Length(Str);
   cpos := 0;
   for i := 1 to len do begin
      if str[i] = divider then begin cpos := i; break; end;
   end;

   if cpos = 0 then begin Result := ''; Dest := str; exit; end;

   Dest := Copy (str, 1, cpos-1);
   Result := Copy (str, cpos+1, Len-cpos);
end;

function  GetValidStr2 (Str: string; var Dest: string; Divider1, Divider2: Char): string;
var
   i, cpos, cpos1, cpos2, Len: integer;
begin
	Len := Length(Str);
   cpos1 := 0;
   for i := 1 to len do begin
      if str[i] = divider1 then begin cpos1 := i; break; end;
   end;

   cpos2 := 0;
   for i := 1 to len do begin
      if str[i] = divider2 then begin cpos2 := i; break; end;
   end;

   cpos := 0;
   if cpos1 > 0 then cpos := cpos1;
   if cpos2 > 0 then if cpos > cpos2 then cpos := cpos2;

   if cpos = 0 then begin Result := ''; Dest := str; exit; end;


   Dest := Copy (str, 1, cpos-1);
   Result := Copy (str, cpos+1, Len-cpos);
end;

function  WhereIsChar (PCharCur, PCharCenter:PChar; var lpos, cpos, hpos:integer; GapValue:integer): Boolean;
var
   n : integer;
begin
   Result := FALSE;
   n := StrComp (pcharCur, pCharCenter);
   if n = 0 then exit; // 더이상검색안됨.
   if hpos - lpos <= GapValue then exit;     // 위치가 너무 가까움.

   Result := TRUE;

   if n > 0 then lpos := cpos
   else hpos := cpos;
   cpos := (lpos + hpos) div 2;
end;



///////////////////////////////////////////////
//           TWordString
///////////////////////////////////////////////

procedure SetWordString (var WordString: TWordString; str: string);
var len : Word;
begin
   len := Length (str);
   if (len >= WORDSTRINGSIZEALLOW) then begin
      len := WordSTRINGSIZEALLOW;
      str := Copy (str, 1, WordSTRINGSIZEALLOW);
   end;
   _StrPCopy (@WordString[2], str);
   WordString[0] := LoByte(len);
   WordString[1] := HiByte(len);
end;

function  GetWordString (var WordString: TWordString): string;
var len : Word;
begin
   Result := '';
   len := WordString[1]*256+WordString[0];
   if len > WORDSTRINGSIZEALLOW then exit;
   WordString[len+2] := 0;
   Result := StrPas (@WordString[2]);
end;

procedure MoveWordString (var Sour, Dest: TWordString);
begin
   move (sour, dest, PWORD (@Sour)^ + 2);
end;

function SizeofWordString (var WordString: TWordString): Word;
begin
   Result := WordString[1]*256 + WordString[0] + 2;
end;

function  GetWordStringDataPointer (var WordString: TWordString): Pointer;
begin
   Result := @WordString[2];
end;

procedure SetWordStringDataSize (var WordString: TWordString; dsize: word);
begin
   WordString[0] := LoByte(dsize);
   WordString[1] := HiByte(dsize);
end;

procedure InverseWordString (var WordString: TWordString);
var
   i, len: integer;
   b, h, l : byte;
begin
   len := WordString[1]*256+WordString[0];

   for i := 0 to len-1 do begin
      b := WordString[i+2];
      h := (b and $f0);
      l := (b and $0f);
      b := (h shr 4) + (l shl 4);
      WordString[i+2] := b;
   end;
end;


//////////////////////////////////////////
//            WString
//////////////////////////////////////////

procedure SetWSpChar (var wstr: WString; pc: pchar);
var len : word;
begin
   len := StrLen (pc);
   if len <= WSTRINGSIZEALLOW then begin
      move (pc^, wstr[2], len);
      PWORD (@wstr)^ := len;
      wstr[PWORD(@wstr)^+2] := 0;
   end else ClearWs (wstr);
end;

procedure GetWSpChar (var wstr: WString; pret: pchar);
begin
   pret^ := char (0);
   if PWORD(@wstr)^ <= WSTRINGSIZEALLOW then begin
      wstr[PWORD(@wstr)^+2] := 0;
      move (wstr[2], pret^, PWORD(@wstr)^+1); // +1 은 문자열마지막 0 까지 이동
   end else begin
   end;
end;

procedure SetWSString (var wstr: WString; str: string);
var len : word;
begin
   len := Length (str);
   if len <= WSTRINGSIZEALLOW then begin
      _StrPCopy (@wstr[2], str);
      PWORD (@wstr)^ := len;
      wstr[PWORD(@wstr)^+2] := 0;
   end else ClearWs (wstr);
end;

function  GetWSString (var wstr: WString): string;
begin
   Result := '';
   if PWORD(@wstr)^ <= WSTRINGSIZEALLOW then begin
      wstr[PWORD(@wstr)^+2] := 0;
      Result := StrPas (@wstr[2]);
   end else begin
   end;
end;

procedure MoveWS (var Sour, Dest: WString);
begin
   if PWORD(@Sour)^ <= WSTRINGSIZEALLOW then
      move (sour, dest, PWORD (@Sour)^ + 2+1);
end;

procedure ClearWS (var wstr: WString);
begin
   PWORD (@wstr)^ := 0;
   wstr[2] := 0;
end;

function  SizeofWS (var wstr: WString): Word;
begin
   Result := PWORD(@wstr)^;
end;

function CompareWS (var S1, S2: WString): integer;
var
   i, w : word;
   pb1, pb2: pbyte;
begin
   Result := 0;
   w := PWORD(@S1)^;
   if w < PWORD(@S2)^ then w := PWORD(@S2)^;
   pb1 := @S1[2]; pb2 := @S2[2];
   for i := 0 to w -1 do begin
      Result := pb1^ - pb2^;
      if Result <> 0 then exit;
      inc (pb1); inc (pb2);
   end;
end;

procedure WScat (var dest, Sour: WString);
begin
   if (PWORD(@Dest)^ + PWORD(@Sour)^) <= WSTRINGSIZEALLOW then begin
      move (sour[2], dest[2+PWORD(@Dest)^], PWORD(@Sour)^);
      PWORD(@Dest)^ := PWORD(@Dest)^ + PWORD(@Sour)^;
      dest[PWORD(@dest)^+2] := 0;
   end;
end;

procedure IntToWS (aInt: integer; var wstr: WString);
var
   n, temp: integer;
   bominus : Boolean;
   pb : pbyte;
begin
   if aInt < 0 then bominus := TRUE
   else bominus := FALSE;
   if bominus then aInt := -aInt;

   n := 1;
   if aInt >= 10          then n := 10;
   if aInt >= 100         then n := 100;
   if aInt >= 1000        then n := 1000;
   if aInt >= 10000       then n := 10000;
   if aInt >= 100000      then n := 100000;
   if aInt >= 1000000     then n := 1000000;
   if aInt >= 10000000    then n := 10000000;
   if aInt >= 100000000   then n := 100000000;
   if aInt >= 1000000000  then n := 1000000000;

   pb := @wstr[2];
   if bominus then begin pb^ := byte('-'); inc (pb); end;

   while TRUE do begin
      if n <= 1 then begin
         pb^ := byte (byte('0')+aInt); inc (pb);
         pb^ := 0;
         break;
      end;

      temp := aInt div n;
      pb^ := byte (byte('0')+temp); inc (pb);
      aInt := aInt mod n;
      n := n div 10;
   end;
   PWORD (@wstr)^ := StrLen (@wstr[2]);
end;

function  WsToInt (var wstr: WString): integer;
var
   i, n, cur : integer;
   pb : pbyte;
begin
   Result := 0;
   n := PWORD(@wstr)^;
   if (n > 10) or (n = 0) then exit;
   if (n = 1) and (wstr[2] = byte('-')) then exit;

   cur := 1;

   if wstr[2] = byte ('-') then begin
      pb := @wstr[2+1];
      inc (pb, n-1-1);
      for i := 0 to n-1-1 do begin
         if wstr[2+1+i] = byte('-') then exit;
         if (wstr[2+1+i] < byte('0')) or (wstr[2+1+i] > byte('9'))  then exit;
         Result := Result + cur * (pb^ - byte('0'));
         dec (pb);
         cur := cur * 10;
      end;
      Result := -Result;
   end else begin
      pb := @wstr[2];
      inc (pb, n-1);
      for i := 0 to n-1 do begin
         if wstr[2+i] = byte('-') then exit;
         if (wstr[2+i] < byte('0')) or (wstr[2+i] > byte('9'))  then exit;

         Result := Result + cur * (pb^ - byte('0'));
         dec (pb);
         cur := cur * 10;
      end;
   end;
end;

procedure CopyWS (var sour: WString; Start, Len: integer; var rws: WString);
begin
   PWORD (@rws)^ := len;
   move (sour[2+Start], rws[2], len);
   rws[2+PWORD (@rws)^] := 0;
end;

procedure GetValidWS3 (var sour, dest: WString; Divider: Char; var rws: WString);
var i, cpos, Len: integer;
begin
	Len := SizeofWS(sour);
   cpos := 0;
   for i := 0 to len-1 do if Sour[2+i] = byte(divider) then begin cpos := i; break; end;

   if cpos = 0 then begin ClearWS(rws); MoveWS (Sour, Dest); exit; end;

   CopyWS (sour, 0, cpos-2, dest);
   CopyWS (sour, cpos, Len-cpos-1, rws);
end;

function  PosWS (astr: string; var wstr: WString): integer;
var
   i, j, n, slen: integer;
   flag : Boolean;
begin
   Result := -1;
   n := PWORD(@wstr)^;
   slen := Length (astr);
   if n = 0 then exit;
   if slen = 0 then exit;

   for j := 0 to n -1-slen+1 do begin
      flag := TRUE;
      for i := 0 to slen-1 do
         if wstr[2+j+i] <> byte (astr[i+1]) then begin flag := FALSE; break; end;
      if flag then begin Result := j; exit; end;
   end;
end;

procedure InverseWString (var wstr: WString);
var
   i, len: integer;
   b, h, l : byte;
begin
   len := PWORD(@wstr)^;
   for i := 0 to len-1 do begin
      b := wstr[i+2];
      h := (b and $f0);
      l := (b and $0f);
      b := (h shr 4) + (l shl 4);
      wstr[i+2] := b;
   end;
end;

function Get10000To100 (avalue: integer): string;
var
   n : integer;
   str : string;
begin
   str := InttoStr (avalue div 100) + '.';
   n := avalue mod 100;
   if n >= 10 then str := str + IntToStr (n)
   else str := str + '0'+InttoStr(n);

   Result := str;
end;

end.








