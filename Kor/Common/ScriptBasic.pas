unit ScriptBasic;

interface

uses
  Windows, SysUtils, Classes, aUtil32;

type
  TTokenIdent = (ti_none, ti_name, ti_semicolon, ti_colon,
     ti_comma, ti_variabletype,

     ti_startparam, ti_endparam,
     ti_if, ti_then, ti_notequal, ti_equal, ti_large, ti_small, ti_largeequal, ti_smallequal,

     ti_substitution, ti_plus, ti_minus, ti_mul, ti_div, ti_mod,

     ti_result
     );

  PTTokenIdent = ^TTokenIdent;

  TVariableType = (vt_none, vt_integer, vt_string, vt_boolean);


  TVariableData = record
    rName: string[32];
    rVariabletype : TVariableType;
    rString : string[128];
    rInteger: integer;
    rBoolean : Boolean;
    rboConstant : Boolean;
  end;
  PTVariableData = ^TVariableData;

  TScriptStack = class  // 파라미터 때문에 생김
   private
    DataList : TList;
   public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure Push (var VariableData: TVariableData);
    procedure Pop (var VariableData: TVariableData);
  end;

  TScriptParser = class
   private
    FBufferStr : string;
    FPosition : integer;
    FBufferLength : integer;
    FCurrentLine : integer;
    procedure SkipBlank;
    function  ViewByte: char;
    function  ViewNextByte: char;
    function  GetByte: char;
    function  GetConstString: string;

    function  isSkipChar (c : char): Boolean;
    function  isOneParserChar (c1: char): Boolean;
    function  isTwoParserChar (c1, c2: char): Boolean;
   public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure LoadFromFile (aFileName: string);
    procedure LoadFromStream (aStream: TStream);
    function  GetToken: string;
    function  ViewToken: string;
    property  CurrentLine : integer read FCurrentLine;
  end;

  TLineTokenClass = class
   private
    BeginCount : integer;
    LastToken : string;
    TokenList : TStringList;
    IdentList : TList;
    function IsEnded: Boolean;
    function GetCount: integer;
    function GetToken (aindex: integer): string;
    function GetIdent (aindex: integer): TTokenIdent;
   public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function  Add (atoken: string): TTokenIdent;
    procedure Delete (aindex: integer);
    procedure DeletebyToken (atoken: string);
    function  GetTokenIndex (atoken: string): integer;
//    function  GetCenterTokens (stoken, etoken: string): string;

    function  GetParamsCount: integer;
    function  GetResult: string;

    property Tokens[Index: Integer]: string read GetToken;
    property Idents[Index: Integer]: TTokenIdent read GetIdent;
    property Ended: Boolean read isEnded;
    property Count: integer read GetCount;
  end;

  TIntegerStack = class  // 파라미터 때문에 생김
   private
    DataList : TList;
   public
    constructor Create;
    destructor Destroy; override;
    function  Push (var aInt: integer): Boolean;
    function  Pop (var aInt: integer): Boolean;
  end;

  TScriptLine = class
   private
    StringList : TStringList;
    FEnded: Boolean;
    function  GetCount: integer;
    procedure Clear;
   public
    constructor Create;
    destructor Destroy; override;
    procedure AddToken (aToken: string);
    procedure DeleteToken (aIndex: integer);
    function  View (aIndex: integer): string;
    function  IsToken (aToken: string): Boolean;
    property Count : integer read GetCount;
    property Ended : Boolean read FEnded;
  end;


  TScriptSection = class
   private
    FPosition : integer;
    FScriptLine : TScriptLine;
    StringList : TStringList;

    procedure SetPosition (aPosition: integer);
    function  GetCount: integer;
   public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure AddToken (atoken: string);
    procedure DeleteToken (aIndex: integer);
    procedure InsertToken (aIndex: integer; atoken: string);
    procedure LoadFromScriptParser (aParser: TScriptParser; aEndTokens: array of string);
    procedure LoadFromScriptSection (aSection: TScriptSection; aEndTokens: array of string);
    function  GetToken: string;
    function  ViewToken: string;
    procedure LoadLine (aLine: integer);
    function  GetLineCount: integer;

    property  Line : TScriptLine read FScriptLine;
    property  Position : integer read FPosition write SetPosition;
    property  Count : integer read GetCount;
  end;

  function  GetTypebyString (astr: string): TVariableType;
  function  isConstantToken (astr: string): Boolean;
  function  isIntegerConstant (astr: string): Boolean;
  function  isCharConstant (astr: string): Boolean;
  function  CompareIdent (pfir, psec: PTTokenIdent; acount: integer): Boolean;
  function  GetTokenIdent (atoken: string): TTokenIdent;

type
  TInterfaceDefineType = (idef_none, idef_integer, idef_string, idef_boolean, idef_procedure, idef_ifunction, idef_sfunction, idef_bfunction);

  TInterfaceDefineData = record
    rName : string[32];
    rtype : TInterfaceDefineType;
    rDecriptString : string [255];
  end;
  PTInterfaceDefineData = ^TInterfaceDefineData;

  TInterfaceDefineClass = class
   private
    DataList : TList;
   public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    function  GetDefineType (aName: string): TInterfaceDefineType;
    function  Add (aName, aDecriptString: string; atype: TInterfaceDefineType): Boolean;
  end;

var
   gScriptStack : TScriptStack;

implementation


constructor TInterfaceDefineClass.Create;
begin
   DataList := TList.Create;
end;

destructor TInterfaceDefineClass.Destroy;
begin
   Clear;
   DataList.Free;
   inherited Destroy;
end;

procedure TInterfaceDefineClass.Clear;
var i : integer;
begin
   for i := 0 to DataList.Count -1 do dispose (DataList[i]);
   DataList.Clear;
end;

function  TInterfaceDefineClass.GetDefineType (aName: string): TInterfaceDefineType;
var i: integer;
begin
   Result := idef_none;
   for i := 0 to DataList.Count -1 do begin
      if PTInterfaceDefineData (DataList[i])^.rName = aName then begin
         Result := PTInterfaceDefineData (DataList[i])^.rtype;
         exit;
      end;
   end;
end;

function  TInterfaceDefineClass.Add (aName, aDecriptString: string; atype: TInterfaceDefineType): Boolean;
var p : PTInterfaceDefineData;
begin
   Result := FALSE;
   if GetDefineType (aName) <> idef_none then exit;
   if Length (aDecriptString) > 254 then aDecriptString := Copy (aDecriptString, 1, 254);
   
   new (p);
   p^.rName := aName;
   p^.rtype := aType;
   p^.rDecriptString := aDecriptString;
   DataList.Add (p);
   Result := TRUE;
end;

////////////////////////////////
//
///////////////////////////////
constructor TScriptLine.Create;
begin
   StringList := TStringList.Create;
   FEnded := FALSE;
end;

destructor TScriptLine.Destroy;
begin
   Clear;
   StringList.Free;
   inherited Destroy;
end;

procedure TScriptLine.Clear;
begin
   FEnded := FALSE;
   StringList.Clear;
end;

procedure TScriptLine.AddToken (aToken: string);
begin
   StringList.Add (aToken);
   if aToken = ';' then FEnded := TRUE;
end;

procedure TScriptLine.DeleteToken (aIndex: integer);
begin
   if (aIndex < 0) or (aIndex >= StringList.Count) then exit;
   StringList.Delete (aIndex);
end;

function  TScriptLine.IsToken (aToken: string): Boolean;
var i: integer;
begin
   Result := FALSE;
   for i := 0 to StringList.Count -1 do if StringList[i] = aToken then Result := TRUE;
end;

function  TScriptLine.GetCount: integer;
begin
   Result := StringList.Count;
end;

function  TScriptLine.View (aIndex: integer): string;
begin
   Result := '';
   if (aIndex < 0) or (aIndex >= StringList.Count) then exit;
   Result := StringList[aindex];
end;

//////////////////////////////////
//
//////////////////////////////////
constructor TScriptSection.Create;
begin
   FPosition := 0;
   StringList := TStringList.Create;
   FScriptLine := TScriptLine.Create;
end;

destructor TScriptSection.Destroy;
begin
   Clear;
   FScriptLine.Free;
   StringList.Free;
   inherited Destroy;
end;

procedure TScriptSection.Clear;
begin
   FPosition := 0;
   StringList.Clear;
   FScriptLine.Clear;
end;

function  TScriptSection.GetLineCount: integer;
var i: integer;
begin
   Result := 0;
   if StringList.Count = 0 then exit;
   for i := 0 to StringList.Count -1 do if StringList[i] = ';' then inc (Result);
   if StringList[StringList.Count-1] <> ';' then inc (Result);
end;

procedure TScriptSection.LoadLine (aLine: integer);
var
   i, CurLine, SavePosition: integer;
   str: string;
begin
   SavePosition := FPosition;
   CurLine := 0;
   for i := 0 to StringList.Count -1 do begin
      FPosition := i;
      if CurLine = aLine then break;
      if StringList[i] = ';' then inc (CurLine);
   end;

   FScriptLine.Clear;
   while TRUE do begin
      str := GetToken;
      if str = '' then break;
      FScriptLine.AddToken (str);
      if FScriptLine.Ended then break;
   end;

   FPosition := SavePosition;
end;

function  TScriptSection.GetCount: integer;
begin
   Result := StringList.Count;
end;

procedure TScriptSection.LoadFromScriptParser (aParser: TScriptParser; aEndTokens: array of string);
var
   i, nParam : integer;
   str: string;
begin
   Clear;
   nParam := High (aEndTokens)+1;
   while TRUE do begin
      str := aParser.ViewToken;
      if str = '' then exit;
      for i := 0 to nParam-1 do if str = aEndTokens[i] then exit;
      str := aParser.GetToken;
      AddToken (str);
   end;
end;

procedure TScriptSection.LoadFromScriptSection (aSection: TScriptSection; aEndTokens: array of string);
var
   i, nParam : integer;
   str: string;
begin
   Clear;
   nParam := High (aEndTokens)+1;
   while TRUE do begin
      str := aSection.ViewToken;
      if str = '' then exit;
      for i := 0 to nParam-1 do if str = aEndTokens[i] then exit;
      str := aSection.GetToken;
      AddToken (str);
   end;
end;

procedure TScriptSection.AddToken (atoken: string);
begin
   StringList.Add (aToken);
end;

procedure TScriptSection.DeleteToken (aIndex: integer);
begin
   if (aIndex < 0) or (aIndex >= StringList.Count) then exit;
   StringList.Delete (aIndex);
end;

procedure TScriptSection.InsertToken (aIndex: integer; atoken: string);
begin
   if (aIndex < 0) or (aIndex >= StringList.Count) then exit;
   StringList.Insert (aIndex, atoken);
end;

procedure TScriptSection.SetPosition (aPosition: integer);
begin
   if (aPosition < 0) or (aPosition >= StringList.Count) then exit;
   FPosition := aPosition;
end;

function  TScriptSection.GetToken: string;
begin
   Result := '';
   if (FPosition < 0) or (FPosition >= StringList.Count) then exit;
   Result := StringList[FPosition];
   inc (FPosition);
end;

function  TScriptSection.ViewToken: string;
begin
   Result := '';
   if (FPosition < 0) or (FPosition >= StringList.Count) then exit;
   Result := StringList[FPosition];
end;


/////////////////////////////////
//        TIntegerStack        //
/////////////////////////////////
constructor TIntegerStack.Create;
begin
   DataList := TList.Create;
end;

destructor TIntegerStack.Destroy;
begin
   DataList.Free;
   inherited Destroy;
end;

function  TIntegerStack.Push (var aInt: integer): Boolean;
begin
   DataList.Add (Pointer (aInt));
   Result := TRUE;
end;

function  TIntegerStack.Pop (var aInt: integer): Boolean;
begin
   Result := FALSE;
   if DataList.Count = 0 then exit;
   aInt := integer (DataList [ DataList.Count -1]);
   DataList.Delete (DataList.Count -1);
   Result := TRUE;
end;



function  GetTypebyString (astr: string): TVariableType;
begin
   Result := vt_none;
   if astr = 'boolean' then Result := vt_Boolean
   else if astr = 'integer' then Result := vt_integer
   else if astr = 'string' then Result := vt_string;

//   if Result = vt_none then raise Exception.Create('GetTypeByString: None Tyep');
end;

function  CompareIdent (pfir, psec: PTTokenIdent; acount: integer): Boolean;
var i: integer;
begin
   Result := FALSE;
   for i := 0 to aCount-1 do begin
      if pfir^ <> psec^ then exit;
      inc (pfir); inc (psec);
   end;
   Result := TRUE;
end;

function  GetTokenIdent (atoken: string): TTokenIdent;
begin
   Result := ti_name;
   if atoken = 'if' then Result := ti_if
   else if atoken = 'then' then Result := ti_then
   else if atoken = 'result' then Result := ti_result

   else if atoken = '>' then Result := ti_large
   else if atoken = '<' then Result := ti_small
   else if atoken = '>=' then Result := ti_largeequal
   else if atoken = '<=' then Result := ti_smallequal
   else if atoken = '<>' then Result := ti_notequal
   else if atoken = '=' then Result := ti_equal

   else if atoken = ':=' then Result := ti_substitution
   else if atoken = ':' then Result := ti_colon
   else if atoken = ',' then Result := ti_comma
   else if atoken = '+' then Result := ti_plus
   else if atoken = '-' then Result := ti_minus
   else if atoken = '*' then Result := ti_mul
   else if atoken = '/' then Result := ti_div
   else if atoken = 'mod' then Result := ti_mod
   else if atoken = 'div' then Result := ti_div

   else if atoken = ';' then Result := ti_semicolon
   else if atoken = '(' then Result := ti_startparam
   else if atoken = ')' then Result := ti_endparam;
   if GetTypebyString (atoken) <> vt_none then Result := ti_variabletype;
end;

///////////////////////////////////
//       델파이 Script
///////////////////////////////////
constructor TLineTokenClass.Create;
begin
   TokenList := TStringList.Create;
   IdentList := TList.Create;
   BeginCount := 0; LastToken := '';
end;

destructor TLineTokenClass.Destroy;
begin
   Clear;
   TokenList.Free;
   IdentList.Free;
   inherited Destroy;
end;

procedure TLineTokenClass.Clear;
begin
   TokenList.Clear;
   IdentList.Clear;
   BeginCount := 0; LastToken := '';
end;

function TLineTokenClass.GetCount: integer;
begin
   Result := TokenList.Count;
end;

function TLineTokenClass.IsEnded: Boolean;
begin
   if (LastToken = ';') and (BeginCount = 0) then Result := TRUE
   else Result := FALSE;
end;

function  TLineTokenClass.GetTokenIndex (atoken: string): integer;
var i: integer;
begin
   Result := -1;
   for i := 0 to TokenList.Count-1 do begin
      if TokenList[i] = atoken then begin
         Result := i;
         exit;
      end;
   end;
end;

function  TLineTokenClass.GetToken (aindex: integer): string;
begin
   if (aindex >= TokenList.Count) or (aindex < 0) then Result := ''
   else Result := TokenList[aindex];
end;

function TLineTokenClass.GetIdent (aindex: integer): TTokenIdent;
begin
   if (aindex >= IdentList.Count) or (aindex < 0) then Result := ti_none
   else Result := TTokenIdent (IdentList[aindex]);
end;

function TLineTokenClass.Add (atoken: string): TTokenIdent;
begin
   if atoken = 'begin' then inc (BeginCount)
   else if atoken = 'end' then dec (BeginCount);
   LastToken := atoken;
   TokenList.Add (atoken);
   Result := GetTokenIdent (atoken);
   IdentList.Add (Pointer(Result));
end;

procedure TLineTokenClass.Delete (aindex: integer);
begin
   if (aindex >= TokenList.Count) or (aindex < 0) then exit;
   TokenList.Delete (aIndex);
   IdentList.Delete (aIndex);
end;

procedure TLineTokenClass.DeletebyToken (atoken: string);
var i: integer;
begin
   for i := TokenList.Count -1 downto 0 do begin
      if TokenList[i] = atoken then begin
         TokenList.Delete (i);
         IdentList.Delete (i);
      end;
   end;
end;

const
   sadd_ident : array [0..6-1] of TTokenIdent = (ti_name, ti_substitution, ti_name, ti_plus, ti_name, ti_semicolon);
   ssub_ident : array [0..6-1] of TTokenIdent = (ti_name, ti_substitution, ti_name, ti_minus, ti_name, ti_semicolon);
   smul_ident : array [0..6-1] of TTokenIdent = (ti_name, ti_substitution, ti_name, ti_mul, ti_name, ti_semicolon);
   sdiv_ident : array [0..6-1] of TTokenIdent = (ti_name, ti_substitution, ti_name, ti_div, ti_name, ti_semicolon);
   smod_ident : array [0..6-1] of TTokenIdent = (ti_name, ti_substitution, ti_name, ti_mod, ti_name, ti_semicolon);

   snotequal_ident : array [0..6-1] of TTokenIdent = (ti_name, ti_substitution, ti_name, ti_notequal, ti_name, ti_semicolon);
   sequal_ident : array [0..6-1] of TTokenIdent = (ti_name, ti_substitution, ti_name, ti_equal, ti_name, ti_semicolon);
   slarge_ident : array [0..6-1] of TTokenIdent = (ti_name, ti_substitution, ti_name, ti_large, ti_name, ti_semicolon);
   ssmall_ident : array [0..6-1] of TTokenIdent = (ti_name, ti_substitution, ti_name, ti_small, ti_name, ti_semicolon);
   slargeequal_ident : array [0..6-1] of TTokenIdent = (ti_name, ti_substitution, ti_name, ti_largeequal, ti_name, ti_semicolon);
   ssmallequal_ident : array [0..6-1] of TTokenIdent = (ti_name, ti_substitution, ti_name, ti_smallequal, ti_name, ti_semicolon);

   smov_ident : array [0..4-1] of TTokenIdent = (ti_name, ti_substitution, ti_name, ti_semicolon);
   sret_ident : array [0..4-1] of TTokenIdent = (ti_result, ti_substitution, ti_name, ti_semicolon);

function  TLineTokenClass.GetResult: string;
var
   i : integer;
   tiArr : array [0..10-1] of TTokenIdent;
begin
   Result := '';
   FillChar (tiArr, sizeof(tiArr), 0);
   for i := 0 to Count -1 do tiArr[i] := Idents[i];

   if CompareIdent (@tiArr, @sadd_ident, 6) then Result := format ('#add %s %s %s',[Tokens[0], Tokens[2], Tokens[4]]);
   if CompareIdent (@tiArr, @ssub_ident, 6) then Result := format ('#sub %s %s %s',[Tokens[0], Tokens[2], Tokens[4]]);
   if CompareIdent (@tiArr, @smul_ident, 6) then Result := format ('#mul %s %s %s',[Tokens[0], Tokens[2], Tokens[4]]);
   if CompareIdent (@tiArr, @sdiv_ident, 6) then Result := format ('#div %s %s %s',[Tokens[0], Tokens[2], Tokens[4]]);
   if CompareIdent (@tiArr, @smod_ident, 6) then Result := format ('#mod %s %s %s',[Tokens[0], Tokens[2], Tokens[4]]);

   if CompareIdent (@tiArr, @snotequal_ident, 6) then Result := format ('#notequal %s %s %s',[Tokens[0], Tokens[2], Tokens[4]]);
   if CompareIdent (@tiArr, @sequal_ident, 6) then Result := format ('#equal %s %s %s',[Tokens[0], Tokens[2], Tokens[4]]);
   if CompareIdent (@tiArr, @slarge_ident, 6) then Result := format ('#large %s %s %s',[Tokens[0], Tokens[2], Tokens[4]]);
   if CompareIdent (@tiArr, @ssmall_ident, 6) then Result := format ('#small %s %s %s',[Tokens[0], Tokens[2], Tokens[4]]);
   if CompareIdent (@tiArr, @slargeequal_ident, 6) then Result := format ('#largeequal %s %s %s',[Tokens[0], Tokens[2], Tokens[4]]);
   if CompareIdent (@tiArr, @ssmallequal_ident, 6) then Result := format ('#smallequal %s %s %s',[Tokens[0], Tokens[2], Tokens[4]]);

   if CompareIdent (@tiArr, @smov_ident, 4) then Result := format ('#mov %s %s',[Tokens[0], Tokens[2]]);
   if CompareIdent (@tiArr, @sret_ident, 4) then Result := format ('#result %s',[Tokens[2]]);
end;

function  TLineTokenClass.GetParamsCount: integer;
var
   i: integer;
   boStarted: Boolean;
begin
   Result := 0;
   boStarted := FALSE;
   for i := 0 to TokenList.Count -1 do begin
      if TokenList[i] = ',' then continue;
      if TokenList[i] = '(' then begin boStarted := TRUE; continue; end;
      if TokenList[i] = ')' then begin boStarted := FALSE; continue; end;
      if boStarted then inc (Result);
   end;
end;

////////////////////////////////////////////////

function isConstantToken (astr: string): Boolean;
begin
   Result := FALSE;
   if astr = '' then exit;
   if astr[1] = '''' then Result := TRUE;
   if (astr[1] >= '0') and (astr[1] <= '9') then Result := TRUE;
   if (astr = 'true') or (astr = 'false') then Result := TRUE;
end;

function  isIntegerConstant (astr: string): Boolean;
begin
   Result := FALSE;
   if astr = '' then exit;
   if (astr[1] >= '0') and (astr[1] <= '9') then Result := TRUE;
end;

function  isCharConstant (astr: string): Boolean;
begin
   Result := FALSE;
   if astr = '' then exit;
   if astr[1] = '''' then Result := TRUE;
end;

///////////////////////////////////////////////////////////
function GetCenterStr (astr: string; sc, ec: char): string;
var i, sn, en: integer;
begin
   Result := '';
   sn := 0; en := 0;
   for i := 1 to Length (astr) do if sc = astr[i] then begin sn := i; break; end;
   for i := Length (astr) downto 1 do if ec = astr[i] then begin en := i; break; end;

   if (sn = 0) or (en = 0) then exit;
   Result := Copy (astr, sn+1, en-1-sn);
end;

/////////////////////////////////
//        TScriptParser        //
/////////////////////////////////
constructor TScriptParser.Create;
begin
   FBufferStr := '';
   FPosition := 1;
   FBufferLength := 0;
   FCurrentLine := 1;
end;

destructor TScriptParser.Destroy;
begin
   inherited Destroy;
end;

function  TScriptParser.isSkipChar (c : char): Boolean;
begin
   Result := FALSE;
   if c = ' ' then Result := TRUE;
   if c = #9 then Result := TRUE;
   if c = #13 then Result := TRUE;
end;

procedure TScriptParser.Clear;
begin
   FBufferStr := '';
   FPosition := 1;
   FBufferLength := 0;
   FCurrentLine := 1;
end;

// TwoParserchar 가 먼저 실행되어야됨
function  TScriptParser.isOneParserChar (c1: char): Boolean;
begin
   Result := FALSE;
   if c1 = ':' then Result := TRUE;
   if c1 = ';' then Result := TRUE;
//   if c1 = '.' then Result := TRUE;

   if c1 = ',' then Result := TRUE;

   if c1 = '(' then Result := TRUE;
   if c1 = ')' then Result := TRUE;

   if c1 = '=' then Result := TRUE;
   if c1 = '>' then Result := TRUE;
   if c1 = '<' then Result := TRUE;

   if c1 = '+' then Result := TRUE;
   if c1 = '-' then Result := TRUE;
   if c1 = '/' then Result := TRUE;
   if c1 = '*' then Result := TRUE;
end;

function  TScriptParser.isTwoParserChar (c1, c2: char): Boolean;
begin
   Result := FALSE;
   if (c1 = ':') and (c2 = '=') then Result := TRUE;    // 대입
   if (c1 = '<') and (c2 = '>')  then Result := TRUE;   // 같지안다
   if (c1 = '>') and (c2 = '=')  then Result := TRUE;   // 같지안다
   if (c1 = '<') and (c2 = '=')  then Result := TRUE;   // 같지안다
end;

function  TScriptParser.GetConstString: string;
var
   i : integer;
   c : char;
begin
   Result := GetByte;
   for i := 0 to 64-1 do begin
      c := GetByte;
      Result := Result + c;
      if c = '''' then exit;
   end;
end;

// 주석문 : //, { }, (* *),
procedure TScriptParser.SkipBlank;
var c1, c2: char;
begin
   while TRUE do begin
      c1 := ViewByte;
      if isSkipChar (c1) then begin GetByte; continue; end;
      c2 := ViewNextByte;
      if c1 = char (0) then break;
      if (c1 = '/') and (c2 = '/') then begin
         Getbyte; GetByte;
         while (ViewByte <> #13) do GetByte;
         continue;
      end;
      if isSkipChar (c1) then GetByte
      else break;
   end;
end;

function  TScriptParser.GetByte: char;
var c: char;
begin
   if FPosition > FBufferLength then begin Result := char (0); exit; end;
   c := FBufferStr[FPosition];
   inc (FPosition);
   if c = #13 then inc (FCurrentLine); 
   Result := c;
end;

function TScriptParser.ViewByte: char;
begin
   if FPosition > FBufferLength then begin Result := char (0); exit; end;
   Result := FBufferStr[FPosition];
end;

function TScriptParser.ViewNextByte: char;
begin
   if (FPosition +1) > FBufferLength then begin Result := char (0); exit; end;
   Result := FBufferStr[FPosition+1];
end;

procedure TScriptParser.LoadFromFile (aFileName: string);
var Stream : TFileStream;
begin
   if not FileExists (aFileName) then exit;
   Stream := TFileStream.Create (aFileName, fmOpenRead);
   LoadFromStream (Stream);
   Stream.Free;
end;

procedure TScriptParser.LoadFromStream (aStream: TStream);
var
   i : integer;
   StringList : TStringList;
begin
   StringList := TStringList.Create;
   StringList.LoadFromStream (aStream);

   FBufferStr := '';
   for i := 0 to StringList.Count -1 do FBufferStr := FBufferStr + StringList[i] + #13;
   FBufferLength := Length (FBufferStr);
   FPosition := 1;
   FCurrentLine := 1;

   StringList.Free;
end;

function  TScriptParser.GetToken: string;
var
   c1, c2 : char;
   retstr: string;
begin
   SkipBlank;

   retstr := '';

   while TRUE do begin
      c1 := ViewByte;
      c2 := ViewNextByte;
      if c1 = Char (0) then break;

      if c1 = '''' then begin
         if retstr = '' then retstr := GetConstString;
         break;
      end;

      if isSkipChar (c1) then break;

      if isTwoParserChar (c1, c2) then begin
         if retstr = '' then retstr := GetByte + GetByte;
         break;
      end;
      
      if isOneParserChar (c1) then begin
         if retstr = '' then retstr := GetByte;
         break;
      end;
      retstr := retstr + GetByte;
   end;
   if retstr <> '' then if retstr[1] <> '''' then retstr := lowercase (retstr);
   
   Result := retstr;
end;

function  TScriptParser.ViewToken: string;
var SaveLine, SavePosition : integer;
begin
   SaveLine := FCurrentLine;
   SavePosition := FPosition;

   Result := GetToken;

   FCurrentLine := SaveLine;
   FPosition := SavePosition;
end;


////////////////////////////////
//       TScriptStack         //
////////////////////////////////
constructor TScriptStack.Create;
begin
   DataList := TList.Create;
end;

destructor TScriptStack.Destroy;
begin
   Clear;
   DataList.Free;
   inherited Destroy;
end;

procedure TScriptStack.Clear;
var i: integer;
begin
   for i := 0 to DataList.Count -1 do dispose (DataList[i]);
   DataList.Clear;
end;

procedure TScriptStack.Push (var VariableData: TVariableData);
var
   p : PTVariableData;
begin
   new (p);
   p^ := VariableData;
   DataList.add (p);
end;

procedure TScriptStack.Pop (var VariableData: TVariableData);
var
   p : PTVariableData;
begin
   p := DataList [DataList.Count - 1];
   VariableData := p^;
   Dispose (p);
   DataList.delete (DataList.Count - 1);
end;

initialization
begin
   gScriptStack := TScriptStack.Create;
end;

finalization
begin
   gScriptStack.Free;
end;

end.


