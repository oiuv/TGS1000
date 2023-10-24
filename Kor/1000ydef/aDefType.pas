unit aDefType;

interface

uses
   Windows, Sysutils, Classes, aUtil32;

const
   COMDATASIZE = 4096;

type
   TComData = record
     cnt : integer;
     data : array [0..COMDATASIZE] of byte;
   end;
   PTComData = ^TComData;

const
   DATA_TYPE_NONE     = 0;
   DATA_TYPE_DATA     = 1;
//   DATA_TYPE_MESSAGE  = 2;
      MSG_NONE          = 0;
      MSG_CONNECT       = 1;
      MSG_DISCONNECT    = 2;
      MSG_SAVEANDCLOSE  = 3;
//      MSG_SAVECHARDATA  = 4;
      MSG_MAKECHARDATA  = 5;
      MSG_REQUESTCLOSE  = 6;
      MSG_CLOSED        = 7;

   DATA_TYPE_MESSAGE2  = 3;
      MSG2_NONE            = 0;
      MSG2_CONNECT         = 1;
      MSG2_DISCONNECT      = 2;
      MSG2_REQUESTCLOSE    = 3;

      MSG2_SETPORT         = 4;
      MSG2_SETSLEEP        = 5;
      MSG2_SETPROCESSCOUNT = 6;

      MSG2_SOCKETACTIVE    = 7;
      MSG2_SOCKETDEACTIVE  = 8;

      MSG2_ALLOWCONNECT    = 9;
      MSG2_REFUSECONNECT   = 10;

type
   TSocketData = record
      rtype : byte;
      rConid : integer;
      rDataSize : integer;
   end;
   PTSocketData = ^TSocketData;

   TMessageData = record
      rtype : byte;
      rmsg : byte;
      rConid : integer;
      rDestServer : integer;
      rWordString : TWordString;
   end;
   PTMessageData = ^TMessageData;

   TMessageData2 = record
      rmsg : byte;
      rConid : integer;
      rInteger : integer;
      rString16 : string[16];
   end;
   PTMessageData2 = ^TMessageData2;

type
   TSafeAddComDataFunction = procedure (aHandle: integer; len: integer; pdata: pbyte);
   TSafeGetComDataFunction = function  (aHandle: integer; var Code: TComData): Boolean;

implementation

end.
