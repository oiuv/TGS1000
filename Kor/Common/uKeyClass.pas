unit uKeyClass;

interface

uses
   Windows, Classes, SysUtils;

type

   TStringKeyData = record
      StringKey : String [64 - 1];
      KeyValue : Pointer;
   end;
   PTStringKeyData = ^TStringKeyData;

   TIntegerKeyData = record
      IntegerKey : Integer;
      KeyValue : Pointer;
   end;
   PTIntegerKeyData = ^TIntegerKeyData;

   TMultiStringKeyData = record
      StringKey : String [64 - 1];
      KeyValue : Integer;
   end;
   PTMultiStringKeyData = ^TMultiStringKeyData;

   TStringKeyClass = class
   private
      DataList : TList;

      function IndexOf (aKey : String) : Integer;
      function GetCount : Integer;
      function GetInsertPos (aKey : String) : Integer;
   public
      constructor Create;
      destructor Destroy; override;

      procedure Clear;

      procedure Sort;

      // function Add (aKey : String; aKeyValue : Pointer) : Boolean;
      function Insert (aKey : String; aKeyValue : Pointer) : Boolean;
      function Delete (aKey : String) : Boolean;
      function Select (aKey : String) : Pointer;

      // function GetKey (aIndex : Integer) : String;

      property Count : Integer read GetCount;
   end;

   TIntegerKeyClass = class
   private
      DataList : TList;

      function IndexOf (aKey : Integer) : Integer;
      function GetCount : Integer;
      function GetInsertPos (aKey : Integer) : Integer;
   public
      constructor Create;
      destructor Destroy; override;

      procedure Clear;

      procedure Sort;

      // function Add (aKey : Integer; aKeyValue : Pointer) : Boolean;
      function Insert (aKey : Integer; aKeyValue : Pointer) : Boolean;
      function Delete (aKey : Integer) : Boolean;
      function Select (aKey : Integer) : Pointer;

      property Count : Integer read GetCount;
   end;

   TMultiStringKeyClass = class
   private
      DataList : TList;

      function GetCount : Integer;
      function GetInsertPos (aKey : String) : Integer;
   public
      constructor Create;
      destructor Destroy; override;

      procedure Clear;

      procedure Sort;

      // function Add (aKey : String; aKeyValue : Integer) : Boolean;
      function Insert (aKey : String; aKeyValue : Integer) : Boolean;
      function Delete (aKey : String) : Boolean;
      function Select (aKey : String; var aStartPos, aEndPos : Integer) : Integer;

      function GetKeyString (aIndex : Integer) : String;
      function GetKeyValue (aIndex : Integer) : Integer;

      property Count : Integer read GetCount;
   end;


   {
   TKeyList = class
   private
      KeyData : TStringKeyClass;
      DataList : TList;

      function Get (aIndex : Integer) : Pointer;
      function GetCount : Integer;
   public
      constructor Create;
      destructor Destroy; override;

      procedure Clear;

      function Add (aKey : String; aData : Pointer) : Boolean;
      procedure Delete (aKey : String);
      function Find (aKey : String) : Pointer;

      property Count : Integer read GetCount;
      property Items [aIndex : Integer] : Pointer read Get;
   end;
   }

   function StringKeyClassSortCompare (Item1, Item2: Pointer): Integer;
   function IntegerKeyClassSortCompare (Item1, Item2: Pointer): Integer;

implementation

function StringKeyClassSortCompare (Item1, Item2: Pointer): Integer;
var
   pd1, pd2 : PTStringKeyData;
begin
   Result := 0;

   pd1 := PTStringKeyData (Item1);
   pd2 := PTStringKeyData (Item2);

   if pd1^.StringKey > pd2^.StringKey then begin
      Result := 1;
   end else if pd1^.StringKey < pd2^.StringKey then begin
      Result := -1;
   end;
end;

function IntegerKeyClassSortCompare (Item1, Item2: Pointer): Integer;
var
   pd1, pd2 : PTIntegerKeyData;
begin
   Result := 0;

   pd1 := PTIntegerKeyData (Item1);
   pd2 := PTIntegerKeyData (Item2);

   if pd1^.IntegerKey > pd2^.IntegerKey then begin
      Result := 1;
   end else if pd1^.IntegerKey < pd2^.IntegerKey then begin
      Result := -1;
   end;
end;

// TStringKeyClass

constructor TStringKeyClass.Create;
begin
   DataList := TList.Create;
end;

destructor TStringKeyClass.Destroy;
begin
   Clear;
   DataList.Free;

   inherited Destroy;
end;

procedure TStringKeyClass.Clear;
var
   i : Integer;
   pd : PTStringKeyData;
begin
   for i := 0 to DataList.Count - 1 do begin
      pd := DataList.Items [i];
      if pd <> nil then Dispose (pd);
   end;
   DataList.Clear;
end;

function TStringKeyClass.IndexOf (aKey : String) : Integer;
var
   HighPos, LowPos, MidPos : Integer;
   pd : PTStringKeyData;
begin
   Result := -1;

   LowPos := 0;
   HighPos := DataList.Count - 1;
   MidPos := (LowPos + HighPos) div 2;

   while LowPos <= HighPos do begin
      pd := DataList.Items [MidPos];
      if pd^.StringKey = aKey then begin
         Result := MidPos;
         exit;
      end else if pd^.StringKey > aKey then begin
         HighPos := MidPos - 1;
      end else begin
         LowPos := MidPos + 1;
      end;
      MidPos := (LowPos + HighPos) div 2;
   end;
end;


{
function TStringKeyClass.GetKey (aIndex : Integer) : String;
var
   i : Integer;
   pd : PTStringKeyData;
begin
   Result := '';
   for i := 0 to DataList.Count - 1 do begin
      pd := DataList.Items [i];
      if pd^.KeyValue = aIndex then begin
         Result := pd^.StringKey;
         exit;
      end;
   end;
end;
}

function TStringKeyClass.GetCount : Integer;
begin
   Result := DataList.Count;
end;

procedure TStringKeyClass.Sort;
begin
   DataList.Sort (StringKeyClassSortCompare);
end;

{
function TStringKeyClass.Add (aKey : String; aKeyValue : Pointer) : Boolean;
var
   pd : PTStringKeyData;
   p : Pointer;
begin
   Result := false;

   if Trim (aKey) = '' then exit;

   p := Select (aKey);
   if p <> nil then exit;

   New (pd);
   pd^.StringKey := aKey;
   pd^.KeyValue := aKeyValue;
   DataList.Add (pd);

   Result := true;
end;
}

function TStringKeyClass.Insert (aKey : String; aKeyValue : Pointer) : Boolean;
var
   nPos : Integer;
   pd : PTStringKeyData;
   p : Pointer;
begin
   Result := false;

   if Trim (aKey) = '' then exit;

   p := Select (aKey);
   if p <> nil then exit;

   New (pd);
   pd^.StringKey := aKey;
   pd^.KeyValue := aKeyValue;

   nPos := GetInsertPos (aKey);
   if nPos < 0 then exit;
   
   DataList.Insert (nPos, pd);

   Result := true;
end;

function TStringKeyClass.Delete (aKey : String) : Boolean;
var
   nPos : Integer;
   pd : PTStringKeyData;
begin
   Result := false;

   nPos := IndexOf (aKey);
   if (nPos < 0) or (nPos >= DataList.Count) then exit;

   pd := DataList.Items [nPos];
   Dispose (pd);

   DataList.Delete (nPos);

   Result := true;
end;

function TStringKeyClass.Select (aKey : String) : Pointer;
var
   HighPos, LowPos, MidPos : Integer;
   pd : PTStringKeyData;
begin
   Result := nil;

   LowPos := 0;
   HighPos := DataList.Count - 1;
   MidPos := (LowPos + HighPos) div 2;

   while LowPos <= HighPos do begin
      pd := DataList.Items [MidPos];
      if pd^.StringKey = aKey then begin
         Result := pd^.KeyValue;
         exit;
      end else if pd^.StringKey > aKey then begin
         HighPos := MidPos - 1;
      end else begin
         LowPos := MidPos + 1;
      end;
      MidPos := (LowPos + HighPos) div 2;
   end;
end;

function TStringKeyClass.GetInsertPos (aKey : String) : Integer;
var
   HighPos, LowPos, MidPos : Integer;
   pd : PTStringKeyData;
begin
   Result := -1;
   
   LowPos := 0;
   HighPos := DataList.Count - 1;
   MidPos := (LowPos + HighPos) div 2;

   while LowPos <= HighPos do begin
      pd := DataList.Items [MidPos];
      if pd^.StringKey = aKey then begin
         exit;
      end else if pd^.StringKey > aKey then begin
         HighPos := MidPos - 1;
      end else begin
         LowPos := MidPos + 1;
      end;
      MidPos := (LowPos + HighPos) div 2;
   end;

   if HighPos >= 0 then MidPos := MidPos + 1;

   Result := MidPos;
end;

// TMultiStringKeyClass

constructor TMultiStringKeyClass.Create;
begin
   DataList := TList.Create;
end;

destructor TMultiStringKeyClass.Destroy;
begin
   Clear;
   DataList.Free;

   inherited Destroy;
end;

procedure TMultiStringKeyClass.Clear;
var
   i : Integer;
   pd : PTStringKeyData;
begin
   for i := 0 to DataList.Count - 1 do begin
      pd := DataList.Items [i];
      if pd <> nil then Dispose (pd);
   end;
   DataList.Clear;
end;

function TMultiStringKeyClass.GetKeyString (aIndex : Integer) : String;
var
   pd : PTStringKeyData;
begin
   Result := '';

   if (aIndex < 0) or (aIndex >= DataList.Count) then exit;

   pd := DataList.Items [aIndex];

   Result := pd^.StringKey;
end;

function TMultiStringKeyClass.GetKeyValue (aIndex : Integer) : Integer;
var
   pd : PTMultiStringKeyData;
begin
   Result := -1;

   if (aIndex < 0) or (aIndex >= DataList.Count) then exit;

   pd := DataList.Items [aIndex];

   Result := pd^.KeyValue;
end;

function TMultiStringKeyClass.GetCount : Integer;
begin
   Result := DataList.Count;
end;

procedure TMultiStringKeyClass.Sort;
begin
   DataList.Sort (StringKeyClassSortCompare);
end;

{
function TMultiStringKeyClass.Add (aKey : String; aKeyValue : Integer) : Boolean;
var
   nPos : Integer;
   pd : PTMultiStringKeyData;
begin
   Result := false;

   if Trim (aKey) = '' then exit;

   New (pd);
   pd^.StringKey := aKey;
   pd^.KeyValue := aKeyValue;
   DataList.Add (pd);

   Sort;

   Result := true;
end;
}

function TMultiStringKeyClass.Insert (aKey : String; aKeyValue : Integer) : Boolean;
var
   nPos : Integer;
   pd : PTMultiStringKeyData;
begin
   Result := false;

   if Trim (aKey) = '' then exit;

   New (pd);
   pd^.StringKey := aKey;
   pd^.KeyValue := aKeyValue;

   nPos := GetInsertPos (aKey);
   if nPos < 0 then exit;

   if nPos < DataList.Count then begin
      DataList.Insert (nPos, pd);
   end else begin
      DataList.Add (pd);
   end;

   Result := true;
end;


function TMultiStringKeyClass.Delete (aKey : String) : Boolean;
var
   i, nStartPos, nEndPos : Integer;
   pd : PTStringKeyData;
begin
   Result := false;

   if Select (aKey, nStartPos, nEndPos) > 0 then begin
      for i := nEndPos downto nStartPos do begin
         pd := DataList.Items [i];
         Dispose (pd);
         DataList.Delete (i);
      end;
   end;

   Result := true;
end;

function TMultiStringKeyClass.Select (aKey : String; var aStartPos, aEndPos : Integer) : Integer;
var
   nStartPos, nEndPos, HighPos, LowPos, MidPos : Integer;
   pd : PTStringKeyData;
begin
   Result := 0;

   LowPos := 0;
   HighPos := DataList.Count - 1;
   MidPos := (LowPos + HighPos) div 2;

   aStartPos := -1; aEndPos := -1;
   nStartPos := -1; nEndPos := -1;
   while LowPos <= HighPos do begin
      pd := DataList.Items [MidPos];
      if pd^.StringKey = aKey then begin
         nStartPos :=  MidPos;
         nEndPos :=  MidPos;
         while nStartPos > 0 do begin
            pd := DataList.Items [nStartPos - 1];
            if pd^.StringKey <> aKey then break;
            Dec (nStartPos);
         end;
         while nEndPos < DataList.Count - 1 do begin
            pd := DataList.Items [nEndPos + 1];
            if pd^.StringKey <> aKey then break;
            Inc (nEndPos);
         end;
         aStartPos := nStartPos;
         aEndPos := nEndPos;
         Result := nEndPos - nStartPos + 1;
         exit;
      end else if pd^.StringKey > aKey then begin
         HighPos := MidPos - 1;
      end else begin
         LowPos := MidPos + 1;
      end;
      MidPos := (LowPos + HighPos) div 2;
   end;
end;

function TMultiStringKeyClass.GetInsertPos (aKey : String) : Integer;
var
   HighPos, LowPos, MidPos : Integer;
   pd : PTStringKeyData;
begin
   Result := 0;

   LowPos := 0;
   HighPos := DataList.Count - 1;
   MidPos := (LowPos + HighPos) div 2;

   while LowPos <= HighPos do begin
      pd := DataList.Items [MidPos];
      if pd^.StringKey = aKey then begin
         while MidPos <= DataList.Count - 1 do begin
            pd := DataList.Items [MidPos];
            if pd^.StringKey <> aKey then break;
            Inc (MidPos);
         end;
         Result := MidPos;
         exit;
      end else if pd^.StringKey > aKey then begin
         HighPos := MidPos - 1;
      end else begin
         LowPos := MidPos + 1;
      end;
      MidPos := (LowPos + HighPos) div 2;
   end;

   if HighPos >= 0 then MidPos := MidPos + 1;

   Result := MidPos;   
end;

// TIntegerKeyClass

constructor TIntegerKeyClass.Create;
begin
   DataList := TList.Create;
end;

destructor TIntegerKeyClass.Destroy;
begin
   Clear;
   DataList.Free;

   inherited Destroy;
end;

procedure TIntegerKeyClass.Clear;
var
   i : Integer;
   pd : PTIntegerKeyData;
begin
   for i := 0 to DataList.Count - 1 do begin
      pd := DataList.Items [i];
      if pd <> nil then Dispose (pd);
   end;
   DataList.Clear;
end;

function TIntegerKeyClass.GetCount : Integer;
begin
   Result := DataList.Count;
end;

function TIntegerKeyClass.IndexOf (aKey : Integer) : Integer;
var
   HighPos, LowPos, MidPos : Integer;
   pd : PTIntegerKeyData;
begin
   Result := -1;

   LowPos := 0;
   HighPos := DataList.Count - 1;
   MidPos := (LowPos + HighPos) div 2;

   while LowPos <= HighPos do begin
      pd := DataList.Items [MidPos];
      if pd^.IntegerKey = aKey then begin
         Result := MidPos;
         exit;
      end else if pd^.IntegerKey > aKey then begin
         HighPos := MidPos - 1;
      end else begin
         LowPos := MidPos + 1;
      end;
      MidPos := (LowPos + HighPos) div 2;
   end;
end;

procedure TIntegerKeyClass.Sort;
begin
   DataList.Sort (IntegerKeyClassSortCompare);
end;

{
function TIntegerKeyClass.Add (aKey : Integer; aKeyValue : Pointer) : Boolean;
var
   pd : PTIntegerKeyData;
begin
   Result := false;

   if IndexOf (aKey) <> -1 then exit;

   New (pd);
   pd^.IntegerKey := aKey;
   pd^.KeyValue := aKeyValue;
   DataList.Add (pd);

   Sort;

   Result := true;
end;
}

function TIntegerKeyClass.Insert (aKey : Integer; aKeyValue : Pointer) : Boolean;
var
   nPos : Integer;
   pd : PTIntegerKeyData;
begin
   Result := false;

   if IndexOf (aKey) <> -1 then exit;

   New (pd);
   pd^.IntegerKey := aKey;
   pd^.KeyValue := aKeyValue;

   nPos := GetInsertPos (aKey);
   if nPos < 0 then exit;

   DataList.Insert (nPos, pd);

   Result := true;
end;

function TIntegerKeyClass.Delete (aKey : Integer) : Boolean;
var
   nIndex : Integer;
   pd : PTIntegerKeyData;
begin
   Result := false;

   nIndex := IndexOf (aKey);
   if (nIndex < 0) or (nIndex >= DataList.Count)  then exit;

   pd := DataList.Items [nIndex];
   Dispose (pd);

   DataList.Delete (nIndex);

   Result := true;
end;

function TIntegerKeyClass.Select (aKey : Integer) : Pointer;
var
   HighPos, LowPos, MidPos : Integer;
   pd : PTIntegerKeyData;
begin
   Result := nil;

   LowPos := 0;
   HighPos := DataList.Count - 1;
   MidPos := (LowPos + HighPos) div 2;

   while LowPos <= HighPos do begin
      pd := DataList.Items [MidPos];
      if pd^.IntegerKey = aKey then begin
         Result := pd^.KeyValue;
         exit;
      end else if pd^.IntegerKey > aKey then begin
         HighPos := MidPos - 1;
      end else begin
         LowPos := MidPos + 1;
      end;
      MidPos := (LowPos + HighPos) div 2;
   end;
end;

function TIntegerKeyClass.GetInsertPos (aKey : Integer) : Integer;
var
   HighPos, LowPos, MidPos : Integer;
   pd : PTIntegerKeyData;
begin
   Result := -1;
   
   LowPos := 0;
   HighPos := DataList.Count - 1;
   MidPos := (LowPos + HighPos) div 2;

   while LowPos <= HighPos do begin
      pd := DataList.Items [MidPos];
      if pd^.IntegerKey = aKey then begin
         exit;
      end else if pd^.IntegerKey > aKey then begin
         HighPos := MidPos - 1;
      end else begin
         LowPos := MidPos + 1;
      end;
      MidPos := (LowPos + HighPos) div 2;
   end;

   if HighPos >= 0 then MidPos := MidPos + 1;

   Result := MidPos;   
end;


{
// TKeyList

constructor TKeyList.Create;
begin
   KeyData := TStringKeyClass.Create;
   DataList := TList.Create;
end;

destructor TKeyList.Destroy;
begin
   Clear;
   inherited Destroy;
end;

procedure TKeyList.Clear;
begin
   KeyData.Clear;
   DataList.Clear;
end;

function TKeyList.Get (aIndex : Integer) : Pointer;
begin
   Result := nil;
   if aIndex < DataList.Count then begin
      Result := DataList.Items [aIndex];
   end;
end;

function TKeyList.GetCount : Integer;
begin
   Result := DataList.Count;
end;

function TKeyList.Add (aKey : String; aData : Pointer) : Boolean;
begin
   Result := false;
   if KeyData.Add (aKey, DataList.Count) = true then begin
      DataList.Add (aData);
      Result := true;
   end;
end;

procedure TKeyList.Delete (aKey : String);
var
   nIndex : Integer;
begin
   nIndex := KeyData.Select (aKey);
   if KeyData.Delete (aKey) = true then begin
      DataList.Delete (nIndex);
   end;
end;

function TKeyList.Find (aKey : String) : Pointer;
var
   nIndex : Integer;
begin
   Result := nil;

   nIndex := KeyData.Select (aKey);
   if nIndex >= 0 then begin
      Result := Get (nIndex);
   end;
end;
}

end.
