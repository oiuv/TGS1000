unit uAnsTick;

interface

uses
	Windows, SysUtils, Classes, mmsystem;


   function ProgramHour: integer;
   function mmTickSetAddValue (avalue: integer): Boolean;

var
   mmAnsTick : integer = 0;

implementation

var
   mytimerid : integer;

   mmAnsTickAddValue : integer = 1;

function ProgramHour: integer;
begin
   Result := mmAnsTick div mmAnsTickAddValue div 360000;
end;

procedure mmTickTimerProc( uTimerID, uMessage: UINT; dwUser, dw1, dw2: DWORD) stdcall;
begin
   mmAnsTick := mmAnsTick + mmAnsTickAddValue;
end;

function  mmTickSetAddValue (avalue: integer): Boolean;
begin
   Result := TRUE;
   if avalue < 1 then begin Result := FALSE; exit; end;
   if avalue > 100 then begin Result := FALSE; exit; end;
   mmAnsTickAddValue := avalue;
end;

Initialization
begin
   mytimerid := timeSetEvent(10, 10, @mmTickTimerProc, 1000,  TIME_PERIODIC);
end;

Finalization
begin
   timeKillEvent(mytimerid);
end;

{
uses
	Windows, SysUtils, Classes, mmsystem;

 
   function ProgramHour: integer;
   function mmTickSetAddValue (avalue: integer): Boolean;
   function mmAnsTick: integer;

   procedure mmAnsTickMark;
   function  mmAnsTickisflowMark: Boolean;

implementation

var
   LastTick : DWORD = 0;
   CurMod : DWORD = 0;
   mmAnsTickAddValue : integer = 1;
   CurAnsTick : integer = 0;

   MarkTick : DWORD = 0;

procedure mmAnsTickMark;
begin
   MarkTick := TimeGetTime;
end;

function  mmAnsTickisflowMark: Boolean;
begin
   if MarkTick <> TimeGetTime then Result := TRUE
   else Result := FALSE;
end;

function mmAnsTick: integer;
var
   inctick : DWORD;
   CurTick : DWORD;
begin
   CurTick := TimeGetTime;
   if CurTick >= LastTick then inctick := CurTick - LastTick
   else inctick := 0;
   LastTick := CurTick;

   inctick := inctick + CurMod;
   while TRUE do begin
      if inctick < 10 then break;
      CurAnsTick := CurAnsTick + mmAnsTickAddValue;
      inctick := incTick - 10;
   end;
   CurMod := inctick;

   Result := CurAnsTick;
end;

function ProgramHour: integer;
begin
   Result := mmAnsTick div mmAnsTickAddValue div 360000;
end;

function  mmTickSetAddValue (avalue: integer): Boolean;
begin
   Result := TRUE;
   if avalue < 1 then begin Result := FALSE; exit; end;
   if avalue > 100 then begin Result := FALSE; exit; end;
   mmAnsTickAddValue := avalue;
end;

Initialization
begin
   LastTick := TimeGetTime;
end;

Finalization
begin
end;
}


end.


