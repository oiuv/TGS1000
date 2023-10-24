unit uCrypt;

interface

uses
   Windows, Sysutils, Classes;

const
   CRYPT_PACKET_MAXSIZE = 1024;

   function EnCryption (sour, dest: pbyte; asize: integer): Integer;
   function DeCryption (sour, dest: pbyte; asize: integer): Integer;

implementation

///////////////////////////////////
//           Crypt
///////////////////////////////////

var
   CurrentRandom : integer = 1;

   EnCryptTable: array [0..64-1] of byte;
   DeCryptTable: array [59..123-1] of byte;

function UniformRandom (aMax: integer): integer;
begin
   CurrentRandom := (1229 * CurrentRandom + 351750) mod 1664501;
   Result := CurrentRandom mod aMax;
end;

procedure Decoding3 ( sour, dest: Pbyte);
var
   buf : array [0..4] of byte;
   b1, b2 : byte;
begin
   move (sour^, buf, 4);
   b1 := buf[0] shl 2; b2 := buf[1] shr 4;
   dest^ := b1 or b2; inc (dest);

   b1 := buf[1] shl 4; b2 := buf[2] shr 2;
   dest^ := b1 or b2; inc (dest);

   b1 := buf[2] shl 6; b2 := buf[3];
   dest^ := b1 or b2;
end;

function DeCryption (sour, dest: pbyte; asize: integer): Integer;
var
   i, nblock, dsize : integer;
   buf : array [0..8192 - 1] of byte;
begin
   if asize mod 4 <> 0 then begin
      Result := -1;
      exit;
   end;
   nblock := asize div 4;

   move (sour^, buf, asize); buf[asize] := 0;

   for i := 0 to (nblock*4)-1 do begin
      if (buf[i] < 59) or (buf[i] > 123 - 1) then begin
         Result := -1;
         exit;
      end; // 암호화 에러..
      buf[i] := DeCryptTable [ buf[i] ];  // buf[i] := buf[i] - $3B;
   end;

   for i := 0 to nblock-1 do Decoding3 (@buf[i*4], PBYTE(integer(dest) + i * 3));

   dsize := nblock * 3;

   Result := dsize;
end;

procedure Encoding4 ( sour, dest: Pbyte);
var
   buf : array [0..4] of byte;
   b1, b2 : byte;
begin
   move (sour^, buf, 3);

   dest^ := buf[0] shr 2; inc (dest);

   b1 := (buf[0] and $03) shl 4;
   b2 := (buf[1] shr 4);
   dest^ := b1 or b2; inc (dest);

   b1 := (buf[1] and $0f) shl 2;
   b2 := (buf[2] shr 6);
   dest^ := b1 or b2; inc (dest);

   dest^ := buf[2] and $3f;
end;

function EnCryption (sour, dest: pbyte; asize: integer): Integer;
var
   i, nblock: integer;
begin
   PBYTE (integer(sour)+asize)^ := 0; //   sour.data[sour.cnt] := 0;
   PBYTE (integer(sour)+asize+1)^ := 0;
   PBYTE (integer(sour)+asize+2)^ := 0;

   nblock := asize div 3;
   if (asize mod 3) <> 0 then nblock := nblock + 1;

   for i := 0 to nblock-1 do begin
      Encoding4 (PBYTE (integer(sour)+i*3) , PBYTE(integer(dest)+i*4)); //Encoding4 (sour.data[i*3], @dest.data[i*4]);
      PBYTE (integer(dest)+i*4+0)^ := EncryptTable [ PBYTE (integer(dest)+i*4+0)^]; //dest.data[i*4+0] := dest.data[i*4+0] + $3B;
      PBYTE (integer(dest)+i*4+1)^ := EncryptTable [ PBYTE (integer(dest)+i*4+1)^]; //dest.data[i*4+1] := dest.data[i*4+1] + $3B;
      PBYTE (integer(dest)+i*4+2)^ := EncryptTable [ PBYTE (integer(dest)+i*4+2)^]; //dest.data[i*4+2] := dest.data[i*4+2] + $3B;
      PBYTE (integer(dest)+i*4+3)^ := EncryptTable [ PBYTE (integer(dest)+i*4+3)^]; //dest.data[i*4+3] := dest.data[i*4+3] + $3B;
   end;

   PBYTE (integer(dest)+nblock*4)^ := 0;
   Result := nblock*4;
end;

procedure InitCryptTable;
var
   i, idx, n: integer;
   List : TList;
begin
   List := TList.Create;
   for i := 0 to 64-1 do List.Add (TObject(i));

   CurrentRandom := 1;

   for i := 0 to 64-1 do begin
      idx := UniformRandom (List.Count);
      n := Integer (List[idx]); List.Delete (idx);
      EnCryptTable[i] := n + $3B;
      DeCryptTable[EnCryptTable[i]] := i;
   end;
   List.Free;
end;


initialization
begin
   InitCryptTable;
end;

Finalization
begin
end;

end.

