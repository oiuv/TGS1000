unit AnsUnit;

interface

uses
	Windows, SysUtils, Classes, AUtil32;

const
     KINGDBINDEX_ID = 'ATI0';
     FILERECORDDB_ID = 'FRD0';

type
 TBlackBox = class
  private
   DebugString : TStringList;
  public
   BoxName : string;
   BoxFields : string;
   constructor Create (aName: string);
   destructor Destroy; override;
   procedure SaveToFile;
   procedure Add (str: string);
   procedure AddUnique (str: string);
 end;

  TAnsIndexFileHeader = record
     Ident : array[0..3] of char;
     Count : integer;
     DataSize : integer;
     boSavedIndex : Boolean;
     None : array [0..31] of byte;
  end;

  TAnsIndexData = record
    No: integer;
    prdata: pbyte;
  end;
  PTAnsIndexData = ^TAnsIndexData;

  TAnsIndexClass = class
  private
    FName : string;
    FDataSize : integer;
    FTag : integer;
    DataList : TList;
    FBoString : Boolean;

    function    IndexCompare (pdata1, pdata2: pbyte): integer;
    function    FindIndex (apdata: pbyte): integer;
    function    GetCount: integer;
  public
    constructor Create (aName: string; aDataSize: integer; aBoString: Boolean);
    destructor  Destroy; override;
    procedure   Clear;
    procedure   SaveToFile (aFileName: string);
    procedure   SaveToIndexFile (aFileName: string);
    function    LoadFromIndexFile (aFileName: string): Boolean;
    function    Insert (aNo: integer; astr: string): integer;
    procedure   Delete (astr: string);
    function    Select (astr: string): integer;

    function    GetIndexString (aindex: integer): string;
    function    GetIndexNo (aindex: integer): integer;

    property    Name: string read FName;
    property    Tag: integer read FTag write FTag;
    property    DataSize: integer read FDataSize;
    property    BoString: Boolean read FBoString;
    property    Count : Integer read GetCount;
  end;


   TAnsListAllocFunction   = function : pointer of object;
   TAnsListFreeFunction    = procedure (Item: Pointer) of object;

   TAnsList = class
   private
      DataList : TList;
      UnUsedList : TList;
      AllocFunction   : TAnsListAllocFunction;
      FreeFunction    : TAnsListFreeFunction;
      FMaxUnUsedCount : integer;
      function GetCount:integer;
      function GetData (index: integer) : pointer;
   public
      constructor Create (sbuffer: integer;
                          aAllocFunction   : TAnsListAllocFunction;
                          aFreeFunction    : TAnsListFreeFunction);
      destructor Destroy; override;
      function   GetUnUsedPointer: pointer;
      function   Add (item: Pointer):integer;
      procedure  Delete (index: integer);
      // 2000.09.16 Insert Method 추가 by Lee.S.G
      procedure  Insert (index:integer; item:Pointer);
      property   Items[index:integer] : pointer read GetData; default;
      property   Count : integer read GetCount;
      property   MaxUnUsedCount : integer read FMaxUnUsedCount write FMaxUnUsedCount;
   end;

  TACSFileHeader = record
    ident : array [0..8-1] of char;
    count : integer;
  end;

   TConvStringData = record
      rOrgstr : string [255];
      rViewstr : string [255];
   end;
   PTConvStringData = ^TConvStringData;

   TAnsStringClass = class
   private
      DataList : TList;
   public
      constructor Create;
      destructor Destroy; override;
      procedure LoadFromFile (aFileName: string);
      function  GetString (astr: string): string;
   end;

  TFieldType = (ft_string, ft_integer, ft_word, ft_byte, ft_binary, ft_boolean);

  TFileRecordDbFileHeader = record
   rIdent: array [0..4-1] of char;
   rCount : integer;
   rRecordSize : integer;
   rNameSize : integer;
   rDataFieldCount : integer;
  end;

  TFileRecordFieldData = record
   rFieldName : array [0..32] of char;
   rFieldType : TFieldType;
   rFieldSize : integer;
   rFieldStartPos : integer;
  end;
  PTFileRecordFieldData = ^TFileRecordFieldData;

  TFileRecordDb = class
  private
   AnsIndex : TAnsIndexClass;
   DataList : TList;
   FieldList : TList;
   OpenedHeader : TFileRecordDbFileHeader;
   function GetNamePb (aName: string): pbyte;
   function GetPf (fname: string): PTFileRecordFieldData;
   function GetRecordCount: integer;
   function GetFieldCount: integer;
  public
   constructor Create (aNameSize: integer);
   destructor Destroy; override;
   procedure LoadFromFile (aFileName: string);
   procedure SaveToFile (aFileName: string);
   procedure LoadFromSdbFile (aFileName: string);
   procedure SaveToSdbFile (aFileName: string);

   procedure Clear;

   procedure AddField (aFieldName: string; aFieldType: TFieldType; aFieldSize: integer);
   procedure DeleteField (aFieldName: string);
   procedure SetFieldSize (aFieldName: string; aFieldType: TFieldType; aFieldSize: integer);
   procedure ConvertFieldType (aFieldName: string; aFieldType: TFieldType; aFieldSize: integer);

   function  add (aname: string): integer;
   function  delete (aname: string): Boolean;

   function  getfieldvaluestring (aname, fname: string): string;
   function  getfieldvalueinteger (aname, fname: string): integer;

   procedure setfieldvaluestring (aname, fname, adata: string);
   procedure setfieldvalueinteger (aname, fname: string; adata: integer);

   property  Count : integer read GetRecordCount;
   property  FieldCount : integer read GetFieldCount;
  end;

  TAnsIndexClass16 = class
  private
    IndexArr : array [0..16-1] of TAnsIndexclass;
    function    GetCount: integer;
    function    GetDataIndex (astr: string): integer;
  public
    constructor Create (aName: string; aDataSize: integer);
    destructor  Destroy; override;
    procedure   Clear;
    function    Insert (aNo: integer; astr: string): integer;
    procedure   Delete (astr: string);
    function    Select (astr: string): integer;
    property    Count : Integer read GetCount;
  end;

implementation

constructor TAnsIndexClass16.Create (aName: string; aDataSize: integer);
var i: integer;
begin
   for i := 0 to 16-1 do IndexArr[i] := TAnsIndexclass.Create (aName, aDataSize, TRUE);
end;

destructor  TAnsIndexClass16.Destroy;
var i: integer;
begin
   for i := 0 to 16-1 do IndexArr[i].Free;
   inherited destroy;
end;

function    TAnsIndexClass16.GetCount: integer;
var i, n: integer;
begin
   n := 0;
   for i := 0 to 16-1 do n := n + IndexArr[i].Count;
   Result := n;
end;

procedure   TAnsIndexClass16.Clear;
var i: integer;
begin
   for i := 0 to 16-1 do IndexArr[i].Clear;
end;

function    TAnsIndexClass16.GetDataIndex (astr: string): integer;
var i, n: integer;
begin
   n := 0;
   for i := 1 to Length(astr) do n := n + word (astr[i]);
   Result := n mod 16;
end;

function    TAnsIndexClass16.Insert (aNo: integer; astr: string): integer;
begin
   Result := IndexArr[ GetDataIndex (astr)].Insert (aNo, astr);
end;

procedure   TAnsIndexClass16.Delete (astr: string);
begin
   IndexArr[ GetDataIndex (astr)].delete (astr);
end;

function    TAnsIndexClass16.Select (astr: string): integer;
begin
   Result := IndexArr[ GetDataIndex (astr)].Select (astr);
end;


/////////////////////////////
//   파일구조체 리스트
/////////////////////////////
procedure TFileRecordDb.AddField (aFieldName: string; aFieldType: TFieldType; aFieldSize: integer);
var
   i, osize, nsize : integer;
   pfield : PTFileRecordFieldData;
   pbo, pbn : pbyte;
begin
   osize := OpenedHeader.rNameSize;
   for i := 0 to FieldList.Count -1 do begin
      pfield := FieldList[i];
      pfield^.rFieldStartPos := osize;
      osize := osize + pfield^.rFieldSize;
   end;

   new (pfield);
   StrPcopy (pfield^.rFieldName, aFieldName);
   pfield^.rFieldType := aFieldType;
   pfield^.rFieldSize := aFieldSize;
   pfield^.rFieldStartPos := 0;
   FieldList.Add (pfield);

   nsize := OpenedHeader.rNameSize;
   for i := 0 to FieldList.Count -1 do begin
      pfield := FieldList[i];
      pfield^.rFieldStartPos := nsize;
      nsize := nsize + pfield^.rFieldSize;
   end;

   OpenedHeader.rIdent := FILERECORDDB_ID;
   OpenedHeader.rCount := DataList.Count;
   OpenedHeader.rRecordSize := nsize;
   OpenedHeader.rDataFieldCount := FieldList.Count;

   for i := 0 to DataList.Count -1 do begin
      pbo := DataList[i];
      GetMem (pbn, nsize);
      FillChar (pbn^, nsize, 0);
      move (pbo^, pbn^, osize);
      dispose (pbo);
      DataList[i] := pbn;
   end;
end;

procedure TFileRecordDb.DeleteField (aFieldName: string);
begin
{
   OpenedHeader.rIdent := FILERECORDDB_ID;
   OpenedHeader.rCount := 0;
   OpenedHeader.rRecordSize := aNameSize;
   OpenedHeader.rNameSize := aNameSize;
   OpenedHeader.rDataFieldCount := 0;
}
end;

procedure TFileRecordDb.SetFieldSize (aFieldName: string; aFieldType: TFieldType; aFieldSize: integer);
begin
end;

procedure TFileRecordDb.ConvertFieldType (aFieldName: string; aFieldType: TFieldType; aFieldSize: integer);
begin
end;

constructor TFileRecordDb.Create (aNameSize: integer);
begin
   OpenedHeader.rIdent := FILERECORDDB_ID;
   OpenedHeader.rCount := 0;
   OpenedHeader.rRecordSize := aNameSize;
   OpenedHeader.rNameSize := aNameSize;
   OpenedHeader.rDataFieldCount := 0;
   AnsIndex := TAnsIndexClass.Create ('index', aNameSize, TRUE);
   DataList := TList.Create;
   FieldList := TList.Create;
   Clear;
end;

destructor  TFileRecordDb.Destroy;
var i: integer;
begin
   for i := 0 to DataList.Count -1 do dispose (DataList[i]);
   DataList.Free;
   for i := 0 to FieldList.Count -1 do dispose (FieldList[i]);
   FieldList.Free;
   AnsIndex.Free;
   inherited destroy;
end;

procedure TFileRecordDb.Clear;
var i: integer;
begin
   for i := 0 to DataList.Count -1 do dispose (DataList[i]);
   DataList.Clear;
   AnsIndex.Clear;

   OpenedHeader.rIdent := FILERECORDDB_ID;
   OpenedHeader.rCount := 0;
end;

function  TFileRecordDb.GetRecordCount: integer;
begin
   Result := DataList.Count;
end;

function  TFileRecordDb.GetFieldCount: integer;
begin
   Result := FieldList.Count;
end;

procedure TFileRecordDb.LoadFromFile (aFileName: string);
var
   i, cnt, rsize: integer;
   allocpb, pb, pdata : pbyte;
   pfield : PTFileRecordFieldData;
   FileHeader : TFileRecordDbFileHeader;
   Stream : TFileStream;
begin
   if not FileExists (aFileName) then exit;
   Stream := TFileStream.Create (aFileName, fmOpenRead);
   Stream.ReadBuffer (FileHeader, sizeof(FileHeader));
   if (FileHeader.rIdent <> FILERECORDDB_ID) then begin Stream.Free; exit; end;
   OpenedHeader := FileHeader;

   Clear;

   rsize := OpenedHeader.rNameSize;
   for i := 0 to FileHeader.rDataFieldCount -1 do begin
      new (pfield);
      Stream.ReadBuffer (pfield^, sizeof (TFileRecordFieldData) );
      FieldList.Add (pfield);
      pfield^.rFieldStartPos := rsize;
      rsize := rsize + pfield^.rFieldSize;
   end;

   cnt := rsize * OpenedHeader.rCount;
   GetMem (allocpb, cnt);
   Stream.ReadBuffer (allocpb^, cnt);
   Stream.Free;

   AnsIndex.Free;
   AnsIndex := TAnsIndexClass.Create ('Index', OpenedHeader.rNameSize, TRUE);

   pb := allocpb;
   for i := 0 to OpenedHeader.rCount -1 do begin
      GetMem (pdata, rsize);
      move (pb^, pdata^, rsize);
      inc (pb, rsize);
      DataList.Add (pdata);
      AnsIndex.Insert (Integer(pdata), StrPas (@pdata));
   end;
   FreeMem (allocpb, cnt);
end;

procedure TFileRecordDb.SaveToFile (aFileName: string);
var
   i, cnt, rsize: integer;
   allocpb, pb, pdata : pbyte;
   pfield : PTFileRecordFieldData;
   FileHeader : TFileRecordDbFileHeader;
   Stream : TFileStream;
begin
   FileHeader := OpenedHeader;
   FileHeader.rIdent := FILERECORDDB_ID;
   FileHeader.rCount := DataList.Count;
   FileHeader.rNameSize := OpenedHeader.rNameSize;
   FileHeader.rDataFieldCount :=FieldList.Count;

   if FileExists (aFileName) then DeleteFile (aFileName);
   Stream := TFileStream.Create (aFileName, fmCreate);
   Stream.WriteBuffer (FileHeader, sizeof(FileHeader));

   rsize := OpenedHeader.rNameSize;
   for i := 0 to FieldList.Count -1 do begin
      pfield := FieldList[i];
      Stream.ReadBuffer (pfield^, sizeof (TFileRecordFieldData) );
      rsize := rsize + pfield^.rFieldSize;
   end;

   cnt := rsize * OpenedHeader.rCount;
   GetMem (allocpb, cnt);

   pb := allocpb;
   for i := 0 to DataList.Count -1 do begin
      pdata := DataList[i];
      move (pdata^, pb^, rsize);
      inc (pb, rsize);
   end;
   Stream.WriteBuffer (allocpb^, cnt);
   FreeMem (allocpb, cnt);
   Stream.Free;
end;

procedure TFileRecordDb.LoadFromSdbFile (aFileName: string);
var
   i, j, tempnamesize, rsize: integer;
   str, rdstr : string;
   pf : PTFileRecordFieldData;
   SList : TStringList;
   pb : pchar;
begin
   SList := TStringList.Create;
   if not FileExists (aFileName) then exit;
   Clear;
   for i := 0 to FieldList.Count -1 do dispose (FieldList[i]);
   FieldList.Clear;

   SList.LoadFromFile (aFileName);
   if SList.Count = 0 then exit;

   str := SList[0];

   str := GetValidStr3 (str, rdstr, ',');   // Name
   while TRUE do begin
      str := GetValidStr3 (str, rdstr, ',');
      if rdstr = '' then break;
      new (pf);
      StrPcopy (@pf^.rFieldName, rdstr);
      pf^.rFieldType := ft_string;
      pf^.rFieldSize := 0;
      FieldList.Add (pf);
      if str = '' then break;
   end;

// Get Info Fieldsize
   tempnamesize := 0;
   for j := 1 to SList.Count -1 do begin
      str := SList[j];
      str := GetValidStr3 (str, rdstr, ',');
      if Length (rdstr)+1 > tempnamesize then tempnamesize := Length(rdstr)+1;
      for i := 0 to FieldList.Count -1 do begin
         pf := FieldList[i];
         str := GetValidStr3 (str, rdstr, ',');
         if Length(rdstr) + 1 > pf^.rFieldSize then pf^.rFieldSize := Length(rdstr) + 1;
      end;
   end;

   rsize := tempnamesize;
   for i := 0 to FieldList.Count -1 do begin
      pf := FieldList[i];
      pf^.rFieldStartPos := rsize;
      rsize := rsize + pf^.rFieldSize;
   end;

   OpenedHeader.rIdent := FILERECORDDB_ID;
   OpenedHeader.rCount := SList.Count -1;
   OpenedHeader.rRecordSize := rsize;
   OpenedHeader.rNameSize := tempnamesize;
   OpenedHeader.rDataFieldCount := FieldList.Count;

   for j := 1 to SList.Count -1 do begin
      GetMem (pb, rsize);
      DataList.Add (pb);
      str := SList[j];
      str := GetValidStr3 (str, rdstr, ',');
      StrPcopy (pb, rdstr);
      AnsIndex.Insert (integer(pb), rdstr);
      inc (pb, tempnamesize);
      for i := 0 to FieldList.Count -1 do begin
         pf := FieldList[i];
         str := GetValidStr3 (str, rdstr, ',');
         StrPcopy (pb, rdstr);
         inc (pb, pf^.rFieldSize);
      end;
   end;

   SList.Free;
end;

procedure TFileRecordDb.SaveToSdbFile (aFileName: string);
var
   i, j: integer;
   pb : pchar;
   str : string;
   SList : TStringList;
   pf : PTFileRecordFieldData;
begin
   SList := TStringList.Create;

   str := 'Name,';
   for i := 0 to FieldList.Count -1 do begin
      pf := FieldList[i];
      str := str + StrPas (pf^.rFieldName)+',';
   end;
   SList.add (str);

   for j := 0 to DataList.Count -1 do begin
      pb := DataList[j];

      str := StrPas (pb)+',';
      inc (pb, OpenedHeader.rNameSize);
      for i := 0 to FieldList.Count -1 do begin
         pf := FieldList[i];
         str := str + StrPas (pb) + ',';
         inc (pb, pf^.rFieldSize);
      end;
      SList.Add (str);
   end;

   SList.SaveToFile (aFileName);
   SList.Free;
end;

function  TFileRecordDb.add (aname: string): integer;
var pb : pbyte;
begin
   Result := -1;
   if AnsIndex.Select (aname) = -1 then exit;
   if Length (aname) >= OpenedHeader.rNameSize then exit;

   getmem (pb,OpenedHeader.rRecordSize);
   FillChar (pb^,OpenedHeader.rRecordSize, 0);
   StrPCopy (@pb, aname);
   Result := DataList.Add (pb);

   AnsIndex.Insert (integer(pb), aname);
   inc (OpenedHeader.rCount);
end;

function  TFileRecordDb.delete (aname: string): Boolean;
var i, n : integer;
begin
   Result := FALSE;
   n := AnsIndex.Select (aname);
   if n = -1 then exit;
   AnsIndex.delete (aname);

   Result := TRUE;
   for i := 0 to DataList.Count -1 do begin
      if INTEGER(DataList[i]) = n then begin
         dispose (DataList[i]);
         DataList.Delete (i);
         dec (OpenedHeader.rCount);
         exit;
      end;
   end;
end;

function  TFileRecordDb.GetNamePb (aName: string): pbyte;
var n: integer;
begin
   n := AnsIndex.Select (aname);
   if n <> -1 then Result := pbyte(n)
   else Result := nil;
end;

function  TFileRecordDb.Getpf (fname: string): PTFileRecordFieldData;
var i: integer;
begin
   Result := nil;
   for i := 0 to FieldList.Count -1 do begin
      if CompareText (PTFileRecordFieldData (FieldList[i]).rFieldName, fname) = 0 then begin
         Result := FieldList[i];
         exit;
      end;
   end;
end;


function  TFileRecordDb.getfieldvaluestring (aname, fname: string): string;
var
   pb : pbyte;
   pf : PTFileRecordFieldData;
begin
   Result := '';
   pb := GetNamePb (aname); if pb = nil then exit;
   pf := Getpf (fname);     if pf = nil then exit;
   inc (pb, pf^.rFieldStartPos);
   Result := StrPas (@pb);
end;

procedure TFileRecordDb.setfieldvaluestring (aname, fname, adata: string);
var
   pb : pbyte;
   pf : PTFileRecordFieldData;
begin
   pb := GetNamePb (aname); if pb = nil then exit;
   pf := Getpf (fname);     if pf = nil then exit;
   inc (pb, pf^.rFieldStartPos);
   StrPCopy (@pb, adata);
end;

function  TFileRecordDb.getfieldvalueinteger (aname, fname: string): integer;
var
   pb : pbyte;
   pf : PTFileRecordFieldData;
begin
   Result := 0;
   pb := GetNamePb (aname); if pb = nil then exit;
   pf := Getpf (fname);     if pf = nil then exit;
   inc (pb, pf^.rFieldStartPos);
   Result := PINTEGER (pb)^;
end;

procedure TFileRecordDb.setfieldvalueinteger (aname, fname: string; adata: integer);
var
   pb : pbyte;
   pf : PTFileRecordFieldData;
begin
   pb := GetNamePb (aname); if pb = nil then exit;
   pf := Getpf (fname);     if pf = nil then exit;
   inc (pb, pf^.rFieldStartPos);
   PINTEGER (pb)^ := adata;
end;



//////////////////////////
//   String 바꿈.
//////////////////////////
constructor TAnsStringClass.Create;
begin
   DataList := TList.Create;
end;

destructor TAnsStringClass.Destroy;
var i : integer;
begin
   for i := 0 to DataList.Count -1 do dispose (DataList[i]);
   DataList.Free;
   inherited destroy;
end;

function  TAnsStringClass.GetString (astr: string): string;
var
   i: integer;
   pd : PTConvStringData;
begin
   for i := 0 to DataList.Count -1 do begin
      pd := DataList[i];
      if pd^.rOrgstr = astr then begin
         Result := pd^.rviewStr;
         exit;
      end;
   end;
   result := astr;
end;

procedure TAnsStringClass.LoadFromFile (aFileName: string);
var
   i : integer;
   str: string;
   Stream : TFileStream;
   ACSFileHeader : TACSFileHeader;
   Buffer : array [0..200] of char;
   pd : PTConvStringData;
begin
   if not FileExists (aFileName) then exit;

   for i := 0 to DataList.Count -1 do dispose (DataList[i]);
   DataList.Clear;

   Stream := TFileStream.Create (aFileName, fmOpenRead);
   Stream.ReadBuffer (ACSFileHeader, sizeof (ACSFileHeader));
   for i := 0 to ACSFileHeader.Count -1 do begin
      new (pd);
      Stream.ReadBuffer (buffer, 200);
      Change4Bit (@buffer, 200);
      str := StrPas (buffer);
      if str = '' then str := 'New Line';
      pd^.rViewStr := str;

      Stream.ReadBuffer (buffer, 200);
      Change4Bit (@buffer, 200);
      str := StrPas (buffer);
      if str = '' then str := 'New Line';
      pd^.rOrgstr := str;
      DataList.Add (pd);
   end;
   Stream.Free;
end;
{
var
   i : integer;
   str, rdstr: string;
   StringList : TStringList;
   pd : PTConvStringData;
begin
   if not FileExists (aFileName) then exit;
   for i := 0 to DataList.Count -1 do dispose (DataList[i]);
   DataList.Clear;

   StringList := TStringList.Create;
   StringList.LoadFromFile (aFileName);

   for i := 0 to StringList.Count -1 do begin
      new (pd);
      str := StringList[i];
      str := GetValidStr3 (str, rdstr, ';');
      pd^.rOrgstr := rdstr;
      str := GetValidStr3 (str, rdstr, ';');
      pd^.rviewstr := rdstr;
      DataList.Add (pd);
   end;

   StringList.Free;
end;
}
/////////////////////////////////////
//         TDebug
/////////////////////////////////////

constructor TBlackBox.Create (aName: string);
begin
   BoxName := aName;
   DebugString := TStringList.Create;
   BoxFields := 'Name,';
end;

destructor  TBlackBox.Destroy;
begin
   SaveToFile;
   DebugString.free;
   inherited Destroy;
end;

procedure TBlackBox.SaveToFile;
begin
   if DebugString.Count <> 0 then begin
      DebugString.Insert (0, BoxFields);
      try
         DebugString.SaveToFile (BoxName);
      finally
         DebugString.Delete (0);
      end;
   end;
end;

procedure TBlackBox.Add (str:string);
begin
   if str <> '' then DebugString.add (str);
   if DebugString.Count > 5000 then DebugString.delete(0);
   if Pos ('Save', str) > 0 then SaveToFile;
end;

procedure TBlackBox.AddUnique (str:string);
var
   i :integer;
   flag : Boolean;
begin
   flag := TRUE;
   for i := 0 to DebugString.Count -1 do begin
      if DebugString[i] = str then flag := FALSE;
   end;
   if flag then Add (str);
end;


//////////////////////////////////////////////////
//             KingIndexClass
//////////////////////////////////////////////////

constructor TAnsIndexClass.Create (aName: string; aDataSize: integer; aBoString: Boolean);
begin
   FName := aname;
   DataList := TList.Create;
   FDataSize := aDataSize;
   FTag := 0;
   FboString := aboString;
end;

destructor  TAnsIndexClass.Destroy;
begin
   Clear;
   DataList.Free;
   inherited destroy;
end;

function    TAnsIndexClass.GetCount: integer;
begin
   Result := DataList.Count;
end;

procedure   TAnsIndexClass.SaveToFile (aFileName: string);
var
   i : integer;
   pd : PTAnsIndexData;
   str : string;
   StringList : TStringList;
begin
//   exit;
   StringList := TStringList.Create;

   for i := 0 to DataList.Count -1 do begin
      pd := DataList[i];
      str := IntToStr (pd^.No) + ',';
      if boString then begin
         str := str + StrPas (pchar (pd^.prdata) );
      end else begin
         str := str + IntToStr ( PINTEGER (pd^.prdata)^ );
      end;
      StringList.Add (str);
   end;

   StringList.SaveToFile (aFileName);
   StringList.Free;
end;

function   TAnsIndexClass.LoadFromIndexFile (aFileName: string): Boolean;
var
   i, cnt: integer;
   allocpb, pb : pbyte;
   pi: PTAnsIndexData;
   FileHeader : TAnsIndexFileHeader;
   Stream : TFileStream;
begin
   Result := FALSE;
   if not FileExists (aFileName) then exit;
   Stream := TFileStream.Create (aFileName, fmOpenReadWrite);
   Stream.ReadBuffer (FileHeader, sizeof(FileHeader));

   if (FileHeader.Ident <> KINGDBINDEX_ID) or (not FileHeader.boSavedIndex) then begin
      Stream.Free;
      exit;
   end;

   Result := TRUE;

   Clear;

   FileHeader.boSavedindex := FALSE;
   Stream.Seek (0, soFromBeginning);
   Stream.WriteBuffer (FileHeader, sizeof(FileHeader));

   cnt := (FileHeader.DataSize + 4) * FileHeader.Count;
   GetMem (allocpb, cnt);
   Stream.ReadBuffer (allocpb^, cnt);
   Stream.Free;

   FDataSize := FileHeader.DataSize;

   pb := allocpb;
   for i := 0 to FileHeader.Count -1 do begin
      new (pi);
      getmem (pi^.prdata, FDataSize);
      FillChar (pi^.prdata^, FDataSize, 0);

      move (pb^, pi^.No, 4);               inc (pb, 4);
      move (pb^, pi^.prdata^, FDataSize);   inc (pb, FDataSize);
      DataList.Add (pi);
   end;
   FreeMem (allocpb, cnt);
end;

procedure   TAnsIndexClass.SaveToIndexFile (aFileName: string);
var
   i, cnt: integer;
   allocpb, pb : pbyte;
   pi : PTAnsIndexData;
   FileHeader : TAnsIndexFileHeader;
   Stream : TFileStream;
begin
   FillChar (FileHeader, sizeof(TAnsIndexFileHeader), 0);
   FileHeader.Ident := KINGDBINDEX_ID;
   FileHeader.Count := DataList.Count;
   FileHeader.DataSize := FDataSize;
   FileHeader.boSavedindex := TRUE;

   if FileExists (aFileName) then DeleteFile (aFileName);
   Stream := TFileStream.Create (aFileName, fmCreate);
   Stream.WriteBuffer (FileHeader, sizeof(FileHeader));

   cnt := (FDataSize + 4) * DataList.Count;
   GetMem (allocpb, cnt);
   pb := allocpb;
   for i := 0 to DataList.Count -1 do begin
      pi := DataList[i];
      move (pi^.No, pb^, 4);               inc (pb, 4);
      move (pi^.prdata^, pb^, FDataSize);   inc (pb, FDataSize);
   end;
   Stream.WriteBuffer (allocpb^, cnt);
   FreeMem (allocpb, cnt);
   Stream.Free;
end;

procedure   TAnsIndexClass.Clear;
var i: integer;
begin
   for i := DataList.Count-1 downto 0 do begin
      FreeMem (PTAnsIndexData (DataList[i])^.prdata);
      dispose (DataList[i]);
      DataList.Delete (i);
   end;
end;

function    TAnsIndexClass.IndexCompare (pdata1, pdata2: pbyte): integer;
var i : integer;
begin
   if boString then begin
      Result := 0;
      for i := 0 to DataSize-1 do begin
         Result := pdata1^ - pdata2^;
         if Result <> 0 then exit;
         inc (pdata1); inc (pdata2);
      end;
   end else begin
      Result := PINTEGER (pdata1)^ - PINTEGER(pdata2)^;
   end;
end;

function    TAnsIndexClass.FindIndex (apdata: pbyte): integer;
var
   i, ret, lpos, hpos, cpos: integer;
begin
   Result := -1;
   if DataList.Count = 0 then exit;

   hpos := DataList.Count-1;
   lpos := 0;
   cpos := (lpos+hpos) div 2;

   for i := 0 to 32-1 do begin
      ret := IndexCompare (apdata, PTAnsIndexData (DataList[cpos])^.prdata);
      if ret = 0 then begin Result := cpos; exit; end;

      if ret > 0 then lpos := cpos
      else hpos := cpos;
      cpos := (lpos + hpos) div 2;

      if hpos - lpos < 3 then break;
   end;

   for i := lpos to hpos do begin
      ret := IndexCompare (apdata, PTAnsIndexData (DataList[i])^.prdata );
      if ret = 0 then begin Result := i; exit; end;
   end;
end;

function   TAnsIndexClass.Insert (aNo: integer; astr: string): integer;
   function    FindIndex2 (apdata: pbyte): integer;
   var
      i, ret, lpos, hpos, cpos: integer;
   begin
      Result := 0;
      if DataList.Count = 0 then exit;

      hpos := DataList.Count-1;
      lpos := 0;
      cpos := (lpos+hpos) div 2;

      for i := 0 to 32-1 do begin
         ret := IndexCompare (apdata, PTAnsIndexData (DataList[cpos])^.prdata);
         if ret > 0 then lpos := cpos
         else hpos := cpos;
         cpos := (lpos + hpos) div 2;

         if hpos - lpos < 3 then break;
      end;

      hpos := hpos + 1;   // 5
      lpos := lpos - 1;   // 5
      if hpos >= DataList.Count then hpos := DataList.Count -1;
      if lpos < 0 then lpos := 0;

      for i := lpos to hpos do begin
         ret := IndexCompare (apdata, PTAnsIndexData (DataList[i])^.prdata );
         if ret < 0 then begin Result := i; exit; end;
      end;
      Result := DataList.Count;
   end;
var
   pid : PTAnsIndexData;
begin
   new (pid);
   getmem (pid^.prdata, DataSize);

   pid^.No := aNo;
   FillChar (pid^.prdata^, DataSize, 0);
   if boString then StrPcopy (pchar (pid^.prdata), astr)
   else PINTEGER (pid^.prdata)^ := _StrToInt (astr);

   Result := FindIndex2 (pid^.prdata);
   if Result <> DataList.Count then DataList.insert (Result, pid)
   else DataList.Add (pid);
end;

procedure   TAnsIndexClass.Delete (astr: string);
var
   index: integer;
   temp : array [0..256-1] of byte;
begin
   FillChar (temp, DataSize, 0);
   if boString then StrPCopy (@temp, astr)
   else PINTEGER (@Temp)^ := _StrToInt (astr);

   index := FindIndex (@temp);
   if index <> -1 then begin
      FreeMem (PTAnsIndexData (DataList[index])^.prdata);
      dispose (DataList[index]);
      DataList.Delete (index);
   end;
end;

function    TAnsIndexClass.Select (astr: string): integer;
var
   index: integer;
   temp : array [0..256-1] of byte;
begin
   Result := -1;
   FillChar (temp, DataSize, 0);
   if boString then begin
      if Length(aStr) > 255 then exit
      else StrPCopy (@temp, astr);
   end else begin
      PINTEGER (@Temp)^ := _StrToInt (astr);
   end;
   index := FindIndex (@temp);
   if index = -1 then exit;
   Result := PTAnsIndexData (DataList[index])^.No;
end;

function    TAnsIndexClass.GetIndexString (aindex: integer): string;
var pd : PTAnsIndexData;
begin
   Result := '';
   if aindex < 0 then exit;
   if aindex >= DataList.Count then exit;
   pd := DataList[aindex];

   if boString then begin
      Result := StrPas (pchar (pd^.prdata) );
   end else begin
      Result := IntToStr ( PINTEGER (pd^.prdata)^ );
   end;
end;

function    TAnsIndexClass.GetIndexNo (aindex: integer): integer;
var pd : PTAnsIndexData;
begin
   Result := -1;
   if aindex < 0 then exit;
   if aindex >= DataList.Count then exit;
   pd := DataList[aindex];

   Result := pd^.No;
end;

//////////////////////////////////
//          AnsList
//////////////////////////////////

constructor TAnsList.Create (sbuffer: integer; aAllocFunction: TAnsListAllocFunction; aFreeFunction: TAnsListFreeFunction);
var i : integer;
begin
   FMaxUnUsedCount := 100;
   DataList := TList.Create;
   UnUsedList := TList.Create;

   AllocFunction := aAllocFunction;
   FreeFunction :=  aFreeFunction;

   for i := 0 to sbuffer-1 do UnUsedList.Add (AllocFunction);
end;

destructor TAnsList.Destroy;
var i : integer;
begin
   for i := 0 to UnUsedList.Count -1 do FreeFunction (UnUsedList[i]);
   for i := 0 to DataList.Count -1 do FreeFunction (DataList[i]);
   UnUsedList.Free;
   DataList.Free;
   inherited destroy;
end;

function   TAnsList.GetData (index: integer) : pointer;
begin
   Result := DataList[index];
end;

function   TAnsList.GetCount:integer;
begin
   Result := DataList.Count;
end;

function   TAnsList.GetUnUsedPointer: pointer;
var
   n : Integer;
begin
   if UnUsedList.Count > 0 then begin
      n := UnUsedList.Count;
      Result := UnUsedList[n - 1];
      UnUsedList.Delete (n - 1);
   end else begin
      Result := AllocFunction;
   end;
end;

procedure  TAnsList.Delete (index: integer);
var
   n : Integer;
begin
   if index < DataList.Count then begin
      UnUsedList.Add (DataList[index]);
      DataList.Delete (index);

      if FMaxUnUsedCount < 0 then exit;

      if FMaxUnUsedCount < UnUsedList.Count then begin
         n := UnUsedList.Count;
         FreeFunction (UnUsedList[n - 1]);
         UnUsedList.Delete (n - 1);
      end;
      if FMaxUnUsedCount < UnUsedList.Count then begin
         n := UnUsedList.Count;
         FreeFunction (UnUsedList[n - 1]);
         UnUsedList.Delete (n - 1);
      end;
   end;
end;

function   TAnsList.Add (item: Pointer):integer;
begin
   Result := DataList.Add (item);
end;

procedure  TAnsList.Insert (index:integer; item: Pointer);
begin
   DataList.Insert (index, item);
end;

end.
