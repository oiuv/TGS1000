unit Common;

interface

{
const
   NATION_KOREA         =   1;
   NATION_TAIWAN        =   2;
   NATION_CHINA1        =   3;
   
   NATION_VERSION       =   NATION_KOREA;
   PROGRAM_VERSION      =   14;

   NAME_SIZE            =  19;
   WORDSTRINGSIZE       = 4096;
   WORDSTRINGSIZEALLOW  = WORDSTRINGSIZE - 3;

   CM_NONE              =   0;
   CM_VERSION           =   2;
   CM_IDPASS            =   3;
   CM_CREATEIDPASS      =   4;
   CM_CHANGEPASSWORD    =   5;
   CM_CREATECHAR        =   6;
   CM_DELETECHAR        =   7;
   CM_SELECTCHAR        =   8;

   CM_CREATEIDPASS2     =  24;
   CM_IDPASSAZACOM      =  25;

   SM_CONNECTTHRU       = 253;
   SM_RECONNECT         = 254;
   SM_CLOSE             = 255;
   SM_WINDOW            =   1;
   SM_MESSAGE           =   2;
   SM_CHARINFO          =   3;
   SM_CHATMESSAGE       =   4;

   MESSAGE_NONE         =   0;
   MESSAGE_LOGIN        =   1;
   MESSAGE_CREATELOGIN  =   2;
   MESSAGE_SELCHAR      =   3;
   MESSAGE_GAMEING      =   4;

   PM_NONE              =   0;
   PM_CHECKPAID         =   1;

   BM_GATEINFO          =   0;

   PACKET_PROCESSRESULT =   0;

   // Login Server Message
   LG_INSERT            =   0;
   LG_SELECT            =   1;
   LG_DELETE            =   2;
   LG_UPDATE            =   3;

   // DB Server Message
   DB_INSERT            =   0;
   DB_SELECT            =   1;
   DB_DELETE            =   2;
   DB_UPDATE            =   3;
   DB_LOCK              =   4;
   DB_UNLOCK            =   5;
   DB_CONNECTTYPE       =   6;
   DB_ITEMSELECT        =   7;
   DB_ITEMUPDATE        =   8;

   // Game Server Message
   GM_CONNECT           =   0;
   GM_DISCONNECT        =   1;
   GM_SENDUSERDATA      =   2;
   GM_SENDGAMEDATA      =   3;
   GM_DUPLICATE         =   4;
   GM_SENDALL           =   5;
   GM_UNIQUEVALUE       =   6;

   DB_OK                =   0;
   DB_ERR               =   1;
   DB_ERR_NOTFOUND      =   2;
   DB_ERR_DUPLICATE     =   3;
   DB_ERR_IO            =   4;
   DB_ERR_INVALIDDATA   =   5;
   DB_ERR_NOTENOUGHSPACE =  6;

   

type
   TNameString = array [0..NAME_SIZE - 1] of byte;
   TWordString = array [0..WORDSTRINGSIZE - 1] of byte;

   PByte = ^Byte;
   TConnectInfo = record
      RemoteIP : String;
      RemotePort : Integer;
      LocalPort : Integer;
   end;

   TComData = record
      Size : word;
      Data : array[0..4096-1] of byte;
   end;
   PTComData = ^TComData;

   TWordComData = record
      Size : word;
      Data : array[0..4096-1] of byte;
   end;
   PTWordComData = ^TWordComData;

   TCKey = record
      msg : byte;
      key : word;
   end;
   PTCKey = ^TCKey;

   TCVer = record
      msg : byte;
      Ver : word;
      Nation : Word;
   end;
   PTCVer = ^TCVer;

   TCIDPass = record
      msg : byte;
      ID : TNameString;
      Pass : TNameString;
   end;
   PTCIDPass = ^TCIDPass;

   TCCreateIdPass = record
      Msg : byte;
      ID : TNameString;
      Pass : TNameString;
      Name : TNameString;
      Telephone : TNameString;
      Birth : TNameString;
   end;
   PTCCreateIdPass = ^TCCreateIdPass;

   TCCreateIdPass2 = record
      msg : byte;
      ID : TNameString;
      Pass : TNameString;
      Name : TNameString;
      MasterKey : TNameString;
      NativeNumber : TNameString;
   end;
   PTCCreateIdPass2 = ^TCCreateIdPass2;

   TCChangePassWord = record
      msg : byte;
      NewPass : TNameString;
   end;
   PTCChangePassWord = ^TCChangePassWord;

   TCCreateChar = record
      msg : byte;
      CharName : TNameString;
      Sex : byte;
      Village : TNameString;
      Server : TNameString;
   end;
   PTCCreateChar = ^TCCreateChar;

   TCDeleteChar = record
      msg : byte;
      CharName : TNameString;
   end;
   PTCDeleteChar = ^TCDeleteChar;

   TCSelectChar = record
      msg : byte;
      CharName : TNameString;
   end;
   PTCSelectChar = ^TCSelectChar;

   TSMessage = record
      msg : byte;
      key : word;
      WordString : TWordString;
   end;
   PTSMessage = ^TSMessage;

   TSWindow = record
      msg : byte;
      window : byte;
      boShow : Boolean;
   end;
   PTSWindow = ^TSWindow;

   TWordInfoString = record
      rmsg : byte;
      rWordString: TWordString;
   end;
   PTWordInfoString = ^TWordInfoString;

   TSReConnect = record
      rmsg : byte;
      rId : TNameString;
      rPass : TNameString;
      rCharName : TNameString;
      rIpAddr : TNameString;
      rPort : integer;
   end;
   PTSReConnect = ^TSReConnect;

   TSConnectThru = record
      rMsg : Byte;
      rIpAddr : TNameString;
      rPort : Integer;
   end;
   PTSConnectThru = ^TSConnectThru;

   TPaidData = record
      rLoginId : String [20];
      rIpAddr : String [20];
      rRemainDay : Integer;
      rboTimePay : Boolean;
      rMakeDate : String [20];
   end;
   PTPaidData = ^TPaidData;

   TBalanceData = record
      rMsg : Byte;
      rIpAddr : array [0..20 - 1] of char;
      rPort : Integer;
      rUserCount : Integer;
   end;
   PTBalanceData = ^TBalanceData;
}

implementation

end.
