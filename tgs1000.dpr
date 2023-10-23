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
  deftype in '..\1000ydef\deftype.pas',
  uCharCheck in '..\common\uCharCheck.pas',
  uCookie in '..\common\uCookie.pas',
  uUtil in '..\common\uUtil.pas',
  ScriptBasic in '..\common\ScriptBasic.pas',
  ScriptCls in '..\common\ScriptCls.pas',
  BSCommon in '..\common\BSCommon.pas',
  uDBRecordDef in '..\common\uDBRecordDef.pas',
  uPackets in '..\common\uPackets.pas',
  uCrypt in '..\common\uCrypt.pas',
  uKeyClass in '..\common\uKeyClass.pas',
  uBuffer in '..\common\uBuffer.pas',
  uImage in '..\common\uImage.pas',
  uFuck in '..\common\uFuck.pas',
  uAnsTick in '..\common\uAnsTick.pas',
  AnsImg2 in '..\common\AnsImg2.pas',
  BmpUtil in '..\common\BmpUtil.pas',
  AnsStringCls in '..\common\AnsStringCls.pas';

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

