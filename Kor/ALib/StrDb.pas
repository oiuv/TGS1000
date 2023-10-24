unit strdb;

interface

uses Windows, Classes, SysUtils, AUtil32, dialogs;

const
   BYTESTRINGSIZE = 255;

type
  TByteString = array[0..BYTESTRINGSIZE-1] of byte;
  PTByteString = ^TByteString;

  TStringDb = class
  private
   Open_Data : TStringList;
   Open_Name: string;

   DbName : string;
   pWriteBuffer : PChar;
   WriteBufferSize : integer;

   NameList : TStringList;
   DbStringList : TStringList;
   FieldList : TStringList;

   function  GetNameCount: Integer;
   function  GetFieldCount: Integer;
   function  OpenRecord ( cName: string): Boolean;
   procedure CloseRecord;
  public
   constructor Create;
   destructor Destroy; override;
   procedure Clear;
   function  GetFieldIndex ( cField : string) : integer;

   function  GetNameIndex ( cName : string) : integer;
   procedure LoadFromFile ( aFileName: string);
   procedure LoadFromStream (aStream : TStream);
   procedure LoadFromFileCode ( aFileName: string);
   procedure SaveToFile ( aFileName: string);

   function  GetFieldValueInteger ( cName, cField: string) : Integer;
   function  SetFieldValueInteger ( cName, cField: string; Value: Integer) : Boolean;

   function  GetFieldValueString ( cName, cField: string) : string;
   function  SetFieldValueString ( cName, cField, Value: string) : Boolean;

   function  GetFieldValueBoolean ( cName, cField: string) : Boolean;
   function  SetFieldValueBoolean ( cName, cField: string; Value: Boolean) : Boolean;

   function  GetDbString ( cName: string): string;
   function  GetDbStringByChar ( cName: string; pb:pchar): string;
   function  GetDbStringFirstPos (cName: string): string;
   function  AddDbString ( aDbStr: string): Boolean;
   function  InsertDbString ( aDbStr: string): Boolean;
   function  SetDbString ( cName, aDbStr: string): Boolean;

   function  AddName ( cName : string) : Boolean;
   function  InsertName ( idx: integer; cName : string) : Boolean;
   function  DeleteName ( cName : string) : Boolean;
   function  GetDbFields : string;
   function  SetDbFields ( aFields : string): Boolean;
   function  GetIndexString (Index:Integer) : string;
   function  GetIndexName (Index:Integer) : string;
   property  Count : integer read GetNameCount;
   property  FieldCount : integer read GetFieldCount;
  end;

   procedure SetByteString (var ByteString:TByteString; str: string);
   function  GetByteString (ByteString:TByteString): string;
   procedure InverseByteString (var ByteString:TByteString);

implementation

procedure InverseByteString (var ByteString:TByteString);
var
   i: integer;
   b, h, l : byte;
begin
   for i := 0 to BYTESTRINGSIZE -1 do begin
      b := ByteString[i];
      h := (b and $f0);
      l := (b and $0f);
      b := (h shr 4) + (l shl 4);
      ByteString[i] := b;
   end;
end;

procedure SetByteString (var ByteString:TByteString; str: string);
var len : Word;
begin
   len := Length (str);
   if (len >= (BYTESTRINGSIZE-2)) then begin
      len := BYTESTRINGSIZE -2;
      str := Copy (str, 1, BYTESTRINGSIZE-2);
   end;
   FillChar (ByteString, sizeof(TByteString), 0);
   _StrPCopy (@ByteString[1], str);
   ByteString[0] := len;
end;

function  GetByteString (ByteString:TByteString): string;
var len : Word;
begin
   len := ByteString[0];
   ByteString[len+1] := 0;
   Result := StrPas (@ByteString[1]);
end;

///////////////////////////
//       TStringDb
///////////////////////////


constructor TStringDb.Create;
var i : integer;
begin
   dbName := 'noname.sdb';
   pWriteBuffer := nil;
   WriteBufferSize := 0;
   DbStringList := TStringList.Create;
   NameList := TSTringList.Create;
   FieldList := TStringList.Create;
   Open_Data := TSTringList.Create;
   for i := 0 to 200 do Open_Data.Add ('');
   Open_Name := '';
end;

destructor TStringDb.Destroy;
begin
   Open_Data.Free;
   FieldList.Free;
   NameList.Free;
   DbStringList.Free;

   if pWriteBuffer <> nil then FreeMem (pWriteBuffer, WriteBufferSize);

   inherited Destroy;
end;

procedure TStringDb.Clear;
begin
   CloseRecord;
   FieldList.Clear;
   Open_Data.Clear;
   DbStringList.Clear;
end;

function  TStringDb.GetFieldIndex ( cField : string) : integer;
var i : integer;
begin
   Result := -1;
   for i := 0 to FieldList.Count-1 do begin
      if CompareText ( FieldList[i], cField) = 0 then begin Result := i; exit; end;
   end;
end;

function  TStringDb.GetNameIndex ( cName : string) : integer;
var i: integer;
begin
   Result := -1;
   for i := 0 to NameList.Count -1 do
      if CompareStr ( cName,NameList[i]) = 0 then begin Result := i; exit; end;
end;

procedure TStringDb.LoadFromStream (aStream : TStream);
var
   i : integer;
   str, rdstr: string;
begin
   CloseRecord;
   
   FieldList.Clear;
   DbStringList.Clear;
   NameList.Clear;
   Open_Data.Clear;

   DbStringList.LoadFromStream (aStream);
   for i := DbStringList.Count -1 downto 0 do begin          // 지워진 레코드,
      str := DbStringList[i];
      if str = '' then begin DbStringList.Delete (i); continue; end;
      if str[1] = ',' then DbStringList.Delete (i);
   end;

   if DbStringList.Count = 0 then exit;

   str := DbStringList[0];
   while str <> '' do begin
      str := GetValidStr3 (str, rdstr, ',');
      FieldList.add (rdstr);
      Open_Data.Add('');
   end;

   DbStringList.Delete (0);

   for i := 0 to DbStringList.Count -1 do begin
      str := DbStringList[i];
      str := GetValidStr3 (str, rdstr, ',');
      NameList.Add (rdstr);
   end;
end;

procedure TStringDb.LoadFromFile ( aFileName: string);
var
   i : integer;
   str, rdstr: string;
   showbuf : array [0..64] of byte;
begin
   if FileExists (aFileName) = FALSE then begin
      StrPcopy (@ShowBuf, aFileName+'이 없습니다.');
      Windows.MessageBox( 0, @ShowBuf, 'Error', 0);
      exit;
   end;

   CloseRecord;

   FieldList.Clear;
   DbStringList.Clear;
   NameList.Clear;
   Open_Data.Clear;

   DbStringList.LoadFromFile (aFileName);
   for i := DbStringList.Count -1 downto 0 do begin          // 지워진 레코드,
      str := DbStringList[i];
      if str = '' then begin DbStringList.Delete (i); continue; end;
      if str[1] = ',' then DbStringList.Delete (i);
   end;

   if DbStringList.Count = 0 then begin
      StrPcopy (@ShowBuf, aFileName+'이 잘못됫습니다.');
      Windows.MessageBox( 0, @ShowBuf, '마지막 왕국', 0);
      exit;
   end;

   str := DbStringList[0];
   while str <> '' do begin
      str := GetValidStr3 (str, rdstr, ',');
      FieldList.add (rdstr);
      Open_Data.Add('');
   end;
   dbName := aFileName;

   DbStringList.Delete (0);

   for i := 0 to DbStringList.Count -1 do begin
      str := DbStringList[i];
      str := GetValidStr3 (str, rdstr, ',');
      NameList.Add (rdstr);
   end;
end;

procedure TStringDb.LoadFromFileCode ( aFileName: string);
var
   i, n, cnt : integer;
   str, rdstr: string;
   showbuf : array [0..64] of byte;
   ByteString : TByteString;
   Stream : TFileStream;
begin
   n := File_Size (aFileName);

   if n = -1 then begin
      StrPcopy (@ShowBuf, aFileName+'이 없습니다.');
      Windows.MessageBox( 0, @ShowBuf, '천년', 0);
      exit;
   end;

   if (n mod BYTESTRINGSIZE) <> 0 then begin
      StrPcopy (@ShowBuf, aFileName+'의 크기가 틀립니다.');
      Windows.MessageBox( 0, @ShowBuf, '천년', 0);
      exit;
   end;

   CloseRecord;

   FieldList.Clear;
   DbStringList.Clear;
   NameList.Clear;
   Open_Data.Clear;

   cnt := n div BYTESTRINGSIZE;

   Stream := TFileStream.Create (aFileName, fmOpenRead or fmShareDenyWrite);
   for i := 0 to cnt -1 do begin
      Stream.ReadBuffer (ByteString, sizeof(ByteString));
      inverseByteString (ByteString);
      str := GetByteString (ByteString);
      DbStringList.Add (str);
   end;
   Stream.Free;

   for i := DbStringList.Count -1 downto 0 do begin          // 지워진 레코드,
      str := DbStringList[i];
      if str = '' then begin DbStringList.Delete (i); continue; end;
      if str[1] = ',' then DbStringList.Delete (i);
   end;

   str := DbStringList[0];
   while str <> '' do begin
      str := GetValidStr3 (str, rdstr, ',');
      FieldList.add (rdstr);
      Open_Data.Add('');
   end;
   dbName := aFileName;

   DbStringList.Delete (0);

   for i := 0 to DbStringList.Count -1 do begin
      str := DbStringList[i];
      str := GetValidStr3 (str, rdstr, ',');
      NameList.Add (rdstr);
   end;
end;

procedure TStringDb.SaveToFile ( aFileName: string);
var
   i, clen, wsize : integer;
   tempfieldstr : string;
   ptemp : pchar;
   Stream : TFileStream;
begin
   CloseRecord;

   dbName := aFileName;

   tempfieldstr := '';
   for i := 0 to FieldList.Count-1 do tempfieldstr := tempfieldstr+FieldList[i]+',';
   wsize := Length(tempfieldstr) + 2;
   for i := 0 to DbStringList.count -1 do wsize := wsize + Length (DbStringList[i])+2;

   if wsize >= WriteBufferSize-1 then begin
      if pWriteBuffer <> nil then FreeMem (pWriteBuffer, WriteBufferSize);
      WriteBufferSize := wsize + 16384 + wsize div 10;
      GetMem ( pWriteBuffer, WriteBufferSize)
   end;

   ptemp := pWriteBuffer;

   _StrPCopy (ptemp, tempfieldstr+#13+#10);   clen := Length(tempfieldstr) + 2;
   inc (ptemp, clen);

   for i := 0 to DbStringList.count -1 do begin
      _StrPCopy (ptemp, DbStringList[i]+#13+#10);
      clen := Length (DbStringList[i])+2;
      inc (ptemp, clen);
   end;

   Stream := TFileStream.create (aFileName, fmCreate);
   Stream.WriteBuffer (pWriteBuffer^, wsize);
   Stream.Free;
end;

function  TStringDb.OpenRecord ( cName: string): Boolean;
var
   i, n : integer;
   str, rdstr : string;
begin
   Result := FALSE;
   CloseRecord;

   n := GetNameIndex (cName);
   if n = -1 then exit;

   str := DbStringList[n];
   for i := 0 to FieldList.Count -1 do begin
      str := GetValidStr3(str, rdstr, ',');
      Open_Data[i] := rdstr;
   end;
   Open_Name := cName;

   Result := TRUE;
end;

procedure TStringDb.CloseRecord;
var
   i, n : integer;
   str : string;
begin
   if Open_Name <> '' then begin
      n := GetNameIndex (Open_Name);
      if n <> -1 then begin
         str := '';
         for i := 0 to FieldList.Count -1 do str := str + Open_Data[i] + ',';
         DbStringList[n] := str;
      end;
   end;

   Open_Name := '';
   for i := 0 to FieldList.Count -1 do Open_Data[i] := '';
end;

function  TStringDb.GetFieldValueString ( cName, cField: string) : string;
var fn: integer;
begin
   Result := '';
   if cName <> Open_Name then
      if OpenRecord (cName) = FALSE then exit;

   fn := GetFieldIndex (cField);
   if fn = -1 then begin
      Showmessage(DbName + ' : Field Not Found : '+cField);
      exit;
   end;
   Result := Open_Data[fn];
end;

function  TStringDb.SetFieldValueString ( cName, cField, Value: string) : Boolean;
var fn: integer;
begin
   Result := FALSE;
   if cName <> Open_Name then
      if OpenRecord (cName) = FALSE then exit;

   fn := GetFieldIndex ( cField);
   if fn = -1 then begin
      Showmessage(DbName + ' : Field Not Found : '+cField);
      exit;
   end;
   Open_Data[fn] := Value;
   Result := TRUE;
end;

function  TStringDb.GetFieldValueBoolean ( cName, cField: string) : Boolean;
var str: string;
begin
   str := GetFieldValueString ( cName, cField);
   if str = 'TRUE' then Result := TRUE
   else Result := FALSE;
end;

function  TStringDb.SetFieldValueBoolean ( cName, cField: string; Value: Boolean) : Boolean;
var str: string;
begin
   if Value then str := 'TRUE'
   else str := 'FALSE';
   Result := SetFieldValueString ( cName, cField, str);
end;

function  TStringDb.GetFieldValueInteger ( cName, cField: string) : Integer;
var str: string;
begin
   str := GetFieldValueString ( cName, cField);
   Result := _StrToInt(str);
end;

function  TStringDb.SetFieldValueInteger ( cName, cField: string; Value: Integer) : Boolean;
var str: string;
begin
   str := IntToStr (Value);
   Result := SetFieldValueString ( cName, cField, str);
end;

function  TStringDb.GetDbString ( cName: string): string;
var idx : integer;
begin
   CloseRecord;
   idx := GetNameIndex (cName);
   if idx = -1 then Result := ''
   else Result := DbStringList[idx];
end;

function  TStringDb.GetDbStringByChar ( cName: string; pb:pchar): string;
var idx : integer;
begin
   CloseRecord;
   idx := GetNameIndex (cName);
   if idx = -1 then Result := ''
   else _StrPCopy (pb, DbStringList[idx]);
end;

function  TStringDb.GetDbStringFirstPos (cName: string): string;
var i : integer;
begin
   Result := '';
   for i := 0 to DbStringList.Count -1 do begin
      if Pos (NameList[i], cName) > 0 then begin
         Result := DbStringList[i];
         exit;
      end;
   end;
end;

function  TStringDb.SetDbString ( cName, aDbStr: string): Boolean;
var idx : integer;
begin
   CloseRecord;
   idx := GetNameIndex (cName);
   if idx = -1 then Result := FALSE
   else begin
      DbStringList[idx] := aDbStr;
      Result := TRUE;
   end;
end;

function  TStringDb.AddDbString ( aDbStr: string): Boolean;
var uname : string;
begin
   CloseRecord;

   DbStringList.Add (aDbStr);

   GetValidStr3 (aDbStr, uname, ',');
   NameList.Add (uname);

   Result := TRUE;
end;

function  TStringDb.InsertDbString ( aDbStr: string): Boolean;
var uname : string;
begin
   CloseRecord;

   DbStringList.Insert (0, aDbStr);

   GetValidStr3 (aDbStr, uname, ',');
   NameList.Insert (0, uname);

   Result := TRUE;
end;

function  TStringDb.InsertName ( idx: integer; cName : string) : Boolean;
var
   i : integer;
   str : string;
begin
   CloseRecord;
   Result := FALSE;
   if idx <> 0 then exit;
   
   if GetNameIndex ( cName) <> -1 then exit;

   NameList.Insert (idx, cName);

   str := cName + ',';
   for i := 1 to FieldList.Count-1 do str := str + ',';
   DBStringList.Insert (idx, Str);
   Result := TRUE;
end;

function  TStringDb.AddName ( cName : string): Boolean;
var
   i : integer;
   str : string;
begin
   CloseRecord;
   Result := FALSE;
   if GetNameIndex ( cName) <> -1 then exit;

   NameList.Add (cName);

   str := cName + ',';
   for i := 1 to FieldList.Count-1 do str := str + ',';
   DBStringList.Add (Str);
   Result := TRUE;
end;

function  TStringDb.DeleteName ( cName : string) : Boolean;
var idx : integer;
begin
   CloseRecord;

   Result := FALSE;
   idx := GetNameIndex ( cName);
   if idx = -1 then exit;

   DbStringList.Delete (idx);
   NameList.Delete (idx);
   Result := TRUE;
end;

function TStringDb.SetDbFields ( aFields : string): Boolean;
var str, rdstr : string;
begin
   CloseRecord;
   FieldList.Clear;
   Open_Data.Clear;

   str := aFields;

   while TRUE do begin
      if str = '' then break;
      str := GetValidStr3 (str, rdstr, ',');
      if rdstr = '' then break;

      FieldList.Add (rdstr);
      Open_Data.add ('');
   end;
   Result := TRUE;
end;

function  TStringDb.GetDbFields : string;
var
   i : integer;
   str : string;
begin
   str := '';
   for i := 0 to FieldList.Count-1 do begin
      str := str + FieldList[i]+ ',';
   end;
   Result := str;
end;

function  TStringDb.GetIndexString (Index:Integer) : string;
begin
   CloseRecord;
   Result := '';
   if index < 0 then exit;
   if index >= DbStringList.Count then exit;
   Result := DbStringList[index];
end;

function  TStringDb.GetIndexName (Index:Integer) : string;
begin
   Result := '';
   if index < 0 then exit;
   if index >= DbStringList.Count then exit;
   Result := NameList[index];
end;

function TStringDb.GetNameCount: Integer;
begin
   Result :=  DbStringList.Count;
end;

function  TStringDb.GetFieldCount: Integer;
begin
   Result := FieldList.Count;
end;


end.
