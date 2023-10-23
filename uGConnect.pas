unit uGConnect;

interface

uses
   Classes, SysUtils, ScktComp, Graphics, mmSystem, uPackets, DefType;

type
   TConnectData = record
      Socket : TCustomWinSocket;
   end;
   PTConnectData = ^TConnectData;

   TGateConnector = class
   private
      Socket : TCustomWinSocket;
      
      GateNo : Integer;

      GateSender : TPacketSender;
      GateReceiver : TPacketReceiver;
   public
      constructor Create (aSocket : TCustomWinSocket; aGateNo : Integer);
      destructor Destroy; override;

      procedure Update (CurTick : Integer);

      procedure MessageProcess (aPacket : PTPacketData);

      procedure AddReceiveData (aData : PChar; aCount : Integer);
      procedure AddSendData (aConnectID : Integer; aData : PChar; aCount : Integer);

      procedure AddSendServerData (aConnectID : Integer; aMsg : Byte; aData : PChar; aCount : Integer);

      function SendBytesPerSec : Integer;
      function ReceiveBytesPerSec : Integer;
      function WBCount : Integer;
      function WriteAllow : Boolean;

      procedure SetWriteAllow (boFlag : Boolean);
   end;

   TGateConnectorList = class
   private
      DataList : TList;
      DeleteList : TList;

      function GetCount : Integer;
      function Get (aIndex : Integer) : Pointer;
   public
      constructor Create;
      destructor Destroy; override;

      procedure Clear;

      function CreateConnect (aSocket : TCustomWinSocket) : Boolean;
      function DeleteConnect (aSocket : TCustomWinSocket) : Boolean;

      procedure Update (CurTick : Integer);
      procedure AddReceiveData (aSocket : TCustomWinSocket; aData : PChar; aCount : Integer);
      procedure AddSendData (aGateNo, aConnectID : Integer; aData : PChar; aCount : Integer);
      procedure AddSendDataForAll (aData : PChar; aCount : Integer);
      procedure AddSendServerData (aGateNo, aConnectID : Integer; aMsg : Byte; aData : PChar; aCount : Integer);

      procedure SetWriteAllow (aSocket : TCustomWinSocket);

      property Count : Integer read GetCount;
      property Items [aIndex : Integer] : Pointer read Get;
   end;

var
   GateConnectorList : TGateConnectorList;

implementation

uses
   FGate, uConnect, SVMain, BasicObj;

// TGateConnector
constructor TGateConnector.Create (aSocket : TCustomWinSocket; aGateNo : Integer);
begin
   Socket := aSocket;
   GateNo := aGateNo;

   GateSender := TPacketSender.Create ('Gate', BufferSizeS2S, aSocket, false, true);
   GateReceiver := TPacketReceiver.Create ('Gate', BufferSizeS2S, false);

   // GateSender.PutPacket (GateNo, GM_UNIQUEVALUE, 0, nil, 0);
end;

destructor TGateConnector.Destroy;
begin
   GateSender.Free;
   GateReceiver.Free;

   inherited Destroy;
end;

function TGateConnector.SendBytesPerSec : Integer;
begin
   Result := GateSender.SendBytesPerSec;
end;

function TGateConnector.ReceiveBytesPerSec : Integer;
begin
   Result := GateReceiver.ReceiveBytesPerSec;
end;

function TGateConnector.WBCount : Integer;
begin
   Result := GateSender.WouldBlockCount;
end;

function TGateConnector.WriteAllow : Boolean;
begin
   Result := GateSender.WriteAllow;
end;

procedure TGateConnector.AddReceiveData (aData : PChar; aCount : Integer);
begin
   if aCount > 0 then begin
      GateReceiver.PutData (aData, aCount);
   end;
end;

procedure TGateConnector.AddSendData (aConnectID : Integer; aData : PChar; aCount : Integer);
begin
   if (aCount >= 0) and (aCount < SizeOf (TPacketData)) then begin
      GateSender.PutPacket (aConnectID, GM_SENDGAMEDATA, 0, aData, aCount);
   end;
end;

procedure TGateConnector.AddSendServerData (aConnectID : Integer; aMsg : Byte; aData : PChar; aCount : Integer);
begin
   if (aCount >= 0) and (aCount < SizeOf (TPacketData)) then begin
      GateSender.PutPacket (aConnectID, aMsg, 0, aData, aCount);
   end;
end;

procedure TGateConnector.Update (CurTick : Integer);
var
   Packet : TPacketData;
begin
   GateReceiver.Update;
   // for i := 0 to PACKET_PROCESS_COUNT - 1 do begin
   while GateReceiver.Count > 0 do begin
      if GateReceiver.GetPacket (@Packet) = false then break;
      MessageProcess (@Packet);
   end;
   GateSender.Update;
end;

procedure TGateConnector.MessageProcess (aPacket : PTPacketData);
begin
   Case aPacket^.RequestMsg of
      GM_CONNECT :
         begin
            ConnectorList.CreateConnect (GateNo, aPacket);
         end;
      GM_DISCONNECT :
         begin
            ConnectorList.DeleteConnect (GateNo, aPacket^.RequestID);
         end;
      GM_SENDUSERDATA :
         begin
            // ConnectorList.StartConnect (GateNo, aPacket^.RequestID, 
         end;
      GM_SENDGAMEDATA :
         begin
            ConnectorList.AddReceiveData (GateNo, aPacket);
         end;
      GM_UNIQUEVALUE :
         begin
            GateSender.PutPacket (GateNo, GM_UNIQUEVALUE, 0, nil, 0);
         end;
      Else
         begin
            frmMain.WriteLogInfo ('Unknown Message Received');
         end;   
   end;
end;

procedure TGateConnector.SetWriteAllow (boFlag : Boolean);
begin
   GateSender.WriteAllow := boFlag;
end;

// TGateConnectorList
constructor TGateConnectorList.Create;
begin
   DataList := TList.Create;
   DeleteList := TList.Create;
end;

destructor TGateConnectorList.Destroy;
begin
   Clear;
   DataList.Free;
   DeleteList.Free;
   inherited Destroy;
end;

function TGateConnectorList.Get (aIndex : Integer) : Pointer;
begin
   Result := nil;
   if aIndex < DataList.Count then begin
      Result := DataList.Items [aIndex];
   end;
end;

function TGateConnectorList.GetCount : Integer;
begin
   Result := DataList.Count;
end;

procedure TGateConnectorList.Clear;
var
   i : Integer;
   GateConnector : TGateConnector;
   pd : PTConnectData;
begin
   for i := 0 to DataList.Count - 1 do begin
      GateConnector := DataList.Items [i];
      GateConnector.Free;
   end;
   DataList.Clear;
   for i := 0 to DeleteList.Count - 1 do begin
      pd := DeleteList.Items [i];
      Dispose (pd);
   end;
   DeleteList.Clear;
end;

function TGateConnectorList.CreateConnect (aSocket : TCustomWinSocket) : Boolean;
var
   i, j : Integer;
   boFind : Boolean;
   GateConnector : TGateConnector;
   GateNo : Integer;
begin
   Result := false;

   GateNo := -1;
   for i := 0 to 10 - 1 do begin
      boFind := false;
      for j := 0 to DataList.Count - 1 do begin
         GateConnector := DataList.Items [j];
         if GateConnector.GateNo = i then begin
            boFind := true;
            break;
         end;
      end;
      if boFind = false then begin
         GateNo := i;
         break;
      end;
   end;

   if GateNo = -1 then exit;

   GateConnector := TGateConnector.Create (aSocket, GateNo);
   DataList.Add (GateConnector);

   Result := true;
end;

function TGateConnectorList.DeleteConnect (aSocket : TCustomWinSocket) : Boolean;
var
   pd : PTConnectData;
begin
   Result := true;

   New (pd);
   pd^.Socket := aSocket;
   DeleteList.Add (pd);
end;

procedure TGateConnectorList.AddReceiveData (aSocket :  TCustomWinSocket; aData : PChar; aCount : Integer);
var
   i : Integer;
   GateConnector : TGateConnector;
begin
   for i := 0 to DataList.Count - 1 do begin
      GateConnector := DataList.Items [i];
      if GateConnector.Socket = aSocket then begin
         GateConnector.AddReceiveData (aData, aCount);
         exit;
      end;
   end;
end;

procedure TGateConnectorList.AddSendData (aGateNo, aConnectID : Integer; aData : PChar; aCount : Integer);
var
   i : Integer;
   GateConnector : TGateConnector;
begin
   for i := 0 to DataList.Count - 1 do begin
      GateConnector := DataList.Items [i];
      if GateConnector.GateNo = aGateNo then begin
         GateConnector.AddSendData (aConnectID, aData, aCount);
         exit;
      end;
   end;
end;

procedure TGateConnectorList.AddSendServerData (aGateNo, aConnectID : Integer; aMsg : Byte; aData : PChar; aCount : Integer);
var
   i : Integer;
   GateConnector : TGateConnector;
begin
   for i := 0 to DataList.Count - 1 do begin
      GateConnector := DataList.Items [i];
      if (GateConnector.GateNo = aGateNo) then begin
         GateConnector.AddSendServerData (aConnectID, aMsg, aData, aCount);
         exit;
      end;
   end;
end;

procedure TGateConnectorList.AddSendDataForAll (aData : PChar; aCount : Integer);
var
   i : Integer;
   GateConnector : TGateConnector;
begin
   for i := 0 to DataList.Count - 1 do begin
      GateConnector := DataList.Items [i];
      GateConnector.AddSendServerData (0, GM_SENDALL, aData, aCount);
   end;
end;

procedure TGateConnectorList.Update (CurTick : Integer);
var
   i,j  : Integer;
   GateConnector : TGateConnector;
   pd : PTConnectData;
begin
   if DeleteList.Count > 0 then begin
      for i := 0 to DeleteList.Count - 1 do begin
         pd := DeleteList.Items [i];
         for j := 0 to DataList.Count - 1 do begin
            GateConnector := DataList.Items [j];
            if GateConnector.Socket = pd^.Socket then begin
               ConnectorList.CloseConnectByGateNo (GateConnector.GateNo);
               GateConnector.Free;
               DataList.Delete (j);
               break;
            end;
         end;
         Dispose (pd);
      end;
      DeleteList.Clear;
   end;

   for i := 0 to DataList.Count - 1 do begin
      GateConnector := DataList.Items [i];
      iGStartTick := timeGetTime;
      GateConnector.Update (CurTick);
      iGEndTick := timeGetTime;

      if MaxDelayGateConnectorTick < iGEndTick - iGStartTick then begin
         MaxDelayGateConnectorTick := iGEndTick - iGStartTick;
         AddLog (format ('MDGCT:%d', [MaxDelayGateConnectorTick]));
      end;
   end;
end;

procedure TGateConnectorList.SetWriteAllow (aSocket : TCustomWinSocket);
var
   i : Integer;
   GateConnector : TGateConnector;
begin
   for i := 0 to DataList.Count - 1 do begin
      GateConnector := DataList.Items [i];
      if GateConnector.Socket = aSocket then begin
         GateConnector.SetWriteAllow (true);
         exit;
      end;
   end;
end;

end.
