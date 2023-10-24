unit uCBasicConnector;

interface

uses
   Windows, Classes, SysUtils, ScktComp, WinSock,
   uBuffer;

const
   INTERNAL_BUFFER_SIZE = 16384;

type
   TCBasicConnector = class
   private
      FboWriteAllow : Boolean;

      FSecTick : LongWord;
      FRecvBytesInSec : Integer;
      FSendBytesInSec : Integer;
      FRecvBytesPerSec : Integer;
      FSendBytesPerSec : Integer;

      function GetConnected : Boolean;
   protected
      FSocket : TClientSocket;

      FProcessBytes : Integer;
      FSocketBufferSize : Integer;
      FBufferSize : Integer;

      FSendBuffer : TBuffer;
      FRecvBuffer : TBuffer;

      FName : String;
      FAddress : String;
      FPort : Integer;

      procedure OnConnect (Sender: TObject; Socket: TCustomWinSocket); virtual;
      procedure OnDisconnect (Sender: TObject; Socket: TCustomWinSocket); virtual;
      procedure OnError (Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer); virtual;
      procedure OnRead (Sender: TObject; Socket: TCustomWinSocket); virtual;
      procedure OnWrite (Sender: TObject; Socket: TCustomWinSocket); virtual;

      procedure DoRead; virtual; abstract;
      procedure DoSend;
   public
      constructor Create (aName : String; aProcessBytes, aSocketBufferSize, aBufferSize : Integer);
      destructor Destroy; override;

      procedure Connect; overload;
      procedure Connect (aIP : String; aPort : Integer); overload;
      procedure Disconnect;

      procedure AddSendData (aData : PChar; aSize : Integer);
      procedure AddReceiveData (aData : PChar; aSize : Integer);

      procedure Update (CurTick : LongWord); virtual;

      property Connected : Boolean read GetConnected;
      
      property RecvBytesPerSec : Integer read FRecvBytesPerSec;
      property SendBytesPerSec : Integer read FSendBytesPerSec;
   end;

implementation

uses
   FMain;

constructor TCBasicConnector.Create (aName : String; aProcessBytes, aSocketBufferSize, aBufferSize : Integer);
begin
   FName := aName;
   FAddress := '';
   FPort := 0;

   FProcessBytes := aProcessBytes;
   if FProcessBytes > INTERNAL_BUFFER_SIZE then
      FProcessBytes := INTERNAL_BUFFER_SIZE;
      
   FSocketBufferSize := aSocketBufferSize;
   FBufferSize := aBufferSize;

   FSocket := TClientSocket.Create (nil);
   FSocket.ClientType := ctNonBlocking;
   FSocket.OnConnect := OnConnect;
   FSocket.OnDisconnect := OnDisconnect;
   FSocket.OnError := OnError;
   FSocket.OnRead := OnRead;
   FSocket.OnWrite := OnWrite;

   FSendBuffer := TBuffer.Create (FBufferSize);
   FRecvBuffer := TBuffer.Create (FBufferSize);

   FboWriteAllow := false;

   FSecTick := 0;
   FRecvBytesInSec := 0;
   FSendBytesInSec := 0;
   FRecvBytesPerSec := 0;
   FSendBytesPerSec := 0;
end;

destructor TCBasicConnector.Destroy;
begin
   if FSocket.Active = true then begin
      FSocket.Close;
   end;
   FRecvBuffer.Free;
   FSendBuffer.Free;
   FSocket.Free;

   inherited Destroy;
end;

function TCBasicConnector.GetConnected : Boolean;
begin
   Result := FSocket.Active;
end;

procedure TCBasicConnector.DoSend;
var
   nBytes, nSend : Integer;
   buffer : array [0..INTERNAL_BUFFER_SIZE - 1] of Byte;
begin
   if FboWriteAllow = false then exit;
   
   while FSendBuffer.Count > 0 do begin
      nBytes := FSendBuffer.Count;
      if nBytes > FProcessBytes then nBytes := FProcessBytes;
      if FSendBuffer.View (@buffer, nBytes) = false then break;

      nSend := FSocket.Socket.SendBuf (buffer, nBytes);
      if nSend < 0 then nSend := 0;
      FSendBuffer.Flush (nSend);
      Inc (FSendBytesInSec, nSend);

      if nSend < nBytes then begin
         FboWriteAllow := false;
         break;
      end;
   end;
end;

procedure TCBasicConnector.OnConnect (Sender: TObject; Socket: TCustomWinSocket);
var
   Size, OptLen : Integer;
begin
   FSendBuffer.Clear;
   FRecvBuffer.Clear;
   
   FboWriteAllow := false;
   FSecTick := 0;
   FRecvBytesInSec := 0;
   FSendBytesInSec := 0;
   FRecvBytesPerSec := 0;
   FSendBytesPerSec := 0;

   Size := FSocketBufferSize;
   OptLen := SizeOf (Integer);
   SetSockOpt (Socket.SocketHandle, SOL_SOCKET, SO_RCVBUF, @Size, OptLen);
   SetSockOpt (Socket.SocketHandle, SOL_SOCKET, SO_SNDBUF, @Size, OptLen);
end;

procedure TCBasicConnector.OnDisconnect (Sender: TObject; Socket: TCustomWinSocket);
begin
   FSendBuffer.Clear;
   FRecvBuffer.Clear;
   
   FboWriteAllow := false;
   FSecTick := 0;
   FRecvBytesInSec := 0;
   FSendBytesInSec := 0;
   FRecvBytesPerSec := 0;
   FSendBytesPerSec := 0;
end;

procedure TCBasicConnector.OnError (Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
begin
   if (ErrorCode = 10053) or (ErrorCode = 10061) then Socket.Close;
   ErrorCode := 0;
end;

procedure TCBasicConnector.OnRead (Sender: TObject; Socket: TCustomWinSocket);
var
   nRead : Integer;
   buffer : array [0..INTERNAL_BUFFER_SIZE - 1] of Byte;
begin
   nRead := Socket.ReceiveBuf (buffer, FProcessBytes);
   if nRead > 0 then begin
      Inc (FRecvBytesInSec, nRead);
      AddReceiveData (@buffer, nRead);
   end;
end;

procedure TCBasicConnector.OnWrite (Sender: TObject; Socket: TCustomWinSocket);
begin
   FboWriteAllow := true;
end;

procedure TCBasicConnector.Connect;
begin
   Disconnect;

   FSocket.Address := FAddress;
   FSocket.Port := FPort;
   FSocket.Active := true;
end;

procedure TCBasicConnector.Connect (aIP : String; aPort : Integer);
begin
   Disconnect;

   FAddress := aIP;
   FPort := aPort;
   FSocket.Address := FAddress;
   FSocket.Port := FPort;
   FSocket.Active := true;
end;

procedure TCBasicConnector.Disconnect;
begin
   if FSocket.Socket.SocketHandle <> INVALID_SOCKET then FSocket.Close;
end;

procedure TCBasicConnector.AddReceiveData (aData : PChar; aSize : Integer);
begin
   FRecvBuffer.Put (aData, aSize);
end;

procedure TCBasicConnector.AddSendData (aData : PChar; aSize : Integer);
begin
   FSendBuffer.Put (aData, aSize);
end;

procedure TCBasicConnector.Update (CurTick : LongWord);
begin
   DoRead;
   DoSend;

   if CurTick >= FSecTick + 1000 then begin
      FRecvBytesPerSec := FRecvBytesInSec;
      FSendBytesPerSec := FSendBytesInSec;
      FRecvBytesInSec := 0;
      FSendBytesInSec := 0;

      FSecTick := CurTick;
   end;
end;

end.
