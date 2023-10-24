unit uCharCheck;

interface

uses
   Windows, Classes, SysUtils, DefType;

procedure InitCodeTable(value: integer);
function CheckChar(wch: WideChar): integer;
function CheckString(str: PChar): integer;
function CheckPascalString(aStr : String): integer;

implementation

var
   CodeTable: integer = 0; // 0이면 한글, 1이면 대만, 2이면 중국

procedure InitCodeTable(value: integer);
begin
   CodeTable := value;
end;

function IsKorean(HighByte, LowByte: Byte): integer;
begin
   Result := 0;
   if (HighByte in [$B0..$C8]) and (LowByte in [$A1..$FE]) then
      Result := 2;
end;

function IsTaiwan(HighByte, LowByte: Byte): integer;
begin
   Result := 2;

   if (HighByte in [$A4..$C6, $C9..$F9]) and (LowByte in [$40..$7E]) then
      exit;

   if (HighByte in [$A4..$C5, $C9..$F8]) and (LowByte in [$A1..$FE]) then
      exit;

   if (HighByte = $F9) and (LowByte in [$A1..$DC]) then exit;

   Result := 0;
end;

function IsChina(HighByte, LowByte: Byte): integer;
begin
   Result := 2;

   case HighByte of
      $81..$A0, $B0..$D6, $D8..$F7:
         if LowByte in [$40..$7E, $80..$FE] then exit;
      $AA..$AF, $F8..$FE:
         if LowByte in [$40..$7E, $80..$A0] then exit;
      $D7:
         if LowByte in [$40..$7E, $80..$F9] then exit;
   end;

   Result := 0;
end;

function CheckChar(wch: WideChar): integer;
var
   str: string;
   HighByte, LowByte: Byte;
begin
   Result := 0;

   if IsCharAlphaNumericW(wch) then begin
      if Ord(wch) < 255 then
         Result := 1  // 영문자 또는 숫자
      else begin
         str := wch;
         //완성형 한글체크.
         HighByte := Ord(str[1]);
         LowByte := Ord(str[2]);
         case CodeTable of
         0: Result := IsKorean(HighByte, LowByte);
         1: Result := IsTaiwan(HighByte, LowByte);
         2: Result := IsChina(HighByte, LowByte);
         end;
      end;
   end;
end;

function CheckString(str: PChar): integer;
var
   wstr: WideString;
   i: integer;
begin
   wstr := str;

   for i := 1 to Length(wstr) do begin
      Result := CheckChar(wstr[i]);
      if Result = 0 then exit;
   end;

   Result := 1;
end;

function CheckPascalString (aStr : String) : Integer;
var
   szStr : array [0..256] of Char;
begin
   if Length (aStr) > 255 then aStr := Copy (aStr, 1, 255); 
   StrPCopy (@szStr, aStr);
   Result := CheckString (@szStr);
end;

initialization
begin
   Case NATION_VERSION of
      NATION_KOREA : InitCodeTable (0);
      NATION_TAIWAN, NATION_TAIWAN_TEST : InitCodeTable (1);
      NATION_CHINA_1, NATION_CHINA_1_TEST : InitCodeTable (2);
   end;
end;

finalization
begin
end;

end.
