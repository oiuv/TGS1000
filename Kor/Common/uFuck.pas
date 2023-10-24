unit uFuck;

interface

uses
   Windows, Classes, SysUtils;

function GetMacAddr: string;
function GetIpAddr: string;
function GetHostName: string;
function GetAdapterName: string;
function GetFingerPrint: string;

function MakeCode(Salt: Word; const strFingerPrint, strIdentifier: string): string;
function ExtractSalt(const strCode: string): Word;
function GetDefaultSalt: Word;

procedure WriteCode(const strCode: string);
function ReadCode: string;

implementation

uses
   WinSock, uImage, DateUtils, Registry;

const
   MAX_ADAPTER_ADDRESS_LENGTH = 8;
   MAX_ADAPTER_NAME_LENGTH = 256;
   MAX_ADAPTER_DESCRIPTION_LENGTH = 128;

type
   TTIME_T = array[1..189] of byte;

   TMacAddress = array[1..MAX_ADAPTER_ADDRESS_LENGTH] of byte;

   PTIP_ADDRESS_STRING = ^TIP_ADDRESS_STRING;
   TIP_ADDRESS_STRING = array[0..15] of char;

   PTIP_ADDR_STRING = ^TIP_ADDR_STRING;
   TIP_ADDR_STRING = packed record
      Next: PTIP_ADDR_STRING;
      IpAddress: TIP_ADDRESS_STRING;
      IpMask: TIP_ADDRESS_STRING;
      Context: DWORD;
   end;
   
   PTIP_ADAPTER_INFO = ^TIP_ADAPTER_INFO;
   TIP_ADAPTER_INFO = packed record
      Next: PTIP_ADAPTER_INFO;
      ComboIndex: DWORD;
      AdapterName: array[1..MAX_ADAPTER_NAME_LENGTH + 4] of char;
      Description: array[1..MAX_ADAPTER_DESCRIPTION_LENGTH + 4] of char;
      AddressLength: UINT;
      Address: TMacAddress;
      Index: DWORD;
      rType: UINT;
      DhcpEnabled: UINT;
      CurrentIpAddress: PTIP_ADDR_STRING;
      IpAddressList: TIP_ADDR_STRING;
      GatewayList: TIP_ADDR_STRING;
      DhcpServer: TIP_ADDR_STRING;
      HaveWins: LongBool;
      PrimaryWinsServer: TIP_ADDR_STRING;
      SecondaryWinsServer: TIP_ADDR_STRING;
      LeaseObtained: integer;
      LeaseExpires: integer;
   end;

function GetAdaptersInfo( pAdapterInfo: PTIP_ADAPTER_INFO; pOutBufLen: PULONG ): DWORD; stdcall; external 'IPHLPAPI.DLL';

function MacAddr2Str( MacAddr: array of byte; size: integer ): string;
var
   i: integer;
begin
   Result := '';
   if size = 0 then exit;

   for i := 0 to size-1 do begin
     Result := Result + IntToHex(MacAddr[i], 2);
   end;
end;

var
   pAdapterInfo: PTIP_ADAPTER_INFO;
   Error: DWORD;

function BuildAdapterInfo: DWORD;
var
   BufLen: DWORD;
begin
   BufLen := sizeof(TIP_ADAPTER_INFO);
   GetMem(pAdapterInfo, BufLen);

   if GetAdaptersInfo(pAdapterInfo, @BufLen) = ERROR_BUFFER_OVERFLOW then begin
      FreeMem(pAdapterInfo);
      GetMem(pAdapterInfo, BufLen);
   end;

   Error := GetAdaptersInfo(pAdapterInfo, @BufLen);
   Result := Error;
   SetKey2;
end;

procedure FreeAdapterInfo;
begin
   FreeMem(pAdapterInfo);
end;

function GetMacAddr: string;
begin
   Result := '';
   if Error = NO_ERROR then begin
      Result := MacAddr2Str(pAdapterInfo.Address, pAdapterInfo.AddressLength);
   end;
end;

function GetIPAddr: string;
begin
   Result := '';
   if Error = NO_ERROR then begin
      Result := StrPas(@pAdapterInfo.IpAddressList.IpAddress);
   end;
end;

function GetAdapterName: string;
begin
   Result := '';
   if Error = NO_ERROR then begin
      Result := StrPas(@pAdapterInfo.AdapterName);
   end;
end;

function GetHostName: string;
var
   temp: array[0..19] of char;
   len: integer;
   WSAData: TWSAData;
begin
   WSAStartup($0101, WSAData);
   len := 18;
   Result := '';
   FillChar(temp, 20, 0);
   if WinSock.gethostname(@temp, len) = 0 then begin
      Result := StrPas(@temp);
   end;
end;

function GetFingerPrint: string;
begin
   Result := GetHostName + ';' + GetMacAddr + ';' + GetIpAddr;
end;

type
  TBinCode = array[0..14] of byte;

function BinCodeToStr(var BinCode: TBinCode): string;
var
   i: integer;
   TempCode: int64;
   Code16: array[0..23] of byte;
begin
   FillChar(Code16, 16, 0);
   Move(BinCode[0], TempCode, 5);
   for i := 0 to 7 do begin
      Code16[7-i] := TempCode and 31;
      TempCode := TempCode shr 5;
   end;
   Move(BinCode[5], TempCode, 5);
   for i := 0 to 7 do begin
      Code16[15-i] := TempCode and 31;
      TempCode := TempCode shr 5;
   end;
   Move(BinCode[10], TempCode, 5);
   for i := 0 to 7 do begin
      Code16[23-i] := TempCode and 31;
      TempCode := TempCode shr 5;
   end;
   Result := '';
   for i := 0 to 23 do begin
      if Code16[i] > 9 then
         Result := Result + chr(Code16[i] + ord('A') - 10)
      else
         Result := Result + chr(Code16[i] + ord('0'));
   end;
end;

type
  SHA1_CTX = packed record
    state: array [0..4] of DWORD;  // state (ABCD)
    count: array [0..1] of DWORD;  // number of bits, modulo 2^64 (lsb first)
    buffer: array [0..63] of byte; // input buffer
  end;
  THashArray = array [0..63] of byte;

const
  PADDING: array [0..63] of byte = (
    $80, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
  );

// Note: Replace "for loop" with standard memcpy if possible.
procedure SHA1_memcpy(var output: array of byte; var input: array of byte; startA, startB, len: cardinal);
var
  i: cardinal;
begin
  for i:=1 to len do
    output[startA+i-1] := input[startB+i-1];
end;

// Note: Replace "for loop" with standard memset if possible.
procedure SHA1_memset(var output: array of byte; value: cardinal; start, len: cardinal);
var
  i: cardinal;
begin
  for i:=1 to len do
    output[start+i-1] := value;
end;

// Encodes input (UINT4) into output (unsigned char). Assumes len is
// a multiple of 4.
procedure Encode(var output: array of byte; var input: array of DWORD; len: cardinal);
var
  i, j: cardinal;
begin
  i := 0;
  j := 0;

  while (j<len) do
    begin
    output[j+3] := (input[i] AND $ff);
    output[j+2] := ((input[i] shr 8) AND $ff);
    output[j+1] := ((input[i] shr 16) AND $ff);
    output[j+0] := ((input[i] shr 24) AND $ff);
    inc(i);
    inc(j, 4);
    end;

end;

// Decodes input (unsigned char) into output (UINT4). Assumes len is
// a multiple of 4.
procedure Decode(var output: array of DWORD; var input: array of byte; len: cardinal);
var
  i, j: cardinal;
begin
  i := 0;
  j := 0;

  while (j<len) do begin
    output[i] := (input[j+3]) OR ((input[j+2]) shl 8) OR ((input[j+1]) shl 16) OR ((input[j+0]) shl 24);
    inc(i); inc(j, 4);
  end;
end;

// Rotate all bits, bits dropping off the end get wrapped round and reinserted
// onto the other end
function ROTL(x: DWORD; n: cardinal): DWORD;
begin
  Result := (x shl n) OR (x shr (32-n));
end;

function f(B, C, D: DWORD; t: integer): DWORD;
begin
  if (0 <= t) AND (t <= 19) then
    begin
    Result := (B AND C) OR ((NOT B) AND D);
    end
  else if (20 <= t) AND (t <= 39) then
    begin
    Result := B XOR C XOR D;
    end
  else if (40 <= t) AND (t <= 59) then
    begin
    Result := (B AND C) OR (B AND D) OR (C AND D);
    end
  else if (60 <= t) AND (t <= 79) then
    begin
    Result := B XOR C XOR D;
    end
  else
    begin
    Result := 0;
    end;
end;

function GetK(t: integer): DWORD;
begin
  if (0 <= t) AND (t <= 19) then
    begin
    Result := $5A827999;
    end
  else if (20 <= t) AND (t <= 39) then
    begin
    Result := $6ED9EBA1;
    end
  else if (40 <= t) AND (t <= 59) then
    begin
    Result := $8F1BBCDC;
    end
  else if (60 <= t) AND (t <= 79) then
    begin
    Result := $CA62C1D6;
    end
  else
    begin
    Result := 0;
    end;

end;

// SHA1 basic transformation. Transforms state based on block.
procedure SHA1Transform(var state: array of DWORD; block: array of byte; startOffsetInBlock: cardinal);
var
  A, B, C, D, E: DWORD;
  W: array [0..79] of DWORD;
  TEMP: DWORD;
  i: integer;
  t: integer;
begin
  Decode(W, block[startOffsetInBlock], 64);

  for t:=16 to 79 do
    begin
    // Note: The only difference between SHA and SHA1 is that SHA1 performs a
    // ROTL(..., 1) to W[t], while SHA does not.
    W[t] := ROTL(W[t-3] XOR W[t-8] XOR W[t-14] XOR W[t-16], 1);
    end;

  A := state[0];
  B := state[1];
  C := state[2];
  D := state[3];
  E := state[4];

  for t:=0 to 79 do begin
    TEMP := ROTL(A, 5) + f(B,C,D, t) + E + W[t] + GetK(t);

    E := D;
    D := C;
    C := ROTL(B, 30);
    B := A;
    A := TEMP;
  end;

  state[0] := state[0] + A;
  state[1] := state[1] + B;
  state[2] := state[2] + C;
  state[3] := state[3] + D;
  state[4] := state[4] + E;

  // Zeroize sensitive information.
//  SHA1_memset(x, 0, 0, high(x)+1);
//xxx
  for i:=0 to 79 do
    W[i] := 0;
end;

procedure SHA1Init (var context: SHA1_CTX);
begin
  context.count[0] := 0;
  context.count[1] := 0;
  // Load magic initialization constants.
  context.state[0] := $67452301;
  context.state[1] := $EFCDAB89;
  context.state[2] := $98BADCFE;
  context.state[3] := $10325476;
  context.state[4] := $C3D2E1F0;

end;

procedure SHA1Update(var context: SHA1_CTX; var input: array of byte; inputLen: cardinal);
var
  i, index, partLen: cardinal;
begin
  // Compute number of bytes mod 64
  index := ((context.count[0] shr 3) AND $3F);

  // Update number of bits
  context.count[0] := context.count[0] + (inputLen shl 3);

  if ((context.count[0]) < (inputLen shl 3)) then
    begin
    context.count[1] := context.count[1]+1;
    end;

  context.count[1] := context.count[1] + (inputLen shr 29);

  partLen := 64 - index;

  // Transform as many times as possible.
  if (inputLen >= partLen) then
    begin
    SHA1_memcpy(context.buffer, input, index, 0, partLen);
    SHA1Transform(context.state, context.buffer, 0);

    i:=partLen;
    while ((i+63) < inputLen) do
      begin
      SHA1Transform(context.state, input, i);
      inc(i, 64);
      end;

    index := 0;
    end
  else
    begin
    i := 0;
    end;

  // Buffer remaining input
  SHA1_memcpy(context.buffer, input, index, i, inputLen-i);

end;

procedure SHA1Final(var digest: THashArray; var context: SHA1_CTX);
var
  bits: array [0..7] of byte;
  index: cardinal;
  padLen: cardinal;
  highByteFirst: array [0..1] of DWORD;
  i: integer;
begin

  // Unlike MD5, SHA-1 uses the high word first
  highByteFirst[0] := context.count[1];
  highByteFirst[1] := context.count[0];

  // Save number of bits
  Encode(bits, highByteFirst, 8);

  // Pad out to 56 mod 64.
  index := ((context.count[0] shr 3) AND $3f);
  if (index < 56) then
    begin
    padLen := (56 - index);
    end
  else
    begin
    padLen := (120 - index);
    end;

  SHA1Update(context, PADDING, padLen);

  // Append length (before padding)
  SHA1Update(context, bits, 8);

  // Store state in digest
  Encode(digest, context.state, 20);

  // Zeroize sensitive information.
  for i:=low(context.state) to high(context.state) do
    begin
    context.state[i] := 0;
    end;
  for i:=low(context.count) to high(context.count) do
    begin
    context.count[i] := 0;
    end;
  SHA1_memset(context.buffer, 0, 0, high(context.buffer)+1);
end;

function MakeCode(Salt: Word; const strFingerPrint, strIdentifier: string): string;
var
  TmpData, UserKey: THashArray;
  SrcLen, DstLen: cardinal;
  Src: PByte;
  str: string;
  BinCode: TBinCode;
  i: Cardinal;

  function EncodeSHA1(const strData: string): THashArray;
  var
    digest: THashArray;
    tempStr: array [0..255] of byte;
    context: SHA1_CTX;
    i, len: cardinal;
  begin
    len := length(strData);
    for i:=1 to len do
      tempStr[i-1] := byte(strData[i]);

    SHA1Init(context);
    SHA1Update(context, tempStr, len);
    SHA1Final(digest, context);

    Result := digest;
  end;

  function EncodeAES(var UserKey: THashArray; const Identifier: string): THashArray;
  var
    IV: array[0..AES_BLOCK_LEN] of BYTE;
    UKLen, IVLen, TmpLen: DWORD;
    ret: RET_VAL;
    AlgInfo: AES_ALG_INFO;
    i: integer;
    ResultData, Src: THashArray;
    Dest: PByte;
  begin
    FillChar(Result, 64, 0);

    for i := 0 to 15 do
      IV[i] := ((i * 7) + (i * 13)) and 255;
    IVLen := 16;
    UKLen := 24;
    for i := 20 to 23 do
      UserKey[i] := ((i * 5) + (i * 17)) and 255;

    _AES_SetAlgInfo(AI_CBC, AI_NO_PKCS_PADDING, @IV, AlgInfo);
    ret := _AES_EncKeySchedule(@UserKey, UKLen, AlgInfo);
    if ret <> CTR_SUCCESS then exit;
    ret := _AES_EncInit(AlgInfo);
    if ret <> CTR_SUCCESS then exit;

    SrcLen := Length(strIdentifier);
    Src[0] := 77;
    for i := 1 to SrcLen do
      Src[i] := byte(strIdentifier[i]);
    SrcLen := SrcLen+1;
    TmpLen := 64;
    Dest := @ResultData;
    ret := _AES_EncUpdate(AlgInfo, @Src, SrcLen, Dest, TmpLen);
    if ret <> CTR_SUCCESS then exit;
    DstLen := TmpLen;
    inc(Dest, DstLen);

    TmpLen := 1024;
    ret := _AES_EncFinal(AlgInfo, Dest, TmpLen);
    if ret <> CTR_SUCCESS then exit;
    inc(DstLen, TmpLen);

    Result := ResultData;
  end;

begin
  Result := '';
  if Error <> NO_ERROR then exit;
  if Length(strFingerPrint) < 10 then exit;

  str := strFingerPrint;
  Insert(IntToStr(Salt), str, 10);
  Src := @str[1];

  UserKey := EncodeSHA1(str);
  Move(Salt, BinCode[10], 2);
  Move(Salt, BinCode[13], 2);
  TmpData := EncodeAES(UserKey, strIdentifier);
  Move(TmpData[0], BinCode[0], 10);
  Move(TmpData[11], BinCode[11], 3);
  Result := BinCodeToStr(BinCode);
end;

procedure StrToBinCode(const strCode: string; var BinCode: TBinCode);
var
   i: integer;
   TempCode: int64;
   Code16: array[0..23] of byte;
begin
   for i := 0 to 23 do begin
      if strCode[i+1] <= '9' then
         Code16[i] := Ord(strCode[i+1]) - Ord('0')
      else
         Code16[i] := Ord(strCode[i+1]) - Ord('A') + 10;
   end;
   TempCode := 0;
   for i := 0 to 7 do begin
      TempCode := TempCode shl 5;
      TempCode := TempCode + Code16[i];
   end;
   Move(TempCode, BinCode[0], 5);
   TempCode := 0;
   for i := 8 to 15 do begin
      TempCode := TempCode shl 5;
      TempCode := TempCode + Code16[i];
   end;
   Move(TempCode, BinCode[5], 5);
   TempCode := 0;
   for i := 16 to 23 do begin
      TempCode := TempCode shl 5;
      TempCode := TempCode + Code16[i];
   end;
   Move(TempCode, BinCode[10], 5);
end;

function ExtractSalt(const strCode: string): Word;
var
   BinCode: TBinCode;
begin
   Result := 0;
   if Length(strCode) <> 24 then exit;
   StrToBinCode(strCode, BinCode);
   Result := BinCode[14] * 256 + BinCode[10];
end;

function GetDefaultSalt: Word;
var
   Year, Day: Word;
begin
   DecodeDateDay(Date, Year, Day);
   Result := (Year - 2000) * 400 + Day;
end;

procedure BinCodeXOR(var BinCode: TBinCode; Value: Byte);
var
   i: integer;
begin
   for i := 0 to 14 do begin
      BinCode[i] := BinCode[i] xor Value;
   end;
end;

procedure WriteCode(const strCode: string);
var
   Reg: TRegistry;
   strKey: string;
   BinCode: TBinCode;
begin
   Reg := TRegistry.Create;
   Reg.RootKey := HKEY_CLASSES_ROOT;
   strKey := '\CLSID\' + GetAdapterName;

   Reg.OpenKey(strKey, True);
   StrToBinCode(strCode, BinCode);
   BinCodeXOR(BinCode, 85);
   Reg.WriteBinaryData('', BinCode[0], 15);
   Reg.CloseKey;

   Reg.Free;
end;

function ReadCode: string;
var
   Reg: TRegistry;
   strKey: string;
   BinCode: TBinCode;
begin
   Reg := TRegistry.Create;
   Reg.RootKey := HKEY_CLASSES_ROOT;
   strKey := '\CLSID\' + GetAdapterName;

   Result := '';
   if not Reg.KeyExists(strKey) then exit;
   Reg.OpenKey(strKey, True);
   Reg.ReadBinaryData('', BinCode[0], 15);
   BinCodeXOR(BinCode, 85);
   Result := BinCodeToStr(BinCode);
   Reg.CloseKey;

   Reg.Free;
end;

initialization
begin
   Error := BuildAdapterInfo;
end;

finalization
begin
   FreeAdapterInfo;
end;

end.




