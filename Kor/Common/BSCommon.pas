unit BSCommon;

interface

uses
   AUtil32;

const
   MAX_GROUP_COUNT   = 30;
   MAX_ROOM_COUNT    = 30;

   // From GameServer To BattleServer
   GB_USERCONNECT    = 1;     // 유저가 대련서버에 접속함을 알린다
   GB_USERDISCONNECT = 2;     // 유저의 접속이 끊어졌음을 알린다
   GB_GAMEDATA       = 3;     // 유저로부터 온 패킷을 담은 메세지

   // From BattleServer To GameServer
   BG_NONE           = 1;
   BG_USERCLOSE      = 2;
   BG_GAMEDATA       = 3;

   // BattleServer Message
//   SM_SHOWGROUPLISTWINDOW  = 100;
//   SM_SHOWROOMLISTWINDOW   = 101;

   // Client Message
//   CM_CONFIRMBATTLEGROUP   = 100;
      BATTLEBUTTON_SELECT  = 0;
      BATTLEBUTTON_GRADE   = 1;
      BATTLEBUTTON_EXIT    = 2;

//   CM_CONFIRMBATTLEROOM    = 101;
      BATTLEBUTTON_MAKE    = 0;
      BATTLEBUTTON_FIGHT   = 1;
      BATTLEBUTTON_SHOW    = 2;
      BATTLEBUTTON_ROOMEXIT = 3;

      BATTLEBUTTON_SHOWALL    = 0;
      BATTLEBUTTON_SHOWME     = 1;
      BATTLEBUTTON_GRADEEXIT  = 2;

   // From Battle GameServer To Battle DBServer
   BSBD_GETRANKDATA        = 1;
   BSBD_BATTLERESULT       = 2;
   BSBD_GETRANKPART        = 3;
   BSBD_GETSERVERRANK      = 4;
   BSBD_GETMAINMAGICRANK   = 5;
   BSBD_MAGICRESULT        = 6;

   // From Battle DBServer To Battle GameServer
   BDBS_SENDRANKDATA       = 1;
   BDBS_SENDRANKPART       = 2;
   BDBS_SENDSERVERRANK     = 3;
   BDBS_SENDMAINMAGICRANK  = 4;

type
   // Inner Structure
   TCreateGroupData = record
      Name : String [20];
      ViewName : String [30];
      RoomLimit : Integer;
      MinAge : Integer;
      MaxAge : Integer;
      boGrade : Boolean;
   end;
   PTCreateGroupData = ^TCreateGroupData;

   // Battle Server Structure
   TSShowListWindow = record
      rMsg : Byte;
      rWindow : Byte;
      rType : Byte;  // 0 : Show Record; 1 : Add Record; 2 : Delete Record; 3 : Update Record;
      rWordString : TWordString;
   end;
   PTSShowListWindow = ^TSShowListWindow;

   // Battle Ranking DB Structure
   TSendRankData = record
      rCharName : String [20];
      rServerName : String [20];
      rWin : Integer;           // 승
      rLose : Integer;          // 패
      rDisConnected : Integer;  // 끊긴거
      rBattleRecord : Integer;  // 전적
      rPoints : Integer;        // 점수
      rGrade : Integer;         // 순위
   end;
   PTSendRankData = ^TSendRankData;

   TGetRankData = record
      rName : String [20];
      rServerName : String [20];
      rAge : Word;
      rSex : Byte;   // 0: 남 1: 여
   end;
   PTGetRankData = ^TGetRankData;

   TGetRankPart = record
      rAge : Integer;
      rStart : Integer;
      rEnd : Integer;
   end;
   PTGetRankPart = ^TGetRankPart;

   TGetMainMagicRank = record
      rMainMagic : String [20];     // 주무공이름
      rStart : Integer;
      rEnd : Integer;
   end;
   PTGetMainMagicRank = ^TGetMainMagicRank;

// 한방에 3300
   TSendRankPart = record
      rStart : Integer;
      rEnd : Integer;
      rData : array [0..50 - 1] of TSendRankData;
   end;
   PTSendRankPart = ^TSendRankPart;

   TSendServerRankData = record
      rServerName : String [20];
      rPoints : Integer;
   end;
   PTSendServerRankData = ^TSendServerRankData;

   TSendServerRankPart = record
      rStart : Integer;
      rEnd : Integer;
      rData : array [0..10 - 1] of TSendServerRankData;
   end;
   PTSendServerRankPart = ^TSendServerRankPart;

   TBattleResultData = record
      rOwnerName : String [20];
      rOwnerServer : String [20];
      rFighterName : String [20];
      rFighterServer : String [20];
      rOwnerWin : Byte;
      rOwnerLose : Byte;
      rOwnerDisCon : Byte;
      rFighterWin : Byte;
      rFighterLose : Byte;
      rFighterDisCon : Byte;
   end;
   PTBattleResultData = ^TBattleResultData;

   TMainMagicData = record
      rName : String [20];
      rServerName : String [20];
      rMagic : String [20];
   end;
   PTMainMagicData = ^TMainMagicData;

implementation

end.
