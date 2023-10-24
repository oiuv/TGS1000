unit uRemoteDef;

interface

const
   REMOTE_CMD_NONE            = 10;
   REMOTE_CMD_FIELD_X         = 11;
   REMOTE_CMD_READ_X          = 12;
   REMOTE_CMD_WRITE_X         = 13;
   REMOTE_CMD_INSERT          = 14;
   REMOTE_CMD_DELETE          = 15;
   REMOTE_CMD_RESULT          = 16;

//   REMOTE_CMD_LOGIN           = 7; // LOGIN CHECK
   REMOTE_CMD_VERIFICATIONID  = 17;
   REMOTE_CMD_ADDLOG          = 18;
   REMOTE_CMD_MAKEPASSWORD    = 19;
   REMOTE_CMD_CHANGEPASSWORD  = 20;
   REMOTE_CMD_DBLIST          = 21;
   REMOTE_CMD_DBCONNECT       = 22;

   REMOTE_CMD_FIELD           = 31;
   REMOTE_CMD_READ            = 32;
   REMOTE_CMD_WRITE           = 33;
   REMOTE_CMD_WHOAMI          = 34;

   // add by minds at 2005-04-05 14:07
   REMOTE_CMD_NETSTAT         = 35;

   REMOTE_RESULT_NONE         = 10;
   REMOTE_RESULT_OK           = 11;
   REMOTE_RESULT_BADCMD       = 12;
   REMOTE_RESULT_NOTFOUND     = 13;
   REMOTE_RESULT_DUPLICATE    = 14;
   REMOTE_RESULT_NOSPACE      = 15;
   REMOTE_RESULT_NOACCESS     = 16;

  // add by Steven at 2004-11-25 15:32:36
   REMOTE_USER_LIST           = 70;
   REMOTE_USER_ADD            = 71;
   REMOTE_USER_DELETE         = 72;
   REMOTE_USER_UPDATE         = 73;

   REMOTE_ITEM_SEND           = 80;
   REMOTE_ITEM_SUCCESS        = 81;
   REMOTE_ITEM_FAIL           = 82;

type
   TRemotePacket = packed record
      Len : Word;
      Cmd : Byte;
      Result : Byte;
      Data : array [0..8192 - 1] of Char;
   end;
   PTRemotePacket = ^TRemotePacket;

implementation

end.





