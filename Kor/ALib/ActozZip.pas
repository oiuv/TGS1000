unit ActozZip;

interface

uses
   windows, classes, Sysutils, LZRW1KH, graphics, WinSock;

const
   ActozZipIDent = 'AZF0';
   MaxBufferSize = 30000;
   CIBFileIDent = 'cib1';

type
  TCIBFileHeader = record
    IDent : array[0..3] of Char;
    ImageDataSize : integer;
    SayDataSize : integer;
  end;

  TCIBFile = class
   private
    FFileName: string;
    FBitmap: TBitmap;
    FSayData: TStringList;
    function    ReadBitmap : TBitmap;
    function    ReadSayData : TStringList;
   public
    constructor Create(aBitmap: TBitmap; aSayData: TStringList; aID, aMap, aIP, aTime: string);
    destructor  Destroy; override;
    procedure   Clear;

    procedure   LoadFromFile (aFileName: string);
    procedure   SaveToFile (aFileName: string);
    property    Bitmap : TBitmap read ReadBitmap;
    property    SayData : TStringList read ReadSayData;
  end;

  TActozZipFileHeader = record
    IDent : array [0..8-1] of char;   // 'AZF0'
    BufferCount : integer;
    OrgSize : integer;
    CompressSize : integer;
  end;

  TActozZip = class
   private
    FName: string;
    pBuf: pbyte;
    FCompressSize : integer;
    FOrgSize : integer;
    FBufferCount : integer;
    SourBP, DestBP : BufferPtr;
   public
    constructor Create;
    destructor Destroy; override;

    procedure Clear;

    procedure LoadFormFile (aFileName: string);   // '*.azf'
    procedure SaveToFile (aFileName: string);     // '*.azf'
    procedure LoadFromStream (aStream: TStream);
    procedure SaveToStream (aStream: TStream);

    procedure SetDataFromStream (aStream: TStream);
    procedure GetDataFromStream (aStream: TStream);
  end;

implementation

function SetFileDate: string;
var
   year, mon, day : word;
   str : string;
begin
   str := '';
   DecodeDate(Date, year, mon, day);
   str := IntToStr(year)+'_'+IntToStr(mon)+'_'+IntToStr(day)+'_ '+TimeToStr(Time);
   Result := str;
end;

function LocalIP: string;
type
   TaPInAddr = array [0..10] of PInAddr;
   PaPInAddr = ^TaPInAddr;
var
   phe: PHostEnt;  // HostEntry ±¸Á¶Ã¼
   pptr: PaPInAddr;
   Buffer: array [0..255] of char;
   i: Integer;
begin
   LocalIP := '';
   GetHostName(Buffer, SizeOf(Buffer));
   phe := GetHostByName(buffer);
   if phe = nil then begin
      LocalIP := '127.0.0.1';
      System.Exit;
   end;
   pptr := PaPInAddr(Phe^.h_addr_list);
   i := 0;
   while pptr^[i] <> nil do begin
      LocalIP := StrPas(inet_ntoa(pptr^[i]^));
      Inc(i);
   end;
end;

////////////////////////////////////////////////////////////////////////////////
//                                TCIBFile
////////////////////////////////////////////////////////////////////////////////
constructor TCIBFile.Create(aBitmap: TBitmap; aSayData: TStringList; aID, aMap, aIP, aTime: string);
var
   i: integer;
begin
   FFileName := '';
   FBitmap := nil;
   FSayData := nil;
   FBitmap := TBitmap.Create;
   FSayData := TStringList.Create;

   if aBitmap <> nil then FBitmap.Assign (aBitmap);
   if aSayData <> nil then begin
      for i := 0 to aSayData.Count-1 do begin
         FSayData.Add(aSayData[i]);
      end;
      if FSayData.Count < 4 then begin
         FSayData.Add('                   ');
         FSayData.Add('                   ');
         FSayData.Add('                   ');
      end;

      FSayData.Add ('');
      if aTime = '' then aTime := SetFileDate;
      FSayData.Add (aTime);
      FSayData.Add (Format ('Map : %S',[aMap]));
      FSayData.Add (Format ('LocalIP : %s',[LocalIP]));
      FSayData.Add (Format ('ID : %S',[aID]));
      FSayData.Add (Format ('SERVER : %S',[aIP]));
   end;
end;

destructor  TCIBFile.Destroy;
begin
   FBitmap.Free;
   FSayData.Free;
   inherited Destroy;
end;

procedure   TCIBFile.Clear;
begin
   FFileName := '';
   if FBitmap <> nil then FBitmap.Free;
   if FSayData <> nil then FSayData.Free;
   FBitmap := TBitmap.Create;
   FSayData := TStringList.Create;
end;

procedure   TCIBFile.LoadFromFile (aFileName: string);
var
   ActozZip : TActozZip;
   Header : TCIBFileHeader;
   Stream : TFileStream;
   SourStream : TMemoryStream;
begin
   Stream := nil;
   SourStream := nil;
   ActozZip := nil;
   Clear;
   try
      Stream := TFileStream.Create (aFileName, fmOpenRead);
      SourStream := TMemoryStream.Create;
      ActozZip := TActozZip.Create;
      Stream.ReadBuffer (Header, sizeof(Header));

      ActozZip.LoadFromStream (Stream);
      ActozZip.GetDataFromStream (SourStream);

      SourStream.Position := 0;
      FBitmap.LoadFromStream (SourStream);
      ActozZip.LoadFromStream (Stream);

      SourStream.Clear;
      ActozZip.GetDataFromStream (SourStream);
      SourStream.Position := 0;
      FSayData.LoadFromStream (SourStream);
   except
      Clear;
      if Stream <> nil then Stream.Free;
      if ActozZip <> nil then ActozZip.Free;
      if SourStream <> nil then SourStream.Free;
      Raise Exception.Create ('FALSE AZF File [LoadFromFile]');
   end;
   if Stream <> nil then Stream.Free;
   if ActozZip <> nil then ActozZip.Free;
   if SourStream <> nil then SourStream.Free;
end;

procedure   TCIBFile.SaveToFile (aFileName: string);
var
   ActozZip : TActozZip;
   Header : TCIBFileHeader;
   Stream : TFileStream;
   SourStream : TMemoryStream;
   n : integer;
begin
   ActozZip := TActozZip.Create;
   SourStream := nil;
   Stream := nil;
   try
      Stream := TFileStream.Create (aFileName, fmCreate or fmOpenReadWrite);
      SourStream := TMemoryStream.Create;

      FBitmap.SaveToStream (SourStream);
      SourStream.Position := 0;
      ActozZip.SetDataFromStream (SourStream);

      Stream.Seek (sizeof(Header), soFromBeginning);
      ActozZip.SaveToStream (Stream);

      n := Stream.Size;
      Header.ImageDataSize := n - sizeof(header);

      SourStream.Clear;
      FSayData.SaveToStream (SourStream);

      ActozZip.Clear;
      SourStream.Position := 0;
      ActozZip.SetDataFromStream (SourStream);
      ActozZip.SaveToStream (Stream);

      n := Stream.Size;
      Header.SayDataSize := n - Header.ImageDataSize - sizeof(header);

      Header.IDent := CIBFileIDent;
      Stream.Seek (0,0);
      Stream.WriteBuffer (Header, sizeof(Header));
   except
      if SourStream <> nil then SourStream.Free;
      if Stream <> nil then Stream.Free;
      ActozZip.Free;
      Raise Exception.Create ('FALSE AZF File [SaveToFile]');
      exit;
   end;
   if SourStream <> nil then SourStream.Free;
   if Stream <> nil then Stream.Free;
   ActozZip.Free;
end;

function    TCIBFile.ReadBitmap : TBitmap;
begin
   Result := nil;
   if FBitmap <> nil then Result := FBitmap;
end;

function    TCIBFile.ReadSayData : TStringList;
begin
   Result := nil;
   if FSayData <> nil then Result := FSayData;
end;

////////////////////////////////////////////////////////////////////////////////
//                                TActozZip
////////////////////////////////////////////////////////////////////////////////
constructor TActozZip.Create;
begin
   FName := '';
   pBuf := nil;
   FCompressSize := 0;
   FOrgSize := 0;
   FBufferCount := 0;
   GetMem (SourBP, MaxBufferSize+1000);
   GetMem (DestBP, MaxBufferSize+1000);
end;

destructor TActozZip.Destroy;
begin
   Clear;
   Freemem (SourBP);
   FreeMem (DestBP);
   inherited Destroy;
end;

procedure TActozZip.Clear;
begin
   if FCompressSize <> 0 then FreeMem (pBuf);
   pBuf := nil;
   FCompressSize := 0;
   FOrgSize := 0;
end;

procedure TActozZip.LoadFormFile (aFileName: string);   // '*.azf'
var Stream: TFileStream;
begin
   if not FileExists (aFileName) then exit;
   Stream := TFileStream.Create (aFileName, fmOpenRead);
   LoadFromStream (Stream);
   Stream.Free;
end;

procedure TActozZip.SaveToFile (aFileName: string);     // '*.azf'
var Stream: TFileStream;
begin
   Stream := TFileStream.Create (aFileName, fmCreate);
   SaveToStream (Stream);
   Stream.Free;
end;

procedure TActozZip.LoadFromStream (aStream: TStream);
var Header : TActozZipFileHeader;
begin
   aStream.ReadBuffer (Header, sizeof (Header));
   if Header.IDent <> ActozZipIDent then begin
      Raise Exception.Create ('NOT Value AZF File');
      exit;
   end;
   Clear;
   FOrgSize := Header.OrgSize;
   FCompressSize := Header.CompressSize;
   FBufferCount := Header.BufferCount;
   GetMem (pBuf, FCompressSize);
   aStream.ReadBuffer (pBuf^, FCompressSize);
end;

procedure TActozZip.SaveToStream (aStream: TStream);
var Header : TActozZipFileHeader;
begin
   Header.Ident := ActozZipIDent;
   Header.BufferCount := FBufferCount;
   Header.CompressSize := FCompressSize;
   Header.OrgSize := FOrgSize;
   aStream.WriteBuffer (Header, sizeof (Header));
   aStream.WriteBuffer (pBuf^, FCompressSize);
end;

procedure TActozZip.SetDataFromStream (aStream: TStream);
var
   i, n, fsize, compsize : integer;
   DestBuf : pbyte;
   sp, dp : pbyte;
begin
   Clear;
   FOrgSize := aStream.Size;

   GetMem (DestBuf, FOrgSize);
   dp := DestBuf;

   fsize := FOrgSize;
   FBufferCount := 0;

   FCompressSize := 0;
   while fsize > 0 do begin
      if fsize > MaxBufferSize then begin
         compsize := MaxBufferSize;
      end else begin
         compsize := fsize;
      end;
      aStream.ReadBuffer (SourBP^, compsize);
      n := Compression(SourBP, DestBP, compsize);
      fsize := fsize - compsize;
      FCompressSize := FCompressSize + n;

      Move (n, dp^, sizeof(Word));
      inc (dp, sizeof(Word));
      inc (FCompressSize, sizeof(Word));
      Move (DestBP^, dp^, n);
      inc (dp, n);
      inc (FBufferCount);
   end;
   ///////////////////////////////////////
   GetMem (pBuf, FCompressSize);
   sp := DestBuf;
   dp := pBuf;
   for i := 0 to FCompressSize -1 do begin
      dp^ := not sp^;
      inc (sp); inc (dp);
   end;
   ///////////////////////////////////////
   FreeMem (DestBuf);
end;

procedure TActozZip.GetDataFromStream (aStream: TStream);
var
   i, n, compsize : integer;
   SourBuf : pbyte;
   sp, dp : pbyte;
begin
   if pBuf = nil then exit;
   if FCompressSize = 0 then exit;
   GetMem (SourBuf, FCompressSize);
   ///////////////////////////////////////
   sp := pBuf;
   dp := SourBuf;
   for i := 0 to FCompressSize -1 do begin
      dp^ := not sp^;
      inc (sp); inc (dp);
   end;
   ///////////////////////////////////////
   sp := SourBuf;
   compsize := 0;
   for i := 0 to FBufferCount -1 do begin
      move (sp^, compsize, sizeof(Word));
      inc (sp, sizeof(Word));
      move (sp^, SourBP^, compsize);
      n := Decompression (SourBP, DestBP, compsize);
      aStream.WriteBuffer (DestBP^, n);
      inc (sp, compsize);
   end;
   Freemem (SourBuf);
end;

end.
