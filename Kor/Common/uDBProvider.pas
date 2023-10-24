unit uDBProvider;

interface

uses
   Windows, Classes, SysUtils, StdCtrls, ComCtrls, mmSystem, uRecordDef,uCookie,
   uUtil, DefType;

const
   MAX_OPEN_FILE = 64;

type

   TIndexData = record
      Name : String [32];
      FileNo : Integer;
      RecordNo : Integer;
   end;
   PTIndexData = ^TIndexData;
   TBlankData = record
      FileNo : Integer;
      RecordNo : Integer;
   end;
   PTBlankData = ^TBlankData;

   TIndexClass = class
   private
      Header : TIndexHeader;
      RecordBuffer : TIndexData;

      DataList : TList;
      LastErrorStr : String;

      function GetCount : Integer;
   public
      constructor Create;
      destructor Destroy; override;

      procedure Clear;
      procedure Sort;

      function LoadFromFile (aFileName : String; var aBlankList : TList) : Boolean;
      function SaveToFile (aFileName : String; var aBlankList : TList) : Boolean;

      function Add (aName : String; aFileNo, aRecordNo : Integer) : Byte;
      function Delete (aName : String) : Byte;
      function Select (aName : String; var aFileNo, aRecordNo : Integer) : Boolean;
      function SelectByIndex (aIndex : Integer; var aFileNo, aRecordNo : Integer) : Boolean;

      function Insert (aName : String; aFileNo, aRecordNo : Integer) : Byte;
      function GetInsertPos (aName : String) : Integer;

      procedure Print (aControl : TMemo);

      property GetLastErrorStr : String read LastErrorStr;
      property Count : Integer read GetCount;
   end;

   TDBProvider = class
   private
      FullName : String;

      FilePath, FileName, FileExt : String;
      FileCount : Integer;

      DBStream : array [0..MAX_OPEN_FILE - 1] of TFileStream;
      Header : array [0..MAX_OPEN_FILE - 1] of TDBHeader;

      RecordBuffer : TDBRecord;

      IndexClass : TIndexClass;
      BlankList : TList;

      PrintControl : TMemo;

      LastErrorStr : String;

      function GetTotalRecordCount : Integer;
      function GetUsedRecordCount : Integer;
      function GetUnusedRecordCount : Integer;

      function GetFileName (aNo : Integer) : String;
      function GetFreeFileNo : Integer;
   public
      constructor Create (aFileName : String);
      destructor Destroy; override;

      function CreateDB : Boolean;
      function OpenDB : Boolean;
      function CloseDB : Boolean;

      function AddBlankRecord (aCount : Integer) : Boolean;

      procedure Clear;

      function SelectDisk (aIndexName : String; aDBRecord : PTDBRecord) : Byte;
      function UpdateDisk (aIndexName : String; aDBRecord : PTDBRecord) : Byte;

      function Select (aIndexName : String; aDBRecord : PTDBRecord) : Byte;
      function Insert (aIndexName : String; aDBRecord : PTDBRecord) : Byte;
      function Delete (aIndexName : String) : Byte;
      function Update (aIndexName : String; aDBRecord : PTDBRecord) : Byte;

      function ChangeDataToWebStr (aDBRecord : PTDBRecord) : String;
      function ChangeDataToStr (aDBRecord : PTDBRecord) : String;
      procedure ChangeStrToData (aStr : String; var DBRecord : TDBRecord);

      procedure SetPrintControl (aMemo : TMemo);
      procedure ShowInfo (aStr : String);

      procedure BackupHeader (aStream : TFileStream);
      function BackupRecord (aStream : TFileStream; aIndex : Integer) : Boolean;

      property TotalRecordCount : Integer read GetTotalRecordCount;
      property UsedRecordCount : Integer read GetUsedRecordCount;
      property UnusedRecordCount : Integer read GetUnusedRecordCount;
   end;

   function IndexSortCompare (Item1, Item2: Pointer): Integer;

var
   DBProvider : TDBProvider = nil;

implementation

uses
   FMain, uLevelExp;

function IndexSortCompare (Item1, Item2: Pointer): Integer;
var
   pd1, pd2 : PTIndexData;
begin
   Result := 0;
   
   pd1 := PTIndexData (Item1);
   pd2 := PTIndexData (Item2);

   if pd1^.Name > pd2^.Name then begin
      Result := 1;
   end else if pd1^.Name < pd2^.Name then begin
      Result := -1;
   end;
end;

// TIndexClass

constructor TIndexClass.Create;
begin
   LastErrorStr := '';

   FillChar (Header, SizeOf (TIndexHeader), 0);
   FillChar (RecordBuffer, SizeOf (TIndexData), 0);
   DataList := TList.Create;
end;

destructor TIndexClass.Destroy;
begin
   Clear;
   DataList.Free;

   inherited Destroy;
end;

procedure TIndexClass.Clear;
var
   i : Integer;
   pd : PTIndexData;
begin
   for i := 0 to DataList.Count - 1 do begin
      pd := DataList.Items [i];
      if pd <> nil then Dispose (pd);
   end;
   DataList.Clear;
end;

function TIndexClass.GetCount : Integer;
begin
   Result := DataList.Count;
end;

procedure TIndexClass.Sort;
begin
   DataList.Sort (IndexSortCompare);
end;

function TIndexClass.LoadFromFile (aFileName : String; var aBlankList : TList) : Boolean;
var
   i : Integer;
   nCode : byte;
   nCount : Integer;
   Stream : TFileStream;

   IndexData : TIndexData;
   BlankData : TBlankData;
   pd : PTBlankData;
begin
   Result := false;

   if not FileExists (aFileName) then exit;

   Stream := nil;
   try
      Stream := TFileStream.Create (aFileName, fmOpenReadWrite);
      Stream.ReadBuffer (Header, SizeOf (TIndexHeader));
   except
      if Stream <> nil then Stream.Free;
      exit;
   end;

   Header.ID[3] := 0;
   if StrPas (@Header.ID) <> IndexID then begin
      Stream.Free;
      exit;
   end;

   try
      nCount := 0;
      for i := 0 to Header.IndexRecordCount - 1 do begin
         Stream.ReadBuffer (IndexData, SizeOf (TIndexData));
         nCode := Add (IndexData.Name, IndexData.FileNo, IndexData.RecordNo);
         if nCode <> DB_OK then break;
         nCount := nCount + 1;
      end;
      Header.IndexRecordCount := nCount;

      nCount := 0;
      for i := 0 to Header.BlankRecordCount - 1 do begin
         Stream.ReadBuffer (BlankData, SizeOf (TBlankData));
         New (pd);
         pd^.RecordNo := i;
         aBlankList.Add (pd);
         nCount := nCount + 1;
      end;
      Header.BlankRecordCount := nCount;
   except
      if Stream <> nil then Stream.Free;
      exit;
   end;
   Stream.Free;

   Result := true;
end;

function TIndexClass.SaveToFile (aFileName : String; var aBlankList : TList) : Boolean;
var
   i : Integer;
   Stream : TFileStream;

   pid : PTIndexData;
   pbd : PTBlankData;
begin
   Result := false;

   if FileExists (aFileName) then DeleteFile (aFileName);

   StrPCopy (@Header.ID, IndexID);
   Header.IndexRecordCount := DataList.Count;
   Header.BlankRecordCount := aBlankList.Count;

   Stream := nil;
   try
      Stream := TFileStream.Create (aFileName, fmCreate);
      Stream.WriteBuffer (Header, SizeOf (TIndexHeader));
   except
      if Stream <> nil then Stream.Free;
      exit;
   end;
   
   try
      for i := 0 to Header.IndexRecordCount - 1 do begin
         pid := DataList.Items [i];
         Stream.WriteBuffer (pid^, SizeOf (TIndexData));
      end;
      for i := 0 to Header.BlankRecordCount - 1 do begin
         pbd := aBlankList.Items [i];
         Stream.WriteBuffer (pbd^, SizeOf (TBlankData));
      end;
   except
      if Stream <> nil then Stream.Free;
      exit;
   end;

   Stream.Free;
   Result := true;

end;

procedure TIndexClass.Print (aControl : TMemo);
var
   i : Integer;
   pd : PTIndexData;
begin
   for i := 0 to DataList.Count - 1 do begin
      pd := DataList.Items [i];
      aControl.Lines.Add (pd^.Name);
   end;
end;

function TIndexClass.Add (aName : String; aFileNo, aRecordNo : Integer) : Byte;
var
   nFile, nPos : Integer;
   pd : PTIndexData;
begin
   Result := DB_OK;

   if aName = '' then begin
      LastErrorStr := 'Invalid Name';
      Result := DB_ERR_INVALIDDATA;
      exit;
   end;

   if Select (aName, nFile, nPos) = true then begin
      LastErrorStr := 'Invalid Key (same key is already being)';
      Result := DB_ERR_DUPLICATE;
      exit;
   end;

   New (pd);
   pd^.Name := aName;
   pd^.FileNo := aFileNo;
   pd^.RecordNo := aRecordNo;

   DataList.Add (pd);
end;

function TIndexClass.Insert (aName : String; aFileNo, aRecordNo : Integer) : Byte;
var
   nFile, nPos : Integer;
   pd : PTIndexData;
begin
   Result := DB_OK;

   if aName = '' then begin
      LastErrorStr := 'Invalid Name';
      Result := DB_ERR_INVALIDDATA;
      exit;
   end;

   if Select (aName, nFile, nPos) = true then begin
      LastErrorStr := 'Invalid Key (same key is already being)';
      Result := DB_ERR_DUPLICATE;
      exit;
   end;

   New (pd);
   pd^.Name := aName;
   pd^.FileNo := aFileNo;
   pd^.RecordNo := aRecordNo;

   nPos := GetInsertPos (aName);
   if nPos < 0 then begin
      Result := DB_ERR_DUPLICATE;
      exit;
   end;

   DataList.Insert (nPos, pd);

   {
   for i := 0 to DataList.Count - 1 do begin
      pd := DataList.Items[i];
      frmMain.AddLog (pd^.Name);
   end;
   }
end;

function TIndexClass.Delete (aName : String) : Byte;
var
   nFile, nPos : Integer;
   pd : PTIndexData;
begin
   Result := DB_OK;

   if Select (aName, nFile, nPos) = true then begin
      Result := DB_ERR_NOTFOUND;
      exit;
   end;

   pd := DataList.Items [nPos];
   Dispose (pd);

   DataList.Delete (nPos);
end;

function TIndexClass.Select (aName : String; var aFileNo, aRecordNo : Integer) : Boolean;
var
   HighPos, LowPos, MidPos : Integer;
   pd : PTIndexData;
begin
   Result := false;

   LowPos := 0;
   HighPos := DataList.Count - 1;
   MidPos := (LowPos + HighPos) div 2;

   while LowPos <= HighPos do begin
      pd := DataList.Items [MidPos];
      if pd^.Name = aName then begin
         aFileNO := pd^.FileNo;
         aRecordNo := pd^.RecordNo;
         Result := true;
         exit;
      end else if pd^.Name > aName then begin
         HighPos := MidPos - 1;
      end else begin
         LowPos := MidPos + 1;
      end;
      MidPos := (LowPos + HighPos) div 2;
   end;
end;

function TIndexClass.SelectByIndex (aIndex : Integer; var aFileNo, aRecordNo : Integer) : Boolean;
var
   pd : PTIndexData;
begin
   Result := false;
   if aIndex >= DataList.Count then exit;

   pd := DataList.Items [aIndex];

   aFileNo := pd^.FileNo;
   aRecordNo := pd^.RecordNo;
   Result := true;
end;

function TIndexClass.GetInsertPos (aName : String) : Integer;
var
   HighPos, LowPos, MidPos : Integer;
   pd : PTIndexData;
begin
   Result := -1;

   LowPos := 0;
   HighPos := DataList.Count - 1;
   MidPos := (LowPos + HighPos) div 2;

   while LowPos <= HighPos do begin
      pd := DataList.Items [MidPos];
      if pd^.Name = aName then begin
         exit;
      end else if pd^.Name > aName then begin
         HighPos := MidPos - 1;
      end else begin
         LowPos := MidPos + 1;
      end;
      MidPos := (LowPos + HighPos) div 2;
   end;

   if HighPos >= 0 then MidPos := MidPos + 1;
   
   Result := MidPos;
end;

// TDBProvider
constructor TDBProvider.Create (aFileName : String);
var
   i, nPos : Integer;
begin
   FullName := aFileName;

   FilePath := ExtractFilePath (FullName);   // '..\'
   FileName := ExtractFileName (FullName);   // 'createdb'
   FileExt := ExtractFileExt (FullName);     // '.fdb'
   nPos := Pos (FileExt, FileName);
   if nPos >= 1 then begin
      FileName := Copy (FileName, 1, nPos - 1);
   end;


   FileCount := 0;

   for i := 0 to MAX_OPEN_FILE - 1 do begin
      DBStream [i] := nil;
      FillChar (Header [i], sizeof (TDBHeader), 0);
   end;
   IndexClass := nil;
   BlankList := nil;
   LastErrorStr := '';

   PrintControl := nil;
end;

destructor TDBProvider.Destroy;
begin
   Clear;
   inherited Destroy;
end;

function TDBProvider.GetTotalRecordCount : Integer;
var
   i, iCount : Integer;
begin
   iCount := 0;
   for i := 0 to FileCount - 1 do begin
      iCount := iCount + Header [i].RecordCount;
   end;

   Result := iCount;
end;

function TDBProvider.GetUsedRecordCount : Integer;
begin
   Result := IndexClass.Count;
end;

function TDBProvider.GetUnusedRecordCount : Integer;
begin
   Result := BlankList.Count;
end;

function TDBProvider.GetFileName (aNo : Integer) : String;
begin
   Result := '';
   if aNo < 10 then begin
      Result := format ('%s%s0%d%s', [FilePath, FileName, aNo, FileExt]);
   end else begin
      Result := format ('%s%s%d%s', [FilePath, FileName, aNo, FileExt]);
   end;
end;

function TDBProvider.GetFreeFileNo : Integer;
var
   i, FileNo, MaxCount : Integer;
begin
   Result := 0;

   MaxCount := 1024 * 1024 * 1024 div Header [0].RecordFullSize;

   FileNo := FileCount;
   for i := 0 to FileCount - 1 do begin
      if Header [i].RecordCount < MaxCount then begin
         FileNo := i;
         break;
      end;
   end;

   Result := FileNo;
end;

function TDBProvider.CreateDB : Boolean;
begin
   Result := false;

   Clear;

   if FileExists (GetFileName (0)) then exit;

   ShowInfo (format ('%s creating...', [FullName]));

   try
      FillChar (Header [0], SizeOf (TDBHeader), 0);
      StrPCopy (@Header [0].ID, 'DBID');
      Header [0].RecordCount := 0;
      Header [0].RecordDataSize := SizeOf (TDBRecord) - 1;
      Header [0].RecordFullSize := SizeOf (TDBRecord);
      Header [0].boSavedIndex := FALSE;
      DBStream [0] := TFileStream.Create (GetFileName (0), fmCreate);
      DBStream [0].WriteBuffer (Header [0], sizeof (TDBHeader));
      DBStream [0].Free;
      DBStream [0] := nil;
   except
      exit;
   end;

   ShowInfo ('completed');
   Result := true;
end;

function TDBProvider.AddBlankRecord (aCount : Integer) : Boolean;
var
   i, MaxCount, CurFileNo, FreeFileNo : Integer;
   pd : PTBlankData;
begin
   Result := false;
   if DBStream [0] = nil then exit;

   try
      MaxCount := 1024 * 1024 * 1024 div Header [0].RecordFullSize;
      FillChar (RecordBuffer, SizeOf (TDBRecord), 0);

      FreeFileNo := GetFreeFileNo;

      CurFileNo := -1;
      for i := 0 to aCount - 1 do begin
         if FreeFileNo < FileCount then begin
            if CurFileNo <> FreeFileNo then begin
               CurFileNo := FreeFileNo;
               DBStream [CurFileNo].Seek (SizeOf (TDBHeader) + Header [CurFileNo].RecordCount * Header [CurFileNo].RecordFullSize, soFromBeginning);
            end;
            DBStream [CurFileNo].WriteBuffer (RecordBuffer, SizeOf (TDBRecord));
            Header [CurFileNo].RecordCount := Header [CurFileNo].RecordCount + 1;
            New (pd);
            pd^.FileNo := CurFileNo;
            pd^.RecordNo := Header [CurFileNo].RecordCount;
            BlankList.Add (pd);

            if Header [CurFileNo].RecordCount >= MaxCount then begin
               DBStream [CurFileNo].Seek (0, soFromBeginning);
               DBStream [CurFileNo].WriteBuffer (Header [CurFileNo], SizeOf (TDBHeader));
               FreeFileNo := GetFreeFileNo;
               CurFileNo := -1;
            end;
         end else begin
            FillChar (Header [FreeFileNo], SizeOf (TDBHeader), 0);
            StrPCopy (@Header [FreeFileNo].ID, 'DBID');
            Header [FreeFileNo].RecordCount := 0;
            Header [FreeFileNo].RecordDataSize := SizeOf (TDBRecord) - 1;
            Header [FreeFileNo].RecordFullSize := SizeOf (TDBRecord);
            Header [FreeFileNo].boSavedIndex := FALSE;

            DBStream [FreeFileNo] := TFileStream.Create (GetFileName (FreeFileNo), fmCreate);
            DBStream [FreeFileNo].WriteBuffer (Header [FreeFileNo], sizeof (TDBHeader));
            DBStream [FreeFileNo].Free;
            DBStream [FreeFileNo] := TFileStream.Create (GetFileName (FreeFileNo), fmOpenReadWrite);
            DBStream [FreeFileNo].ReadBuffer (Header [FreeFileNo], sizeof (TDBHeader));
            DBStream [FreeFileNo].WriteBuffer (RecordBuffer, SizeOf (TDBRecord));
            Header [FreeFileNo].RecordCount := Header [FreeFileNo].RecordCount + 1;

            New (pd);
            pd^.FileNo := FreeFileNo;
            pd^.RecordNo := Header [FreeFileNo].RecordCount;
            BlankList.Add (pd);

            FileCount := FileCount + 1;
            CurFileNo := FreeFileNo;
         end;
      end;

      if CurFileNo <> -1 then begin
         DBStream [CurFileNo].Seek (0, soFromBeginning);
         DBStream [CurFileNo].WriteBuffer (Header [CurFileNo], SizeOf (TDBHeader));
      end;
   except
      exit;
   end;
   Result := true;
end;

function TDBProvider.OpenDB : Boolean;
var
   i, j, nFile, nPos : Integer;
   nCount : Integer;
   StartTick, EndTick, TickSum : Integer;
   nMin, nSec, nMSec : Word;
   nCode : Byte;
   pd : PTBlankData;
begin
   Result := false;

   Clear;

   ShowInfo (format ('%s reading...', [FullName]));

   StartTick := timeGetTime;
   IndexClass := TIndexClass.Create;
   BlankList := TList.Create;

   try
      FileCount := 0;
      for i := 0 to MAX_OPEN_FILE - 1 do begin
         if not FileExists (GetFileName (i)) then break;

         DBStream [i] := TFileStream.Create (GetFileName (i), fmOpenReadWrite);
         DBStream [i].ReadBuffer (Header [i], sizeof (TDBHeader));
         Inc (FileCount);
      end;
   except
      exit;
   end;

   if FileCount = 0 then exit;

   // IndexFileName := ChangeFileExt (FileName, '.IDX');
   // if IndexClass.LoadFromFile (IndexFileName, BlankList) = false then begin

   for j := 0 to FileCount - 1 do begin
      try
         nCount := 0;
         for i := 0 to Header [j].RecordCount - 1 do begin
            // DBStream.Seek (sizeof (TDBHeader) + (i * Header.RecordFullSize), soFromBeginning);
            DBStream [j].ReadBuffer (RecordBuffer, sizeof (TDBRecord));
            if RecordBuffer.boUsed = 1 then begin
               nCode := IndexClass.Add (StrPas (@RecordBuffer.PrimaryKey), j, i);
               if nCode <> DB_OK then begin
                  ShowInfo (format ('Invalid Data at %d (%s)', [i + 1, StrPas (@RecordBuffer.PrimaryKey)]));
                  ShowInfo (format ('-> %s', [IndexClass.GetLastErrorStr]));
                  ShowInfo (format ('-> %s,%s', [StrPas (@RecordBuffer.PrimaryKey), StrPas (@RecordBuffer.MasterName)]));

                  if IndexClass.Select (StrPas (@RecordBuffer.PrimaryKey), nFile, nPos) = true then begin
                     DBStream [nFile].Seek (sizeof (TDBHeader) + (nPos * Header [nFile].RecordFullSize), soFromBeginning);
                     DBStream [nFile].ReadBuffer (RecordBuffer, sizeof (TDBRecord));
                     ShowInfo (format ('-> %s,%s', [StrPas (@RecordBuffer.PrimaryKey), StrPas (@RecordBuffer.MasterName)]));
                  end;

                  // 잘못된 레코드는 새로 추가할수 있도록 빈레코드로 한다
                  New (pd);
                  pd^.FileNo := j;
                  pd^.RecordNo := i;
                  BlankList.Add (pd);

                  FillChar (RecordBuffer, SizeOf (TDBRecord), 0);
                  DBStream [j].Seek (sizeof (TDBHeader) + (i * Header [j].RecordFullSize), soFromBeginning);
                  DBStream [j].WriteBuffer (RecordBuffer, sizeof (TDBRecord));
               end;
            end else begin
               new (pd);
               pd^.FileNo := j;
               pd^.RecordNo := i;
               BlankList.Add (pd);
            end;
            Inc (nCount);
         end;
      except
         Header [j].RecordCount := nCount;
         ShowInfo (format ('Record Read failed at %d', [nCount]));
      end;
   end;
   EndTick := timeGetTime;

   TickSum := EndTick - StartTick;
   nMin := TickSum div (1000 * 60);
   TickSum := TickSum - (1000 * 60 * nMin);
   nSec := TickSum div 1000;
   TickSum := TickSum - (1000 * nSec);
   nMSec := TickSum;

   ShowInfo (format ('Elasped Time %d min %d sec %d', [nMin, nSec, nMSec]));

   ShowInfo (format ('Record Count (Header Value) : %d', [GetTotalRecordCount]));
   ShowInfo (format ('Used Record Count   : %d', [IndexClass.Count]));
   ShowInfo (format ('Unused Record Count : %d', [BlankList.Count]));
   ShowInfo ('Sorting...');
   StartTick := timeGetTime;
   IndexClass.Sort;
   EndTick := timeGetTime;

   TickSum := EndTick - StartTick;
   nMin := TickSum div (1000 * 60);
   TickSum := TickSum - (1000 * 60 * nMin);
   nSec := TickSum div 1000;
   TickSum := TickSum - (1000 * nSec);
   nMSec := TickSum;

   ShowInfo (format ('Elasped Time %d min %d sec %d', [nMin, nSec, nMSec]));

   ShowInfo ('read completed');

   // IndexClass.Print (PrintControl);
   Result := true;
end;

function TDBProvider.CloseDB : Boolean;
begin
   Result := true;
   Clear;
end;

procedure TDBProvider.Clear;
var
   i : Integer;
   pd : PTBlankData;
begin
   for i := 0 to FileCount - 1 do begin
      if DBStream [i] <> nil then begin
         DBStream [i].Free;
         DBStream [i] := nil;
      end;
   end;
   if IndexClass <> nil then IndexClass.Free;
   if BlankList <> nil then begin
      for i := 0 to BlankList.Count - 1 do begin
         pd := BlankList.Items [i];
         Dispose (pd);
      end;
      BlankList.Clear;
      BlankList.Free;
   end;

   IndexClass := nil;
   BlankList := nil;
end;

function TDBProvider.SelectDisk (aIndexName : String; aDBRecord : PTDBRecord) : Byte;
var
   nFile, nPos : Integer;
begin
   Result := DB_OK;

   if IndexClass.Select (aIndexName, nFile, nPos) = false then begin
      Result := DB_ERR_NOTFOUND;
      exit;
   end;

   try
      DBStream [nFile].Seek (sizeof (TDBHeader) + (nPos * Header [nFile].RecordFullSize), soFromBeginning);
      DBStream [nFile].ReadBuffer (aDBRecord^, sizeof (TDBRecord));

      if StrPas (@aDBRecord^.PrimaryKey) <> aIndexName then begin
         Result := DB_ERR_NOTFOUND;
         exit;
      end;
   except
      Result := DB_ERR_IO;
   end;
end;

function TDBProvider.UpdateDisk (aIndexName : String; aDBRecord : PTDBRecord) : Byte;
var
   nFile, nPos : Integer;
   DBRecord : TDBRecord;
begin
   Result := DB_OK;

   if IndexClass.Select (aIndexName, nFile, nPos) = false then begin
      Result := DB_ERR_NOTFOUND;
      exit;
   end;

   try
      DBStream [nFile].Seek (sizeof (TDBHeader) + (nPos * Header [nFile].RecordFullSize), soFromBeginning);
      DBStream [nFile].ReadBuffer (DBRecord, sizeof (TDBRecord));
      if StrPas (@DBRecord.PrimaryKey) <> aIndexName then begin
         Result := DB_ERR_INVALIDDATA;
         exit;
      end;

      DBStream [nFile].Seek (sizeof (TDBHeader) + (nPos * Header [nFile].RecordFullSize), soFromBeginning);
      DBStream [nFile].WriteBuffer (aDBRecord^, sizeof (TDBRecord));
   except
      Result := DB_ERR_IO;
      exit;
   end;
end;

function TDBProvider.Select (aIndexName : String; aDBRecord : PTDBRecord) : Byte;
begin
   Result := SelectDisk (aIndexName, aDBRecord);
end;

function TDBProvider.Insert (aIndexName : String; aDBRecord : PTDBRecord) : Byte;
var
   nFile, nPos : Integer;
   pd : PTBlankData;
   nCode : Byte;
begin
   Result := DB_OK;

   if BlankList.Count > 0 then begin
      pd := BlankList.Items [0];
      nFile := pd^.FileNo;
      nPos := pd^.RecordNo;

      nCode := IndexClass.Insert (aIndexName, nFile, nPos);
      if nCode = DB_OK then begin
         aDBRecord^.boUsed := 1;

         try
            DBStream [nFile].Seek (sizeof (TDBHeader) + (nPos * Header [nFile].RecordFullSize), soFromBeginning);
            DBStream [nFile].WriteBuffer (aDBRecord^, sizeof (TDBRecord));
         except
            Result := DB_ERR_IO;
            exit;
         end;

         Dispose (pd);
         BlankList.Delete (0);
         // IndexClass.Sort;
      end else begin
         Result := nCode;
      end;
   end else begin
      Result := DB_ERR_NOTENOUGHSPACE;
   end;
end;

function TDBProvider.Delete (aIndexName : String) : Byte;
var
   nFile, nPos : Integer;
begin
   Result := DB_OK;

   if IndexClass.Select (aIndexName, nFile, nPos) = false then begin
      Result := DB_ERR_NOTFOUND;
      exit;
   end;

   {
   FillChar (RecordBuffer, sizeof (TDBRecord), 0);

   try
      DBStream.Seek (sizeof (TDBHeader) + (nPos * Header.RecordFullSize), soFromBeginning);
      DBStream.WriteBuffer (RecordBuffer, sizeof (TDBRecord));
   except
      Result := DB_ERR_IO;
      exit;
   end;

   DataPool.Erase (aIndexName);
   Result := IndexClass.Delete (aIndexName);
   }
end;

function TDBProvider.Update (aIndexName : String; aDBRecord : PTDBRecord) : Byte;
begin
   Result := UpdateDisk (aIndexName, aDBRecord);
end;

procedure TDBProvider.BackupHeader (aStream : TFileStream);
var
   tmpHeader : TDBHeader;
begin
   ShowInfo ('Backup Start');
   Move (Header [0], tmpHeader, SizeOf (TDBHeader));

   tmpHeader.RecordCount := GetTotalRecordCount;
   aStream.WriteBuffer (tmpHeader, SizeOf (TDBHeader));
end;

function TDBProvider.BackupRecord (aStream : TFileStream; aIndex : Integer) : Boolean;
var
   nFile, nPos : Integer;
   tmpRecord : TDBRecord;
begin
   Result := false;

   if IndexClass.SelectByIndex (aIndex, nFile, nPos) = false then begin
      ShowInfo ('Backup end');
      exit;
   end;

   DBStream [nFile].Seek (sizeof (TDBHeader) + (nPos * Header [nFile].RecordFullSize), soFromBeginning);
   DBStream [nFile].ReadBuffer (tmpRecord, sizeof (TDBRecord));

   aStream.WriteBuffer (tmpRecord, SizeOf (TDBRecord));

   Result := true;
end;

procedure TDBProvider.SetPrintControl (aMemo : TMemo);
begin
   PrintControl := aMemo;
end;

procedure TDBProvider.ShowInfo (aStr : String);
begin
   if PrintControl = nil then exit;

   PrintControl.Lines.Add (aStr);
end;

function TDBProvider.ChangeDataToWebStr (aDBRecord : PTDBRecord) : String;
var
   i : Integer;
   RetStr, Str : String;
begin
   RetStr := StrPas (@aDBRecord^.PrimaryKey);
   RetStr := RetStr + ',' + StrPas (@aDBRecord^.MasterName);
   RetStr := RetStr + ',' + StrPas (@aDBRecord^.Password);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.GroupKey);
   RetStr := RetStr + ',' + StrPas (@aDBRecord^.Guild);
   RetStr := RetStr + ',' + StrPas (@aDBRecord^.LastDate);
   RetStr := RetStr + ',' + StrPas (@aDBRecord^.CreateDate);
   RetStr := RetStr + ',' + StrPas (@aDBRecord^.Sex);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.ServerID);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.X);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.Y);

   Str := IntToStr (GetLevel (aDBRecord^.Light + aDBRecord^.Dark));
   RetStr := RetStr + ',' + Str;
   
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.Light);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.Dark);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.Energy);
   RetStr := RetStr + ',' + IntToStr (GetLevel (aDBRecord^.InPower));
   RetStr := RetStr + ',' + IntToStr (GetLevel (aDBRecord^.OutPower));
   RetStr := RetStr + ',' + IntToStr (GetLevel (aDBRecord^.Magic));
   RetStr := RetStr + ',' + IntToStr (GetLevel (aDBRecord^.Life));
   RetStr := RetStr + ',' + IntToStr (GetLevel (aDBRecord^.Talent));
   RetStr := RetStr + ',' + IntToStr (GetLevel (aDBRecord^.GoodChar));
   RetStr := RetStr + ',' + IntToStr (GetLevel (aDBRecord^.BadChar));
   RetStr := RetStr + ',' + IntToStr (GetLevel (aDBRecord^.Adaptive));
   RetStr := RetStr + ',' + IntToStr (GetLevel (aDBRecord^.Revival));
   RetStr := RetStr + ',' + IntToStr (GetLevel (aDBRecord^.Immunity));
   RetStr := RetStr + ',' + IntToStr (GetLevel (aDBRecord^.Virtue));
   RetStr := RetStr + ',' + IntToStr (GetLevel (aDBRecord^.CurEnergy));
   RetStr := RetStr + ',' + IntToStr (GetLevel (aDBRecord^.CurInPower));
   RetStr := RetStr + ',' + IntToStr (GetLevel (aDBRecord^.CurOutPower));
   RetStr := RetStr + ',' + IntToStr (GetLevel (aDBRecord^.CurMagic));
   RetStr := RetStr + ',' + IntToStr (GetLevel (aDBRecord^.CurLife));
   RetStr := RetStr + ',' + IntToStr (GetLevel (aDBRecord^.CurHealth));
   RetStr := RetStr + ',' + IntToStr (GetLevel (aDBRecord^.CurSatiety));
   RetStr := RetStr + ',' + IntToStr (GetLevel (aDBRecord^.CurPoisoning));
   RetStr := RetStr + ',' + IntToStr (GetLevel (aDBRecord^.CurHeadSeak));
   RetStr := RetStr + ',' + IntToStr (GetLevel (aDBRecord^.CurArmSeak));
   RetStr := RetStr + ',' + IntToStr (GetLevel (aDBRecord^.CurLegSeak));
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.ExtraExp);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.AddableStatePoint);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.TotalStatePoint);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.CurrentGrade);

   for i := 0 to 10 - 1 do begin
      Str := IntToStr (GetLevel (aDBRecord^.BasicMagicArr[i].Skill));
      RetStr := RetStr + ',' + Str;
   end;
   for i := 0 to 10 - 1 do begin
      Str := IntToStr (GetLevel (aDBRecord^.BasicRiseMagicArr[i].Skill));
      RetStr := RetStr + ',' + StrPas (@aDBRecord^.BasicRiseMagicArr[i].Name) + ':' + Str;
   end;
   for i := 0 to 8 - 1 do begin
      RetStr := RetStr + ',' + StrPas (@aDBRecord^.WearItemArr[i].Name) + ':' +
      IntToStr (aDBRecord^.WearItemArr[i].Color) + ':' +
      IntToStr (aDBRecord^.WearItemArr[i].Count) + ':' +
      IntToSTr (aDBRecord^.WearItemArr[i].CurDurability) + ':' +
      IntToSTr (aDBRecord^.WearItemArr[i].Durability) + ':' +
      IntToSTr (aDBRecord^.WearItemArr[i].Upgrade) + ':' +
      IntToStr (aDBRecord^.WearItemArr[i].AddType);
   end;
   for i := 0 to 30 - 1 do begin
      RetStr := RetStr + ',' + StrPas (@aDBRecord^.HaveItemArr[i].Name) + ':' +
      IntToStr (aDBRecord^.HaveItemArr[i].Color) + ':' +
      IntToStr (aDBRecord^.HaveItemArr[i].Count) + ':' +
      IntToSTr (aDBRecord^.HaveItemArr[i].CurDurability) + ':' +
      IntToSTr (aDBRecord^.HaveItemArr[i].Durability) + ':' +
      IntToSTr (aDBRecord^.HaveItemArr[i].Upgrade) + ':' +
      IntToStr (aDBRecord^.HaveItemArr[i].AddType);
   end;
   for i := 0 to 30 - 1 do begin
      Str := IntToStr (Getlevel (aDBRecord^.HaveMagicArr[i].Skill));
      RetStr := RetStr + ',' + StrPas (@aDBRecord^.HaveMagicArr[i].Name) + ':' + Str;
   end;
   for i := 0 to 30 - 1 do begin
      Str := IntToStr (GetLevel (aDBRecord^.HaveRiseMagicArr[i].Skill));
      RetStr := RetStr + ',' + StrPas (@aDBRecord^.HaveRiseMagicArr[i].Name) + ':' + Str;
   end;
   for i := 0 to 30 - 1 do begin
      Str := IntToStr (GetLevel (aDBRecord^.HaveMysteryMagicArr[i].Skill));
      RetStr := RetStr + ',' + StrPas (@aDBRecord^.HaveMysteryMagicArr[i].Name) + ':' + Str;
   end;

   for i := 0 to 15 - 1 do begin
      Str := IntToStr (GetLevel (aDBRecord^.HaveBestSpecialMagicArr[i].Skill)) + ':'
         + IntToStr (aDBRecord^.HaveBestSpecialMagicArr[i].Grade) + ':'
         + IntToStr (aDBRecord^.HaveBestSpecialMagicArr[i].rDamageBody) + ':'
         + IntToStr (aDBRecord^.HaveBestSpecialMagicArr[i].rDamageHead) + ':'
         + IntToStr (aDBRecord^.HaveBestSpecialMagicArr[i].rDamageArm) + ':'
         + IntToStr (aDBRecord^.HaveBestSpecialMagicArr[i].rDamageLeg) + ':'
         + IntToStr (aDBRecord^.HaveBestSpecialMagicArr[i].rDamageEnergy) + ':'
         + IntToStr (aDBRecord^.HaveBestSpecialMagicArr[i].rArmorBody) + ':'
         + IntToStr (aDBRecord^.HaveBestSpecialMagicArr[i].rArmorHead) + ':'
         + IntToStr (aDBRecord^.HaveBestSpecialMagicArr[i].rArmorArm) + ':'
         + IntToStr (aDBRecord^.HaveBestSpecialMagicArr[i].rArmorLeg) + ':'
         + IntToStr (aDBRecord^.HaveBestSpecialMagicArr[i].rArmorEnergy);
      RetStr := RetStr + ',' + StrPas (@aDBRecord^.HaveBestSpecialMagicArr[i].Name) + ':' + Str;
   end;

   for i := 0 to 5 - 1 do begin
      Str := IntToStr (GetLevel (aDBRecord^.HaveBestProtectMagicArr[i].Skill)) + ':'
         + IntToStr (aDBRecord^.HaveBestProtectMagicArr[i].Grade) + ':'
         + IntToStr (aDBRecord^.HaveBestProtectMagicArr[i].rDamageBody) + ':'
         + IntToStr (aDBRecord^.HaveBestProtectMagicArr[i].rDamageHead) + ':'
         + IntToStr (aDBRecord^.HaveBestProtectMagicArr[i].rDamageArm) + ':'
         + IntToStr (aDBRecord^.HaveBestProtectMagicArr[i].rDamageLeg) + ':'
         + IntToStr (aDBRecord^.HaveBestProtectMagicArr[i].rDamageEnergy) + ':'
         + IntToStr (aDBRecord^.HaveBestProtectMagicArr[i].rArmorBody) + ':'
         + IntToStr (aDBRecord^.HaveBestProtectMagicArr[i].rArmorHead) + ':'
         + IntToStr (aDBRecord^.HaveBestProtectMagicArr[i].rArmorArm) + ':'
         + IntToStr (aDBRecord^.HaveBestProtectMagicArr[i].rArmorLeg) + ':'
         + IntToStr (aDBRecord^.HaveBestProtectMagicArr[i].rArmorEnergy);
      RetStr := RetStr + ',' + StrPas (@aDBRecord^.HaveBestProtectMagicArr[i].Name) + ':' + Str;
   end;

   for i := 0 to 5 - 1 do begin
      Str := IntToStr (GetLevel (aDBRecord^.HaveBestAttackMagicArr[i].Skill)) + ':'
         + IntToStr (aDBRecord^.HaveBestAttackMagicArr[i].Grade) + ':'
         + IntToStr (aDBRecord^.HaveBestAttackMagicArr[i].rDamageBody) + ':'
         + IntToStr (aDBRecord^.HaveBestAttackMagicArr[i].rDamageHead) + ':'
         + IntToStr (aDBRecord^.HaveBestAttackMagicArr[i].rDamageArm) + ':'
         + IntToStr (aDBRecord^.HaveBestAttackMagicArr[i].rDamageLeg) + ':'
         + IntToStr (aDBRecord^.HaveBestAttackMagicArr[i].rDamageEnergy) + ':'
         + IntToStr (aDBRecord^.HaveBestAttackMagicArr[i].rArmorBody) + ':'
         + IntToStr (aDBRecord^.HaveBestAttackMagicArr[i].rArmorHead) + ':'
         + IntToStr (aDBRecord^.HaveBestAttackMagicArr[i].rArmorArm) + ':'
         + IntToStr (aDBRecord^.HaveBestAttackMagicArr[i].rArmorLeg) + ':'
         + IntToStr (aDBRecord^.HaveBestAttackMagicArr[i].rArmorEnergy);
      RetStr := RetStr + ',' + StrPas (@aDBRecord^.HaveBestAttackMagicArr[i].Name) + ':' + Str;
   end;



   for i := 0 to 5 - 1 do begin
      RetStr := RetStr + ',' + StrPas (@aDBRecord^.HaveMaterialItemArr[i].Name) + ':' +
      IntToStr (aDBRecord^.HaveMaterialItemArr[i].Color) + ':' +
      IntToStr (aDBRecord^.HaveMaterialItemArr[i].Count) + ':' +
      IntToSTr (aDBRecord^.HaveMaterialItemArr[i].CurDurability) + ':' +
      IntToSTr (aDBRecord^.HaveMaterialItemArr[i].Durability) + ':' +
      IntToSTr (aDBRecord^.HaveMaterialItemArr[i].Upgrade) + ':' +
      IntToStr (aDBRecord^.HaveMaterialItemArr[i].AddType);
   end;
   for i := 0 to 10 - 1 do begin
      RetStr := RetStr + ',' + StrPas (@aDBRecord^.HaveMarketItemArr[i].Name) + ':' +
      IntToStr (aDBRecord^.HaveMarketItemArr[i].Color) + ':' +
      IntToStr (aDBRecord^.HaveMarketItemArr[i].Count) + ':' +
      IntToSTr (aDBRecord^.HaveMarketItemArr[i].CurDurability) + ':' +
      IntToSTr (aDBRecord^.HaveMarketItemArr[i].Durability) + ':' +
      IntToSTr (aDBRecord^.HaveMarketItemArr[i].Upgrade) + ':' +
      IntToStr (aDBRecord^.HaveMarketItemArr[i].AddType) + ':' +
      IntToStr (aDBRecord^.HaveMarketItemArr[i].Cost);
   end;
   RetStr := RetStr + ',' + StrPas (@aDBRecord^.Person1);
   RetStr := RetStr + ',' + StrPas (@aDBRecord^.Person2);
   for i := 0 to 10 - 1 do begin
      RetStr := RetStr + ',' + IntToStr (aDBRecord^.Key [i]);
   end;
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.CompleteQuestNo);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.CurrentQuestNo);
   RetStr := RetStr + ',' + StrPas (@aDBRecord^.QuestStr);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.FirstQuestNo);

   RetStr := RetStr + ',' + IntToSTr(aDBRecord^.JobKind);
   
   Result := RetStr;
end;


function TDBProvider.ChangeDataToStr (aDBRecord : PTDBRecord) : String;
var
   i : Integer;
   RetStr : String;
begin
   RetStr := StrPas (@aDBRecord^.PrimaryKey);
   RetStr := RetStr + ',' + StrPas (@aDBRecord^.MasterName);
   RetStr := RetStr + ',' + StrPas (@aDBRecord^.Password);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.GroupKey);
   RetStr := RetStr + ',' + StrPas (@aDBRecord^.Guild);
   RetStr := RetStr + ',' + StrPas (@aDBRecord^.LastDate);
   RetStr := RetStr + ',' + StrPas (@aDBRecord^.CreateDate);
   RetStr := RetStr + ',' + StrPas (@aDBRecord^.Sex);
   RetStr := RetStr + ',' + StrPas (@aDBRecord^.Lover);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.ServerID);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.X);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.Y);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.Light);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.Dark);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.Energy);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.InPower);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.OutPower);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.Magic);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.Life);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.Talent);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.GoodChar);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.BadChar);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.Adaptive);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.Revival);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.Immunity);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.Virtue);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.CurEnergy);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.CurInPower);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.CurOutPower);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.CurMagic);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.CurLife);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.CurHealth);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.CurSatiety);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.CurPoisoning);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.CurHeadSeak);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.CurArmSeak);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.CurLegSeak);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.ExtraExp);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.AddableStatePoint);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.TotalStatePoint);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.CurrentGrade);

   for i := 0 to 10 - 1 do begin
      RetStr := RetStr + ',' + IntToStr (aDBRecord^.BasicMagicArr[i].Skill);
   end;
   for i := 0 to 10 - 1 do begin
      RetStr := RetStr + ',' + StrPas (@aDBRecord^.BasicRiseMagicArr[i].Name) + ':' + IntToStr (aDBRecord^.BasicRiseMagicArr[i].Skill);
   end;
   for i := 0 to 8 - 1 do begin
      RetStr := RetStr + ',' + StrPas (@aDBRecord^.WearItemArr[i].Name) + ':' +
      IntToStr (aDBRecord^.WearItemArr[i].Color) + ':' +
      IntToStr (aDBRecord^.WearItemArr[i].Count) + ':' +
      IntToSTr (aDBRecord^.WearItemArr[i].CurDurability) + ':' +
      IntToSTr (aDBRecord^.WearItemArr[i].Durability) + ':' +
      IntToSTr (aDBRecord^.WearItemArr[i].Upgrade) + ':' +
      IntToSTr (aDBRecord^.WearItemArr[i].AddType)+ ':' +
      IntToSTr (aDBRecord^.WearItemArr[i].LockState)+ ':' +
      IntToSTr (aDBRecord^.WearItemArr[i].unLockTime);
      // StrPas (@aDBRecord^.WearItemArr [i].Code);
   end;
   for i := 0 to 30 - 1 do begin
      RetStr := RetStr + ',' + StrPas (@aDBRecord^.HaveItemArr[i].Name) + ':' +
      IntToStr (aDBRecord^.HaveItemArr[i].Color) + ':' +
      IntToStr (aDBRecord^.HaveItemArr[i].Count) + ':' +
      IntToSTr (aDBRecord^.HaveItemArr[i].CurDurability) + ':' +
      IntToSTr (aDBRecord^.HaveItemArr[i].Durability) + ':' +
      IntToSTr (aDBRecord^.HaveItemArr[i].Upgrade) + ':' +
      IntToSTr (aDBRecord^.HaveItemArr[i].AddType)+ ':' +
      IntToSTr (aDBRecord^.HaveItemArr[i].LockState)+ ':' +
      IntToSTr (aDBRecord^.HaveItemArr[i].unLockTime);
      // StrPas (@aDBRecord^.HaveItemArr [i].Code);
   end;
   for i := 0 to 30 - 1 do begin
      RetStr := RetStr + ',' + StrPas (@aDBRecord^.HaveMagicArr[i].Name) + ':' + IntToStr (aDBRecord^.HaveMagicArr[i].Skill);
   end;
   for i := 0 to 30 - 1 do begin
      RetStr := RetStr + ',' + StrPas (@aDBRecord^.HaveRiseMagicArr[i].Name) + ':' + IntToStr (aDBRecord^.HaveRiseMagicArr[i].Skill);
   end;
   for i := 0 to 30 - 1 do begin
      RetStr := RetStr + ',' + StrPas (@aDBRecord^.HaveMysteryMagicArr[i].Name) + ':' + IntToStr (aDBRecord^.HaveMysteryMagicArr[i].Skill);
   end;

   for i := 0 to 15 - 1 do begin
      RetStr := RetStr + ','
         + StrPas (@aDBRecord^.HaveBestSpecialMagicArr[i].Name) + ':'
         + IntToStr (aDBRecord^.HaveBestSpecialMagicArr[i].Skill) + ':'
         + IntToStr (aDBRecord^.HaveBestSpecialMagicArr[i].Grade) + ':'
         + IntToStr (aDBRecord^.HaveBestSpecialMagicArr[i].rDamageBody) + ':'
         + IntToStr (aDBRecord^.HaveBestSpecialMagicArr[i].rDamageHead) + ':'
         + IntToStr (aDBRecord^.HaveBestSpecialMagicArr[i].rDamageArm) + ':'
         + IntToStr (aDBRecord^.HaveBestSpecialMagicArr[i].rDamageLeg) + ':'
         + IntToStr (aDBRecord^.HaveBestSpecialMagicArr[i].rDamageEnergy) + ':'
         + IntToStr (aDBRecord^.HaveBestSpecialMagicArr[i].rArmorBody) + ':'
         + IntToStr (aDBRecord^.HaveBestSpecialMagicArr[i].rArmorHead) + ':'
         + IntToStr (aDBRecord^.HaveBestSpecialMagicArr[i].rArmorArm) + ':'
         + IntToStr (aDBRecord^.HaveBestSpecialMagicArr[i].rArmorLeg) + ':'
         + IntToStr (aDBRecord^.HaveBestSpecialMagicArr[i].rArmorEnergy);
   end;

   for i := 0 to 5 - 1 do begin
      RetStr := RetStr + ','
         + StrPas (@aDBRecord^.HaveBestProtectMagicArr[i].Name) + ':'
         + IntToStr (aDBRecord^.HaveBestProtectMagicArr[i].Skill) + ':'
         + IntToStr (aDBRecord^.HaveBestProtectMagicArr[i].Grade) + ':'
         + IntToStr (aDBRecord^.HaveBestProtectMagicArr[i].rDamageBody) + ':'
         + IntToStr (aDBRecord^.HaveBestProtectMagicArr[i].rDamageHead) + ':'
         + IntToStr (aDBRecord^.HaveBestProtectMagicArr[i].rDamageArm) + ':'
         + IntToStr (aDBRecord^.HaveBestProtectMagicArr[i].rDamageLeg) + ':'
         + IntToStr (aDBRecord^.HaveBestProtectMagicArr[i].rDamageEnergy) + ':'
         + IntToStr (aDBRecord^.HaveBestProtectMagicArr[i].rArmorBody) + ':'
         + IntToStr (aDBRecord^.HaveBestProtectMagicArr[i].rArmorHead) + ':'
         + IntToStr (aDBRecord^.HaveBestProtectMagicArr[i].rArmorArm) + ':'
         + IntToStr (aDBRecord^.HaveBestProtectMagicArr[i].rArmorLeg) + ':'
         + IntToStr (aDBRecord^.HaveBestProtectMagicArr[i].rArmorEnergy);
   end;

   for i := 0 to 5 - 1 do begin
      RetStr := RetStr + ','
         + StrPas (@aDBRecord^.HaveBestAttackMagicArr[i].Name) + ':'
         + IntToStr (aDBRecord^.HaveBestAttackMagicArr[i].Skill) + ':'
         + IntToStr (aDBRecord^.HaveBestAttackMagicArr[i].Grade) + ':'
         + IntToStr (aDBRecord^.HaveBestAttackMagicArr[i].rDamageBody) + ':'
         + IntToStr (aDBRecord^.HaveBestAttackMagicArr[i].rDamageHead) + ':'
         + IntToStr (aDBRecord^.HaveBestAttackMagicArr[i].rDamageArm) + ':'
         + IntToStr (aDBRecord^.HaveBestAttackMagicArr[i].rDamageLeg) + ':'
         + IntToStr (aDBRecord^.HaveBestAttackMagicArr[i].rDamageEnergy) + ':'
         + IntToStr (aDBRecord^.HaveBestAttackMagicArr[i].rArmorBody) + ':'
         + IntToStr (aDBRecord^.HaveBestAttackMagicArr[i].rArmorHead) + ':'
         + IntToStr (aDBRecord^.HaveBestAttackMagicArr[i].rArmorArm) + ':'
         + IntToStr (aDBRecord^.HaveBestAttackMagicArr[i].rArmorLeg) + ':'
         + IntToStr (aDBRecord^.HaveBestAttackMagicArr[i].rArmorEnergy);
   end;

   for i := 0 to 5 - 1 do begin
      RetStr := RetStr + ',' + StrPas (@aDBRecord^.HaveMaterialItemArr[i].Name) + ':' +
      IntToStr (aDBRecord^.HaveMaterialItemArr[i].Color) + ':' +
      IntToStr (aDBRecord^.HaveMaterialItemArr[i].Count) + ':' +
      IntToSTr (aDBRecord^.HaveMaterialItemArr[i].CurDurability) + ':' +
      IntToSTr (aDBRecord^.HaveMaterialItemArr[i].Durability) + ':' +
      IntToSTr (aDBRecord^.HaveMaterialItemArr[i].Upgrade) + ':' +
      IntToSTr (aDBRecord^.HaveMaterialItemArr[i].AddType)+ ':' +
      IntToSTr (aDBRecord^.HaveMaterialItemArr[i].LockState)+ ':' +
      IntToSTr (aDBRecord^.HaveMaterialItemArr[i].unLockTime);
   end;
   for i := 0 to 10 - 1 do begin
      RetStr := RetStr + ',' + StrPas (@aDBRecord^.HaveMarketItemArr[i].Name) + ':' +
      IntToStr (aDBRecord^.HaveMarketItemArr[i].Color) + ':' +
      IntToStr (aDBRecord^.HaveMarketItemArr[i].Count) + ':' +
      IntToSTr (aDBRecord^.HaveMarketItemArr[i].CurDurability) + ':' +
      IntToSTr (aDBRecord^.HaveMarketItemArr[i].Durability) + ':' +
      IntToSTr (aDBRecord^.HaveMarketItemArr[i].Upgrade) + ':' +
      IntToSTr (aDBRecord^.HaveMarketItemArr[i].AddType) + ':' +
      IntToStr (aDBRecord^.HaveMarketItemArr[i].Cost);
   end;
   RetStr := RetStr + ',' + StrPas (@aDBRecord^.Person1);
   RetStr := RetStr + ',' + StrPas (@aDBRecord^.Person2);
   RetStr := RetStr + ',' + StrPas (@aDBRecord^.Person3);
   RetStr := RetStr + ',' + StrPas (@aDBRecord^.Person4);

   for i := 0 to 10 - 1 do begin
      RetStr := RetStr + ',' + IntToStr (aDBRecord^.Key [i]);
   end;
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.CompleteQuestNo);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.CurrentQuestNo);
   RetStr := RetStr + ',' + StrPas (@aDBRecord^.QuestStr);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.FirstQuestNo);

   RetStr := RetStr + ',' + IntToStr (aDBRecord^.JobKind);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.ExtJobKind);
   RetStr := RetStr + ',' + IntToStr (aDBRecord^.CurJobExp);

   for i := 0 to 20 - 1 do begin
      RetStr := RetStr + ',' + IntToStr (aDBRecord^.EventRecord [i]);
   end;

   Result := RetStr;
end;

procedure TDBProvider.ChangeStrToData (aStr : String; var DBRecord : TDBRecord);
var
   i : Integer;
   str, rdstr : String;
   uPrimaryKey, uMasterName, uPassword, uGroupKey, uGuild, uLastDate, uCreateDate, uSex, uLover, uServerId, uX, uY : String;
   uLight, uDark, uEnergy, uInPower, uOutPower, uMagic, uLife, uTalent, uGoodChar : String;
   uBadChar, uAdaptive, uRevival, uImmunity, uVirtue, uCurEnergy, uCurInPower : String;
   uCurOutPower, uCurMagic, uCurLife, uCurHealth, uCurSatiety, uCurPoisoning : String;
   uCurHeadSeak, uCurArmSeak, uCurLegSeak, uExtraExp, uAddableStatePoint, uTotalStatePoint, uCurrentGrade , uCurJobExp , uExtJobKind: String;
   uBasicMagic : array[0..10 - 1] of String;
   uBasicRiseMagic : array[0..10 - 1] of String;
   uHaveMysteryMagic : array[0..30 -1] of String; //2002-11-07 giltae   
   uWearItem : array[0..8 - 1] of String;
   uHaveItem : array[0..30 - 1] of String;
   uHaveMagic : array[0..30 - 1] of String;
   uHaveRiseMagic : array[0..30 - 1] of String;
   uHaveBestSpecialMagic : array[0..15-1] of String;
   uHaveBestAttackMagic : array[0..5-1] of String;
   uHaveBestProtectMagic : array[0..5-1] of String;
   uHaveMaterialItem : array[0..5 - 1] of String;
   uHaveMarketItem : array [0..10 - 1] of String;
   uPerson1, uPerson2 : String;
   uKey : array [0..10 - 1] of String;
   uEventRecord : array [0..20 - 1] of String;
   uCompleteQuest, uCurrentQuest : String;
   uQuestStr, uFirstQuest : String;
   uJobKind, uPerson3, uPerson4 : String;
   uname, ucount, ucolor, uskill, ugrade,uLockState,uunLockTime : String;
   udura, ucurdura, uupgrade, ucost, uaddtype : String;
   udamagebody,udamagehead,udamagearm,udamageleg,uarmorbody,uarmorhead,uarmorarm,uarmorleg : string;
   udamageenergy,uarmorenergy : string;
begin
   str := aStr;

   str := GetTokenStr (str, uPrimaryKey, ',');
   str := GetTokenStr (str, uMasterName, ',');
   str := GetTokenStr (str, uPassword, ',');
   str := GetTokenStr (str, uGroupKey, ',');
   str := GetTokenStr (str, uGuild, ',');
   str := GetTokenStr (str, uLastDate, ',');
   str := GetTokenStr (str, uCreateDate, ',');
   str := GetTokenStr (str, uSex, ',');
   str := GetTokenStr (str, uLover, ',');
   str := GetTokenStr (str, uServerId, ',');
   str := GetTokenStr (str, uX, ',');
   str := GetTokenStr (str, uY, ',');
   str := GetTokenStr (str, uLight, ',');
   str := GetTokenStr (str, uDark, ',');
   str := GetTokenStr (str, uEnergy, ',');
   str := GetTokenStr (str, uInPower, ',');
   str := GetTokenStr (str, uOutPower, ',');
   str := GetTokenStr (str, uMagic, ',');
   str := GetTokenStr (str, uLife, ',');
   str := GetTokenStr (str, uTalent, ',');
   str := GetTokenStr (str, uGoodChar, ',');
   str := GetTokenStr (str, uBadChar, ',');
   str := GetTokenStr (str, uAdaptive, ',');
   str := GetTokenStr (str, uRevival, ',');
   str := GetTokenStr (str, uImmunity, ',');
   str := GetTokenStr (str, uVirtue, ',');
   str := GetTokenStr (str, uCurEnergy, ',');
   str := GetTokenStr (str, uCurInPower, ',');
   str := GetTokenStr (str, uCurOutPower, ',');
   str := GetTokenStr (str, uCurMagic, ',');
   str := GetTokenStr (str, uCurLife, ',');
   str := GetTokenStr (str, uCurHealth, ',');
   str := GetTokenStr (str, uCurSatiety, ',');
   str := GetTokenStr (str, uCurPoisoning, ',');
   str := GetTokenStr (str, uCurHeadSeak, ',');
   str := GetTokenStr (str, uCurArmSeak, ',');
   str := GetTokenStr (str, uCurLegSeak, ',');
   str := GetTokenStr (str, uExtraExp, ',');
   str := GetTokenStr (str, uAddableStatePoint, ',');
   str := GetTokenStr (str, uTotalStatePoint, ',');
   str := GetTokenStr (str, uCurrentGrade, ',');

   for i := 0 to 10 - 1 do begin
      str := GetTokenStr (str, uBasicMagic[i], ',');
   end;
   for i := 0 to 10 - 1 do begin
      str := GetTokenStr (str, uBasicRiseMagic[i], ',');
   end;
   for i := 0 to 8 - 1 do begin
      str := GetTokenStr (str, uWearItem[i], ',');
   end;
   for i := 0 to 30 - 1 do begin
      str := GetTokenStr (str, uHaveItem[i], ',');
   end;
   for i := 0 to 30 - 1 do begin
      str := GetTokenStr (str, uHaveMagic[i], ',');
   end;
   for i := 0 to 30 - 1 do begin
      str := GetTokenStr (str, uHaveRiseMagic[i], ',');
   end;
   for i := 0 to 30 - 1 do begin
      str := GetTokenStr (str, uHaveMysteryMagic[i], ',');
   end;

   //2003-09-19
   for i := 0 to 15 - 1 do begin
      str := GetTokenStr (str, uHaveBestSpecialMagic[i], ',');
   end;
   for i := 0 to 5 - 1 do begin
      str := GetTokenStr (str, uHaveBestProtectMagic[i], ',');
   end;
   for i := 0 to 5 - 1 do begin
      str := GetTokenStr (str, uHaveBestAttackMagic[i], ',');
   end;
   //////////////////////////


   for i := 0 to 5 - 1 do begin
      str := GetTokenStr (str, uHaveMaterialItem[i], ',');
   end;
   for i := 0 to 10 - 1 do begin
      str := GetTokenStr (str, uHaveMarketItem[i], ',');
   end;

   str := GetTokenStr (str, uPerson1, ',');
   str := GetTokenStr (str, uPerson2, ',');
   str := GetTokenStr (str, uPerson3, ',');
   str := GetTokenStr (str, uPerson4, ',');
   for i := 0 to 10 - 1 do begin
      str := GetTokenStr (str, uKey[i], ',');
   end;
   str := GetTokenStr (str, uCompleteQuest, ',');
   str := GetTokenStr (str, uCurrentQuest, ',');
   str := GetTokenStr (str, uQuestStr, ',');
   str := GetTokenStr (str, uFirstQuest, ',');
   str := GetTokenStr (str, uJobKind, ',');

  // add by Orber at 2005-03-23 11:40:56

   str := GetTokenStr (str, uExtJobKind, ',');
   str := GetTokenStr (str, uCurJobExp, ',');

   for i := 0 to 20 - 1 do begin
      str := GetTokenStr (str, uEventRecord [i], ',');
   end;


   StrPCopy (@DBRecord.PrimaryKey, uPrimaryKey);
   StrPCopy (@DBRecord.MasterName, uMasterName);
   StrPCopy (@DBRecord.Password, uPassword);
   DBRecord.GroupKey := _StrToInt (uGroupKey);
   StrPCopy (@DBRecord.Guild, uGuild);
   StrPCopy (@DBRecord.LastDate, uLastDate);
   StrPCopy (@DBRecord.CreateDate, uCreateDate);
   StrPCopy (@DBRecord.Sex, uSex);
   StrPCopy (@DBRecord.Lover, uLover);
   DBRecord.ServerID := _StrToInt (uServerId);
   DBRecord.X := _StrToInt (uX);
   DBRecord.Y := _StrToInt (uY);
   DBRecord.Light := _StrToInt (uLight);
   DBRecord.Dark := _StrToInt (uDark);
   DBRecord.Energy := _StrToInt (uEnergy);
   DBRecord.InPower := _StrToInt (uInPower);
   DBRecord.OutPower := _StrToInt (uOutPower);
   DBRecord.Magic := _StrToInt (uMagic);
   DBRecord.Life := _StrToInt (uLife);
   DBRecord.Talent := _StrToInt (uTalent);
   DBRecord.GoodChar := _StrToInt (uGoodChar);
   DBRecord.BadChar := _StrToInt (uBadChar);
   DBRecord.Adaptive := _StrToInt (uAdaptive);
   DBRecord.Revival := _StrToInt (uRevival);
   DBRecord.Immunity := _StrToInt (uImmunity);
   DBRecord.Virtue := _StrToInt (uVirtue);
   DBRecord.CurEnergy := _StrToInt (uCurEnergy);
   DBRecord.CurInPower := _StrToInt (uCurInPower);
   DBRecord.CurOutPower := _StrToInt (uCurOutPower);
   DBRecord.CurMagic := _StrToInt (uCurMagic);
   DBRecord.CurLife := _StrToInt (uCurLife);
   DBRecord.CurHealth := _StrToInt (uCurHealth);
   DBRecord.CurSatiety := _StrToInt (uCurSatiety);
   DBRecord.CurPoisoning := _StrToInt (uCurPoisoning);
   DBRecord.CurHeadSeak := _StrToInt (uCurHeadSeak);
   DBRecord.CurArmSeak := _StrToInt (uCurArmSeak);
   DBRecord.CurLegSeak := _StrToInt (uCurLegSeak);
   DBRecord.ExtraExp := _StrToInt (uExtraExp);
   DBRecord.AddableStatePoint := _StrToInt (uAddableStatePoint);
   DBRecord.TotalStatePoint := _StrToInt (uTotalStatePoint);
   DBRecord.CurrentGrade := _StrToInt (uCurrentGrade);

   for i := 0 to 10 - 1 do begin
      DBRecord.BasicMagicArr[i].Skill := _StrToInt (uBasicMagic[i]);
   end;
   for i := 0 to 10 - 1 do begin
      rdstr := uBasicRiseMagic[i];
      rdstr := GetTokenStr (rdstr, uname, ':');
      rdstr := GetTokenStr (rdstr, uskill, ':');

      StrPCopy (@DBRecord.BasicRiseMagicArr[i].Name, uname);
      DBRecord.BasicRiseMagicArr[i].Skill := _StrToInt (uskill);
   end;
   for i := 0 to 8 - 1 do begin
      rdstr := uWearItem[i];
      rdstr := GetTokenStr (rdstr, uname, ':');
      rdstr := GetTokenStr (rdstr, ucolor, ':');
      rdstr := GetTokenStr (rdstr, ucount, ':');
      rdstr := GetTokenStr (rdstr, ucurdura, ':');
      rdstr := GetTokenStr (rdstr, udura, ':');
      rdstr := GetTokenStr (rdstr, uupgrade, ':');
      rdstr := GetTokenStr (rdstr, uaddtype, ':');
      // add by Orber 2004-09-13 10:16
      rdstr := GetTokenStr (rdstr, uLockState, ':');
      rdstr := GetTokenStr (rdstr, uunLockTime, ':');
      // rdstr := GetTokenStr (rdstr, ucode, ':');

      StrPCopy (@DBRecord.WearItemArr[i].Name, uname);
      DBRecord.WearItemArr[i].Color := _StrToInt (ucolor);
      DBRecord.WearItemArr[i].Count := _StrToInt (ucount);
      DBRecord.WearItemArr[i].CurDurability := _StrToInt (ucurdura);
      DBRecord.WearItemArr[i].Durability := _StrToInt (udura);
      DBRecord.WearItemArr[i].Upgrade := _StrToInt (uupgrade);
      DBRecord.WearItemArr[i].AddType := _StrToInt (uaddtype);
      // add by Orber 2004-09-13 10:16
      DBRecord.WearItemArr[i].LockState := _StrToInt (uLockState);
      DBRecord.WearItemArr[i].unLockTime := _StrToInt (uunLockTime);
      // StrPCopy (@DBRecord.WearItemArr [i].Code, ucode);
   end;
   for i := 0 to 30 - 1 do begin
      rdstr := uHaveItem[i];
      rdstr := GetTokenStr (rdstr, uname, ':');
      rdstr := GetTokenStr (rdstr, ucolor, ':');
      rdstr := GetTokenStr (rdstr, ucount, ':');
      rdstr := GetTokenStr (rdstr, ucurdura, ':');
      rdstr := GetTokenStr (rdstr, udura, ':');
      rdstr := GetTokenStr (rdstr, uupgrade, ':');
      rdstr := GetTokenStr (rdstr, uaddtype, ':');
      // add by Orber 2004-09-13 10:16
      rdstr := GetTokenStr (rdstr, uLockState, ':');
      rdstr := GetTokenStr (rdstr, uunLockTime, ':');
      // rdstr := GetTokenStr (rdstr, ucode, ':');

      StrPCopy (@DBRecord.HaveItemArr[i].Name, uname);
      DBRecord.HaveItemArr[i].Color := _StrToInt (ucolor);
      DBRecord.HaveItemArr[i].Count := _StrToInt (ucount);
      DBRecord.HaveItemArr[i].CurDurability := _StrToInt (ucurdura);
      DBRecord.HaveItemArr[i].Durability := _StrToInt (udura);
      DBRecord.HaveItemArr[i].Upgrade := _StrToInt (uupgrade);
      DBRecord.HaveItemArr[i].AddType := _StrToInt (uaddtype);
      // add by Orber 2004-09-13 10:16
      DBRecord.HaveItemArr[i].LockState := _StrToInt (uLockState);
      DBRecord.HaveItemArr[i].unLockTime := _StrToInt (uunLockTime);
      // StrPCopy (@DBRecord.HaveItemArr [i].Code, ucode);
   end;
   for i := 0 to 30 - 1 do begin
      rdstr := uHaveMagic[i];
      rdstr := GetTokenStr (rdstr, uname, ':');
      rdstr := GetTokenStr (rdstr, uskill, ':');

      StrPCopy (@DBRecord.HaveMagicArr[i].Name, uname);
      DBRecord.HaveMagicArr[i].Skill := _StrToInt (uskill);
   end;
   for i := 0 to 30 - 1 do begin
      rdstr := uHaveRiseMagic[i];
      rdstr := GetTokenStr (rdstr, uname, ':');
      rdstr := GetTokenStr (rdstr, uskill, ':');

      StrPCopy (@DBRecord.HaveRiseMagicArr[i].Name, uname);
      DBRecord.HaveRiseMagicArr[i].Skill := _StrToInt (uskill);
   end;

   for i := 0 to 30 - 1 do begin
      rdstr := uHaveMysteryMagic[i];
      rdstr := GetTokenStr (rdstr, uname, ':');
      rdstr := GetTokenStr (rdstr, uskill, ':');

      StrPCopy (@DBRecord.HaveMysteryMagicArr[i].Name, uname);
      DBRecord.HaveMysteryMagicArr[i].Skill := _StrToInt (uskill);
   end;
   
   //2003-09-18
   for i := 0 to 15 - 1 do begin
      rdstr := uHaveBestSpecialMagic[i];
      rdstr := GetTokenStr (rdstr, uname, ':');
      rdstr := GetTokenStr (rdstr, uskill, ':');
      rdstr := GetTokenStr (rdstr, ugrade, ':');
      rdstr := GetTokenStr (rdstr, udamagebody, ':');
      rdstr := GetTokenStr (rdstr, udamagehead, ':');
      rdstr := GetTokenStr (rdstr, udamagearm, ':');
      rdstr := GetTokenStr (rdstr, udamageleg, ':');
      rdstr := GetTokenStr (rdstr, udamageenergy, ':');
      rdstr := GetTokenStr (rdstr, uarmorbody, ':');
      rdstr := GetTokenStr (rdstr, uarmorhead, ':');
      rdstr := GetTokenStr (rdstr, uarmorarm, ':');
      rdstr := GetTokenStr (rdstr, uarmorleg, ':');
      rdstr := GetTokenStr (rdstr, uarmorenergy, ':');

      StrPCopy (@DBRecord.HaveBestSpecialMagicArr[i].Name, uname);
      DBRecord.HaveBestSpecialMagicArr[i].Skill := _strtoint(uskill);
      DBRecord.HaveBestSpecialMagicArr[i].Grade := _strtoint(ugrade);
      DBRecord.HaveBestSpecialMagicArr[i].rDamageBody := _strtoint(udamagebody);
      DBRecord.HaveBestSpecialMagicArr[i].rDamageHead := _strtoint(udamagehead);
      DBRecord.HaveBestSpecialMagicArr[i].rDamageArm := _strtoint(udamagearm);
      DBRecord.HaveBestSpecialMagicArr[i].rDamageLeg := _strtoint(udamageleg);
      DBRecord.HaveBestSpecialMagicArr[i].rDamageEnergy := _strtoint(udamageenergy);
      DBRecord.HaveBestSpecialMagicArr[i].rArmorBody := _strtoint(uarmorbody);
      DBRecord.HaveBestSpecialMagicArr[i].rArmorHead := _strtoint(uarmorhead);
      DBRecord.HaveBestSpecialMagicArr[i].rArmorArm := _strtoint(uarmorarm);
      DBRecord.HaveBestSpecialMagicArr[i].rArmorLeg := _strtoint(uarmorleg);
      DBRecord.HaveBestSpecialMagicArr[i].rArmorEnergy := _strtoint(uarmorenergy);
   end;

   for i := 0 to 5 - 1 do begin
      rdstr := uHaveBestProtectMagic[i];
      rdstr := GetTokenStr (rdstr, uname, ':');
      rdstr := GetTokenStr (rdstr, uskill, ':');
      rdstr := GetTokenStr (rdstr, ugrade, ':');
      rdstr := GetTokenStr (rdstr, udamagebody, ':');
      rdstr := GetTokenStr (rdstr, udamagehead, ':');
      rdstr := GetTokenStr (rdstr, udamagearm, ':');
      rdstr := GetTokenStr (rdstr, udamageleg, ':');
      rdstr := GetTokenStr (rdstr, udamageenergy, ':');
      rdstr := GetTokenStr (rdstr, uarmorbody, ':');
      rdstr := GetTokenStr (rdstr, uarmorhead, ':');
      rdstr := GetTokenStr (rdstr, uarmorarm, ':');
      rdstr := GetTokenStr (rdstr, uarmorleg, ':');
      rdstr := GetTokenStr (rdstr, uarmorenergy, ':');

      StrPCopy (@DBRecord.HaveBestProtectMagicArr[i].Name, uname);
      DBRecord.HaveBestProtectMagicArr[i].Skill := _strtoint(uskill);
      DBRecord.HaveBestProtectMagicArr[i].Grade := _strtoint(ugrade);
      DBRecord.HaveBestProtectMagicArr[i].rDamageBody := _strtoint(udamagebody);
      DBRecord.HaveBestProtectMagicArr[i].rDamageHead := _strtoint(udamagehead);
      DBRecord.HaveBestProtectMagicArr[i].rDamageArm := _strtoint(udamagearm);
      DBRecord.HaveBestProtectMagicArr[i].rDamageLeg := _strtoint(udamageleg);
      DBRecord.HaveBestProtectMagicArr[i].rDamageEnergy := _strtoint(udamageenergy);
      DBRecord.HaveBestProtectMagicArr[i].rArmorBody := _strtoint(uarmorbody);
      DBRecord.HaveBestProtectMagicArr[i].rArmorHead := _strtoint(uarmorhead);
      DBRecord.HaveBestProtectMagicArr[i].rArmorArm := _strtoint(uarmorarm);
      DBRecord.HaveBestProtectMagicArr[i].rArmorLeg := _strtoint(uarmorleg);
      DBRecord.HaveBestProtectMagicArr[i].rArmorEnergy := _strtoint(uarmorenergy);
   end;

   for i := 0 to 5 - 1 do begin
      rdstr := uHaveBestAttackMagic[i];
      rdstr := GetTokenStr (rdstr, uname, ':');
      rdstr := GetTokenStr (rdstr, uskill, ':');
      rdstr := GetTokenStr (rdstr, ugrade, ':');
      rdstr := GetTokenStr (rdstr, udamagebody, ':');
      rdstr := GetTokenStr (rdstr, udamagehead, ':');
      rdstr := GetTokenStr (rdstr, udamagearm, ':');
      rdstr := GetTokenStr (rdstr, udamageleg, ':');
      rdstr := GetTokenStr (rdstr, udamageenergy, ':');
      rdstr := GetTokenStr (rdstr, uarmorbody, ':');
      rdstr := GetTokenStr (rdstr, uarmorhead, ':');
      rdstr := GetTokenStr (rdstr, uarmorarm, ':');
      rdstr := GetTokenStr (rdstr, uarmorleg, ':');
      rdstr := GetTokenStr (rdstr, uarmorenergy, ':');

      StrPCopy (@DBRecord.HaveBestAttackMagicArr[i].Name, uname);
      DBRecord.HaveBestAttackMagicArr[i].Skill := _strtoint(uskill);
      DBRecord.HaveBestAttackMagicArr[i].Grade := _strtoint(ugrade);
      DBRecord.HaveBestAttackMagicArr[i].rDamageBody := _strtoint(udamagebody);
      DBRecord.HaveBestAttackMagicArr[i].rDamageHead := _strtoint(udamagehead);
      DBRecord.HaveBestAttackMagicArr[i].rDamageArm := _strtoint(udamagearm);
      DBRecord.HaveBestAttackMagicArr[i].rDamageLeg := _strtoint(udamageleg);
      DBRecord.HaveBestAttackMagicArr[i].rDamageEnergy := _strtoint(udamageenergy);
      DBRecord.HaveBestAttackMagicArr[i].rArmorBody := _strtoint(uarmorbody);
      DBRecord.HaveBestAttackMagicArr[i].rArmorHead := _strtoint(uarmorhead);
      DBRecord.HaveBestAttackMagicArr[i].rArmorArm := _strtoint(uarmorarm);
      DBRecord.HaveBestAttackMagicArr[i].rArmorLeg := _strtoint(uarmorleg);
      DBRecord.HaveBestAttackMagicArr[i].rArmorEnergy := _strtoint(uarmorenergy);
   end;

   for i := 0 to 5 - 1 do begin
      rdstr := uHaveMaterialItem[i];
      rdstr := GetTokenStr (rdstr, uname, ':');
      rdstr := GetTokenStr (rdstr, ucolor, ':');
      rdstr := GetTokenStr (rdstr, ucount, ':');
      rdstr := GetTokenStr (rdstr, ucurdura, ':');
      rdstr := GetTokenStr (rdstr, udura, ':');
      rdstr := GetTokenStr (rdstr, uupgrade, ':');
      rdstr := GetTokenStr (rdstr, uaddtype, ':');
      rdstr := GetTokenStr (rdstr, uLockState, ':');
      rdstr := GetTokenStr (rdstr, uunLockTime, ':');



      StrPCopy (@DBRecord.HaveMaterialItemArr[i].Name, uname);
      DBRecord.HaveMaterialItemArr[i].Color := _StrToInt (ucolor);
      DBRecord.HaveMaterialItemArr[i].Count := _StrToInt (ucount);
      DBRecord.HaveMaterialItemArr[i].CurDurability := _StrToInt (ucurdura);
      DBRecord.HaveMaterialItemArr[i].Durability := _StrToInt (udura);
      DBRecord.HaveMaterialItemArr[i].Upgrade := _StrToInt (uupgrade);
      DBRecord.HaveMaterialItemArr[i].AddType := _StrToInt (uaddtype);
      // add by Orber 2004-09-13 10:16
      DBRecord.HaveMaterialItemArr[i].LockState := _StrToInt (uLockState);
      DBRecord.HaveMaterialItemArr[i].unLockTime := _StrToInt (uunLockTime);

   end;
   for i := 0 to 10 - 1 do begin
      rdstr := uHaveMarketItem[i];
      rdstr := GetTokenStr (rdstr, uname, ':');
      rdstr := GetTokenStr (rdstr, ucolor, ':');
      rdstr := GetTokenStr (rdstr, ucount, ':');
      rdstr := GetTokenStr (rdstr, ucurdura, ':');
      rdstr := GetTokenStr (rdstr, udura, ':');
      rdstr := GetTokenStr (rdstr, uupgrade, ':');
      rdstr := GetTokenStr (rdstr, uaddtype, ':');
      rdstr := GetTokenStr (rdstr, ucost, ':');

      StrPCopy (@DBRecord.HaveMarketItemArr[i].Name, uname);
      DBRecord.HaveMarketItemArr[i].Color := _StrToInt (ucolor);
      DBRecord.HaveMarketItemArr[i].Count := _StrToInt (ucount);
      DBRecord.HaveMarketItemArr[i].CurDurability := _StrToInt (ucurdura);
      DBRecord.HaveMarketItemArr[i].Durability := _StrToInt (udura);
      DBRecord.HaveMarketItemArr[i].Upgrade := _StrToInt (uupgrade);
      DBRecord.HaveMarketItemArr[i].AddType := _StrToInt (uaddtype);
      DBRecord.HaveMarketItemArr[i].Cost := _StrToInt (ucost);      
   end;

   StrPCopy (@DBRecord.Person1, uPerson1);
   StrPCopy (@DBRecord.Person2, uPerson2);
   StrPCopy (@DBRecord.Person3, uPerson3);
   StrPCopy (@DBRecord.Person4, uPerson4);
   for i := 0 to 10 - 1 do begin
      DBRecord.Key [i] := _StrToInt (uKey [i]);
   end;
   DBRecord.CompleteQuestNo := _StrToInt (uCompleteQuest);
   DBRecord.CurrentQuestNo := _StrToInt (uCurrentQuest);
   StrPCopy (@DBRecord.QuestStr, uQuestStr);
   DBRecord.FirstQuestNo := _StrToInt (uFirstQuest);

   DBRecord.JobKind := _StrToInt (uJobKind);
   DBRecord.ExtJobKind := _StrToInt (uExtJobKind);
   DBRecord.CurJobExp := _StrToInt (uCurJobExp);


   for i := 0 to 20 - 1 do begin
        DBRecord.EventRecord[i] := _StrToInt( uEventRecord [i]);
   end;
end;

end.
