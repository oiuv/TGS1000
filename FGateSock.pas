unit FGateSock;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  ScktComp, adeftype, barutil, WinSock;

const
   WRITEALLOW_FALSE = 0;
   WRITEALLOW_TRUE  = 1;

type
  TSSData = record
    rSocket : TCustomWinSocket;
    rMySocketsBigBufferClass : TBigBufferClass;
    rMyServersBigBufferClass : TBigBufferClass;
    rWBlock : TComData;
    rWriteAllow: integer;
    rAddress: string[32];
    rBoConnected : Boolean;
  end;
  PTSSData = ^TSSData;

  TFrmGateSock = class(TForm)
    ServerSocket1: TServerSocket;
    procedure ServerSocket1ClientDisconnect(Sender: TObject; Socket: TCustomWinSocket);
    procedure ServerSocket1ClientError(Sender: TObject; Socket: TCustomWinSocket; ErrorEvent: TErrorEvent; var ErrorCode: Integer);
    procedure ServerSocket1ClientRead(Sender: TObject; Socket: TCustomWinSocket);
    procedure ServerSocket1ClientWrite(Sender: TObject; Socket: TCustomWinSocket);
    procedure ServerSocket1Accept(Sender: TObject; Socket: TCustomWinSocket);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    { Private declarations }
    // procedure MessageProcess(atype, aGateNo, aConid: integer; var Code: TComData);
    procedure MessageProcess(atype, aConid: integer; var Code: TComData);
  public
    { Public declarations }
    function  SendProcess: Boolean;
    procedure ReceiveProcess;
  end;
{
      function GetSSDataIndex (aConId: integer): integer;
      function GetSocketsComdata (var atype, aConId: integer; var Code: TComData): Boolean;
      function AddServersComdata (atype, aConId: integer; var Code: TComData): Boolean;
      function AddMessage2 (atype, aConId, amsg, aInt: integer; astr16: string): Boolean;
}
      function GetSSDataIndex (aConId: integer): integer;
      function GetSocketsComdata (var atype, aConId: integer; var Code: TComData): Boolean;
      function AddServersComdata (atype, aConId: integer; var Code: TComData): Boolean;
      // function AddMessage2 (atype, aGateNo, aConId, amsg, aInt: integer; astr16: string): Boolean;

var
  FrmGateSock: TFrmGateSock;

  GateSocketMaxValue : Integer = 0;

  SSDataArr : array [0..4-1] of TSSData;

implementation

uses SVMain, uConnect;

{$R *.DFM}
const
    CONID_MUL = 1000000;

procedure TFrmGateSock.FormCreate(Sender: TObject);
var
   i: integer;
begin
   ServerSocket1.Port := FrmMain.ServerIni.ReadInteger ('GATEWAY', 'PORT', 2999);
   ServerSocket1.Active := TRUE;
   for i := 0 to 4-1 do begin
      FillChar (SSDataArr[i], sizeof(TSSData), 0);
      SSDataArr[i].rMySocketsBigBufferClass := TBigBufferClass.Create ('MySocketsBigBufferClass');
      SSDataArr[i].rMyServersBigBufferClass := TBigBufferClass.Create ('MyServersBigBufferClass');
      SSDataArr[i].rAddress := FrmMain.ServerIni.ReadString ('GATEWAY', 'ADDRESS'+IntToStr(i), '');
      SSDataArr[i].rBoConnected := FALSE;
   end;

end;

procedure TFrmGateSock.FormDestroy(Sender: TObject);
var i: integer;
begin
   for i := 0 to 4-1 do begin
      SSDataArr[i].rMySocketsBigBufferClass.Free;
      SSDataArr[i].rMyServersBigBufferClass.Free;
   end;
end;

function GetSSDataIndex (aConId: integer): integer;
begin
   Result := aConid div CONID_MUL;
end;

function AddMessage2 (atype, aGateNo, aConId, amsg, aInt: integer; astr16: string): Boolean;
var
   idx : integer;
   TempCode : TComData;
   psd : PTSocketData;
   pmd : PTMessageData2;
begin
   idx := GetSSDataIndex (aConid);

   psd := @TempCode.Data;
   psd^.rtype := atype;
   psd^.rConid := aConid - idx*CONID_MUL;
   // psd^.rConid := aConid;
   psd^.rDataSize := sizeof(TMessageData2);

   pmd := @TempCode.Data[sizeof(TSocketData)];
   pmd^.rmsg := amsg;
   // pmd^.rConid := aConid - idx*CONID_MUL;
   pmd^.rConid := aConid;
   pmd^.rInteger := aInt;
   pmd^.rString16 := astr16;

   TempCode.cnt := sizeof (TSocketData) + sizeof(TMessageData2);

   SSDataArr[idx].rMyServersBigBufferClass.Add (TempCode.cnt+4, @TempCode);

   Result := TRUE;

   if SSDataArr[idx].rSocket = nil then Result := FALSE;
end;

function GetSocketsComdata (var atype, aConId: integer; var Code: TComData): Boolean;
var
   i : integer;
   psd : PTSocketData;
   TempCode: TComData;
begin
   Result := FALSE;

   for i := 0 to 4-1 do begin
      if SSDataArr[i].rMySocketsBigBufferClass.Count < 4 then continue;
      if SSDataArr[i].rMySocketsBigBufferClass.View (4, @TempCode.cnt) <> 4 then exit;
      if SSDataArr[i].rMySocketsBigBufferClass.Count < TempCode.cnt + 4 then exit;
      SSDataArr[i].rMySocketsBigBufferClass.Get (TempCode.cnt+4, @TempCode);
      Psd := @TempCode.Data;
      atype := psd^.rtype;
      // aGateNo := i;
      // aConid := psd^.rConid + i * CONID_MUL;
      aConid := psd^.rConid;
      move (TempCode.Data[sizeof(TSocketData)], Code.Data, psd^.rDataSize);
      Code.cnt := psd^.rDataSize;
      Result := TRUE;
      exit;
   end;
end;

function AddServersComdata (atype, aConId: integer; var Code: TComData): Boolean;
var
   idx : integer;
   TempCode : TComData;
   psd : PTSocketData;
begin
   idx := GetSSDataIndex (aConid);

   psd := @TempCode.Data;
   psd^.rtype := atype;
   psd^.rConid := aConid - idx * CONID_MUL;
   // psd^.rConid := aConid;
   psd^.rDataSize := Code.cnt;
   TempCode.cnt := sizeof (TSocketData) + Code.cnt;
   move (Code.data, TempCode.Data[Sizeof(TSocketData)], Code.Cnt);
   SSDataArr[idx].rMyServersBigBufferClass.Add (TempCode.cnt+4, @TempCode);
   Result := TRUE;
end;

procedure TFrmGateSock.ServerSocket1Accept(Sender: TObject; Socket: TCustomWinSocket);
var
   i, idx: integer;
   str: string;
begin
   str := Socket.RemoteAddress;
   idx := -1;
   for i := 0 to 4-1 do if SSDataArr[i].rAddress = str then begin idx := i; break; end;

   if idx = -1 then begin
      frmMain.WriteLogInfo ('Bad Gate1000 is detected');
      Socket.Close;
      exit;
   end;

   frmMain.WriteLogInfo (format('Gate1000(%s) is detected', [str]));

   SSDataArr[idx].rSocket := Socket;
   SSDataArr[idx].rWriteAllow := WRITEALLOW_FALSE;
   SSDataArr[idx].rWBlock.cnt := 0;
   SSDataArr[idx].rMySocketsBigBufferClass.Clear;
   SSDataArr[idx].rMyServersBigBufferClass.Clear;
   SSDataArr[idx].rBoConnected := TRUE;
end;

procedure TFrmGateSock.ServerSocket1ClientDisconnect(Sender: TObject; Socket: TCustomWinSocket);
var
   i, idx: integer;
   str: string;
begin
   str := Socket.RemoteAddress;
   idx := -1;
   for i := 0 to 4-1 do if SSDataArr[i].rAddress = str then begin idx := i; break; end;
   if idx = -1 then exit;

   frmMain.WriteLogInfo (format('TGS1000:GATE1000 Connection Broken (%s)', [str]));

   SSDataArr[idx].rSocket := nil;
   SSDataArr[idx].rMySocketsBigBufferClass.Clear;
   SSDataArr[idx].rMyServersBigBufferClass.Clear;
   SSDataArr[idx].rWBlock.cnt := 0;
   SSDataArr[idx].rWriteAllow := WRITEALLOW_FALSE;
//   SSDataArr[idx].rAddress: string[32];
   SSDataArr[idx].rBoConnected := FALSE;

   ConnectorList.CloseConnectByGate (idx);
end;

procedure TFrmGateSock.ServerSocket1ClientError(Sender: TObject;
  Socket: TCustomWinSocket; ErrorEvent: TErrorEvent;
  var ErrorCode: Integer);
begin
   Case ErrorEvent of
      eeConnect :
         frmMain.WriteLogInfo (format('ServerSocket Connect Error(%d)!!', [ErrorCode]));
      eeDisconnect :
         frmMain.WriteLogInfo (format('ServerSocket Disconnect Error(%d)!!', [ErrorCode]));
      eeReceive :
         frmMain.WriteLogInfo (format('ServerSocket Receive Error(%d)!!', [ErrorCode]));
      eeSend :
         frmMain.WriteLogInfo (format('ServerSocket Send Error(%d)!!', [ErrorCode]));
      eeAccept :
         frmMain.WriteLogInfo (format('ServerSocket Accept Error(%d)!!', [ErrorCode]));
   end;

   Socket.Close;
   ErrorCode := 0;
end;

procedure TFrmGateSock.ServerSocket1ClientRead(Sender: TObject; Socket: TCustomWinSocket);
var
   i, idx : integer;
   cnt, nRead : integer;
   buffer : array [0..5000] of byte;
begin
   try
      idx := -1;
      for i := 0 to 4-1 do begin
         if SSDataArr[i].rSocket = nil then continue;
         if SSDataArr[i].rSocket.SocketHandle <> Socket.SocketHandle then continue;
         idx := i;
         break;
      end;

      if idx = -1 then exit;

      cnt := Socket.ReceiveLength;
      while cnt > 0 do begin
         if cnt > 4096 then nRead := 4096
         else nRead := cnt;
         nRead := Socket.ReceiveBuf (Buffer, nRead);
         if nRead <> SOCKET_ERROR then begin
            Buffer[nRead] := 0;
            if nRead > 0 then begin
               SSDataArr[idx].rMySocketsBigBufferClass.Add (nRead, @Buffer);
               cnt := cnt - nRead;
            end;
         end else begin
            frmMain.WriteLogInfo ('ReceiveBuf SocketError');
            break;
         end;
      end;
   except
   end;
end;

procedure TFrmGateSock.ServerSocket1ClientWrite(Sender: TObject; Socket: TCustomWinSocket);
var
   i, idx : integer;
begin
   idx := -1;
   for i := 0 to 4-1 do begin
      if SSDataArr[i].rSocket = nil then continue;
      if SSDataArr[i].rSocket.SocketHandle <> Socket.SocketHandle then continue;
      idx := i;
      break;
   end;
   if idx <> -1 then SSDataArr[idx].rWriteAllow := WRITEALLOW_TRUE;
end;

////////////////////////
//
////////////////////////
procedure TFrmGateSock.MessageProcess(atype, aConid: integer; var Code: TComData);
var
   pmd : PTMessageData2;
begin
   case atype of
      DATA_TYPE_MESSAGE2:
         begin
            pmd := @Code.Data;
            case pmd^.rmsg of
               MSG2_CONNECT:
                  begin
                     FrmMain.AddEvent ('Con:'+pmd^.rString16);
                     ConnectorList.CreateConnect (aConid, pmd^.rString16);
                  end;
               MSG2_DISCONNECT:
                  begin
                     FrmMain.AddEvent ('Dis:'+pmd^.rString16);
                     ConnectorList.DeleteConnect (aConId, pmd^.rString16);
                  end;
            end;
         end;
      DATA_TYPE_DATA: ConnectorList.ClientSocketData (aConid, Code);
      DATA_TYPE_NONE:;
   end;
end;

function  TFrmGateSock.SendProcess: Boolean;
var
   i : integer;
   cnt, ret : integer;
   buffer : array [0..4096] of byte;
begin
   Result := FALSE;
   for i := 0 to 4-1 do begin
      if SSDataArr[i].rSocket = nil then continue;
      if SSDataArr[i].rWriteAllow = WRITEALLOW_FALSE then continue;

      if SSDataArr[i].rWBlock.Cnt > 0 then begin
         ret := SSDataArr[i].rSocket.SendBuf(SSDataArr[i].rWBlock.data, SSDataArr[i].rWBlock.cnt);
         if ret = SOCKET_ERROR then begin
            ret := 0;
         end;
         if ret = SSDataArr[i].rWBlock.cnt then begin
            FillChar (SSDataArr[i].rWBlock, sizeof(SSDAtaArr[i].rWBlock), 0);
         end else if ret > 0 then begin
            SSDataArr[i].rWBlock.cnt := SSDataArr[i].rWBlock.cnt - ret;
            Move (SSDataArr[i].rWBlock.data[ret],SSDataArr[i].rWBlock.data[0], SSDataArr[i].rWBlock.cnt);
            SSDataArr[i].rWriteAllow := WRITEALLOW_FALSE;
         end else begin
            SSDataArr[i].rWriteAllow := WRITEALLOW_FALSE;
         end;
         continue;
      end;

      cnt := SSDataArr[i].rMyServersBigBufferClass.Get (4096, @Buffer);
      if cnt = 0 then continue;

      ret := SSDataArr[i].rSocket.SendBuf (Buffer, cnt);
      if ret = SOCKET_ERROR then begin
         ret := 0;
      end;
      if ret < cnt then begin
         SSDataArr[i].rWBlock.cnt := cnt - ret;
         move (Buffer[ret], SSDataArr[i].rWBlock.data, SSDataArr[i].rWBlock.cnt);
         SSDataArr[i].rWriteAllow := WRITEALLOW_FALSE;
         continue;
      end;
      Result := TRUE;
   end;
end;

procedure TFrmGateSock.ReceiveProcess;
var
   TempType, TempGateNo, TempConid : integer;
   Code: TComData;
begin
   while TRUE do begin
      if not GetSocketsComData (TempType, TempConid, Code) then break;
      MessageProcess (Temptype, TempConid, Code);
   end;
end;

end.
