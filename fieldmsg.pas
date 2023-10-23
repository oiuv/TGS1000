unit fieldmsg;

interface

uses
	Windows, SysUtils, Classes, DefType, svClass, uManager;

const
   PHONE_BLOCK_SIZE = 16;

   FIRSTUSERSIZE = PHONE_BLOCK_SIZE * 2;

   FIELDPHONE_STARTPOS  = 0;
   FIELDPHONE_CENTERPOS = 4;
   FIELDPHONE_ENDPOS    = 8;

type

   TFieldProc = function (hfu: Longint; Msg: word; var SenderInfo: TBasicData; var aSubData: TSubData): Integer of object;

   TFieldUser = Record
      hfu : LongInt;
      FieldProc : TFieldProc;
   end;

   PTFieldUser = ^TFieldUser;

   TFieldPhone = class
   private
      Name : String;
      Manager : TManager;

      Width, Height : integer;
      Wblock, Hblock : integer;
      DataList : TList;
      function    GetFieldUser ( hfu: LongInt; ax, ay:integer) : PTFieldUser;
      function    DeleteFieldUser ( Puser : PTFieldUser; ax, ay:integer) : Boolean;
      function    GetDataListByXy (ax, ay, aPos:integer): TList;
    public
      constructor Create (aManager : TManager);
      destructor  Destroy; override;
      function    boExistUser ( hfu: LongInt; ax, ay: integer):Boolean;
      procedure   RegisterUser ( hfu: LongInt; Proc: TFieldProc; ax, ay:integer);
      procedure   UnRegisterUser ( hfu: LongInt; ax, ay:integer);

      function    SendMessage (hfu: Longint; Msg: word; var SenderInfo: TBasicData; var aSubData: TSubData): Integer;
   end;

implementation

uses
   MapUnit, SVMain;

constructor TFieldPhone.Create (aManager : TManager);
var
   i, j: Integer;
   List : TList;
begin
   Manager := aManager;

   Width := TMaper (Manager.Maper).Width;
   Height := TMaper (Manager.Maper).Height;

   wblock := Width div PHONE_BLOCK_SIZE+1;
   hblock := Height div PHONE_BLOCK_SIZE+1;

   Name := Manager.Title;

   DataList := TList.Create;
   for j := 0 to hblock -1 do begin
      for i := 0 to wblock -1 do begin
         List := TList.Create;
         DataList.Add (List);
      end;
   end;
end;

destructor TFieldPhone.Destroy;
var
   i, j : integer;
   List : TList;
begin
   for j := 0 to DataList.Count-1 do begin
      List := DataList[j];
      for i := 0 to List.Count -1 do begin
         Dispose ( List[i]);
      end;
   end;
   for i := 0 to DataList.Count -1 do TList (DataList[i]).Free;
   DataList.Free;
   inherited Destroy;
end;

function    TFieldPhone.GetDataListByXy (ax, ay, aPos: integer): TList;
var
   n : integer;
   xb, yb: integer;
begin
   Result := nil;
   if dataList.Count = 0 then exit;

   xb := ax div PHONE_BLOCK_SIZE;
   yb := ay div PHONE_BLOCK_SIZE;

   case aPos of
      0: begin xb := xb -1; yb := yb -1; end;
      1: begin xb := xb   ; yb := yb -1; end;
      2: begin xb := xb +1; yb := yb -1; end;
      3: begin xb := xb -1; yb := yb   ; end;
      4:;
      5: begin xb := xb +1; yb := yb   ; end;
      6: begin xb := xb -1; yb := yb +1; end;
      7: begin xb := xb   ; yb := yb +1; end;
      8: begin xb := xb +1; yb := yb +1; end;
      else exit;
   end;

   if (xb < 0) or (xb >= wblock) then exit;
   if (yb < 0) or (yb >= hblock) then exit;

   n := xb + yb * wblock;

   if (n >= DataList.Count) or (n < 0) then exit;
   Result := DataList[n];
end;

function TFieldPhone.GetFieldUser ( hfu: LongInt; ax, ay:integer) : PTFieldUser;
var
   i, j : integer;
   pu : PTFieldUser;
   List : TList;
begin
   Result := nil;

   j := 4;
   List := GetDataListByXy (ax, ay, j);
   if List <> nil then begin
      for i := 0 to List.Count-1 do begin
         pu := List.items[i];
         if pu^.hfu = hfu then begin Result := pu; exit; end;
      end;
   end;

   for j := 0 to 8 do begin
      if j = 4 then continue;
      List := GetDataListByXy (ax, ay, j);
      if List = nil then continue;

      for i := 0 to List.Count-1 do begin
         pu := List.items[i];
         if pu^.hfu = hfu then begin Result := pu; exit; end;
      end;
   end;

   {
   xb := ax div PHONE_BLOCK_SIZE;
   yb := ay div PHONE_BLOCK_SIZE;

   //frmMain.WriteLogInfo (format ('FieldPhone Full Search hfu=%d xy (%d,%d) fxy(%d,%d)', [hfu, ax, ay, xb, yb]));
   for i := 0 to DataList.Count - 1 do begin
      LIst := DataList.Items [i];
      for j := 0 to List.Count - 1 do begin
         pu := List.Items [j];
         if pu^.hfu = hfu then begin
            yb := i div wblock;
            xb := i mod wblock;
//            frmMain.WriteLogInfo (format ('Bingo hfu=%d xy (%d,%d) fxy(%d,%d)', [hfu, ax, ay, xb, yb]));
            Result := pu;
            exit;
         end;
      end;
   end;
//   frmMain.WriteLogInfo ('FieldPhone Full Search failed');
   }
end;

function TFieldPhone.DeleteFieldUser ( puser: PTFieldUser; ax, ay:integer) : Boolean;
var
   i, j : integer;
   pu : PTFieldUser;
   List : TList;
begin
   Result := FALSE;

   j := 4;
   List := GetDataListByXy (ax, ay, j);
   if List <> nil then begin
      for i := 0 to List.Count-1 do begin
         pu := List[i];
         if pu = puser then begin
            dispose (pu);
            List.Delete (i);
            Result := TRUE;
            exit;
         end;
      end;
   end;

   for j := 0 to 8 do begin
      if j = 4 then continue;
      List := GetDataListByXy (ax, ay, j);
      if List = nil then continue;

      for i := 0 to List.Count-1 do begin
         pu := List[i];
         if pu = puser then begin
            dispose (pu);
            List.Delete (i);
            Result := TRUE;
            exit;
         end;
      end;
   end;
end;

procedure TFieldPhone.RegisterUser ( hfu: LongInt; Proc: TFieldProc; ax, ay:integer);
var
   puser : PTFieldUser;
   List : TList;
begin
   List := GetDataListByXy (ax, ay, FIELDPHONE_CENTERPOS);
   if List = nil then exit;

   puser := GetFieldUser ( hfu, ax, ay);
   if puser = nil then begin
      new (puser);
      puser^.hfu := hfu;
      puser^.FieldProc := Proc;
      List.Add (puser);
   end else begin
      frmMain.WriteLogInfo ('TFieldPhone.RegisterUser () failed');
   end;
end;

procedure TFieldPhone.UnRegisterUser ( hfu: LongInt; ax, ay:integer);
var puser : PTFieldUser;
begin
   puser := GetFieldUser ( hfu, ax, ay);
   if puser <> nil then begin
      DeleteFieldUser ( puser, ax, ay);
   end else begin
      frmMain.WriteLogInfo (format ('TFieldPhone.UnRegisterUser (%d) failed', [hfu]));
   end;
end;

function  TFieldPhone.boExistUser ( hfu: LongInt; ax, ay:integer):Boolean;
var puser : PTFieldUser;
begin
   puser := GetFieldUser(hfu, ax, ay);
   if puser <> nil then Result := TRUE
   else Result := FALSE;
end;

function  TFieldPhone.SendMessage (hfu: Longint; Msg: word; var SenderInfo: TBasicData; var aSubData: TSubData): Integer;
var
   i, j : integer;
   List : TList;
   puser : PTFieldUser;
   Changed : TFieldUser;
   flag: boolean;
begin

   if (msg = FM_MOVE) or (msg = FM_BACKMOVE) then begin
      flag := FALSE;
      if (SenderInfo.x div PHONE_BLOCK_SIZE) <> (SenderInfo.nx div PHONE_BLOCK_SIZE) then flag := TRUE;
      if (SenderInfo.y div PHONE_BLOCK_SIZE) <> (SenderInfo.ny div PHONE_BLOCK_SIZE) then flag := TRUE;
      if flag then begin
         puser := GetFieldUser (SenderInfo.Id, SenderInfo.x, SenderInfo.y);
         if puser <> nil then begin
            Changed := puser^;
            DeleteFieldUser (puser, SenderInfo.x, SenderInfo.y);
            RegisterUser ( SenderInfo.id, Changed.FieldProc, SenderInfo.nx, SenderInfo.ny);
         end;
      end;
   end;

   if hfu = MANAGERPHONE then begin
      Result := ManagerList.FieldProc ( hfu, Msg, Senderinfo, aSubData);
      exit;
   end;

   if hfu = NOTARGETPHONE then begin
      if Msg = FM_DESTROY then begin
         // SendMessage (hfu, FM_BEFOREDESTROY, SenderInfo, aSubData);
      end;

      puser := GetFieldUser (SenderInfo.id, SenderInfo.x, SenderInfo.y);
      if puser <> nil then begin
         Result := puser^.FieldProc ( hfu, Msg, SenderInfo, aSubData);
      end else begin
         Result := -1;
         exit;
      end;

      for j := 0 to 8 do begin
         List := GetDataListByXy (SenderInfo.x, SenderInfo.y, j);
         if List = nil then continue;

         for i := 0 to List.Count-1 do begin
            puser := List[i];
            if puser^.hfu = SenderInfo.id then continue;
            Result := puser^.FieldProc ( 0, Msg, SenderInfo, aSubData);
         end;
      end;

      if Msg = FM_CREATE then begin
         SendMessage (hfu, FM_AFTERCREATE, SenderInfo, aSubData);
      end;
   end else begin
      puser := GeTFieldUser ( hfu, SenderInfo.x, SenderInfo.y);
      if puser <> nil then begin
         Result := puser^.FieldProc ( hfu, Msg, SenderInfo, aSubData);
      end else begin
         if (msg <> FM_NONE) and (msg <> FM_ADDITEM) and
            (msg <> FM_CLICK) then ;
         Result := -1;
      end;
   end;
end;

end.
