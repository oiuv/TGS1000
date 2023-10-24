unit uLGRecordDef;

interface

type
   TLGHeader = record
      ID : array[0..4 - 1] of byte;
      RecordCount : Integer;
      RecordDataSize : Integer;
      RecordFullSize : Integer;
      boSavedIndex : Boolean;
      Dummy : array [0..32 - 1] of byte;
   end;
   PTLGHeader = ^TLGHeader;

   TCharData = record
      CharName : String [20];
      ServerName : String [20];
   end;

   TLGRecord = record
      PrimaryKey : String [20];
      PassWord : String [20];
      UserName : String [20];
      Birth : String [20];
      Address : String [50];
      NativeNumber : String [20];
      MasterKey : String [20];
      Email : String [50];
      Phone : String [20];
      CharInfo : array [0..5 - 1] of TCharData;
      IpAddr : String [16];
      MakeDate : String [20];
      LastDate : String [20];
   end;
   PTLGRecord = ^TLGRecord;

implementation

end.
