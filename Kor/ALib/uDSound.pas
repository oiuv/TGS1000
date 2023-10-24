unit uDSound;

interface

uses
   Windows, ActiveX, Sysutils, classes, extctrls,
   WaveLoad, DirectShow, DirectSound;


////////////////////////////////////////////////////////////////////////////////
//                      DBaseSound
////////////////////////////////////////////////////////////////////////////////

function  DBaseSoundCreateHandle : integer;
procedure DBaseSoundFreeHandle (aHandle: integer);
procedure DBaseSoundLoadFromFile (aHandle: integer; aFileName: pChar);
procedure DBaseSoundPlay (aHandle: integer);
procedure DBaseSoundStop (aHandle: integer);
procedure DBaseSoundPause (aHandle: integer);
procedure DBaseSoundSetVolume (aHandle, aVolume: integer);
function  DBaseSoundGetVolume (aHandle: integer): integer;
procedure DBaseSoundSetBalance (aHandle, aBalance: integer);
function  DBaseSoundGetBalance (aHandle: integer): integer;
procedure DBaseSoundSetLoop (aHandle: integer; aLoop: Boolean);
function  DBaseSoundGetPlaying (aHandle: integer): Boolean;

////////////////////////////////////////////////////////////////////////////////
//                      DEffectSound
////////////////////////////////////////////////////////////////////////////////
procedure DEffectSoundInit (aHandle: integer);
procedure DEffectSoundFinal;

procedure DEffectSoundMaxBufferCount (Value: integer);
procedure DEffectSoundAdd (aFileName: string; Stream : TStream);
function  DEffectSoundPlay (aFileName: string; aPan, aVolume: integer): Boolean;

implementation

////////////////////////////////////////////////////////////////////////////////
//                      TDBaseSound
////////////////////////////////////////////////////////////////////////////////

type
  TDBaseSound = class
    private
      FboInit : Boolean;
      FGraphBuilder: IGraphBuilder;
      FMediaControl: IMediaControl;
      FMediaSeeking: IMediaSeeking;
      FBasicAudio: IBasicAudio;
      FSourceNext: IBaseFilter;
      FSourceCurrent: IBaseFilter;

      FFileName: string;
      FVolume: integer;
      FBalance: integer;
      FLoop: Boolean;
      FSize: integer;
      FPostion: integer;
      FboPlaying : Boolean;

      Timer : TTimer;
      procedure OnTimer (Sender: TObject);
    public
      constructor Create;
      destructor Destroy; override;

      function Initialize: Boolean;
      procedure Finalize;

      procedure LoadFromFile (aFileName: string);
      procedure Play;
      procedure Stop;
      procedure Pause;

      procedure SetLoop(Value: Boolean);
      procedure SetVolume (Value: integer);
      procedure SetBalance (Value: integer);
      procedure SetPostion (Value: integer);

      property FileName: string read FFileName;
      property Volume: integer read FVolume write SetVolume;
      property Balance: integer read FBalance write SetBalance;
      property Loop: Boolean read FLoop write SetLoop;
      property Size: integer read FSize;
      property Postion: integer read FPostion write SetPostion;
      property Playing: Boolean read FboPlaying;
  end;

////////////////////////////////////////////////////////////////////////////////
//                      TEffectSound
////////////////////////////////////////////////////////////////////////////////
  TEffectSound = class
    private
      FVolume : integer;
      FPan : integer;
      FPlaying : Boolean;
      FFileName : string;
      FWPCMWave : TWPCMWave;
      FDirectSound : IDirectSound;
      FDirectSoundBuffer : IDirectSoundBuffer;
      procedure InitBuffer (Stream: TStream);
      function  FillBuffer(aStream: TStream): Boolean;
      procedure SetVolume (Value: integer); // -10000 ~ 0
      procedure SetPan (Value: integer); // -10000 ~ 10000
    public
      constructor Create (DirectSound : IDirectSound);
      destructor Destroy; override;
      procedure clear;
      procedure Add (aFileName: string; Stream : TStream);
      procedure Play (aFileName: string; aPan, aVolume: integer);
      procedure Stop;
      function  Playing: Boolean;

      property Volume : integer read FVolume write SetVolume;
      property Pan : integer read FPan write SetPan;
  end;

  TEffectSoundData = record
    aFileName: string;
    aEffectSound : TEffectSound;
  end;
  PTEffectSoundData = ^TEffectSoundData;

  TEffectSoundList = class
    private
      FboInit : boolean;
      DataList : TList;
      UnUsedList : TList;
      FTimer : TTimer;
      FMaxBufferCount : integer;
      FDirectSound : IDirectSound;
      procedure UpDate(Sender: TObject);
    public
      constructor Create (aHandle: integer);
      destructor Destroy; override;
      procedure Clear;

      function  isSound (aFileName: string): PTEffectSoundData;
      procedure Add (aFileName: string; Stream : TStream);
      function  Play (aFileName: string; aPan, aVolume: integer): Boolean;
      procedure SetMaxBufferCount (aMaxBufferCount: integer);

      property DirectSound : IDirectSound read FDirectSound;
  end;

var
   EffectSoundList : TEffectSoundList;

////////////////////////////////////////////////////////////////////////////////
//                     TDBaseSound
////////////////////////////////////////////////////////////////////////////////
constructor TDBaseSound.Create;
begin
   FboInit := FALSE;
   Initialize;
   FboPlaying := FALSE;
   FLoop := FALSE;
   Timer := TTimer.Create (nil);
   Timer.OnTimer := OnTimer;
   Timer.Interval := 100;
   Timer.Enabled := TRUE;
end;

destructor TDBaseSound.Destroy;
begin
   Timer.Free;
   Finalize;
   inherited destroy;
end;

procedure TDBaseSound.OnTimer (Sender: TObject);
var
   StopPos, CurPos, NewPos : int64;
begin
   if not assigned (FMediaSeeking) then exit;
   if not FboPlaying then exit;
   FMediaSeeking.GetStopPosition(StopPos);
   FMediaSeeking.GetCurrentPosition (CurPos);
   if CurPos >= StopPos then begin
      if FLoop then begin
         NewPos := 0;
         FMediaSeeking.SetPositions (NewPos, AM_SEEKING_AbsolutePositioning, NewPos, AM_SEEKING_NoPositioning);
         Play;
      end else begin
         NewPos := 0;
         FMediaSeeking.SetPositions (NewPos, AM_SEEKING_AbsolutePositioning, NewPos, AM_SEEKING_NoPositioning);
         Stop;
      end;
   end;
end;

function TDBaseSound.Initialize: Boolean;
begin
   FboInit := FALSE;
   Result := FALSE;
   if Failed (CoInitialize (nil)) then exit;
   if Failed (CoCreateInstance (TGUID(CLSID_FilterGraph), nil, CLSCTX_INPROC_SERVER, TGUID(IID_IGraphBuilder), FGraphBuilder)) then exit;
   if Failed (FGraphBuilder.QueryInterface (IID_IMediaControl, FMediaControl)) then exit;
   if Failed (FGraphBuilder.QueryInterface (IID_IMediaSeeking, FMediaSeeking)) then exit;
   if Failed (FGraphBuilder.QueryInterface (IID_IBasicAudio, FBasicAudio)) then exit;
   Result := TRUE;
   FboInit := TRUE;
end;

procedure TDBaseSound.Finalize;
begin
   if not FboInit then exit;
   if assigned(FMediaControl) then FMediaControl.Stop;
   if assigned(FGraphBuilder) then FGraphBuilder := nil;
   if assigned(FMediaControl) then FMediaControl := nil;
   if assigned(FMediaSeeking) then FMediaSeeking := nil;
   if assigned(FBasicAudio) then FBasicAudio := nil;
   if assigned(FSourceNext) then FSourceNext := nil;
   if assigned(FSourceCurrent) then FSourceCurrent := nil;
   CoUninitialize;
end;
{
procedure TDBaseSound.LoadFromFile (aFileName: string);
var
   pPin: IPin;
   tmpEnumFilters: IEnumFilters;
   tmpBaseFilter: IBaseFilter;
   tmpBaseFilterArr: array [0..49] of IBaseFilter;
   iFilterCount, iPos: integer;
   fetched: Cardinal;
   llpos: Comp;
   StopPos: Comp;
   pFileName: pWideChar;
begin
   if not FileExists (aFileName) then exit;
   pPin := nil;
   GetMem (pFileName, MAX_PATH);
   MultiByteToWideChar (CP_ACP, 0, pchar(aFileName), -1, pFileName, MAX_PATH);
   FGraphBuilder.AddSourceFilter (pFileName, pFileName, FSourceNext);
   FreeMem (pFileName);

   FSourceNext.FindPin ('Output', pPin);
   FMediaControl.Stop;
   tmpEnumFilters := nil;
   tmpBaseFilter := nil;
   FGraphBuilder.EnumFilters (tmpEnumFilters);
   iFilterCount := 0;
   iPos := 0;
   while tmpEnumFilters.Skip (1) = S_OK do begin
      inc (iFilterCount);
   end;
   tmpEnumFilters.Reset;
   fetched := 0;
   while tmpEnumFilters.Next(1, tmpBaseFilterArr[iPos], fetched) = S_OK do begin
      inc (iPos);
   end;
   if assigned (tmpEnumFilters) then tmpEnumFilters := nil;
   for iPos := 0 to iFilterCount -1 do begin
      FGraphBuilder.RemoveFilter (tmpBaseFilterArr[iPos]);
      if tmpBaseFilterArr[iPos] <> FSourceCurrent then FGraphBuilder.AddFilter (tmpBaseFilterArr[iPos], nil);
      if assigned(tmpBaseFilterArr[iPos]) then tmpBaseFilterArr[iPos] := nil;
   end;

   Sleep (5);
   FGraphBuilder.Render (pPin);
   FSourceCurrent := FSourceNext;
   FSourceNext := nil;

   if assigned(pPin) then pPin := nil;
   if assigned(FSourceNext) then FSourceNext := nil;
   llpos := 0;

   Sleep (5);
   FMediaSeeking.SetPositions (llpos, AM_SEEKING_AbsolutePositioning, llpos, AM_SEEKING_NoPositioning);
   Sleep (5);
   FMediaSeeking.GetStopPosition(StopPos);
   FSize := Round(StopPos);
end;
}
procedure TDBaseSound.LoadFromFile (aFileName: string);
var
   pFileName: pWideChar;
begin
   if not FboInit then exit;
   if not FileExists (aFileName) then exit;
   GetMem (pFileName, MAX_PATH);
   MultiByteToWideChar (CP_ACP, 0, pchar(aFileName), -1, pFileName, MAX_PATH);
   FGraphBuilder.RenderFile (pFIleName, nil);
//   FGraphBuilder.AddSourceFilter (pFileName, pFileName, FSourceNext);
   FreeMem (pFileName);
{
   FSourceNext.FindPin ('Output', pPin);
   FMediaControl.Stop;
   tmpEnumFilters := nil;
   tmpBaseFilter := nil;
   FGraphBuilder.EnumFilters (tmpEnumFilters);
   iFilterCount := 0;
   iPos := 0;
   while tmpEnumFilters.Skip (1) = S_OK do begin
      inc (iFilterCount);
   end;
   tmpEnumFilters.Reset;
   fetched := 0;
   while tmpEnumFilters.Next(1, tmpBaseFilterArr[iPos], fetched) = S_OK do begin
      inc (iPos);
   end;
   if assigned (tmpEnumFilters) then tmpEnumFilters := nil;
   for iPos := 0 to iFilterCount -1 do begin
      FGraphBuilder.RemoveFilter (tmpBaseFilterArr[iPos]);
      if tmpBaseFilterArr[iPos] <> FSourceCurrent then FGraphBuilder.AddFilter (tmpBaseFilterArr[iPos], nil);
      if assigned(tmpBaseFilterArr[iPos]) then tmpBaseFilterArr[iPos] := nil;
   end;

   Sleep (5);
   FGraphBuilder.Render (pPin);
   FSourceCurrent := FSourceNext;
   FSourceNext := nil;

   if assigned(pPin) then pPin := nil;
   if assigned(FSourceNext) then FSourceNext := nil;
   llpos := 0;

   Sleep (5);
   FMediaSeeking.SetPositions (llpos, AM_SEEKING_AbsolutePositioning, llpos, AM_SEEKING_NoPositioning);
   Sleep (5);
   FMediaSeeking.GetStopPosition(StopPos);
   FSize := Round(StopPos);
}
end;

procedure TDBaseSound.Play;
begin
   if not FboInit then exit;

   if not assigned(FBasicAudio) then exit;
   Sleep (5);
   FBasicAudio.put_Volume (FVolume);
   if assigned (FMediaControl) then FMediaControl.Run;
   Sleep (5);
   if assigned (FSourceCurrent) then FSourceCurrent := nil;
   FboPlaying := TRUE;
end;

procedure TDBaseSound.Stop;
begin
   if not FboInit then exit;

   FboPlaying := FALSE;
   if assigned (FMediaControl) then FMediaControl.Stop;
end;

procedure TDBaseSound.Pause;
begin
   if not FboInit then exit;

   FboPlaying := FALSE;
   if assigned (FMediaControl) then FMediaControl.Pause;
end;

procedure TDBaseSound.SetLoop(Value: Boolean);
begin
   FLoop := Value;
end;

procedure TDBaseSound.SetVolume (Value: integer);
begin
   if not FboInit then exit;

   if not assigned (FBasicAudio) then exit;
   FVolume := Value;
   FBasicAudio.put_Volume (FVolume);
end;

procedure TDBaseSound.SetBalance (Value: integer);
begin
   if not FboInit then exit;

   if not assigned (FBasicAudio) then exit;
   FBalance := Value;
   FBasicAudio.put_Balance (FBalance);
end;

procedure TDBaseSound.SetPostion (Value: integer); // 0..100
var
   StopPos, NewPos: int64;
begin
   if not FboInit then exit;

   if not assigned (FMediaSeeking) then exit;
   if not FboPlaying then exit;
   FMediaSeeking.GetStopPosition(StopPos);
   NewPos := (StopPos * Value) div 100;
   if NewPos < 0 then NewPos := 0;
   if NewPos > StopPos then NewPos := StopPos;

   FMediaSeeking.SetPositions (NewPos, AM_SEEKING_AbsolutePositioning, NewPos, AM_SEEKING_NoPositioning);
end;

////////////////////////////////////////////////////////////////////////////////
//                      TEffectSoundList
////////////////////////////////////////////////////////////////////////////////

constructor TEffectSoundList.Create (aHandle: integer);
begin
   FboInit := FALSE;

   FDirectSound := nil;
   CoInitialize(nil);
   DataList := TList.Create;
   UnUsedList := TList.Create;
   FTimer := TTimer.Create (nil);
   FTimer.Interval := 500;
   FTimer.Enabled := TRUE;
   FTimer.OnTimer := UpDate;
   if Failed (DirectSoundCreate (nil, FDirectSound, nil)) then exit;
   if Failed (FDirectSound.SetCooperativeLevel (aHandle, DSSCL_PRIORITY)) then begin
      FDirectSound := nil;
      exit;
   end;
   FMaxBufferCount := 100;
   FboInit := TRUE;
end;

destructor TEffectSoundList.Destroy;
begin
   Clear;
   FTimer.Free;
   FDirectSound := nil;
   UnUsedList.Free;
   DataList.Free;
   CoUnInitialize;
   inherited Destroy;
end;

procedure TEffectSoundList.Clear;
var
   i : integer;
   P : PTEffectSoundData;
begin
   if not FboInit then exit;
   for i := 0 to DataList.Count -1 do begin
      P := DataList[i];
      p^.aEffectSound.Stop;
      p^.aEffectSound.Free;
      dispose (p);
   end;
   for i := 0 to UnUsedList.Count -1 do begin
      P := UnUsedList[i];
      p^.aEffectSound.Stop;
      p^.aEffectSound.Free;
      dispose (p);
   end;
   DataList.Clear;
   UnUsedList.Clear;
end;

procedure TEffectSoundList.UpDate(Sender: TObject);
var
   i : integer;
   P : PTEffectSoundData;
begin
   if not FboInit then exit;

   if DataList.Count < FMaxBufferCount then exit;
   for i := DataList.Count -1 downto 0 do begin
      p := DataList[i];
      if not p^.aEffectSound.Playing then begin
         UnUsedList.Add (p);
         DataList.Delete (i);
      end;
   end;
end;

procedure TEffectSoundList.SetMaxBufferCount (aMaxBufferCount: integer);
begin
   FMaxBufferCount := aMaxBufferCount;
end;

function  TEffectSoundList.isSound (aFileName: string): PTEffectSoundData;
var
   P : PTEffectSoundData;
   i : integer;
begin
   Result := nil;
   if not FboInit then exit;

   for i := 0 to DataList.Count -1 do begin
      p := DataList[i];
      if p^.aFileName = aFileName then begin
         Result := p;
         exit;
      end;
   end;
end;

procedure TEffectSoundList.Add (aFileName: string; Stream : TStream);
var P : PTEffectSoundData;
begin
   if not FboInit then exit;

   if UnUsedList.Count > 0 then begin
      p := UnUsedList[UnUsedList.Count-1];
      DataList.Add (p);
      UnUsedList.Delete (UnUsedList.Count-1);
      p^.aFileName := aFileName;
      p^.aEffectSound.Add (aFileName, Stream);
      exit;
   end;

   p := isSound (aFileName);
   if p <> nil then begin
      exit;
   end else begin
      new (p);
      p^.aFileName := aFileName;
      p^.aEffectSound := TEffectSound.Create (FDirectSound);
      DataList.Add (p);
      p^.aEffectSound.Add (aFileName, Stream);
   end;
end;

function  TEffectSoundList.Play (aFileName: string; aPan, aVolume: integer): Boolean;
var P : PTEffectSoundData;
begin
   Result := FALSE;
   if not FboInit then exit;

   p := isSound (aFileName);
   if p = nil then exit;
   p^.aEffectSound.Play (aFileName, aPan, aVolume);
   Result := TRUE;
end;

////////////////////////////////////////////////////////////////////////////////
//                      TEffectSound
////////////////////////////////////////////////////////////////////////////////
constructor TEffectSound.Create (DirectSound : IDirectSound);
begin
   FVolume := 0;
   FPan := 0;
   FPlaying := FALSE;
   FFileName := '';
   FDirectSound := DirectSound;
   FDirectSoundBuffer := nil;
   FWPCMWave := TWPCMWave.Create;
end;

destructor TEffectSound.Destroy;
begin
   Clear;
   FWPCMWave.Free;
   inherited Destroy;
end;

procedure TEffectSound.Clear;
begin
   FDirectSoundBuffer := nil;
   FWPCMWave.Clear;
end;

procedure TEffectSound.InitBuffer(Stream: TStream);
var
   DESC: TDSBufferDesc;
begin
   if FFileName = '' then exit;
   if Assigned (FDirectSoundBuffer) then FDirectSoundBuffer := nil;
   Fillchar (DESC, sizeof(DESC), 0);
   FWPCMWave.Clear;

   if not FWPCMWave.OpenWaveStream (Stream) then exit;

   DESC.dwSize := sizeof(DESC);
   DESC.dwFlags := DSBCAPS_CTRLDEFAULT or DSBCAPS_GETCURRENTPOSITION2 or DSBCAPS_CTRLVOLUME;
   DESC.dwBufferBytes := FWPCMWave.Size;
   DESC.lpwfxFormat := @FWPCMWave.WaveFormatEx;

   if Failed (FDirectSound.CreateSoundBuffer (DESC, FDirectSoundBuffer, nil)) then exit;

   if not Fillbuffer(Stream) then exit;
end;

function  TEffectSound.FillBuffer(aStream: TStream): Boolean;
var
   hr : HResult;
   WaveFileSize : LongInt;
   Data  : pointer;
   Data2: pointer;
   Length  : dWord;
   Length2 : dWord;
   WaveData : Pbyte;
   bufLength : integer;
begin
   Result := FALSE;
   if not Assigned (FDirectSoundBuffer) then exit;
   if FWPCMWave.Size = 0 then exit;

   WaveFileSize := FWPCMWave.Size;
   WaveData := nil;
   GetMem (WaveData, WaveFileSize);
   if not FWPCMWave.ReadWaveStream (WaveData, aStream) then begin
      if WaveData <> nil then FreeMem (WaveData);
      exit;
   end;

   hr := DS_OK;
   While TRUE do begin
      if hr = DSBSTATUS_BUFFERLOST then FDirectSoundBuffer.Restore;
      hr := FDirectSoundBuffer.Lock (0, WaveFileSize, Data, Length, Data2, Length2,0);
      if hr <> DSBSTATUS_BUFFERLOST then Break;
   end;

   if hr <> DS_OK then begin
      if WaveData <> nil then FreeMem (WaveData);
      exit;
   end;

   bufLength := 0;
   Move (WaveData^, PByte( DWord(Data)+DWord(bufLength) )^, Length);
   bufLength := bufLength + integer(Length);
   if Assigned(Data2) then begin
      Move (WaveData^, PByte( DWord(Data)+DWord(bufLength) )^, Length2);
   end;

   FDirectSoundBuffer.Unlock (Data, WaveFileSize, nil, 0);

   if WaveData <> nil then FreeMem (WaveData);
   Data := nil;
   Result := TRUE;
end;

procedure TEffectSound.SetVolume (Value: integer);
begin
   FVolume := Value;
   if Assigned(FDirectSoundBuffer) then
      FDirectSoundBuffer.SetVolume (FVolume);
end;

procedure TEffectSound.SetPan (Value: integer);
begin
   FPan := Value;
   if Assigned(FDirectSoundBuffer) then
      FDirectSoundBuffer.SetPan (FPan);
end;

procedure TEffectSound.Add (aFileName: string;Stream : TStream);
begin
   FFileName := aFileName;
   InitBuffer (Stream);
end;

procedure TEffectSound.Play (aFileName: string; aPan, aVolume: integer);
begin
   FVolume := aVolume;
   FPan := aPan;
   if (FFileName = aFilename) and Assigned(FDirectSoundBuffer) then begin
      FDirectSoundBuffer.SetVolume (FVolume);
      FDirectSoundBuffer.SetPan (FPan);
      FDirectSoundBuffer.Play (0, 0, 0);
      exit;
   end;
end;

procedure TEffectSound.Stop;
begin
   if Assigned(FDirectSoundBuffer) then
      FDirectSoundBuffer.Stop;
end;

function  TEffectSound.Playing: Boolean;
var
   status : DWORD;
begin
   Result := FALSE;
   if not Assigned(FDirectSoundBuffer) then exit;
   FDirectSoundBuffer.GetStatus(status);
   if status and DSBSTATUS_PLAYING = DSBSTATUS_PLAYING then Result := TRUE;
end;

////////////////////////////////////////////////////////////////////////////////
//                      DEffectSound
////////////////////////////////////////////////////////////////////////////////

procedure DEffectSoundInit (aHandle: integer);
begin
   EffectSoundList := TEffectSoundList.Create (aHandle);
end;

procedure DEffectSoundFinal;
begin
   EffectSoundList.Free;
end;

procedure DEffectSoundMaxBufferCount (Value: integer);
begin
   if not Assigned(EffectSoundList) then exit;
   EffectSoundList.SetMaxBufferCount (Value);
end;

procedure DEffectSoundAdd (aFileName: string; Stream : TStream);
begin
   if not Assigned(EffectSoundList) then exit;
   EffectSoundList.Add (aFileName, Stream);
end;

function  DEffectSoundPlay (aFileName: string; aPan, aVolume: integer): Boolean;
begin
   Result := False;
   if not Assigned(EffectSoundList) then exit;
   
   Result := EffectSoundList.Play (aFileName, aPan, aVolume);
end;

////////////////////////////////////////////////////////////////////////////////
//                      DBaseSound
////////////////////////////////////////////////////////////////////////////////

var
   DataList : TList;
//   UnUsedList : TList;

function  DBaseSoundCreateHandle : integer;
var DBaseSound : TDBaseSound;
begin
   {
   if UnUsedList.Count > 0 then begin
      Result := integer (UnUsedList[UnUsedList.Count-1]);
      DataList.Add (UnUsedList[UnUsedList.Count-1]);
      UnUsedList.Delete (UnUsedList.Count-1);
      exit;
   end;
   }
   DBaseSound := TDBaseSound.Create;
   DataList.Add (DBaseSound);
   Result := integer(DBaseSound);
end;

procedure DBaseSoundFreeHandle (aHandle: integer);
var
   DBaseSound : TDBaseSound;
   i : integer;
begin
   for i := DataList.Count -1 downto 0 do begin
      DBaseSound := DataList[i];
      if integer (DBaseSound) = aHandle then begin
         DBaseSound.Stop;
//         UnUsedList.Add (DBaseSound);
         DataList.Delete (i);
      end;
      exit;
   end;
end;

procedure DBaseSoundLoadFromFile (aHandle: integer; aFileName: pchar);
var i : integer;
begin
   for i := 0 to DataList.Count -1 do begin
      if integer(DataList[i]) = aHandle then begin
         TDBaseSound(DataList[i]).LoadFromFile (aFileName);
         exit;
      end;
   end;
end;

procedure DBaseSoundPlay (aHandle: integer);
var i : integer;
begin
   for i := 0 to DataList.Count -1 do begin
      if integer(DataList[i]) = aHandle then begin
         TDBaseSound(DataList[i]).Play;
         exit;
      end;
   end;
end;

procedure DBaseSoundStop (aHandle: integer);
var
   i : integer;
   DBaseSound : TDBaseSound;
begin
   for i := 0 to DataList.Count -1 do begin
      DBaseSound := DataList[i];
      if integer (DBaseSound) = aHandle then begin
         DBaseSound.Stop;
         exit;
      end;
   end;
end;

procedure DBaseSoundPause (aHandle: integer);
var i : integer;
begin
   for i := 0 to DataList.Count -1 do begin
      if integer(DataList[i]) = aHandle then begin
         TDBaseSound(DataList[i]).Pause;
         exit;
      end;
   end;
end;

procedure DBaseSoundSetVolume (aHandle, aVolume: integer);
var i : integer;
begin
   for i := 0 to DataList.Count -1 do begin
      if integer(DataList[i]) = aHandle then begin
         TDBaseSound(DataList[i]).SetVolume (aVolume);
         exit;
      end;
   end;
end;

function  DBaseSoundGetVolume (aHandle: integer): integer;
var i : integer;
begin
   Result := 0;
   for i := 0 to DataList.Count -1 do begin
      if integer(DataList[i]) = aHandle then begin
         Result := TDBaseSound(DataList[i]).Volume;
      end;
   end;
end;

procedure DBaseSoundSetBalance (aHandle, aBalance: integer);
var i : integer;
begin
   for i := 0 to DataList.Count -1 do begin
      if integer(DataList[i]) = aHandle then begin
         TDBaseSound(DataList[i]).SetBalance(aBalance);
      end;
   end;
end;

function  DBaseSoundGetBalance (aHandle: integer): integer;
var i : integer;
begin
   Result := 0;
   for i := 0 to DataList.Count -1 do begin
      if integer(DataList[i]) = aHandle then begin
         Result := TDBaseSound(DataList[i]).Balance;
      end;
   end;
end;

procedure DBaseSoundSetLoop (aHandle: integer; aLoop: Boolean);
var i : integer;
begin
   for i := 0 to DataList.Count -1 do begin
      if integer(DataList[i]) = aHandle then begin
         TDBaseSound(DataList[i]).SetLoop (aLoop);
      end;
   end;
end;

function  DBaseSoundGetPlaying (aHandle: integer): Boolean;
var i : integer;
begin
   Result := FALSE;
   for i := 0 to DataList.Count -1 do begin
      if integer(DataList[i]) = aHandle then begin
         Result := TDBaseSound(DataList[i]).playing;
      end;
   end;
end;

procedure Clear;
var
   i : integer;
begin
   for i := 0 to DataList.Count -1 do begin
      TDBaseSound(DataList[i]).Free;
   end;
   DataList.Clear;
   {
   for i := 0 to unUsedList.Count -1 do begin
      TDBaseSound(unUsedList[i]).Free;
   end;
   unUsedList.Clear;
   }
end;

initialization
begin
   DataList := TList.Create;
//   UnUsedList := TList.Create;
end;

finalization
begin
   Clear;
//   UnUsedList.Free;
   DataList.Free;
end;

end.
