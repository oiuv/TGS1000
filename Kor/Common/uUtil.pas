unit uUtil;

interface

uses
   Windows, Classes, SysUtils, DefType, AUtil32;

procedure Reverse4Bit (aComData : PTComData);

{
procedure SetWordString (var WordString : TWordString; aStr: String);
function  GetWordString (var WordString : TWordString): String;
function  SizeofWordString (var WordString : TWordString): Word;
}

function  GetTokenStr (Str: String; var Dest: String; Divider: Char): String;
function _ToSpace (aStr : String) : String;
function _ToSpaceForTaiwan (aStr : String) : String;

function _StrToInt (aStr : String) : Integer;
function  TestStr (aStr : PChar; aSize : Integer) : Boolean;

function GetDateByStr (aDateTime : TDateTime) : String;
function GetTimeByStr (aDateTime : TDateTime) : String;
function GetFullTimeByStr (aDateTime : TDateTime) : String;

function GetDateByCode (aDateTime : TDateTime) : String;
function GetTimeByCode (aDateTime : TDateTime) : String;
function GetFullTimeByCode (aDateTime : TDateTime) : String;

function GetFixedCode (aValue : Integer) : String;
function GetStringLength(AText: string): Integer;
function GetCurrentChar(atext: string; var curPos, rValue: integer): Boolean;


procedure GetDateTimeDiff (Date1, Date2 : TDateTime; var aDiffDay : Integer; var aDiffSec : Integer);

implementation

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

function  TestStr (aStr : PChar; aSize : Integer) : Boolean;
var
   i : Integer;
begin
   Result := false;

   for i := 0 to aSize - 1 do begin
      if (aStr + i)^ = Char (0) then begin
         Result := true;
         exit;
      end;
   end;
end;

function _StrToInt (aStr : String) : Integer;
begin
   Result := 0;

   if Trim (aStr) = '' then exit;
   try
      Result := StrToInt (aStr);
   except
   end;
end;

function _ToSpace (aStr : String) : String;
var
   i : integer;
begin
   Result := '';
   for i := 1 to Length(aStr) do begin
      if aStr[i] = '_' then begin
         aStr[i] := ' ';
      end;
   end;
   Result := aStr;
end;

function _ToSpaceForTaiwan (aStr : String) : String;
var
   i : integer;
begin
   Result := '';
   for i := 1 to Length(aStr) do begin
      if aStr[i] = '|' then begin
         aStr[i] := ' ';
      end;
   end;
   Result := aStr;
end;

function GetTokenStr (Str: String; var Dest: String; Divider: Char): String;
var
   i, cpos, Len : Integer;
begin
	Len := Length (Str);

   cpos := 0;
   for i := 1 to len do begin
      if str[i] = divider then begin cpos := i; break; end;
   end;

   if cpos = 0 then begin
      Result := '';
      Dest := str;
      exit;
   end;

   Dest := Copy (str, 1, cpos - 1);
   Result := Copy (str, cpos + 1, Len - cpos);
end;

procedure Reverse4Bit (aComData : PTComData);
var
   i : Integer;
   code, highnb, lownb : byte;
begin
   for i := 0 to aComData^.Size - 1 do begin
      code := aComData^.Data [i];
      highnb := code and $F0;
      lownb := code and $0F;
      highnb := highnb shr 4;
      lownb := lownb shl 4;
      aComData^.Data [i] := highnb + lownb;
   end;
end;

{
procedure SetWordString (var WordString : TWordString; aStr: string);
var
   len : Word;
begin
   len := Length (aStr);
   if (len >= WORDSTRINGSIZEALLOW) then begin
      len := WORDSTRINGSIZEALLOW;
      aStr := Copy (aStr, 1, WORDSTRINGSIZEALLOW);
   end;
   StrPCopy (@WordString[2], aStr);
   WordString[0] := LoByte(len);
   WordString[1] := HiByte(len);
end;

function  GetWordString (var WordString : TWordString) : String;
var
   len : Word;
begin
   Result := '';
   len := WordString[1] * 256 + WordString[0];
   if len > WORDSTRINGSIZEALLOW then exit;
   WordString[len + 2] := 0;
   
   Result := StrPas (@WordString[2]);
end;

function SizeofWordString (var WordString: TWordString) : Word;
begin
   Result := WordString[1] * 256 + WordString[0] + 2;
end;
}

function GetDateByStr (aDateTime : TDateTime) : String;
var
   nYear, nMonth, nDay : Word;
   nHour, nMin, nSec : Word;
   Str : String;
begin
   DecodeDate (aDateTime, nYear, nMonth, nDay);
   Str := IntToStr (nYear) + '-';
   if nMonth < 10 then Str := Str + '0';
   Str := Str + IntToStr (nMonth) + '-';
   if nDay < 10 then Str := Str + '0';
   Str := Str + IntToStr (nDay);

   Result := STr;
end;

function GetTimeByStr (aDateTime : TDateTime) : String;
var
   nHour, nMin, nSec, nMSec : Word;
   Str : String;
begin
   DecodeTime (aDateTime, nHour, nMin, nSec, nMSec);

   Str := '';
   if nHour < 10 then Str := Str + '0';
   Str := Str + IntToStr (nHour) + ':';
   if nMin < 10 then Str := Str + '0';
   Str := Str + IntToStr (nMin) + ':';
   if nSec < 10 then Str := Str + '0';
   Str := Str + IntToStr (nSec);

   Result := Str;
end;

function GetFullTimeByStr (aDateTime : TDateTime) : String;
var
   nHour, nMin, nSec, nMSec : Word;
   Str : String;
begin
   DecodeTime (aDateTime, nHour, nMin, nSec, nMSec);

   Str := '';
   if nHour < 10 then Str := Str + '0';
   Str := Str + IntToStr (nHour) + ':';
   if nMin < 10 then Str := Str + '0';
   Str := Str + IntToStr (nMin) + ':';
   if nSec < 10 then Str := Str + '0';
   Str := Str + IntToStr (nSec) + ':';
   if nMSec < 10 then Str := Str + '00'
   else if nMSec < 100 then Str := Str + '0';
   Str := Str + IntToStr (nMSec);

   Result := Str;
end;

function GetDateByCode (aDateTime : TDateTime) : String;
var
   nYear, nMonth, nDay : Word;
   Str : String;
begin
   DecodeDate (aDateTime, nYear, nMonth, nDay);
   Str := IntToStr (nYear);
   if nMonth < 10 then Str := Str + '0';
   Str := Str + IntToStr (nMonth);
   if nDay < 10 then Str := Str + '0';
   Str := Str + IntToStr (nDay);

   Result := STr;
end;

function GetTimeByCode (aDateTime : TDateTime) : String;
var
   nHour, nMin, nSec, nMSec : Word;
   Str : String;
begin
   DecodeTime (aDateTime, nHour, nMin, nSec, nMSec);

   Str := '';
   if nHour < 10 then Str := Str + '0';
   Str := Str + IntToStr (nHour);
   if nMin < 10 then Str := Str + '0';
   Str := Str + IntToStr (nMin);
   if nSec < 10 then Str := Str + '0';
   Str := Str + IntToStr (nSec);

   Result := Str;
end;

function GetFullTimeByCode (aDateTime : TDateTime) : String;
var
   nHour, nMin, nSec, nMSec : Word;
   Str : String;
begin
   DecodeTime (aDateTime, nHour, nMin, nSec, nMSec);

   Str := '';
   if nHour < 10 then Str := Str + '0';
   Str := Str + IntToStr (nHour);
   if nMin < 10 then Str := Str + '0';
   Str := Str + IntToStr (nMin);
   if nSec < 10 then Str := Str + '0';
   Str := Str + IntToStr (nSec);
   if nMSec < 10 then Str := Str + '00'
   else if nMSec < 100 then Str := Str + '0';
   Str := Str + IntToStr (nMSec);

   Result := Str;
end;

function GetFixedCode (aValue : Integer) : String;
var
   Str : String;
begin
   if (aValue < 0) or (aValue >= 1000) then begin
      Result := '000';
      exit;
   end;

   Str := '';
   if aValue < 10 then Str := Str + '00'
   else if aValue < 100 then Str := Str + '0';
   Str := Str + IntToStr (aValue);

   Result := Str;
end;

procedure GetDateTimeDiff (Date1, Date2 : TDateTime; var aDiffDay : Integer; var aDiffSec : Integer);
var
   Diff : TDateTime;
   nHour, nMin, nSec, nMSec : Word;
begin
   aDiffDay := 0;
   aDiffSec := 0;

   Diff := Date2 - Date1;

   aDiffDay := Round (Diff);

   DecodeTime (Diff, nHour, nMin, nSec, nMSec);
   
   aDiffSec := (nHour * 3600) + (nMin * 60) + nSec;
end;

end.
