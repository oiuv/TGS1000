program tgs1000;

uses
  Forms,
  SVMain in 'SVMain.pas' {FrmMain},
  UUser in 'UUser.pas',
  svClass in 'svClass.pas',
  fieldmsg in 'fieldmsg.pas',
  BasicObj in 'BasicObj.pas',
  MapUnit in 'MapUnit.pas',
  SubUtil in 'SubUtil.pas',
  uSendCls in 'uSendCls.pas',
  uMonster in 'uMonster.pas',
  uNpc in 'uNpc.pas',
  uUserSub in 'uUserSub.pas',
  uGuild in 'uGuild.pas',
  FSockets in 'FSockets.pas' {FrmSockets},
  uGuildSub in 'uGuildSub.pas',
  uLetter in 'uLetter.pas',
  uAIPath in 'uAIPath.pas',
  uManager in 'uManager.pas',
  uSkills in 'uSkills.pas',
  FGate in 'FGate.pas' {frmGate},
  uGConnect in 'uGConnect.pas',
  uConnect in 'uConnect.pas',
  uItemLog in 'uItemLog.pas',
  uDoorGen in 'uDoorGen.pas',
  uMopSub in 'uMopSub.pas',
  uObjectEvent in 'uObjectEvent.pas',
  uItemDeal in 'uItemDeal.pas',
  uEvent in 'uEvent.pas',
  uScriptManager in 'uScriptManager.pas',
  uWorkBox in 'uWorkBox.pas',
  FTrace in 'FTrace.pas' {frmTrace},
  FLog in 'FLOg.pas' {frmLog},
  uArena in 'uArena.pas',
  uZhuang in 'uZhuang.pas',
  deftype in '.\Kor\1000ydef\deftype.pas',
  uCharCheck in '.\Kor\Common\uCharCheck.pas',
  uCookie in '.\Kor\Common\uCookie.pas',
  uUtil in '.\Kor\Common\uUtil.pas',
  ScriptBasic in '.\Kor\Common\ScriptBasic.pas',
  ScriptCls in '.\Kor\Common\ScriptCls.pas',
  BSCommon in '.\Kor\Common\BSCommon.pas',
  uDBRecordDef in '.\Kor\Common\uDBRecordDef.pas',
  uPackets in '.\Kor\Common\uPackets.pas',
  uCrypt in '.\Kor\Common\uCrypt.pas',
  uKeyClass in '.\Kor\Common\uKeyClass.pas',
  uBuffer in '.\Kor\Common\uBuffer.pas',
  uImage in '.\Kor\Common\uImage.pas',
  uFuck in '.\Kor\Common\uFuck.pas',
  uAnsTick in '.\Kor\Common\uAnsTick.pas',
  AnsImg2 in '.\Kor\Common\AnsImg2.pas',
  BmpUtil in '.\Kor\Common\BmpUtil.pas',
  AnsStringCls in '.\Kor\Common\AnsStringCls.pas';

{$R *.RES}

begin
  Application.Initialize;
  Application.CreateForm(TFrmMain, FrmMain);
  Application.CreateForm(TFrmSockets, FrmSockets);
  Application.CreateForm(TfrmGate, frmGate);
  Application.CreateForm(TfrmTrace, frmTrace);
  Application.CreateForm(TfrmLog, frmLog);
  Application.Run;
end.

