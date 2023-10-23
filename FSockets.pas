unit FSockets;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  uanstick, ScktComp, StdCtrls, adeftype, ExtCtrls, autil32, deftype, WinSock,
  NMUDP, svClass, uBuffer, uPackets;

type
  TFrmSockets = class(TForm)
    TimerProcess: TTimer;
    NMUDPForSend: TNMUDP;
    sckNotice: TClientSocket;
    timerDisplay: TTimer;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure TimerProcessTimer(Sender: TObject);
    procedure sckNoticeConnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure sckNoticeDisconnect(Sender: TObject;
      Socket: TCustomWinSocket);
    procedure sckNoticeError(Sender: TObject; Socket: TCustomWinSocket;
      ErrorEvent: TErrorEvent; var ErrorCode: Integer);
    procedure sckNoticeRead(Sender: TObject; Socket: TCustomWinSocket);
    procedure sckNoticeWrite(Sender: TObject; Socket: TCustomWinSocket);
    procedure timerDisplayTimer(Sender: TObject);
  private
  public
    function UdpSendMouseInfo (cnt: integer; pb: pbyte): Boolean;
    function UdpItemMoveInfoAddData(cnt: integer; pb: pbyte): Boolean;
    function UdpMoniterAddData (cnt: integer; pb: pbyte) :Boolean;
    function UdpConnectAddData (cnt : Integer; pb : PByte) : Boolean;
    function UdpObjectAddData (cnt : Integer; pb : PByte) : Boolean;
    function UdpRelationAddData (cnt : Integer; pb : PByte) : Boolean;
    function UdpPayAddData (cnt : Integer; pb : PByte) : Boolean;
    
    function AddDataToNotice(aData : PChar; aSize : Integer) : Boolean;

    procedure ReConnectNoticeServer (aAddress : String; aPort : Integer);
  end;

var
  FrmSockets: TFrmSockets;

  NoticeSender : TPacketSender = nil;
  NoticeReceiver : TPacketReceiver = nil;

implementation

uses
   SVMain, uConnect;

{$R *.DFM}

/////////////////////////////////////////////////
//
/////////////////////////////////////////////////

procedure TfrmSockets.ReConnectNoticeServer (aAddress : String; aPort : Integer);
begin
   if sckNotice.Socket.SocketHandle <> INVALID_SOCKET then begin
      sckNotice.Socket.Close;
   end;

   sckNotice.Address := aAddress;
   sckNotice.Port := aPort;
   sckNotice.Active := true;
end;

procedure TFrmSockets.FormCreate(Sender: TObject);
begin
   NoticeSender := TPacketSender.Create ('NoticeSender', BufferSizeS2S, nil, true, true);
   NoticeReceiver := TPacketReceiver.Create ('NoticeReceiver', BufferSizeS2S, true);

   TimerProcess.Interval := 10;
   TimerProcess.Enabled := true;

   timerDisplay.Interval := 1000 * 30;
   timerDisplay.Enabled := true;
end;

procedure TFrmSockets.FormDestroy(Sender: TObject);
begin
   if NoticeSender <> nil then begin
      NoticeSender.Free;
      NoticeSender := nil;
   end;
   if NoticeReceiver <> nil then begin
      NoticeReceiver.Free;
      NoticeReceiver := nil;
   end;
end;

procedure TFrmSockets.TimerProcessTimer(Sender: TObject);
var
   PacketData : TPacketData;
begin
   if NoticeSender <> nil then NoticeSender.Update;
   if NoticeReceiver <> nil then NoticeReceiver.Update;
   if NoticeReceiver <> nil then begin
      while NoticeReceiver.Count > 0 do begin
         if NoticeReceiver.GetPacket (@PacketData) = false then break;
         ConnectorList.ProcessNoticeServerMessage (@PacketData);
      end;
   end;
end;

function TFrmSockets.UdpSendMouseInfo (cnt: integer; pb: pbyte): Boolean;
var
   pComData : PTComData;
   Buffer : array [0..8192] of char;
begin
   try
      if (pb <> nil) and (cnt > 0) and (cnt + 4 < 8192) then begin
         pComData := @Buffer;
         pComData^.Size := cnt;
         move (pb^, pComData^.Data, cnt);

         NMUdpForSend.RemoteHost := Udp_MouseEvent_IpAddress;
         NMUdpForSend.RemotePort := Udp_MouseEvent_Port;

         NMUdpForSend.SendBuffer(Buffer, cnt + 4);
      end else begin
         FrmMain.WriteLogInfo(format('FrmSockets.pas UDPSendMouseInfo Except (Cnt : %d)', [Cnt]));
      end;
   except
      FrmMain.WriteLogInfo('FrmSockets.pas UDPSendMouseInfo Except');
   end;
   Result := TRUE;
end;


function TFrmSockets.UdpItemMoveInfoAddData (cnt: integer; pb: pbyte) :Boolean;
var
   pComData : PTComData;
   Buffer : array [0..8192] of char;
begin
   try
      pComData := @Buffer;
      pComData^.Size := cnt;
      move (pb^, pComData^.data, cnt);

      NMUdpForSend.RemoteHost := Udp_Item_IpAddress;
      NMUdpForSend.RemotePort := Udp_Item_Port;

      NMUdpForSend.SendBuffer(Buffer, cnt + 4);
   except
      FrmMain.WriteLogInfo('FrmSockets.pas UdpItemMoveInfoAddData Except');
   end;
   Result := TRUE;
end;

function TFrmSockets.UdpMoniterAddData (cnt: integer; pb: pbyte) :Boolean;
var
   pComData : PTComData;
   Buffer : array [0..8192] of char;
begin
   try
      pComData := @Buffer;
      pComData^.Size := cnt;
      move (pb^, pComData^.Data, cnt);

      NMUdpForSend.RemoteHost  := Udp_Moniter_IpAddress;
      NMUdpForSend.RemotePort  := Udp_Moniter_Port;

      NMUdpForSend.SendBuffer(Buffer, cnt + 4);
   except
      FrmMain.WriteLogInfo('FrmSockets.pas UdpMonitorAddData Except');
   end;
   Result := TRUE;
end;

function TFrmSockets.UdpConnectAddData (cnt : Integer; pb : PByte) : Boolean;
var
   pComData : PTComData;
   Buffer : array [0..8192] of char;
begin
   pComData := @Buffer;
   pComData^.Size := cnt;
   move (pb^, pComData^.data, cnt);

   NMUdpForSend.RemoteHost := Udp_Connect_IpAddress;
   NMUdpForSend.RemotePort := Udp_Connect_Port;

   NMUdpForSend.SendBuffer(Buffer, cnt + 4);

   Result := TRUE;
end;

function TFrmSockets.UdpPayAddData (cnt : Integer; pb : PByte) : Boolean;
var
   pComData : PTComData;
   Buffer : array [0..8192] of char;
begin
   pComData := @Buffer;
   pComData^.Size := cnt;
   move (pb^, pComData^.data, cnt);

   NMUdpForSend.RemoteHost := Udp_Pay_IpAddress;
   NMUdpForSend.RemotePort := Udp_Pay_Port;

   NMUdpForSend.SendBuffer(Buffer, cnt + 4);

   Result := TRUE;
end;

function TFrmSockets.UdpObjectAddData (cnt : Integer; pb : PByte) : Boolean;
var
   pComData : PTComData;
   Buffer : array [0..8192] of char;
begin
   pComData := @Buffer;
   pComData^.Size := cnt;
   move (pb^, pComData^.data, cnt);

   NMUdpForSend.RemoteHost := Udp_Object_IpAddress;
   NMUdpForSend.RemotePort := Udp_Object_Port;

   NMUdpForSend.SendBuffer(Buffer, cnt + 4);

   Result := TRUE;
end;

function TFrmSockets.UdpRelationAddData (cnt : Integer; pb : PByte) : Boolean;
var
   pComData : PTComData;
   Buffer : array [0..8192] of char;
begin
   pComData := @Buffer;
   pComData^.Size := cnt;
   move (pb^, pComData^.data, cnt);

   NMUdpForSend.RemoteHost := Udp_Relation_IpAddress;
   NMUdpForSend.RemotePort := Udp_Relation_Port;

   NMUdpForSend.SendBuffer(Buffer, cnt + 4);

   Result := TRUE;
end;

function TfrmSockets.AddDataToNotice(aData : PChar; aSize : Integer) : Boolean;
begin
   Result := false;

   if NoticeSender <> nil then begin
      NoticeSender.PutPacket (0, PACKET_GAME, 0, aData, aSize);
      Result := true;
   end;
end;

procedure TFrmSockets.sckNoticeConnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
   NoticeSender.Clear;
   NoticeReceiver.Clear;

   NoticeSender.SocketObject := Socket;
end;

procedure TFrmSockets.sckNoticeDisconnect(Sender: TObject;
  Socket: TCustomWinSocket);
begin
   NoticeSender.Clear;
   NoticeReceiver.Clear;

   NoticeSender.SocketObject := nil;
end;

procedure TFrmSockets.sckNoticeError(Sender: TObject;
  Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
  var ErrorCode: Integer);
begin
   if ErrorCode = 10053 then Socket.Close;
   if ErrorCode = 10061 then Socket.Close;

   ErrorCode := 0;
end;

procedure TFrmSockets.sckNoticeRead(Sender: TObject;
  Socket: TCustomWinSocket);
var
   nRead : Integer;
   buffer : array [0..4096 - 1] of Char;
begin
   nRead := Socket.ReceiveBuf (buffer, 4096);
   if nRead > 0 then begin
      if NoticeReceiver <> nil then begin
         NoticeReceiver.PutData (@buffer, nRead);
      end;
   end;
end;

procedure TFrmSockets.sckNoticeWrite(Sender: TObject;
  Socket: TCustomWinSocket);
begin
   if NoticeSender <> nil then begin
      NoticeSender.WriteAllow := true;
   end;
end;

procedure TFrmSockets.timerDisplayTimer(Sender: TObject);
begin
   if sckNotice.Active = false then begin
      sckNotice.Socket.Close;
      sckNotice.Active := true;
   end;
end;

end.
