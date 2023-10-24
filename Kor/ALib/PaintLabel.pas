unit PaintLabel;

interface

uses
  Windows, Messages, SysUtils, Classes, Graphics, Controls, Forms, Dialogs,
  StdCtrls;

type
  TPaintEvent = procedure (Sender: TObject) of Object;
  TPaintLabel = class(TLabel)
  private
    fOnPaint : TPaintEvent;
    { Private declarations }
  protected
    procedure WMPaint(var Message: TMessage); message WM_PAINT;
    { Protected declarations }
  public
    { Public declarations }
  published
    property OnPaint : TPaintEvent read fOnPaint write fOnPaint;
    { Published declarations }
  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('A2Ctrl', [TPaintLabel]);
end;

procedure TPaintLabel.WMPaint(var Message: TMessage);
begin
  if Assigned (fOnPaint) then begin
    fOnPaint(Self);
  end;
end;

end.
