unit AnsStringCls;

// change by minds 050919
// string parameter change use const.

interface
uses
   SysUtils,classes;

type
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
      function  GetString (const astr: string): string;
   end;

function Conv (const astr: string): string;

implementation

uses
   AUtil32;
var
   AnsStringClass : TAnsStringClass;

function Conv (const astr: string): string;
begin
   Result := AnsStringClass.GetString (astr);
end;

//////////////////////////
//   String ¹Ù²Þ.
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

function  TAnsStringClass.GetString (const astr: string): string;
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

Initialization
begin
   AnsStringClass := TAnsStringClass.Create;
   AnsStringClass.LoadFromFile ('.\tgs1000.acs');


end;

Finalization
begin
   AnsStringClass.Free;
end;

end.
