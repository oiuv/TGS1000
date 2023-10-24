unit uImage;

interface

uses
   Windows;

const
////	현재 아래의 4개 방식을 지원한다.
   AI_ECB = 1;
   AI_CBC = 2;
   AI_OFB = 3;
   AI_CFB = 4;

////	현재 아래의 두 padding을 지원한다.
   AI_NO_PADDING      = 1;  // Padding 없음(입력이 16바이트의 배수)
   AI_NO_PKCS_PADDING = 2;  // padding되는 바이트 수로 padding

////	AES에 관련된 상수들
   AES_BLOCK_LEN		 =	16;	//	in BYTEs
   AES_USER_KEY_LEN	 =	32;	//	(16,24,32) in BYTEs
   AES_NO_ROUNDS		 =	10;
   AES_NO_ROUNDKEY	 =	68;	//	in DWORDs

type
   RET_VAL = DWORD;

   AES_ALG_INFO = record
      ModeID:   DWORD;
      PadType:  DWORD;
      IV:       array[0..AES_BLOCK_LEN-1] of BYTE;
      ChainVar: array[0..AES_BLOCK_LEN-1] of BYTE;
      Buffer:   array[0..AES_BLOCK_LEN-1] of BYTE;
      BufLen:   DWORD;
      RoundKey: array[0..AES_NO_ROUNDKEY-1] of DWORD;
   end;

   TGetKeyProc = procedure (Key: PBYTE; var KeyLen: DWORD);

const
////	Error Code - 정리하고, 적당히 출력해야 함.
   CTR_SUCCESS				  = 0;
   CTR_FATAL_ERROR		  = $1001;
   CTR_INVALID_USERKEYLEN = $1002;	//	비밀키의 길이가 부적절함.
   CTR_PAD_CHECK_ERROR	  = $1003;	//
   CTR_DATA_LEN_ERROR	  = $1004;	//	평문의 길이가 부적절함.
   CTR_CIPHER_LEN_ERROR	  = $1005;	//	암호문이 블록의 배수가 아님.

////	데이타 타입 AES_ALG_INFO에 mode, padding 종류 및 IV 값을 초기화한다.
procedure _AES_SetAlgInfo(ModeID, PadType: DWORD; IV: PBYTE; var AlgInfo: AES_ALG_INFO); cdecl;

////	입력된 AES_USER_KEY_LEN바인트의 비밀키로 라운드 키 생성
function _AES_EncKeySchedule(UserKey: PBYTE; UserKeyLen: DWORD;
                            var AlgInfo: AES_ALG_INFO): RET_VAL; cdecl;
function _AES_DecKeySchedule(UserKey: PBYTE; UserKeyLen: DWORD;
                            var AlgInfo: AES_ALG_INFO): RET_VAL; cdecl;

////	Init/Update/Final 형식을 암호화.
function _AES_EncInit(var AlgInfo: AES_ALG_INFO): RET_VAL; cdecl;
function _AES_EncUpdate(var AlgInfo: AES_ALG_INFO;
                       PlainTxt: PBYTE; PlainTxtLen: DWORD;
                       CipherTxt: PBYTE; var CipherTxtLen: DWORD): RET_VAL; cdecl;
function _AES_EncFinal(var AlgInfo: AES_ALG_INFO;
                      CipherTxt: PBYTE; var CipherTxtLen: DWORD): RET_VAL; cdecl;

////	Init/Update/Final 형식을 복호화.
function _AES_DecInit(var AlgInfo: AES_ALG_INFO): RET_VAL; cdecl;
function _AES_DecUpdate(var AlgInfo: AES_ALG_INFO;
                       PlainTxt: PBYTE; PlainTxtLen: DWORD;
                       CipherTxt: PBYTE; var CipherTxtLen: DWORD): RET_VAL; cdecl;
function _AES_DecFinal(var AlgInfo: AES_ALG_INFO;
                      CipherTxt: PBYTE; var CipherTxtLen: DWORD): RET_VAL; cdecl;

procedure _AES_Encrypt(CipherKey: Pointer; Data: PBYTE); cdecl;
procedure _AES_Decrypt(CipherKey: Pointer; Data: PBYTE); cdecl;

procedure MyEncrypt(ModeType, PadType: DWORD;
                    Src, Dest: PByte; SrcLen: DWORD; var DstLen: DWORD);
procedure MyDecrypt(ModeType, PadType: DWORD;
                    Src, Dest: PByte; SrcLen: DWORD; var DstLen: DWORD);

function SetKey2: Boolean;
function SetKey3: Boolean;

implementation
{$L aes.obj}
{$L aesenc.obj}
{$L memcpy.obj}
{$L memset.obj}

var
   GetKeyReal: TGetKeyProc;
   boKeySetup: Boolean;

////	데이타 타입 AES_ALG_INFO에 mode, padding 종류 및 IV 값을 초기화한다.
procedure _AES_SetAlgInfo(ModeID, PadType: DWORD; IV: PBYTE; var AlgInfo: AES_ALG_INFO); cdecl; external;
////	입력된 AES_USER_KEY_LEN바인트의 비밀키로 라운드 키 생성
function _AES_EncKeySchedule(UserKey: PBYTE; UserKeyLen: DWORD;
                            var AlgInfo: AES_ALG_INFO): RET_VAL; external;

function _AES_DecKeySchedule(UserKey: PBYTE; UserKeyLen: DWORD;
                            var AlgInfo: AES_ALG_INFO): RET_VAL; external;

////	Init/Update/Final 형식을 암호화.
function _AES_EncInit(var AlgInfo: AES_ALG_INFO): RET_VAL; external;

function _AES_EncUpdate(var AlgInfo: AES_ALG_INFO;
                       PlainTxt: PBYTE; PlainTxtLen: DWORD;
                       CipherTxt: PBYTE; var CipherTxtLen: DWORD): RET_VAL; external;

function _AES_EncFinal(var AlgInfo: AES_ALG_INFO;
                      CipherTxt: PBYTE; var CipherTxtLen: DWORD): RET_VAL; external;

////	Init/Update/Final 형식을 복호화.
function _AES_DecInit(var AlgInfo: AES_ALG_INFO): RET_VAL; external;

function _AES_DecUpdate(var AlgInfo: AES_ALG_INFO;
                       PlainTxt: PBYTE; PlainTxtLen: DWORD;
                       CipherTxt: PBYTE; var CipherTxtLen: DWORD): RET_VAL; external;

function _AES_DecFinal(var AlgInfo: AES_ALG_INFO;
                      CipherTxt: PBYTE; var CipherTxtLen: DWORD): RET_VAL; external;

procedure _AES_Encrypt(CipherKey: Pointer; Data: PBYTE); external;

procedure _AES_Decrypt(CipherKey: Pointer; Data: PBYTE); external;

procedure GetKeyIV(Key: PBYTE; var KeyLen: DWORD;
                   IV: PBYTE;  var IVLen: DWORD);
const
   SampleKey: array[0..15] of BYTE = (
      $AF, $E7, $F3, $DE, $D6, $8F, $CA, $46,
      $3B, $F0, $B6, $EC, $44, $F2, $8A, $32
   );
   SampleIV: array[0..15] of BYTE = (
      $79, $3D, $19, $A5, $43, $39, $37, $52,
      $E3, $5A, $D5, $E2, $17, $81, $D4, $D5
   );
var
   i: integer;
begin
   for i := 0 to 15 do begin
      IV^ := SampleIV[i];
      Key^ := SampleKey[i];
      inc(Key); inc(IV);
   end;

   KeyLen := 16;
   IVLen := 16;
end;

procedure MyEncrypt(ModeType, PadType: DWORD;
                    Src, Dest: PByte; SrcLen: DWORD; var DstLen: DWORD);
var
   UserKey: array[0..AES_USER_KEY_LEN-1] of BYTE;
   IV: array[0..AES_BLOCK_LEN] of BYTE;
   UKLen, IVLen, TmpLen: DWORD;
   ret: RET_VAL;
   AlgInfo: AES_ALG_INFO;
begin
   GetKeyIV(@UserKey, UKLen, @IV, IVLen);
   _AES_SetAlgInfo(ModeType, PadType, @IV, AlgInfo);

   GetKeyReal(@UserKey, UKLen);

   ret := _AES_EncKeySchedule(@UserKey, UKLen, AlgInfo);
   if ret <> CTR_SUCCESS then exit;

   ret := _AES_EncInit(AlgInfo);
   if ret <> CTR_SUCCESS then exit;

   TmpLen := 1024;
   ret := _AES_EncUpdate(AlgInfo, Src, SrcLen, Dest, TmpLen);
   if ret <> CTR_SUCCESS then exit;
   DstLen := TmpLen;
   inc(Dest, DstLen);

   TmpLen := 1024;
   ret := _AES_EncFinal(AlgInfo, Dest, TmpLen);
   if ret <> CTR_SUCCESS then exit;
   inc(DstLen, TmpLen);
end;

procedure MyDecrypt(ModeType, PadType: DWORD;
                    Src, Dest: PByte; SrcLen: DWORD; var DstLen: DWORD);
var
   UserKey: array[0..AES_USER_KEY_LEN-1] of BYTE;
   IV: array[0..AES_BLOCK_LEN] of BYTE;
   UKLen, IVLen, TmpLen: DWORD;
   ret: RET_VAL;
   AlgInfo: AES_ALG_INFO;
begin
   GetKeyIV(@UserKey, UKLen, @IV, IVLen);
   _AES_SetAlgInfo(ModeType, PadType, @IV, AlgInfo);

   GetKeyReal(@UserKey, UKLen);

   ret := _AES_DecKeySchedule(@UserKey, UKLen, AlgInfo);
   if ret <> CTR_SUCCESS then exit;

   ret := _AES_DecInit(AlgInfo);
   if ret <> CTR_SUCCESS then exit;

   TmpLen := 1024;
   ret := _AES_DecUpdate(AlgInfo, Src, SrcLen, Dest, TmpLen);
   if ret <> CTR_SUCCESS then exit;
   DstLen := TmpLen;
   inc(Dest, DstLen);

   TmpLen := 1024;
   ret := _AES_DecFinal(AlgInfo, Dest, TmpLen);
   if ret <> CTR_SUCCESS then exit;
   inc(DstLen, TmpLen);
end;

procedure GetKey1(Key: PBYTE; var KeyLen: DWORD);
const
   nKeyLen = 16;
   SampleKey: array[0..nKeyLen-1] of BYTE = (
      $3B, $F0, $B6, $EC, $44, $F2, $8A, $32,
      $D3, $B5, $28, $5B, $59, $D0, $53, $2A
   );
var
   i: integer;
begin
   for i := 0 to nKeyLen-1 do begin
      Key^ := SampleKey[i];
      inc(Key);
   end;
   KeyLen := nKeyLen;
end;

procedure GetKey2(Key: PBYTE; var KeyLen: DWORD);
const
   nKeyLen = 24;
   SampleKey: array[0..nKeyLen-1] of BYTE = (
      $2C, $3E, $6F, $D4, $61, $F2, $42, $59,
      $1B, $43, $0F, $BB, $60, $A7, $CA, $B9,
      $24, $E8, $66, $D7, $3F, $D4, $BB, $8E
   );
var
   i: integer;
begin
   for i := 0 to nKeyLen-1 do begin
      Key^ := SampleKey[i];
      inc(Key);
   end;
   KeyLen := nKeyLen;

end;

procedure GetKey3(Key: PBYTE; var KeyLen: DWORD);
const
   nKeyLen = 16;
   SampleKey: array[0..nKeyLen-1] of BYTE = (
      $3F, $BE, $F0, $24, $DA, $E0, $51, $AD,
      $2B, $D5, $18, $1F, $E8, $9F, $4E, $31
   );
var
   i: integer;
begin
   for i := 0 to nKeyLen-1 do begin
      Key^ := SampleKey[i];
      inc(Key);
   end;
   KeyLen := nKeyLen;
end;

function SetKey2: Boolean;
begin
   GetKeyReal := GetKey2;
   Result := boKeySetup;
   boKeySetup := True;
end;

function SetKey3: Boolean;
begin
   GetKeyReal := GetKey3;
   Result := boKeySetup;
   boKeySetup := True;
end;

initialization
begin
   GetKeyReal := GetKey1;
   boKeySetup := False;
end;

end.

