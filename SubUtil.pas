unit SubUtil;

interface


uses
	Windows, SysUtils, Classes, deftype, math;

function Check8Hit (adir, ax, ay, myx, myy: integer): integer;
function Check5Hit (adir, ax, ay, myx, myy: integer): integer;
function Check4Hit (adir, ax, ay, myx, myy: integer): boolean;   

procedure GetNextPosition (dir: word; var x, y: word);
procedure GetOldPosition (dir: word; var x, y: word);
function  GetNextDirection ( sx, sy, ex, ey: word): word;
function  GetLeftDirection ( key:word): word;
function  GetRightDirection ( key:word): word;
function  GetViewDirection (sx, sy, dx, dy: word): word;
function  GetBackDirection (sx, sy, dx, dy: word): word;
procedure GetOppositeDirection (sx, sy, dx, dy: word; var tx, ty : word);
procedure GetOppositePosition (sx, sy, dx, dy: word; var tx, ty : word);
procedure GetPushPosition (var x,y : word; length : word; dir : word);

function  GetCellLength (sx, sy, dx, dy: word): word;
function  GetLargeLength (sx, sy, dx, dy: word): word;
function  CheckGuardNearPos (var SenderInfo : TBasicData; sx, sy, sdir : word; var dx, dy : Word): Boolean;
function  CheckGuardNearPos2 (var SenderInfo : TBasicData; sx, sy, sdir : word; var dx, dy : Word; afunc : byte): Boolean;
function isWindOfHandGuard (var SenderInfo : TBasicData; sx, sy, dx, dy : word; MinRange,MaxRange : Integer; var aDis: Integer): Boolean;
function  GetDegDirection (adeg: word): word;
procedure GetDegNextPosition ( deg, speed: word; var DrawX, DrawY: integer);
function GetDeg ( cx, cy, tx, ty: integer): word;
function GetNewDeg (deg, tdeg, turn: word): word;

function CheckInArea (x, y : word; sx, sy : word; w : Integer) : Boolean;

   function  GetNewItemId:LongInt;
   function  GetNewMonsterId:LongInt;
   function  GetNewUserId:LongInt;
   function GetNewCallMonsterId:LongInt;
   function GetNewStaticItemId:LongInt;
   function GetNewDynamicObjectID:LongInt;

   function  isUserId ( Id:LongInt): Boolean;
   function  isMonsterId ( Id:LongInt): Boolean;
   function  isObjectItemId ( Id:LongInt): Boolean;
   function  isCallMonsterId ( Id:LongInt): Boolean;
   function  isStaticItemId ( Id:LongInt): Boolean;
   function  isDynamicObjectId ( Id:LongInt): Boolean;

const
   NormalIDMax = 10;

var
   NormalIdCount0 : LongInt = STARTNEWID + 0;
   NormalIdCount1 : LongInt = STARTNEWID + 1;
   NormalIdCount2 : LongInt = STARTNEWID + 2;
   NormalIdCount3 : LongInt = STARTNEWID + 3;
   NormalIdCount4 : LongInt = STARTNEWID + 4;
   NormalIdCount5 : LongInt = STARTNEWID + 5;
   NormalIdCount6 : LongInt = STARTNEWID + 6;
   NormalIdCount7 : LongInt = STARTNEWID + 7;
   NormalIdCount8 : LongInt = STARTNEWID + 8;
   NormalIdCount9 : LongInt = STARTNEWID + 9;

implementation

uses
   svMain;

function Check4Hit (adir, ax, ay, myx, myy: integer): boolean;
var
   xx, yy : integer;
   n : integer;
begin
   Result := false;
   n := adir mod 2;
   case n of
      0:
         begin
            //ºÏ
            xx := ax; yy := ay-1;
            if (myx=xx) and (myy=yy) then begin
               Result := true;
               exit;
            end;


            //µ¿
            xx := ax+1; yy := ay;
            if (myx=xx) and (myy=yy) then begin
               Result := true;
               exit;
            end;

            //¼­
            xx := ax-1; yy := ay;
            if (myx=xx) and (myy=yy) then begin
               Result := true;
               exit;
            end;

            //³²
            xx := ax; yy := ay+1;
            if (myx=xx) and (myy=yy) then begin
               Result := true;
               exit;
            end;

         end;
      1:
         begin
            //ºÏ
            xx := ax+1; yy := ay+1;
            if (myx=xx) and (myy=yy) then begin
               Result := true;
               exit;
            end;

            //µ¿
            xx := ax +1; yy := ay+1;
            if (myx=xx) and (myy=yy) then begin
               Result := true;
               exit;
            end;

            //¼­
            xx := ax-1; yy := ay-1;
            if (myx=xx) and (myy=yy) then begin
               Result := true;
               exit;
            end;

            //³²
            xx := ax-1; yy := ay+1;
            if (myx=xx) and (myy=yy) then begin
               Result := true;
               exit;
            end;
         end;
   end;
end;

function Check5Hit (adir, ax, ay, myx, myy: integer): integer;
var
   tempdir : byte;
   xx, yy: word;
begin
   Result := 0;

   tempdir := adir;
   xx := ax; yy := ay;
   GetNextPosition (tempdir, xx, yy);
   if (myx = xx) and (myy = yy) then begin Result := 100; exit; end;   //99

   tempdir := adir;
   tempdir := GetRightDirection (tempdir);
   xx := ax; yy := ay;
   GetNextPosition (tempdir, xx, yy);
   if (myx = xx) and (myy = yy) then begin Result := 99; exit; end;    //90

   tempdir := adir;
   tempdir := GetLeftDirection (tempdir);
   xx := ax; yy := ay;
   GetNextPosition (tempdir, xx, yy);
   if (myx = xx) and (myy = yy) then begin Result := 99; exit; end;    //90


   tempdir := adir;
   tempdir := GetRightDirection (tempdir);
   tempdir := GetRightDirection (tempdir);
   xx := ax; yy := ay;
   GetNextPosition (tempdir, xx, yy);
   if (myx = xx) and (myy = yy) then begin Result := 99; exit; end;     //80

   tempdir := adir;
   tempdir := GetLeftDirection (tempdir);
   tempdir := GetLeftDirection (tempdir);
   xx := ax; yy := ay;
   GetNextPosition (tempdir, xx, yy);
   if (myx = xx) and (myy = yy) then begin Result := 99; exit; end;     //80
end;

function Check8Hit (adir, ax, ay, myx, myy: integer): integer;
var
   tempdir : byte;
   xx, yy: word;
begin
   Result := 0;

   tempdir := adir;
   xx := ax; yy := ay;
   GetNextPosition (tempdir, xx, yy);
   if (myx = xx) and (myy = yy) then begin Result := 100; exit; end;      //100

   tempdir := GetRightDirection (tempdir);
   xx := ax; yy := ay;
   GetNextPosition (tempdir, xx, yy);
   if (myx = xx) and (myy = yy) then begin Result := 99; exit; end;       //70

   tempdir := GetRightDirection (tempdir);
   xx := ax; yy := ay;
   GetNextPosition (tempdir, xx, yy);
   if (myx = xx) and (myy = yy) then begin Result := 99; exit; end;       //70

   tempdir := GetRightDirection (tempdir);
   xx := ax; yy := ay;
   GetNextPosition (tempdir, xx, yy);
   if (myx = xx) and (myy = yy) then begin Result := 99; exit; end;       //85

   tempdir := GetRightDirection (tempdir);
   xx := ax; yy := ay;
   GetNextPosition (tempdir, xx, yy);
   if (myx = xx) and (myy = yy) then begin Result := 99; exit; end;       //85

   tempdir := GetRightDirection (tempdir);
   xx := ax; yy := ay;
   GetNextPosition (tempdir, xx, yy);
   if (myx = xx) and (myy = yy) then begin Result := 99; exit; end;       //85

   tempdir := GetRightDirection (tempdir);
   xx := ax; yy := ay;
   GetNextPosition (tempdir, xx, yy);
   if (myx = xx) and (myy = yy) then begin Result := 99; exit; end;       //85

   tempdir := GetRightDirection (tempdir);
   xx := ax; yy := ay;
   GetNextPosition (tempdir, xx, yy);
   if (myx = xx) and (myy = yy) then begin Result := 99; exit; end;       //85
end;

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
   id := NormalIDCount0;
   Result := id;
   NormalIDCount0 := NormalIDCount0 + NormalIDMax;
end;

function GetNewMonsterId:LongInt;
var id : LongInt;
begin
   id := NormalIDCount1;
   Result := id;
   NormalIDCount1 := NormalIDCount1 + NormalIDMax;
end;

function GetNewItemId:LongInt;
var id : LongInt;
begin
   id := NormalIDCount2;
   Result := id;
   NormalIDCount2 := NormalIDCount2 + NormalIDMax;
end;

function GetNewCallMonsterId:LongInt;
var id : LongInt;
begin
   id := NormalIDCount3;
   Result := id;
   NormalIDCount3 := NormalIDCount3 + NormalIDMax;
end;

function GetNewStaticItemId:LongInt;
var id : LongInt;
begin
   id := NormalIDCount4;
   Result := id;
   NormalIDCount4 := NormalIDCount4 + NormalIDMax;
end;

function GetNewDynamicObjectId:LongInt;
var id : LongInt;
begin
   id := NormalIDCount5;
   Result := id;
   NormalIDCount5 := NormalIDCount5 + NormalIDMax;
end;

function isUserId( Id:LongInt): Boolean;
var Temp : LongInt;
begin
   Temp := Id - STARTNEWID;
   if (Temp mod NormalIDMax) = 0 then Result := TRUE
   else Result := FALSE;
end;

function isMonsterId( Id:LongInt): Boolean;
var Temp : LongInt;
begin
   Temp := Id - STARTNEWID;
   if (Temp mod NormalIDMax) = 1 then Result := TRUE
   else Result := FALSE;
end;

function isObjectItemId( Id:LongInt): Boolean;
var Temp : LongInt;
begin
   Temp := Id - STARTNEWID;
   if (Temp mod NormalIDMax) = 2 then Result := TRUE
   else Result := FALSE;
end;

function isCallMonsterId( Id:LongInt): Boolean;
var Temp : LongInt;
begin
   Temp := Id - STARTNEWID;
   if (Temp mod NormalIDMax) = 3 then Result := TRUE
   else Result := FALSE;
end;

function isStaticItemId( Id:LongInt): Boolean;
var Temp : LongInt;
begin
   Temp := Id - STARTNEWID;
   if (Temp mod NormalIDMax) = 4 then Result := TRUE
   else Result := FALSE;
end;

function isDynamicObjectId( Id:LongInt): Boolean;
var Temp : LongInt;
begin
   Temp := Id - STARTNEWID;
   if (Temp mod NormalIDMax) = 5 then Result := TRUE
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

function isWindOfHandGuard (var SenderInfo : TBasicData; sx, sy, dx, dy : word; MinRange,MaxRange : Integer; var aDis: Integer): Boolean;
var
   i : Integer;
   tx, ty : Word;
begin
   Result := false;
   aDis := 0;
   aDis := GetCellLength (sx,sy,dx,dy);
   if aDis < MinRange then exit;
   if aDis > MaxRange then exit;

   if (SenderInfo.x = dx) and (SenderInfo.y = dy) then begin
      Result := true;
      exit;
   end;
   
   for i := 0 to 20 - 1 do begin
      if (SenderInfo.GuardX [i] = 0) and (SenderInfo.GuardY [i] = 0) then break;
      tx := SenderInfo.x + SenderInfo.GuardX[i];
      ty := SenderInfo.y + SenderInfo.GuardY[i];
      if ( tx = dx ) and ( tx = dy) then begin
         Result := true;
         exit;
      end;
   end;
end;

function CheckGuardNearPos2 (var SenderInfo : TBasicData; sx, sy, sdir : word; var dx, dy : Word; afunc : byte): Boolean;
var
   tx, ty : Word;
   i : integer;
   per : Integer;
begin
   Result := false;

   dx := 0; dy := 0;

   tx := sx; ty := sy;
   GetNextPosition (sdir, tx, ty);

   if (tx = SenderInfo.x) and (ty = SenderInfo.y) then begin
      Result := true;
      exit;
   end;

   case afunc of
      MAGICFUNC_NONE : begin
         for i := 0 to 20 - 1 do begin
            if (SenderInfo.GuardX [i] = 0) and (SenderInfo.GuardY [i] = 0) then break;

            if (tx = SenderInfo.X + SenderInfo.GuardX [i]) and (ty = SenderInfo.Y + SenderInfo.GuardY [i]) then begin
               dx := SenderInfo.X + SenderInfo.GuardX [i];
               dy := SenderInfo.Y + SenderInfo.GuardY [i];
               Result := true;
               exit;
            end;
         end;
      end;

      MAGICFUNC_8HIT : begin
         if (SenderInfo.GuardX [0] = 0) and (SenderInfo.GuardY [0] = 0) then begin
            per := Check8Hit (sdir, tx, ty, SenderInfo.x, SenderInfo.y);
            if per <> 0 then begin
               Result := true;
               exit;
            end;
         end;
      
         for i := 0 to 20 - 1 do begin
            if (SenderInfo.GuardX [i] = 0) and (SenderInfo.GuardY [i] = 0) then break;
            dx := SenderInfo.X + SenderInfo.GuardX[i];
            dy := SenderInfo.y + SenderInfo.GuardY[i];
            per := Check8Hit (sdir, tx, ty, dx, dy);
            if per <> 0 then begin
               Result := true;
               exit;
            end;
         end;
         exit;
      end;
      MAGICFUNC_5HIT : begin
         if (SenderInfo.GuardX [0] = 0) and (SenderInfo.GuardY [0] = 0) then begin
            per := Check5Hit (sdir, tx, ty, SenderInfo.x, SenderInfo.y);
            if per <> 0 then begin
               Result := true;
               exit;
            end;
         end;
         for i := 0 to 20 - 1 do begin
            if (SenderInfo.GuardX [i] = 0) and (SenderInfo.GuardY [i] = 0) then break;
            dx := SenderInfo.X + SenderInfo.GuardX[i];
            dy := SenderInfo.y + SenderInfo.GuardY[i];
            per := Check5Hit (sdir, tx, ty, dx ,dy);
            if per <> 0 then begin
               Result := true;
               exit;
            end;
         end;
         exit;
      end;
   end;
end;

function CheckGuardNearPos (var SenderInfo : TBasicData; sx, sy, sdir : word; var dx, dy : Word): Boolean;
var
   tx, ty : Word;
   i, xx, yy : integer;
begin
   Result := false;

   dx := 0; dy := 0;
   
   if sx > SenderInfo.X then xx := sx - SenderInfo.X
   else xx := SenderInfo.X - sx;

   if sy > SenderInfo.Y then yy := sy - SenderInfo.Y
   else yy := SenderInfo.Y - sy;

   if ((xx = 1) and (yy = 1)) or ((xx = 1) and (yy = 0)) or ((xx = 0) and (yy = 1)) then begin
      dx := SenderInfo.x;
      dy := SenderInfo.y;
      Result := true;
      exit;
   end;

   tx := sx; ty := sy;
   GetNextPosition (sdir, tx, ty);

   for i := 0 to 20 - 1 do begin
      if (SenderInfo.GuardX [i] = 0) and (SenderInfo.GuardY [i] = 0) then break;

      if (tx = SenderInfo.X + SenderInfo.GuardX [i]) and
         (ty = SenderInfo.Y + SenderInfo.GuardY [i]) then begin
         dx := SenderInfo.X + SenderInfo.GuardX [i];
         dy := SenderInfo.Y + SenderInfo.GuardY [i];
         Result := true;
         exit;
      end;
   end;
                                                                                    
   for i := 0 to 20 - 1 do begin
      if (SenderInfo.GuardX [i] = 0) and (SenderInfo.GuardY [i] = 0) then break;

      if sx > SenderInfo.X + SenderInfo.GuardX [i] then xx := sx - (SenderInfo.X + SenderInfo.GuardX [i])
      else xx := SenderInfo.X + SenderInfo.GuardX [i] - sx;

      if sy > SenderInfo.Y + SenderInfo.GuardY [i] then yy := sy - (SenderInfo.Y + SenderInfo.GuardY [i])
      else yy := SenderInfo.Y + SenderInfo.GuardY [i] - sy;

      if ((xx = 0) and (yy = 1)) or ((xx = 1) and (yy = 0)) then begin
         dx := SenderInfo.X + SenderInfo.GuardX [i];
         dy := SenderInfo.Y + SenderInfo.GuardY [i];
         Result := true;
         exit;
      end;
   end;

   for i := 0 to 20 - 1 do begin
      if (SenderInfo.GuardX [i] = 0) and (SenderInfo.GuardY [i] = 0) then break;

      if sx > SenderInfo.X + SenderInfo.GuardX [i] then xx := sx - (SenderInfo.X + SenderInfo.GuardX [i])
      else xx := SenderInfo.X + SenderInfo.GuardX [i] - sx;

      if sy > SenderInfo.Y + SenderInfo.GuardY [i] then yy := sy - (SenderInfo.Y + SenderInfo.GuardY [i])
      else yy := SenderInfo.Y + SenderInfo.GuardY [i] - sy;

      if (xx = 1) and (yy = 1) then begin
         dx := SenderInfo.X + SenderInfo.GuardX [i];
         dy := SenderInfo.Y + SenderInfo.GuardY [i];
         Result := true;
         exit;
      end;
   end;
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

function GetBackDirection (sx, sy, dx, dy: word): word;
var
   r, t : Real;
   xx, yy: integer;
begin
   Result := DR_DONTMOVE;
   xx := dx-sx; yy := dy-sy;

   r := ArcTan2 (yy, xx);

   if r = 0 then begin
      if (xx=0) and (yy=0) then Result := DR_0;
      if (xx=0) and (sy<dy) then Result := DR_0;
      if (xx=0) and (sy>dy) then Result := DR_4;
      if (yy=0) and (sx<dx) then Result := DR_6;
      if (yy=0) and (sx>dx) then Result := DR_2;
      exit;
   end;

   t := -4*PI/4;
   if (r<=t+PI/8) and (r>(t+-PI/8)) then Result := DR_2;

   t := -3*PI/4;
   if (r<=t+PI/8) and (r>(t+-PI/8)) then Result := DR_3;

   t := -2*PI/4;
   if (r<=t+PI/8) and (r>(t+-PI/8)) then Result := DR_4;

   t := -1*PI/4;
   if (r<=t+PI/8) and (r>(t+-PI/8)) then Result := DR_5;

   t := 0*PI/4;
   if (r<=t+PI/8) and (r>(t+-PI/8)) then Result := DR_6;

   t := 1*PI/4;
   if (r<=t+PI/8) and (r>(t+-PI/8)) then Result := DR_7;

   t := 2*PI/4;
   if (r<=t+PI/8) and (r>(t+-PI/8)) then Result := DR_0;

   t := 3*PI/4;
   if (r<=t+PI/8) and (r>(t+-PI/8)) then Result := DR_1;

   t := 4*PI/4;
   if (r<=t+PI/8) and (r>(t+-PI/8)) then Result := DR_2;
end;

procedure GetOppositeDirection (sx, sy, dx, dy: word; var tx, ty : word);
var
   px, py, ax, ay, rr : Integer;
begin
   px := sx - dx;
   py := sy - dy;

   ax := px;
   ay := py;
   if ax < 0 then ax := -ax;
   if ay < 0 then ay := -ay;
   if ax >= ay then rr := ay
   else rr := ax;
   ax := ax - rr;
   ay := ay - rr;

   if (ax = 0) and (ay = 0) then begin
      if (px > 0) and (py > 0) then begin
         tx := sx + 4 - ax - rr;
         ty := sy + 4 - ay - rr;
      end else if (px > 0) and (py < 0) then begin
         tx := sx + 4 - ax - rr;
         ty := sy - 4 + ay + rr;
      end else if (px < 0) and (py < 0) then begin
         tx := sx - 4 + ax + rr;
         ty := sy - 4 + ay + rr;
      end else begin
         tx := sx - 4 + ax + rr;
         ty := sy + 4 - ay - rr;
      end;
   end else if ax > 0 then begin
      ty := sy;
      if px > 0 then begin
         tx := sx + 4 - ax - rr;
      end else begin
         tx := sx - 4 + ax + rr;
      end;
   end else begin
      tx := sx;
      if py > 0 then begin
         ty := sy + 4 - ay - rr;
      end else begin
         ty := sy - 4 + ay + rr;
      end;
   end;
end;

procedure GetOppositePosition (sx, sy, dx, dy: word; var tx, ty : word);
var
   px, py, ax, ay, rr : Integer;
begin
   px := sx - dx;
   py := sy - dy;

   ax := px;
   ay := py;
   if ax < 0 then ax := -ax;
   if ay < 0 then ay := -ay;
   if ax >= ay then rr := ay
   else rr := ax;
   ax := ax - rr;
   ay := ay - rr;

   if (ax = 0) and (ay = 0) then begin
      if (px > 0) and (py > 0) then begin
         tx := sx + 2 - ax - rr;
         ty := sy + 2 - ay - rr;
      end else if (px > 0) and (py < 0) then begin
         tx := sx + 2 - ax - rr;
         ty := sy - 2 + ay + rr;
      end else if (px < 0) and (py < 0) then begin
         tx := sx - 2 + ax + rr;
         ty := sy - 2 + ay + rr;
      end else begin
         tx := sx - 2 + ax + rr;
         ty := sy + 2 - ay - rr;
      end;
   end else if ax > 0 then begin
      ty := sy;
      if px > 0 then begin
         tx := sx + 2 - ax - rr;
      end else begin
         tx := sx - 2 + ax + rr;
      end;
   end else begin
      tx := sx;
      if py > 0 then begin
         ty := sy + 2 - ay - rr;
      end else begin
         ty := sy - 2 + ay + rr;
      end;
   end;
end;

procedure GetPushPosition (var x,y : word; length : word; dir : word);
var
   i : integer;
begin
   if (length <= 0) or (length >2) then exit;
   for i := 0 to length - 1 do begin
      GetNextPosition(dir, x,y);
   end;
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

function CheckInArea (x, y : word; sx, sy : word; w : Integer) : Boolean;
var
   HalfWidth : Integer;
begin
   Result := false;

   HalfWidth := w div 2;
   if (x >= sx - HalfWidth) and (x <= sx + HalfWidth) then begin
      if (y >= sy - HalfWidth) and (y <= sy + HalfWidth) then begin
         Result := true;
      end;
   end;
end;

end.






