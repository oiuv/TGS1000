unit AiUnit;

interface

uses
  Windows;

const
   AI_NONE        = 0;
   AI_TURN        = 1;
   AI_MOVE        = 2;
   AI_DONTMOVE    = 3;
   AI_CLEAROLDPOS = 4;

type
   TIsMoveable = function (ax, ay: integer): Boolean of object;
   TGotoXyRData = record ract, rdir, rlen : word; end;

  function AI0GotoXy (var aret: TGotoXyRData; cdir, cx, cy, tx, ty, ox, oy: word; IsMoveable: TIsMoveable): Boolean; // 115k

implementation

procedure GetNextPosition (dir: word; var x, y: word);
begin
   case dir of
      0 : y := y - 1;
      1 : begin x := x + 1; y := y - 1; end;
      2 : x := x + 1;
      3 : begin x := x + 1; y := y +1; end;
      4 : y := y + 1;
      5 : begin x := x-1; y := y + 1; end;
      6 : x := x - 1;
      7 : begin x := x - 1; y := y-1; end;
   end;
end;

function  GetNextDirection ( sx, sy, ex, ey: word): word;
var flagx, flagy: integer;
begin
   Result := 8;
   if sx < eX then flagx := 1
   else if sx = ex then flagx := 0
   else flagx := -1;

   if sy < ey then flagy := 1
   else if sy = ey then flagy := 0
   else flagy := -1;

   if (flagx = 0)  and (flagy = -1) then begin Result := 0; exit; end;
   if (flagx = 1)  and (flagy = -1) then begin Result := 1; exit; end;
   if (flagx = 1)  and (flagy = 0)  then begin Result := 2; exit; end;
   if (flagx = 1)  and (flagy = 1)  then begin Result := 3; exit; end;
   if (flagx = 0)  and (flagy = 1)  then begin Result := 4; exit; end;
   if (flagx = -1) and (flagy = 1)  then begin Result := 5; exit; end;
   if (flagx = -1) and (flagy = 0)  then begin Result := 6; exit; end;
   if (flagx = -1) and (flagy = -1) then begin Result := 7; exit; end;
end;

function AI0GotoXy (var aret: TGotoXyRData; cdir, cx, cy, tx, ty, ox, oy: word; IsMoveable: TIsMoveable): Boolean;
var
   i : integer;
   key, len : word;
   lenarr : array [0..8-1] of word;
   mx, my: word;
begin
   Result := TRUE;
   aret.ract := AI_NONE;   aret.rlen := 0;
   if (cx = tx) and (cy = ty) then begin Result := FALSE; exit; end;    // µµÂø

   key := GetNextDirection ( cx, cy, tx, ty);
   mx := cx; my := cy;
   GetNextPosition (key, mx, my);
   if (mx = tx) and (my = ty) then begin
      aret.rdir := key;
      aret.rlen := 1;
      if cdir <> key then begin aret.ract := AI_TURN; exit; end;
      if IsMoveable (mx, my) then begin aret.ract := AI_MOVE; exit; end;
      Result := FALSE;
      aret.ract := AI_DONTMOVE;
      exit;
   end;

   for i := 0 to 8-1 do lenarr[i] := 65535;

   if isMoveable (   cx, cy-1) then if (ox <> cx  ) or (oy <> cy-1) then lenarr[0] := (cx  -tx)*(cx  -tx) + (cy-1-ty)*(cy-1-ty);
   if isMoveable ( cx+1, cy-1) then if (ox <> cx+1) or (oy <> cy-1) then lenarr[1] := (cx+1-tx)*(cx+1-tx) + (cy-1-ty)*(cy-1-ty);
   if isMoveable ( cx+1, cy  ) then if (ox <> cx+1) or (oy <> cy  ) then lenarr[2] := (cx+1-tx)*(cx+1-tx) + (cy  -ty)*(cy  -ty);
   if isMoveable ( cx+1, cy+1) then if (ox <> cx+1) or (oy <> cy+1) then lenarr[3] := (cx+1-tx)*(cx+1-tx) + (cy+1-ty)*(cy+1-ty);
   if isMoveable (   cx, cy+1) then if (ox <> cx  ) or (oy <> cy+1) then lenarr[4] := (cx  -tx)*(cx  -tx) + (cy+1-ty)*(cy+1-ty);
   if isMoveable ( cx-1, cy+1) then if (ox <> cx-1) or (oy <> cy+1) then lenarr[5] := (cx-1-tx)*(cx-1-tx) + (cy+1-ty)*(cy+1-ty);
   if isMoveable ( cx-1, cy  ) then if (ox <> cx-1) or (oy <> cy  ) then lenarr[6] := (cx-1-tx)*(cx-1-tx) + (cy  -ty)*(cy  -ty);
   if isMoveable ( cx-1, cy-1) then if (ox <> cx-1) or (oy <> cy-1) then lenarr[7] := (cx-1-tx)*(cx-1-tx) + (cy-1-ty)*(cy-1-ty);
   
   len := 65535;
   for i := 0 to 8-1 do if len > lenarr[i] then begin key := i; len := lenarr[i]; end;
   mx := cx; my := cy;
   GetNextPosition (key, mx, my);
   aret.rdir := key;
   aret.rlen := len;
   if key <> cdir then begin aret.ract := AI_TURN; exit; end;
   if isMoveable ( mx, my) then aret.ract := AI_MOVE
   else aret.ract := AI_CLEAROLDPOS;
end;

end.
