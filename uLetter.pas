unit uLetter;

interface

uses
   Classes, SysUtils, DefType, AUtil32;

type
   // 쪽지 데이타 구조체
   TLetterData = record
      rDate : TDateTime;
      rTime : TDateTime;
      rSender : TNameString;
      rReceiver : TNameString;
      rSayString : TWordString;
   end;
   PTLetterData = ^TLetterData;

   // 쪽지 전달 기능의 클래스 선언
   TLetterManager = class
      private
      FileName : String;
      LetterList : TList;     // PTLetterData 의 리스트

      SavePeriod : Word;      // 쪽지의 최대 보관 날짜
      SaveLimitCount : Word;  // 쪽지의 최대 보관 건수

      boChanged : Boolean;

      function GetLetterCount : Integer;

      public
      constructor Create (aSavePeriod, aSaveLimitCount : Word; aFileName : String);
      destructor  Destroy; override;

      procedure   Clear;

      function    AddLetter (aSender, aReceiver, aSayString : String) : Boolean;
      function    CheckLetter (aName : String; pList : TList) : Boolean;
      procedure   Update;

      procedure   LoadFromFile (aFileName : String);
      function    SaveToFile (aFileName : String) : Boolean;

      property    LimitCount : Word read SaveLimitCount;
      property    LetterCount : Integer read GetLetterCount;
   end;

   // LetterDataCompare : TListSortCompare;

var
   LetterManager : TLetterManager;

implementation

function LetterDataCompare (Item1, Item2: Pointer): Integer;
var
   pd1, pd2 : PTLetterData;
   n : Integer;
begin
   pd1 := Item1;
   pd2 := Item2;
   if (pd1 = nil) and (pd2 = nil) then begin Result := 0; exit; end;
   if pd1 = nil then begin Result := 1; exit; end;
   if pd2 = nil then begin Result := -1; exit; end;

   n := CompareStr (StrPas(@pd1^.rReceiver), StrPas(@pd2^.rReceiver));
   if n = 0 then begin
      if pd1^.rDate = pd2^.rDate then begin
         if pd1^.rDate = pd2^.rDate then begin
            n := 0;
         end else if pd1^.rDate > pd2^.rDate then begin
            n := 1;
         end else begin
            n := -1;
         end;
      end else if pd1^.rDate > pd2^.rDate then begin
         n := 1;
      end else begin
         n := -1;
      end;
   end;

   Result := n;
end;

constructor TLetterManager.Create (aSavePeriod, aSaveLimitCount : Word; aFileName : String);
begin
   LetterList := TList.Create;

   SavePeriod := aSavePeriod;
   SaveLimitCount := aSaveLimitCount;
   FileName := aFileName;

   LoadFromFile (aFileName);
end;

destructor  TLetterManager.Destroy;
begin
   SaveToFile(FileName);
   
   Clear;
   
   LetterList.Free;
end;

procedure TLetterManager.Clear;
var
   i : Integer;
   pd : PTLetterData;
begin
   for i := 0 to LetterList.Count - 1 do begin
      pd := LetterList.Items[i];
      if pd <> nil then Dispose(pd);
   end;
   LetterList.Clear;
end;

function TLetterManager.GetLetterCount : Integer;
begin
   Result := LetterList.Count;
end;

function    TLetterManager.AddLetter (aSender, aReceiver, aSayString : String) : Boolean;
var
   pd : PTLetterData;
begin
   Result := false;

   if LetterList.Count = SaveLimitCount then exit;
   
   New(pd);
   if pd = nil then Exit;
   pd^.rDate := Date;
   pd^.rTime := Time;
   StrPCopy(@pd^.rSender, aSender);
   StrPCopy(@pd^.rReceiver, aReceiver);
   StrPCopy(@pd^.rSayString, aSayString);

   LetterList.Add (pd);

   boChanged := true;

   Result := true;
end;

function    TLetterManager.CheckLetter (aName : String; pList : TList) : Boolean;
var
   i : Integer;
   pd, pdd : PTLetterData;
   StartPos : Integer;
begin
   Result := false;

   if pList = nil then exit;

   if boChanged = true then begin
      LetterList.Sort (LetterDataCompare);
      boChanged := false;
   end;

   StartPos := -1;
   for i := LetterList.Count - 1 downto 0 do begin
      pd := LetterList.Items[i];
      if pd = nil then continue;
      if StrPas(@pd^.rReceiver) = aName then begin
         StartPos := i;
         break;
      end;
   end;

   for i := StartPos downto 0 do begin
      pd := LetterList.Items[i];
      if pd = nil then continue;
      if StrPas(@pd^.rReceiver) = aName then begin
         New (pdd);
         Move (pd^, pdd^, SizeOf(TLetterData));
         pList.Add (pdd);

         Dispose(pd);
         LetterList.Delete(i);
         Result := true;
      end else break;
   end;
end;

procedure   TLetterManager.Update;
var
   i : Integer;
   pd : PTLetterData;
begin
   for i := LetterList.Count - 1 downto 0 do begin
      pd := LetterList.Items[i];
      if pd = nil then continue;
      if pd^.rDate + SavePeriod < Date then begin
         Dispose (pd);
         LetterList.Delete (i);
      end;
   end;
end;

procedure   TLetterManager.LoadFromFile (aFileName : String);
var
   i : Integer;
   tmpStr, TokenStr : String;
   StrList : TStringList;
   pd : PTLetterData;
   nYear, nMonth, nDay, nHour, nMin, nSec, nMSec : Word;
   Sender, Receiver, Letter : String;
begin
   nMSec := 0;
   pd := nil;
   StrList := nil;

   Clear;
   
   try
      if FileExists (aFileName) = false then exit;

      StrList := TStringList.Create;
      StrList.LoadFromFile (aFileName);
      for i := 1 to StrList.Count - 1 do begin
         tmpStr := StrList.Strings[i];
         if tmpStr = '' then continue;

         tmpStr := GetValidStr3(tmpStr, TokenStr, ',');
         if TokenStr = '' then continue;
         nYear := StrToInt(TokenStr);
         tmpStr := GetValidStr3(tmpStr, TokenStr, ',');
         if TokenStr = '' then continue;
         nMonth := StrToInt(TokenStr);
         tmpStr := GetValidStr3(tmpStr, TokenStr, ',');
         if TokenStr = '' then continue;
         nDay := StrToInt(TokenStr);
         tmpStr := GetValidStr3(tmpStr, TokenStr, ',');
         if TokenStr = '' then continue;
         nHour := StrToInt(TokenStr);
         tmpStr := GetValidStr3(tmpStr, TokenStr, ',');
         if TokenStr = '' then continue;
         nMin := StrToInt(TokenStr);
         tmpStr := GetValidStr3(tmpStr, TokenStr, ',');
         if TokenStr = '' then continue;
         nSec := StrToInt(TokenStr);

         tmpStr := GetValidStr3(tmpStr, Sender, ',');
         if Sender = '' then continue;
         tmpStr := GetValidStr3(tmpStr, Receiver, ',');
         if Receiver = '' then continue;
         Letter := tmpStr;

         New(pd);
         pd^.rDate := EncodeDate (nYear, nMonth, nDay);
         pd^.rTime := EncodeTime (nHour, nMin, nSec, nMSec);

         StrPCopy(@pd^.rSender, Sender);
         StrPCopy(@pd^.rReceiver, Receiver);
         StrPCopy(@pd^.rSayString, Letter);

         LetterList.Add(pd);
      end;
   except
      if StrList <> nil then begin
         StrList.Clear;
         StrList.Free;
      end;
      if pd <> nil then Dispose(pd);
   end;

   LetterList.Sort (LetterDataCompare);
   boChanged := false;
end;

function    TLetterManager.SaveToFile (aFileName : String) : Boolean;
var
   i : Integer;
   tmpStr : String;
   szBuffer : array[0..5000] of Byte;
   Stream : TFileStream;
   pd : PTLetterData;
   nYear, nMonth, nDay, nHour, nMin, nSec, nMSec : Word;
begin
   Result := false;

   if FileExists (aFileName) then DeleteFile (aFileName);
   if LetterList.Count = 0 then exit;
   
   try
      Stream := TFileStream.Create (aFileName, fmCreate);

      tmpStr := 'YEAR,MONTH,DAY,HOUR,MIN,SEC,SENDER,RECEIVER,SAYSTRING' + #13#10;
      StrPCopy(@szBuffer, tmpStr);
      Stream.WriteBuffer (szBuffer, StrLen(@szBuffer));
      for i := 0 to LetterList.Count - 1 do begin
         pd := LetterList.Items[i];
         if pd = nil then continue;
         DecodeDate (pd^.rDate, nYear, nMonth, nDay);
         DecodeTime (pd^.rTime, nHour, nMin, nSec, nMSec);
         tmpStr := Format('%d,%d,%d,%d,%d,%d,%s,%s,%s', [nYear, nMonth, nDay, nHour, nMin, nSec,
            StrPas(@pd^.rSender), StrPas(@pd^.rReceiver), StrPas(@pd^.rSayString)]) + #13#10;
         StrPCopy(@szBuffer, tmpStr);
         Stream.WriteBuffer (szBuffer, StrLen(@szBuffer));
      end;
      
      Stream.Destroy;
   except
   end;

   Result := true;
end;

end.
