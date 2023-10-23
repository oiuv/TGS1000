unit FLog;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, StdCtrls, ExtCtrls, Spin;

type
  TfrmLog = class(TForm)
    txtLog: TMemo;
    Panel1: TPanel;
    Button1: TButton;
    Button2: TButton;
    Button3: TButton;
    SpinEdit1: TSpinEdit;
    CheckBox1: TCheckBox;
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure SpinEdit1Change(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
  private
    { Private declarations }
  public
    procedure AddLog(const strLog: string);
  end;

var
  frmLog: TfrmLog;

implementation

uses SVMain;

{$R *.dfm}

// add by minds 050916
procedure TfrmLog.Button1Click(Sender: TObject);
begin
  txtLog.Clear;
end;

procedure TfrmLog.Button2Click(Sender: TObject);
begin
  txtLog.Lines.SaveToFile(FormatDateTime('yymmdd_hhnnss', Time) + '.log');
end;

procedure TfrmLog.Button3Click(Sender: TObject);
begin
  frmMain.FormClick(nil);
end;

procedure TfrmLog.SpinEdit1Change(Sender: TObject);
begin
  try
    MsgProcTick := SpinEdit1.Value;
  except
  end;
end;

procedure TfrmLog.CheckBox1Click(Sender: TObject);
begin
  CheckMsgProcTick := CheckBox1.Checked;
end;

procedure TfrmLog.AddLog(const strLog: string);
begin
  if txtLog.Lines.Count >= 10000 then begin
    txtLog.Lines.SaveToFile(FormatDateTime('yymmdd_hhnnss', Time) + '.log');
    txtLog.Clear;
  end;
  txtLog.Lines.Add(strLog);
end;

end.
