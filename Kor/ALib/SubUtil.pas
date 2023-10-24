unit SubUtil;

interface


uses
	Windows, SysUtils, Classes, deftype, math;


procedure GetNextPosition (dir: word; var x, y: word);
procedure GetOldPosition (dir: word; var x, y: word);
function  GetNextDirection ( sx, sy, ex, ey: word): word;
function  GetLeftDirection ( key:word): word;
function  GetRightDirection ( key:word): word;
function  GetViewDirection (sx, sy, dx, dy: word): word;

function  GetCellLength (sx, sy, dx, dy: word): word;
function  GetLargeLength (sx, sy, dx, dy: word): word;

function  GetDegDirection (adeg: word): word;
procedure GetDegNextPosition ( deg, speed: word; var DrawX, DrawY: integer);
function GetDeg ( cx, cy, tx, ty: integer): word;
function GetNewDeg (deg, tdeg, turn: word): word;



   function  GetNewItemId:LongInt;
   function  GetNewMonsterId:LongInt;
   function  GetNewUserId:LongInt;
   function GetNewCallMonsterId:LongInt;

   function  isUserId ( Id:LongInt): Boolean;
   function  isMonsterId ( Id:LongInt): Boolean;
   function  isObjectItemId ( Id:LongInt): Boolean;
   function  isCallMonsterId ( Id:LongInt): Boolean;

var
   NormalIdCount : LongInt = STARTNEWID;
   
implementation

function  GetDegDirection (adeg: word): word;
begin
   Result := 0;
   if adeg >= 360 then exit;

   adeg := (adeg*10 + 225) div 10;          // deg + 22.5
   Result := adeg div 45;                     // 8 dir;
   if Result = 8 then Result := 0;
end;

function GetNewDeg (deg, tdeg, turn: word): word;
var
   t1: integer;
   ret : integer;
begin
   ret := deg;
   Result := ret;
   if deg = tdeg then exit;

   t1 := deg - tdeg + 180;
   while TRUE do begin if t1 < 0 then t1 := t1 + 360 else break; end;
   while TRUE do begin if t1 >= 360 then t1 := t1 - 360 else break; end;

   if t1 < 180 then begin
      if t1 + turn > 180 then ret := tdeg
      else ret := deg + turn;
   end else begin
      if t1 - turn < 180 then ret := tdeg
      else ret := deg - turn;
   end;

   while TRUE do begin if ret < 0 then ret := ret + 360 else break; end;
   while TRUE do begin if ret >= 360 then ret := ret - 360 else break; end;
   Result := ret;
end;

function GetDeg ( cx, cy, tx, ty: integer): word;
var
   xx, yy, val: integer;
   r : real;
begin
   xx := cx - tx;
   yy := cy - ty;

   r := ArcTan2 (yy, xx);

   r := r - PI / 2;

   val :=  Round (r * 180 / PI);
   while TRUE do begin
      if val < 0 then val := val + 360
      else break;
   end;

   while TRUE do begin
      if val >= 360 then val := val - 360
      else break;
   end;

   Result := val;
end;

procedure GetDegNextPosition ( deg, speed: word; var DrawX, DrawY: integer);
var
   dx, dy: integer;
   r : real;
begin
   r := PI * deg / 180 - PI / 2;

   dy := Round (sin (r) * speed);
   dx := Round (cos (r) * speed);

   Drawx := DrawX + dx;
   DrawY := DrawY + dy;
end;

function GetNewUserId:LongInt;
var id : LongInt;
begin
   id := NormalIDCount;
   Result := id;
   NormalIDCount := NormalIDCount + 4;
end;

function GetNewMonsterId:LongInt;
var id : LongInt;
begin
   id := NormalIDCount+1;
   Result := id;
   NormalIDCount := NormalIDCount + 4;
end;

function GetNewItemId:LongInt;
var id : LongInt;
begin
   id := NormalIDCount+2;
   Result := id;
   NormalIDCount := NormalIDCount + 4;
end;

function GetNewCallMonsterId:LongInt;
var id : LongInt;
begin
   id := NormalIDCount+3;
   Result := id;
   NormalIDCount := NormalIDCount + 4;
end;

function isUserId( Id:LongInt): Boolean;
var Temp : LongInt;
begin
   Temp := Id-STARTNEWID;
   if (Temp mod 4) = 0 then Result := TRUE
   else Result := FALSE;
end;

function isMonsterId( Id:LongInt): Boolean;
var Temp : LongInt;
begin
   Temp := Id-STARTNEWID;
   if (Temp mod 4) = 1 then Result := TRUE
   else Result := FALSE;
end;

function isObjectItemId( Id:LongInt): Boolean;
var Temp : LongInt;
begin
   Temp := Id-STARTNEWID;
   if (Temp mod 4) = 2 then Result := TRUE
   else Result := FALSE;
end;

function isCallMonsterId( Id:LongInt): Boolean;
var Temp : LongInt;
begin
   Temp := Id-STARTNEWID;
   if (Temp mod 4) = 3 then Result := TRUE
   else Result := FALSE;
end;

procedure GetNextPosition (dir: word; var x, y: word);
begin
   case dir of
      DR_0 : y := y - 1;
      DR_1 : begin x := x + 1; y := y - 1; end;
      DR_2 : x := x + 1;
      DR_3 : begin x := x + 1; y := y +1; end;
      DR_4 : y := y + 1;
      DR_5 : begin x := x-1; y := y + 1; end;
      DR_6 : x := x - 1;
      DR_7 : begin x := x - 1; y := y-1; end;
   end;
end;

procedure GetOldPosition (dir: word; var x, y: word);
begin
   case dir of
      DR_0 : y := y + 1;
      DR_1 : begin x := x - 1; y := y + 1; end;
      DR_2 : x := x - 1;
      DR_3 : begin x := x - 1; y := y - 1; end;
      DR_4 : y := y - 1;
      DR_5 : begin x := x + 1; y := y - 1; end;
      DR_6 : x := x + 1;
      DR_7 : begin x := x + 1; y := y + 1; end;
   end;
end;

function  GetNextDirection ( sx, sy, ex, ey: word): word;
var
   flagx, flagy: integer;
begin
   Result := DR_DONTMOVE;
   if sx < eX then flagx := 1
   else if sx = ex then flagx := 0
   else flagx := -1;

   if sy < ey then flagy := 1
   else if sy = ey then flagy := 0
   else flagy := -1;

   if (flagx = 0)  and (flagy = -1) then Result := DR_0;
   if (flagx = 1)  and (flagy = -1) then Result := DR_1;
   if (flagx = 1)  and (flagy = 0)  then Result := DR_2;
   if (flagx = 1)  and (flagy = 1)  then Result := DR_3;
   if (flagx = 0)  and (flagy = 1)  then Result := DR_4;
   if (flagx = -1) and (flagy = 1)  then Result := DR_5;
   if (flagx = -1) and (flagy = 0)  then Result := DR_6;
   if (flagx = -1) and (flagy = -1) then Result := DR_7;
end;

function  GetLargeLength (sx, sy, dx, dy: word): word;
var
  xx, yy:integer;
begin
   if sx > dx then xx := sx - dx
   else xx := dx - sx;

   if sy > dy then yy := sy - dy
   else yy := dy - sy;

   if xx > yy then Result := xx
   else Result := yy;
end;

function  GetCellLength (sx, sy, dx, dy: word): word;
var
   xx, yy, n: integer;
begin
   Result := 1000;

   if sx > dx then xx := sx - dx
   else xx := dx - sx;
   if sy > dy then yy := sy - dy
   else yy := dy - sy;

   if xx > 255 then exit;
   if yy > 255 then exit;

   n := xx * xx + yy * yy;
   Result := Round ( SQRT ( n) );
end;

function GetViewDirection (sx, sy, dx, dy: word): word;
var
   r, t : Real;
   xx, yy: integer;
begin
   Result := DR_DONTMOVE;
   xx := dx-sx; yy := dy-sy;

   r := ArcTan2 (yy, xx);

   if r = 0 then begin
      if (xx=0) and (yy=0) then Result := DR_4;
      if (xx=0) and (sy<dy) then Result := DR_4;
      if (xx=0) and (sy>dy) then Result := DR_0;
      if (yy=0) and (sx<dx) then Result := DR_2;
      if (yy=0) and (sx>dx) then Result := DR_6;
      exit;
   end;

   t := -4*PI/4;
   if (r<=t+PI/8) and (r>(t+-PI/8)) then Result := DR_6;

   t := -3*PI/4;
   if (r<=t+PI/8) and (r>(t+-PI/8)) then Result := DR_7;

   t := -2*PI/4;
   if (r<=t+PI/8) and (r>(t+-PI/8)) then Result := DR_0;

   t := -1*PI/4;
   if (r<=t+PI/8) and (r>(t+-PI/8)) then Result := DR_1;

   t := 0*PI/4;
   if (r<=t+PI/8) and (r>(t+-PI/8)) then Result := DR_2;

   t := 1*PI/4;
   if (r<=t+PI/8) and (r>(t+-PI/8)) then Result := DR_3;

   t := 2*PI/4;
   if (r<=t+PI/8) and (r>(t+-PI/8)) then Result := DR_4;

   t := 3*PI/4;
   if (r<=t+PI/8) and (r>(t+-PI/8)) then Result := DR_5;

   t := 4*PI/4;
   if (r<=t+PI/8) and (r>(t+-PI/8)) then Result := DR_6;
end;

function  GetRightDirection ( key:word): word;
begin
   Result := DR_DONTMOVE;
   case key of
      DR_0: Result := DR_1;
      DR_1: Result := DR_2;
      DR_2: Result := DR_3;
      DR_3: Result := DR_4;
      DR_4: Result := DR_5;
      DR_5: Result := DR_6;
      DR_6: Result := DR_7;
      DR_7: Result := DR_0;
   end;
end;

function  GetLeftDirection ( key:word): word;
begin
   Result := DR_DONTMOVE;
   case key of
      DR_0: Result := DR_7;
      DR_1: Result := DR_0;
      DR_2: Result := DR_1;
      DR_3: Result := DR_2;
      DR_4: Result := DR_3;
      DR_5: Result := DR_4;
      DR_6: Result := DR_5;
      DR_7: Result := DR_6;
   end;
end;



end.
