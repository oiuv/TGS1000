unit uDBRecordDef;

interface

type
   TDBHeader = packed record
      ID : array[0..4 - 1] of byte;
      RecordCount : Integer;
      RecordDataSize : Integer;
      RecordFullSize : Integer;
      boSavedIndex : Boolean;
      Dummy : array [0..32 - 1] of byte;
   end;
   PTDBHeader = ^TDBHeader;

   TDBItemData = packed record
      Name : array [0..20 - 1] of byte;      // 이름
      Count : Integer;                       // 수량
      Color : Byte;                          // 색상
      Durability : Word;                     // 최대치내구성
      CurDurability : Word;                  // 현재내구성
      UpGrade : byte;                        // 등급
      AddType : Byte;                        // 추가속성
      Dummy : Byte;                          // Reserved

      // add by Orber at 2004-08-26 10:53
      rLockState : Byte;
      runLockTime : Word;
   end;

   TDBMarketItemData = packed record
      Name : array [0..20 - 1] of byte;      // 이름
      Count : Integer;                       // 수량
      Color : Byte;                          // 색상
      Durability : Word;                     // 최대치내구성
      CurDurability : Word;                  // 현재내구성
      UpGrade : byte;                        // 등급
      AddType : Byte;                        // 추가속성
      Cost : Integer;                        // 판매할때 가격
      Dummy : Byte;                          // Reserved
   end;

   TDBMagicData = packed record
      Name : array [0..20 - 1] of byte;
      Skill : Integer;
   end;
   TDBBasicMagicData = packed record
      Skill : integer;
   end;

   TDBBestMagicData = packed record
      Name : array [0..20-1] of byte;
      Grade : byte;
      rDamageBody : word;
      rDamageHead : word;
      rDamageArm : word;
      rDamageLeg : word;
      rDamageEnergy : word;
      rArmorBody : word;
      rArmorHead : word;
      rArmorArm : word;
      rArmorLeg : word;
      rArmorEnergy : word;
      Skill : integer;
   end;

   TDBRecord = packed record
      PrimaryKey     : array [0..20 - 1] of byte;              // 캐릭명

      MasterName     : array [0..20 - 1] of byte;              // 계정명
      Password       : array [0..10 - 1] of byte;              // 비밀번호
      GroupKey       : Word;                                   // 단체번호
      Guild          : array [0..20 - 1] of byte;              // 문파명
      LastDate       : array [0..12 - 1] of byte;              // 최종접속일
      CreateDate     : array [0..12 - 1] of byte;              // 최초접속일
      Sex            : array [0..6 - 1] of byte;               // 성별
      // add by Orber at 2004-12-21 17:46:33
      Lover          : array [0..20-1] of byte;

      ServerId       : byte;                                   // Map 번호
      x              : word;                                   // X 좌표
      y              : word;                                   // Y 좌표

      Light          : Integer;                                // 양기
      Dark           : Integer;                                // 음기
      Energy         : Integer;                                // 원기
      InPower        : Integer;                                // 내공
      OutPower       : Integer;                                // 외공
      Magic          : Integer;                                // 무공
      Life           : Integer;                                // 활력

      Talent         : integer;                                // 재능
      GoodChar       : integer;                                // 신성
      BadChar        : integer;                                // 마성
      Adaptive       : integer;                                // 내성
      Revival        : integer;                                // 재생
      Immunity       : integer;                                // 면역
      Virtue         : integer;                                // 호연지기

      CurEnergy      : integer;                                // 현재 원기
      CurInPower     : integer;                                // 현재 내공
      CurOutPower    : integer;                                // 현재 외공
      CurMagic       : integer;                                // 현재 무공
      CurLife        : integer;                                // 현재 활력
      CurHealth      : integer;                                // 현재
      CurSatiety     : integer;                                // 현재
      CurPoisoning   : integer;                                // 현재
      CurHeadSeek    : integer;                                // 현재 머리 활력
      CurArmSeek     : integer;                                // 현재 팔 활력
      CurLegSeek     : integer;                                // 현재 다리 활력

      ExtraExp       : integer;
      AddableStatePoint : integer;
      TotalStatePoint : integer;
      CurrentGrade : Byte;

      BasicMagicArr  : array [0..10 - 1] of TDBBasicMagicData; // 기본무공
      BasicRiseMagicArr : array [0..10 - 1] of TDBMagicData;   // 낭인무공
      WearItemArr    : array [0..8 - 1] of TDBItemData;        // 착용아이템
      HaveItemArr    : array [0..30 - 1] of TDBItemData;       // 소유아이템
      HaveMagicArr   : array [0..30 - 1] of TDBMagicData;      // 소유무공
      HaveRiseMagicArr : array [0..30 - 1] of TDBMagicData;    // 상승무공
      HaveMysteryArr : array [0..30 - 1] of TDBMagicData;      // 술장법무공      
      HaveBestSpecialMagicArr : array [0..15-1] of TDBBestMagicData; // 초수(필살기)
      HaveBestProtectMagicArr : array [0..5-1] of TDBBestMagicData;  // 공력
      HaveBestAttackMagicArr : array [0..5-1] of TDBBestMagicData;   // 절세무공

      HaveMaterialItemArr : array [0..5 - 1] of TDBItemData;   // 재료창 5개
      HaveMarketItemArr : array [0..10 - 1] of TDBMarketItemData;    // 개인판매창 10개

      Person1        : array [0..20 - 1] of Byte;
      Person2        : array [0..20 - 1] of Byte;
      Key            : array [0..10 - 1] of Byte;

      CompleteQuestNo : Integer;
      CurrentQuestNo : Integer;
      QuestStr       : array [0..20 - 1] of byte;
      FirstQuestNo : Integer;                                   // 초보마을용 quest값...

      JobKind        : byte;              // 직종
      ExtJobKind : Byte;
      CurExtJobExp : Integer;

      Person3        : array [0..20 - 1] of Byte;               // 사제이벤용...
      Person4        : array [0..20 - 1] of Byte;

      EventRecord    : array [0..20 - 1] of Byte;
      Dummy : array[0..66 - 1] of byte;
      CRCKey : Cardinal;
   end;
   PTDBRecord = ^TDBRecord;

  // add by Orber at 2004-11-04 20:05:21
   TCheckCharData  = packed record
      rCharData : TDBRecord;
      rEnd : Byte;
   end;

implementation

end.
