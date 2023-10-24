unit uSBasicConnector;

interface

uses
   Classes, SysUtils, ScktComp, uBuffer, uKeyClass, Deftype;

const
   SERVER_BUFFER_SIZE  = 1024 * 400;
   SERVER_SOCKET_BUFFER_SIZE = 1024 * 64;
   SERVER_PROCESS_BYTES = 16384;

   CLIENT_BUFFER_SIZE  = 16384;
   CLIENT_SOCKET_BUFFER_SIZE = 8192;
   CLIENT_PROCESS_BYTES = 4096;

type
   TSBasicConnector = class
   private
      FProcessBytes : Integer;
   protected
      FSocket : TCustomWinSocket;
      FSocketHandle : Integer;
      FIP : String;

      FRecvBuffer : TBuffer;
      FSendBuffer : TBuffer;

      FboServer : Boolean;
      FboWriteAllow : Boolean;
      FboDeleteAllow : Boolean;

      FInternalBuffer : array [0..SERVER_PROCESS_BYTES - 1] of Byte;

      procedure DoRead; virtual; abstract;
      procedure DoSend;
   public
      constructor Create (aSocket : TCustomWinSocket; aboServer : Boolean);
      destructor Destroy; override;

      procedure Update (CurTick : LongWord); virtual;

      function AddReceiveData (aData : PChar; aSize : Integer) : Boolean; virtual;
      function AddSendData (aData : PChar; aSize : Integer) : Boolean; virtual;

      procedure SetWriteAllow; virtual;
   end;

   TSBasicConnectorList = class
   private
      FListenSocket : TServerSocket;
      FProcessCount : Integer;
      FProcessPos : Integer;

      function GetCount : Integer;
   protected
      FDataList : TList;
      FSocketKey : TIntegerKeyClass;
      
      FboServer : Boolean;
      FProcessBytes : Integer;
      FInternalBuffer : array [0..SERVER_PROCESS_BYTES - 1] of Byte;

      procedure Clear;
   public
      constructor Create (aboServer : Boolean);
      destructor Destroy; override;

      procedure StartListen (aPort : Integer); virtual;
      procedure StopListen; virtual; 

      function AddConnector (aSocket : TCustomWinSocket) : Boolean; virtual; abstract;
      function DelConnector (aSocket : TCustomWinSocket) : Boolean; virtual; abstract;

      function AddReceiveData (aSocket : TCustomWinSocket; aData : PChar; aSize : Integer) : Boolean; virtual;
      function AddSendData (aSocket : TCustomWinSocket; aData : PChar; aSize : Integer) : Boolean; virtual;

      function SetWriteAllow (aSocket : TCustomWinSocket) : Boolean; virtual;

      procedure Update (CurTick : LongWord); virtual;

      procedure OnAccept (Sender: TObject; Socket: TCustomWinSocket); virtual;
      procedure OnClientConnect (Sender: TObject; Socket: TCustomWinSocket); virtual;
      procedure OnClientDisconnect (Sender: TObject; Socket: TCustomWinSocket); virtual;
      procedure OnClientError (Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer); virtual;
      procedure OnClientRead (Sender: TObject; Socket: TCustomWinSocket); virtual;
      procedure OnClientWrite (Sender: TObject; Socket: TCustomWinSocket); virtual;

      property Count : Integer read GetCount;
   end;

implementation

uses
   FMain;

constructor TSBasicConnector.Create (aSocket : TCustomWinSocket; aboServer : Boolean);
begin
   FboServer := aboServer;
   if FboServer = true then FProcessBytes := SERVER_PROCESS_BYTES
   else FProcessBytes := CLIENT_PROCESS_BYTES;
   
   FSocket := aSocket;
   FSocketHandle := FSocket.SocketHandle;
   FIP := FSocket.RemoteAddress;

   if FboServer = true then begin
      FRecvBuffer := TBuffer.Create (SERVER_BUFFER_SIZE);
      FSendBuffer := TBuffer.Create (SERVER_BUFFER_SIZE);
   end else begin
      FRecvBuffer := TBuffer.Create (CLIENT_BUFFER_SIZE);
      FSendBuffer := TBuffer.Create (CLIENT_BUFFER_SIZE);
   end;

   FboWriteAllow := false;
   FboDeleteAllow := false;
end;

destructor TSBasicConnector.Destroy;
begin
   FRecvBuffer.Free;
   FSendBuffer.Free;

   inherited Destroy;
end;

function TSBasicConnector.AddReceiveData (aData : PChar; aSize : Integer) : Boolean;
begin
   Result := FRecvBuffer.Put (aData, aSize);
end;

function TSBasicConnector.AddSendData (aData : PChar; aSize : Integer) : Boolean;
begin
   Result := FSendBuffer.Put (aData, aSize);
end;

procedure TSBasicConnector.DoSend;
var
   nBytes, nSend : Integer;
begin
   if FboWriteAllow = false then exit;

   try
      while FSendBuffer.Count > 0 do begin
         nSend := FSendBuffer.Count;
         if nSend > FProcessBytes then nSend := FProcessBytes;
         if FSendBuffer.View (@FInternalBuffer, nSend) = false then break;

         nBytes := FSocket.SendBuf (FInternalBuffer, nSend);
         if nBytes < 0 then nBytes := 0;
         FSendBuffer.Flush (nBytes);

         if nBytes < nSend then begin
            FboWriteAllow := false;
            break;
         end;
      end;
   except
      FboDeleteAllow := true;
      WriteLogInfo ('TSBasicConnector.DoSend failed exception');
   end;
end;

procedure TSBasicConnector.Update (CurTick : LongWord);
begin
   DoRead;
   DoSend;
end;

procedure TSBasicConnector.SetWriteAllow;
begin
   FboWriteAllow := true;
end;

// TSBasicConnectorList
constructor TSBasicConnectorList.Create (aboServer : Boolean);
begin
   FboServer := aboServer;
   if FboServer = true then FProcessBytes := SERVER_PROCESS_BYTES
   else FProcessBytes := CLIENT_PROCESS_BYTES;
   
   FListenSocket := TServerSocket.Create (nil);
   FListenSocket.OnAccept := OnAccept;
   FListenSocket.OnClientConnect := OnClientConnect;
   FListenSocket.OnClientDisconnect := OnClientDisconnect;
   FListenSocket.OnClientError := OnClientError;
   FListenSocket.OnClientRead := OnClientRead;
   FListenSocket.OnClientWrite := OnClientWrite;
   
   FDataList := TList.Create;
   FSocketKey := TIntegerKeyClass.Create;

   FProcessCount := 40;
   FProcessPos := 0;
end;

destructor TSBasicConnectorList.Destroy;
begin
   StopListen;
   
   Clear;
   FListenSocket.Free;
   FDataList.Free;
   FSocketKey.Free;

   inherited Destroy;
end;

procedure TSBasicConnectorList.Clear;
var
   i : Integer;
   SBasicConnector : TSBasicConnector;
begin
   for i := 0 to FDataList.Count - 1 do begin
      SBasicConnector := FDataList.Items [i];
      SBasicConnector.Free;
   end;
   FDataList.Clear;
   FSocketKey.Clear;
end;

function TSBasicConnectorList.GetCount : Integer;
begin
   Result := FDataList.Count;
end;

procedure TSBasicConnectorList.StartListen (aPort : Integer);
begin
   StopListen;

   FListenSocket.Port := aPort;
   FListenSocket.Active := true;
end;

procedure TSBasicConnectorList.StopListen;
begin
   FListenSocket.Active := false;
end;

function TSBasicConnectorList.AddReceiveData (aSocket : TCustomWinSocket; aData : PChar; aSize : Integer) : Boolean;
var
   SBasicConnector : TSBasicConnector;
begin
   Result := false;
   
   SBasicConnector := FSocketKey.Select (aSocket.SocketHandle);
   if SBasicConnector = nil then begin
      WriteLogInfo (format ('TSBasicConnectorList.AddReceiveData failed %d', [aSocket.SocketHandle]));
      exit;
   end;

   SBasicConnector.AddReceiveData (aData, aSize);

   Result := true;
end;

function TSBasicConnectorList.AddSendData (aSocket : TCustomWinSocket; aData : PChar; aSize : Integer) : Boolean;
var
   SBasicConnector : TSBasicConnector;
begin
   Result := false;

   SBasicConnector := FSocketKey.Select (aSocket.SocketHandle);
   if SBasicConnector = nil then begin
      WriteLogInfo (format ('TSBasicConnectorList.AddSendData failed %d', [aSocket.SocketHandle]));
      exit;
   end;

   SBasicConnector.AddSendData (aData, aSize);

   Result := true;
end;

function TSBasicConnectorList.SetWriteAllow (aSocket : TCustomWinSocket) : Boolean;
var
   SBasicConnector : TSBasicConnector;
begin
   Result := false;

   SBasicConnector := FSocketKey.Select (aSocket.SocketHandle);
   if SBasicConnector = nil then begin
      WriteLogInfo (format ('TSBasicConnectorList.SetWriteAllow failed %d', [aSocket.SocketHandle]));
      exit;
   end;

   SBasicConnector.SetWriteAllow;

   Result := true;
end;

procedure TSBasicConnectorList.OnAccept (Sender: TObject; Socket: TCustomWinSocket);
begin
   if AddConnector (Socket) = false then begin
      WriteLogInfo (format ('TSBasicConnectorList.AddConnector failed %s', [Socket.RemoteAddress]));
   end;
end;

procedure TSBasicConnectorList.OnClientConnect (Sender: TObject; Socket: TCustomWinSocket);
begin
end;

procedure TSBasicConnectorList.OnClientDisconnect (Sender: TObject; Socket: TCustomWinSocket);
begin
   if DelConnector (Socket) = false then begin
      WriteLogInfo (format ('TSBasicConnectorList.DelConnector failed %s', [Socket.RemoteAddress]));
   end;
end;

procedure TSBasicConnectorList.OnClientError (Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
begin
   if ErrorCode = 10053 then Socket.Close;
   ErrorCode := 0; 
end;

procedure TSBasicConnectorList.OnClientRead (Sender: TObject; Socket: TCustomWinSocket);
var
   nRead : Integer;
begin
   nRead := Socket.ReceiveBuf (FInternalBuffer, FProcessBytes);
   if nRead > 0 then begin
      AddReceiveData (Socket, @FInternalBuffer, nRead); 
   end;
end;

procedure TSBasicConnectorList.OnClientWrite (Sender: TObject; Socket: TCustomWinSocket);
begin
   SetWriteAllow (Socket);
end;

procedure TSBasicConnectorList.Update (CurTick : LongWord);
var
   i : Integer;
   SBasicConnector : TSBasicConnector;
begin
   if FDataList.Count >= 40 then begin
      for i := 0 to FProcessCount - 1 do begin
         if FDataList.Count = 0 then break;
         if FProcessPos >= FDataList.Count then FProcessPos := 0;

         SBasicConnector := FDataList.Items [FProcessPos];
         if SBasicConnector.FboDeleteAllow = true then begin
            FSocketKey.Delete (SBasicConnector.FSocketHandle);
            SBasicConnector.Free;
            FDataList.Delete (FProcessPos);
         end else begin
            SBasicConnector.Update (CurTick);
         end;
         Inc (FProcessPos);
      end;
   end else begin
      for i := FDataList.Count - 1 downto 0 do begin
         SBasicConnector := FDataList.Items [i];
         if SBasicConnector.FboDeleteAllow = true then begin
            FSocketKey.Delete (SBasicConnector.FSocketHandle);
            SBasicConnector.Free;
            FDataList.Delete (i);
         end else begin
            SBasicConnector.Update (CurTick);
         end;
      end;
   end;
end;

end.
