unit uPackets;

interface

uses
   SysUtils, Classes, ScktComp, WinSock, mmSystem, uBuffer;

const
   SocketProcessBytes   = 1024 * 8;
   SocketBufferBytes    = 1024 * 64;
   MAX_PACKET_SIZE      = 8192;

   PACKET_START         =  $28;
   PACKET_END           =  $29;

   PROCESS_BYTES        = 1024 * 16;

type

   TPacketData = record
      PacketSize : Word;
      RequestID : Integer;
      RequestMsg : Byte;
      ResultCode : Byte;
      Data : array[0..MAX_PACKET_SIZE - 1] of byte;
   end;
   PTPacketData = ^TPacketData;

   TPacketSender = class
   private
      Name : String;
      Socket : TCustomWinSocket;

      FboUseCrypt : Boolean;
      FboServer : Boolean;
      
      SendBuffer : TBuffer;
      boWriteAllow : Boolean;

      FWouldBlockCount : Integer;

      FSendTick : LongWord;
      FSendBytes : Integer;
      FSendBytesPerSec : Integer;

      boBufferFullLog : Boolean;

      function isDataRemained : Boolean;
      procedure SetWriteAllow (boFlag : Boolean);
      procedure SetSocket (aSocket : TCustomWinSocket);
   public
      LocalBuffer : array [0..PROCESS_BYTES - 1] of Char;

      constructor Create (aName : String; aSize : Integer; aSocket : TCustomWinSocket; aboUseCrypt, aboServer : Boolean);
      destructor Destroy; override;

      procedure Clear;

      procedure Update;

      function PutPacket (aID : Integer; aMsg, aRetCode : Byte; aData : PChar; aSize : Integer) : Boolean;

      procedure WriteLog (aStr : String);

      property SocketObject : TCustomWinSocket read Socket write SetSocket;
      property WriteAllow : Boolean read boWriteAllow write SetWriteAllow;
      property SendBytesPerSec : Integer read FSendBytesPerSec;
      property WouldBlockCount : Integer read FWouldBlockCount;
      property DataRemained : Boolean read isDataRemained;
   end;

   TPacketReceiver = class
   private
      Name : String;

      FboUseCrypt : Boolean;

      FReceiveBytes : Integer;
      FReceiveBytesPerSec : Integer;
      FReceiveTick : LongWord;

      ReceiveBuffer : TBuffer;

      PacketBuffer : TPacketBuffer;

      boBufferFullLog : Boolean;

      function GetCount : Integer;
   public
      LocalBuffer : array [0..PROCESS_BYTES - 1] of Char;

      constructor Create (aName : String; aBufferSize : Integer; aboUseCrypt : Boolean);
      destructor Destroy; override;

      procedure Clear;

      procedure Update;

      function PutData (aData : PChar; aSize : Integer) : Boolean;
      function GetPacket (aPacket : PTPacketData) : Boolean;

      procedure WriteLog (aStr : String);

      property Count : Integer read GetCount;
      property ReceiveBytesPerSec : Integer read FReceiveBytesPerSec;
   end;

implementation

uses
   uCrypt;

// TPacketSender
constructor TPacketSender.Create (aName : String; aSize : Integer; aSocket : TCustomWinSocket; aboUseCrypt, aboServer : Boolean);
var
   Size : Integer;
begin
   Name := aName;

   FboUseCrypt := aboUseCrypt;
   FboServer := aboServer;
   
   FSendBytes := 0;
   FSendBytesPerSec := 0;
   FSendTick := 0;

   FWouldBlockCount := 0;

   Socket := nil;
   SetSocket (aSocket);

   boWriteAllow := false;

   Size := aSize;
   if Size <= 0 then Size := 16384;
   SendBuffer := TBuffer.Create (Size);

   boBufferFullLog := false;
end;

destructor TPacketSender.Destroy;
begin
   SendBuffer.Free;
   inherited Destroy;
end;

procedure TPacketSender.Clear;
begin
   SendBuffer.Clear;
end;

function TPacketSender.isDataRemained : Boolean;
begin
   Result := false;
   if (Socket <> nil) and (SendBuffer.Count > 0) then Result := true;
end;

procedure TPacketSender.SetWriteAllow (boFlag : Boolean);
begin
   boWriteAllow := boFlag;
end;

procedure TPacketSender.SetSocket (aSocket : TCustomWinSocket);
var
   Size, OptLen : Integer;
begin
   Socket := aSocket;
   if Socket = nil then exit;

   if FboServer = true then begin
      Size := SocketBufferBytes;
      OptLen := SizeOf (Integer);
      SetSockOpt (Socket.SocketHandle, SOL_SOCKET, SO_RCVBUF, @Size, OptLen);
      SetSockOpt (Socket.SocketHandle, SOL_SOCKET, SO_SNDBUF, @Size, OptLen);
   end;
end;

procedure TPacketSender.Update;
var
   CurTick : LongWord;
   nSendSize, nSize, nWrite : Integer;
begin
   CurTick := timeGetTime;

   if (boWriteAllow = true) and (SendBuffer.Count > 0) and (Socket <> nil) then begin
      nSize := SendBuffer.Count;
      while nSize > 0 do begin
         nSendSize := nSize;
         if nSendSize > PROCESS_BYTES then nSendSize := PROCESS_BYTES;
         if SendBuffer.View (@LocalBuffer, nSendSize) = false then exit;

         nWrite := Socket.SendBuf (LocalBuffer, nSendSize);
         if nWrite < 0 then nWrite := 0;

         if nWrite > 0 then begin
            SendBuffer.Flush (nWrite);
            FSendBytes := FSendBytes + nWrite;
         end;

         if nWrite < nSendSize then begin
            FWouldBlockCount := FWouldBlockCount + 1;
            boWriteAllow := false;
            break;
         end;
         nSize := nSize - nWrite;
      end;
   end;

   if CurTick >= FSendTick + 1000 then begin
      FSendBytesPerSec := FSendBytes div 1024;
      FSendBytes := 0;
      FSendTick := CurTick;
   end;
end;

function TPacketSender.PutPacket (aID : Integer; aMsg, aRetCode : Byte; aData : PChar; aSize : Integer) : Boolean;
var
   nSize : Word;
   Packet : TPacketData;
   buffer : array [0..8192 - 1] of Byte;
begin
   Result := false;

   if (aSize < 0) or (aSize > MAX_PACKET_SIZE) then exit;

   Packet.PacketSize := SizeOf (Word) + SizeOf (Integer) + SizeOf (Byte) * 2 + aSize;
   Packet.RequestID := aID;
   Packet.RequestMsg := aMsg;
   Packet.ResultCode := aRetCode;
   if aSize > 0 then begin
      Move (aData^, Packet.Data, aSize);
   end;

   nSize := 0;
   if FboUseCrypt = true then begin
      buffer[0] := PACKET_START;
      nSize := EnCryption (@Packet, @buffer[1], Packet.PacketSize);
      buffer[nSize + 1] := PACKET_END;
      buffer[nSize + 2] := 0;
      if SendBuffer.Put (@buffer, nSize + 2) = true then begin
         Result := true;
         exit;
      end;
   end else begin
      if SendBuffer.Put (@Packet, Packet.PacketSize) = true then begin
         Result := true;
         exit;
      end;
   end;

   WriteLog (format ('%sSendBuffer.Put failed BufferSize=%d, InputSize=%d', [Name, SendBuffer.Count, nSize + 2]));
end;

procedure TPacketSender.WriteLog (aStr : String);
var
   Stream : TFileStream;
   FileName : String;
   buffer : array[0..8192 - 1] of byte;
begin
   exit;
   
   try
      FileName := '.\Log\' + Name + 'Sender.Log';
      if FileExists (FileName) then exit;

      Stream := TFileStream.Create (FileName, fmCreate);
      StrPCopy (@buffer, '[' + DateToStr (Date) + ' ' + TimeToStr (Time) + ']' + aStr + #13 + #10);
      Stream.Seek (0, soFromEnd);
      Stream.WriteBuffer (buffer, StrLen (@buffer));
      Stream.Free;
   except
   end;
end;

// TPacketReceiver
constructor TPacketReceiver.Create (aName : String; aBufferSize : Integer; aboUseCrypt : Boolean);
var
   Size : Integer;
begin
   Name := aName;

   FboUseCrypt := aboUseCrypt;
   FReceiveBytes := 0;
   FReceiveBytesPerSec := 0;
   FReceiveTick := 0;

   Size := aBufferSize;
   if Size <= 0 then Size := 16384;
   ReceiveBuffer := TBuffer.Create (Size);
   PacketBuffer := TPacketBuffer.Create (Size);

   boBufferFullLog := false;
end;

destructor TPacketReceiver.Destroy;
begin
   Clear;
   PacketBuffer.Free;
   ReceiveBuffer.Free;

   inherited Destroy;
end;

procedure TPacketReceiver.Clear;
begin
   PacketBuffer.Clear;
   ReceiveBuffer.Clear;
end;

function TPacketReceiver.GetCount : Integer;
begin
   Result := PacketBuffer.Count;
end;

procedure TPacketReceiver.Update;
var
   i, iBase, iPos, iStartPos, iEndPos, nSize : Integer;
   CurTick : LongWord;
   buffer : array [0..8192 - 1] of Byte;
   Packet : TPacketData;
begin
   CurTick := timeGetTime;

   if FboUseCrypt = true then begin
      try
         while ReceiveBuffer.Count > 0 do begin
            nSize := ReceiveBuffer.Count;
            if nSize > 8192 then nSize := 8192;

            if ReceiveBuffer.View (@buffer, nSize) = false then break;

            iPos := 0;
            while iPos < nSize do begin
               iStartPos := -1;
               iBase := iPos;
               for i := iBase to nSize - 1 do begin
                  Inc (iPos);
                  if buffer [i] = PACKET_START then begin
                     iStartPos := i + 1;
                     break;
                  end;
               end;
               if iStartPos = -1 then begin
                  // WriteLog ('Wrong Packet : StartCode not found');
                  ReceiveBuffer.Flush (iPos);
                  exit;
               end;

               iEndPos := -1;
               iBase := iPos;
               for i := iBase to nSize - 1 do begin
                  Inc (iPos);
                  if buffer[i] = PACKET_START then begin
                     // WriteLog ('Wrong Packet : PACKET_START Detected');
                     Dec (iPos);
                     ReceiveBuffer.Flush (iPos);
                     exit;
                  end else if buffer[i] = PACKET_END then begin
                     iEndPos := i - 1;
                     break;
                  end;
               end;
               if iEndPos = -1 then begin
                  iPos := iBase - 1;
                  if iPos = 0 then exit;
                  break;
               end;

               if iEndPos - iStartPos + 1 > 0 then begin
                  DeCryption (@buffer[iStartPos], @Packet, iEndPos - iStartPos + 1);
                  if (Packet.PacketSize > 0) and (Packet.PacketSize <= SizeOf (TPacketData)) then begin
                     PacketBuffer.Put (@Packet, Packet.PacketSize);
                  end;
               end;
            end;
            ReceiveBuffer.Flush (iPos);
         end;
      except
         // WriteLogInfo (format ('PacketReceiver.Update () Exception %d', [iCount]));
      end;
   end else begin
      while ReceiveBuffer.Count > SizeOf (Word) do begin
         if ReceiveBuffer.View (@Packet.PacketSize, SizeOf (Word)) = false then break;
         if ReceiveBuffer.Count < Packet.PacketSize then break;
         if ReceiveBuffer.Get (@Packet, Packet.PacketSize) = false then break;
         if (Packet.PacketSize > 0) and (Packet.PacketSize <= SizeOf (TPacketData)) then begin
            PacketBuffer.Put (@Packet, Packet.PacketSize);
         end;
      end;
   end;

   if CurTick >= FReceiveTick + 1000 then begin
      FReceiveBytesPerSec := FReceiveBytes div 1024;
      FReceiveBytes := 0;
      FReceiveTick := CurTick;
   end;
end;

function TPacketReceiver.PutData (aData : PChar; aSize : Integer) : Boolean;
begin
   Result := false;

   FReceiveBytes := FReceiveBytes + aSize;

   if aSize <= 0 then exit;

   if ReceiveBuffer.Put (aData, aSize) = true then begin
      Result := true;
      exit;
   end;

   WriteLog (format ('%sReceiveBuffer.Put failed BufferSize=%d, InputSize=%d', [Name, ReceiveBuffer.Count, aSize]));
end;

function TPacketReceiver.GetPacket (aPacket : PTPacketData) : Boolean;
begin
   Result := PacketBuffer.Get (PChar (aPacket));
end;

procedure TPacketReceiver.WriteLog (aStr : String);
var
   Stream : TFileStream;
   FileName : String;
   buffer : array[0..8192 - 1] of byte;
begin
   exit;
   
   try
      FileName := '.\Log\' + Name + 'Receiver.Log';
      if FileExists (FileName) then exit;

      Stream := TFileStream.Create (FileName, fmCreate);
      StrPCopy (@buffer, '[' + DateToStr (Date) + ' ' + TimeToStr (Time) + ']' + aStr + #13 + #10);
      Stream.Seek (0, soFromEnd);
      Stream.WriteBuffer (buffer, StrLen (@buffer));
      Stream.Free;
   except
   end;
end;

end.
