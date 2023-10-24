unit WaveLoad;

interface

uses
   Windows, MMSystem, Sysutils, classes;

const
  ID_RIFF = Ord('R') + Ord('I')*$100 + Ord('F')*$10000 + Ord('F')*$1000000;
  ID_WAVE = Ord('W') + Ord('A')*$100 + Ord('V')*$10000 + Ord('E')*$1000000;
  ID_FMT  = Ord('f') + Ord('m')*$100 + Ord('t')*$10000 + Ord(' ')*$1000000;
  ID_FACT = Ord('f') + Ord('a')*$100 + Ord('c')*$10000 + Ord('t')*$1000000;
  ID_DATA = Ord('d') + Ord('a')*$100 + Ord('t')*$10000 + Ord('a')*$1000000;

type
   TWaveFileHeader = record
     aRiffchunk : integer;
     aWaveSize : Longint;
     aWAVEchunk : integer;
   end;
   PTWaveFileHeader = ^TWaveFileHeader;

   TWaveFMTchunk = record
     aFMTchunk : integer;
     aFormatSize : integer;
     aPCMFormatFlag : Word;
     aChannel : Word;
     aSampleRate : integer;
     aSampleRatePerSec : integer;
     aPerSecScale : Word;
     aBits : Word;
   end;
   PTWaveFMTchunk = ^TWaveFMTchunk;

   TWaveDatachunk = record
     aDatachunk : integer;
     aDataSize : Longint;
   end;
   PTWaveDatachunk = ^TWaveDatachunk;


   TWPCMWave = class
      private
         FFileName : string;
         FSize : LongInt;
         FChannels: Word;
         FSamplesPerSec: DWORD;
         FckIn, FckInRiff : TMMCKInfo;
         FWaveFormatEx  : TWaveFormatEx;
         FBufferPostion : Longint;
      public
         constructor Create;
         destructor  destroy; override;
         procedure   Clear;

         function    OpenWave (aFileName: string): Boolean;
         function    OpenWaveStream (Stream: TStream): Boolean;

         function    ReadWave(var aBuffer: Pbyte): Boolean;
         function    ReadWaveStream(var aBuffer: Pbyte; Stream: TStream): Boolean;

         property    FileName : string read FFileName;
         property    Size : integer read FSize;
         property    Channels : Word read FChannels;
         property    SamplesPerSec : DWORD read FSamplesPerSec;
         property    MMCKInfo : TMMCKInfo read FckIn;
         property    MMCKInfoRiff : TMMCKInfo read FckInRiff;
         property    WaveFormatEx : TWaveFormatEx read FWaveFormatEx;
   end;

implementation


function mmioFOURCC(c1, c2, c3, c4: char): FOURCC;
var str : string[4];
begin
  str := c1 + c2 + c3 + c4;
  Result := mmioStringToFOURCC(@str[1], 0);
end;

constructor TWPCMWave.Create;
begin
   inherited Create;
   FFileName := '';
   FSize := 0;
   FChannels := 0;
   FSamplesPerSec := 0;
   FillChar (FckIn, sizeof(FckIn), 0);
   FillChar (FckInRiff, sizeof(FckInRiff), 0);
   FillChar (FWaveFormatEx, sizeof(FWaveFormatEx), 0);
   FBufferPostion := 0;
end;

destructor  TWPCMWave.destroy;
begin
   inherited destroy;
   Clear;
end;

procedure   TWPCMWave.Clear;
begin
   FFileName := '';
   FSize := 0;
   FChannels := 0;
   FSamplesPerSec := 0;
   FillChar (FckIn, sizeof(FckIn), 0);
   FillChar (FckInRiff, sizeof(FckInRiff), 0);
end;

function    TWPCMWave.OpenWave (aFileName: string): Boolean;
var
   mmIO : HmmIO;
begin
   Result := FALSE;
   if not FileExists (aFileName) then exit;

   FFileName := aFileName;
   mmIO  := mmioOpenA(PChar(FFileName), nil,MMIO_READ or MMIO_ALLOCBUF);
   if mmIO = 0 then exit;

   FckInRiff.fccType := mmioFOURCC('W','A','V','E');
   if mmioDescend(mmIO,@FckInRiff,nil,MMIO_FINDRIFF) <> 0 then begin
      mmioClose(mmIO,0); exit;
   end;

   FckIn.ckid := mmioFOURCC('f','m','t',' ');
   if mmioDescend(mmIO,@FckIn,@FckInRiff,0) <> 0 then begin
      mmioClose(mmIO,0); exit;
   end;

   if mmIORead(mmIO,PChar(@FWaveFormatEx),sizeof(FWaveFormatEx)) <> sizeof(FWaveFormatEx) then begin
      mmioClose(mmIO,0); exit;
   end;

   if FWaveFormatEx.wFormatTag <> WAVE_FORMAT_PCM then begin
      mmioClose(mmIO,0); exit;
   end;

   if mmioAscend(mmIO,@FckIn,0) <> 0 then begin
      mmioClose(mmIO,0); exit;
   end;

   FckIn.ckid := mmioFOURCC('d','a','t','a');
   if mmioDescend(mmIO, @FckIn, @FckInRiff,MMIO_FINDCHUNK) <> 0 then begin
      mmioClose(mmIO,0); exit;
   end;

   FSize := FckIn.cksize;
   FChannels := FWaveFormatEx.nChannels;
   FSamplesPerSec := FWaveFormatEx.nSamplesPerSec;
   mmioClose(mmIO,0);
   Result := TRUE;
end;

function    TWPCMWave.OpenWaveStream (Stream: TStream): Boolean;
var
   WaveFileHeader : TWaveFileHeader;
   WaveFMTchunk : TWaveFMTchunk;
   WaveDatachunk : TWaveDatachunk;
begin
   Result := FALSE;
   if Stream = nil then exit;
   FillChar (WaveFileHeader,Sizeof(TWaveFileHeader), 0);
   FillChar (WaveFMTchunk,Sizeof(TWaveFMTchunk), 0);
   FillChar (WaveDatachunk,Sizeof(TWaveDatachunk), 0);

   {TWaveFileHeader}
   Stream.ReadBuffer (WaveFileHeader, Sizeof(TWaveFileHeader));
   if WaveFileHeader.aRiffchunk <> ID_RIFF then exit;
   if WaveFileHeader.aWAVEchunk <> ID_WAVE then exit;

   {TWaveFMTchunk;}
   Stream.ReadBuffer (WaveFMTchunk, Sizeof(TWaveFMTchunk));
   if WaveFMTchunk.aFMTchunk <> ID_FMT then exit;
   if WaveFMTchunk.aFormatSize <> 16 then exit;
   if WaveFMTchunk.aPCMFormatFlag <> WAVE_FORMAT_PCM then exit;

   FWaveFormatEx.wFormatTag := WaveFMTchunk.aPCMFormatFlag;
   FWaveFormatEx.nChannels := WaveFMTchunk.aChannel;
   FWaveFormatEx.nSamplesPerSec := WaveFMTchunk.aSampleRate;
   FWaveFormatEx.nAvgBytesPerSec := WaveFMTchunk.aSampleRatePerSec;
   FWaveFormatEx.nBlockAlign := WaveFMTchunk.aPerSecScale;
   FWaveFormatEx.wBitsPerSample := WaveFMTchunk.aBits;

   {TWaveDatachunk}
   Stream.ReadBuffer (WaveDatachunk, Sizeof(TWaveDatachunk));
   if WaveDatachunk.aDatachunk <> ID_DATA then exit;
   FWaveFormatEx.cbSize := 0;
   FBufferPostion := Stream.Position;
   FSize := WaveDatachunk.aDataSize;
   Result := TRUE;
end;

function    TWPCMWave.ReadWaveStream(var aBuffer: Pbyte; Stream: TStream): Boolean;
begin
   Result := FALSE;
   try
//   Stream.Seek (FBufferPostion, soFromBeginning);
   Stream.ReadBuffer (aBuffer^, FSize);
   except
      aBuffer := nil;
      exit;
   end;
   Result := TRUE;
end;

function    TWPCMWave.ReadWave(var abuffer: Pbyte) : Boolean;
var
   mmIO : HmmIO;
begin
   Result := FALSE;
   if FFileName = '' then exit;
   if FSize = 0 then exit;
   mmIO := mmioOpen(PChar(FFileName), nil,MMIO_READ or MMIO_ALLOCBUF);
   if mmIO = 0 then exit;
   {
   FckInRiff.fccType := mmioFOURCC('W','A','V','E');
   if mmioDescend(mmIO,@FckInRiff,nil,MMIO_FINDRIFF) <> 0 then begin
      mmioClose(mmIO,0); exit;
   end;

   FckIn.ckid := mmioFOURCC('f','m','t',' ');
   if mmioDescend(mmIO,@FckIn,@FckInRiff,0) <> 0 then begin
      mmioClose(mmIO,0); exit;
   end;

   if mmIORead(mmIO,PChar(@FWaveFormatEx),sizeof(FWaveFormatEx)) <> sizeof(FWaveFormatEx) then begin
      mmioClose(mmIO,0); exit;
   end;

   if FWaveFormatEx.wFormatTag <> WAVE_FORMAT_PCM then begin
      mmioClose(mmIO,0); exit;
   end;

   if mmioAscend(mmIO,@FckIn,0) <> 0 then begin
      mmioClose(mmIO,0); exit;
   end;

   FckIn.ckid := mmioFOURCC('d','a','t','a');
   if mmioDescend(mmIO, @FckIn, @FckInRiff,MMIO_FINDCHUNK) <> 0 then begin
      mmioClose(mmIO,0); exit;
   end;

   FSize := FckIn.cksize;
   FChannels := FWaveFormatEx.nChannels;
   FSamplesPerSec := FWaveFormatEx.nSamplesPerSec;
    }
   mmIORead(mmIO,PChar(abuffer),FckIn.cksize);
   mmIOClose(mmIO,0);
   Result := TRUE;
end;

end.
