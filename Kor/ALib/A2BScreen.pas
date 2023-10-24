unit A2BScreen;

interface

uses
   Controls, Classes, Messages, Windows, Forms, AnsImg2, extctrls, mmsystem, graphics;

const
   A2BScreenMAXWSIZE = 640;
   A2BScreenMAXHSIZE = 480;

type
   TOnPaint = procedure (Sender: TObject) of Object;
   TOnMWheelEvent = procedure (aWheelDelta, aXPos, aYPos: integer; aPos: TPoint) of Object;
   TA2DrawEvent = procedure (Sender: TObject) of Object;

   TA2BScreen = class (TCustomControl)
      private
//         bmpInfo : TBitmapInfo;
         FOnPaint : TOnPaint;
         FOnMW : TOnMWheelEvent;
         FOnActivate: TNotifyEvent;
         FOnDeactivate: TNotifyEvent;
         FFrameRate : Cardinal;
         FNowFrameRate : Cardinal;
//         Bits : array [0..640*480*2] of byte;
         FUsedIdle : Boolean;
         Timer : TTimer;
         FInterval : Cardinal;
         FOldTime : DWord;
         FOldTime2 : DWord;
         FOnA2DrawEvent : TA2DrawEvent;
//         FCanvas: TCanvas;
         FHook : Boolean;
//         FSurface : TAns2Image;
//         saveBits : PTAns2Color;

         procedure   initialize;
         procedure   finalize;
         procedure   Resume;
         procedure   Suspend;
         procedure   GetHook;
         procedure   FreeHook;
//         procedure   DrawScreen;
//         procedure   SetBmpInfo;
         procedure   SetInterval(value : Cardinal);
         procedure   TimerTimer(Sender: TObject);
      protected
         procedure   AppIdle(Sender: TObject; var Done: Boolean);
         function    AppProc(var Message: TMessage): Boolean;
         procedure   Loaded; override;
         procedure   WMPaint(var Message: TWMPaint); message WM_PAINT;

         procedure   DoActivate;
         procedure   DoDeactivate;
         procedure   WMMouseWheel(var Message: TWMMouseWheel); message WM_MOUSEWHEEL;
         procedure   WndProc (var Message : TMessage); override;
      public
         constructor Create(AOwner: TComponent); override;
         destructor  Destroy; override;
         property    Canvas;

//         property    Surface: TAns2Image read FSurface write FSurface;
//         procedure   DrawImage (AnsImage: TAns2Image; x, y: Integer; aTrans: Boolean);
//         procedure   BitsClear (aColor: Word);
      published
         property    Align;

         property    OnMWheel : TOnMWheelEvent read FOnMW write FOnMW;
         property    OnPaint : TOnPaint read FOnPaint write FOnPaint;
         property    OnActivate: TNotifyEvent read FOnActivate write FOnActivate;
         property    OnDeactivate: TNotifyEvent read FOnDeactivate write FOnDeactivate;
         property    OnDEvent: TA2DrawEvent read FOnA2DrawEvent write FOnA2DrawEvent;
         property    UsedIdle : Boolean read FUsedIdle write FUsedIdle;
         property    Interval: Cardinal read FInterval write SetInterval;
         property    FrameRate: Cardinal read FFrameRate;
         property    Hook: Boolean read FHook write FHook;

         property    Enabled;
         property    OnClick;
         property    OnDblClick;
         property    OnMouseDown;
         property    OnMouseMove;
         property    OnMouseUp;
         property    OnDragDrop;
         property    OnDragOver;
         property    OnEndDrag;
         property    OnStartDrag;
         property    OnKeyDown;
         property    OnKeyPress;
         property    OnKeyUp;
         property    OnEnter;
         property    OnExit;
   end;

function Max(Val1, Val2: Integer): Integer;
function Min(Val1, Val2: Integer): Integer;

procedure Register;


implementation

function Max(Val1, Val2: Integer): Integer;
begin
  if Val1>=Val2 then Result := Val1 else Result := Val2;
end;

function Min(Val1, Val2: Integer): Integer;
begin
  if Val1<=Val2 then Result := Val1 else Result := Val2;
end;

procedure Register;
begin
  RegisterComponents('A2Ctrl', [TA2BScreen]);
end;

constructor TA2BScreen.Create(AOwner: TComponent);
begin
   inherited Create (AOwner);
   Width := 100;
   Height := 100;
   FUsedIdle := TRUE;
   Timer := nil;
   FInterval := 1000;
   {
   FCanvas := TControlCanvas.Create;
   TControlCanvas(FCanvas).Control := Self;
   }
   FHook := FALSE;
//   FSurface := TAns2Image.Create (A2BScreenMAXWSIZE,A2BScreenMAXHSIZE,0,0);
//   FreeMem (FSurface.Bits, A2BScreenMAXWSIZE*A2BScreenMAXHSIZE*sizeof(TAns2Color));
//   saveBits := FSurface.Bits;
//   FSurface.Bits := @Bits;
end;

destructor  TA2BScreen.Destroy;
begin
   if FHook then FreeHook;
   Finalize;
//   FSurface.Bits := saveBits;
//   FSurface.Bits := nil;
//   FSurface.Free;
   inherited Destroy;
end;

procedure   TA2BScreen.GetHook;
begin
   if FHook then Application.HookMainWindow (AppProc);
end;

procedure   TA2BScreen.FreeHook;
begin
   Application.UnhookMainWindow (AppProc);
end;

procedure   TA2BScreen.Loaded;
var i : integer;
begin
   inherited Loaded;
   if (not (csDesigning in ComponentState)) and Self.Enabled then begin
      FUsedIdle := UsedIdle;
      FInterval := Interval;
      FHook := Hook;
      if FHook then GetHook;
      i := Width mod 2;
      if i > 0 then Width := Width + 1;
      i := Height mod 2;
      if i > 0 then Height := Height + 1;
      if Width > A2BScreenMAXWSIZE then Width := A2BScreenMAXWSIZE;
      if Height > A2BScreenMAXHSIZE then Height := A2BScreenMAXHSIZE;
//      SetBmpInfo;
      Initialize;
   end;
end;
{
procedure   TA2BScreen.SetBmpInfo;
begin
   with BmpInfo.bmiHeader do begin
      biSize        := SizeOf(TBitmapInfoHeader);
      biWidth       := Width;
      biHeight      := -Height;
      biPlanes      := 1;
      biBitCount    := 16;
      biCompression := BI_RGB;
      biClrUsed     := 0;
      biClrImportant:= 0;
   end;
end;

procedure   TA2BScreen.DrawScreen;
var dc : HDC;
begin
   dc := Canvas.Handle;
   SetDIBitsToDevice (dc, 0, 0, Width, Height, 0, 0, 0, Height, @Bits, BmpInfo, DIB_RGB_COLORS);
end;
}
procedure   TA2BScreen.SetInterval(value : Cardinal);
begin
   if FInterval <> value then FInterval := value;
end;

procedure   TA2BScreen.initialize;
begin
   if FUsedIdle then Resume
   else begin
      Timer := TTimer.Create (nil);
      Timer.Interval := FInterval;
      Timer.OnTimer := TimerTimer;
   end;
end;

procedure   TA2BScreen.finalize;
begin
   if FUsedIdle then Suspend
   else if Timer <> nil then Timer.Free;
end;

procedure   TA2BScreen.Resume;
begin
   FOldTime := TimeGetTime;
   FOldTime2 := TimeGetTime;
   Application.OnIdle := AppIdle;
end;

procedure   TA2BScreen.Suspend;
begin
   Application.OnIdle := nil;
end;

procedure   TA2BScreen.AppIdle(Sender: TObject; var Done: Boolean);
var
   t, t2, i : DWord;
begin
   Done := FALSE;
   t := TimeGetTime;
   t2 := t - FOldTime;
   if t2 >= FInterval then begin
      FOldTime := t;
      Inc(FNowFrameRate);
      i := Max(t-FOldTime2, 1);
      if i >= 1000 then begin
         FFrameRate := Round(FNowFrameRate*1000/i);
         FNowFrameRate := 0;
         FOldTime2 := t;
      end;
//      DrawScreen;
      if assigned (FOnA2DrawEvent) then  FOnA2DrawEvent (Self);
   end;
end;

procedure   TA2BScreen.TimerTimer(Sender: TObject);
begin
//   DrawScreen;
   if assigned (FOnA2DrawEvent) then  FOnA2DrawEvent (Self)
end;

function    TA2BScreen.AppProc(var Message: TMessage): Boolean;
begin
   Result := FALSE;
   case Message.Msg of
      CM_ACTIVATE:
          begin
             DoActivate;
          end;
      CM_DEACTIVATE:
          begin
             DoDeactivate;
          end;
   end;
end;

procedure   TA2BScreen.DoActivate;
begin
   if Assigned (FOnActivate) then FOnActivate (Self);
end;

procedure   TA2BScreen.DoDeactivate;
begin
   if Assigned (FOnDeactivate) then FOnDeactivate (Self);
end;

procedure   TA2BScreen.WndProc (var Message : TMessage);
begin
   inherited WndProc(Message);
   case Message.Msg of
      WM_LBUTTONDOWN, WM_LBUTTONDBLCLK :
         begin
            if not (csDesigning in ComponentState) and not Focused then begin
                  Windows.SetFocus (Handle);
               if not Focused then exit;
            end;
         end;
   end;
end;

procedure   TA2BScreen.WMMouseWheel(var Message: TWMMouseWheel);
var
   p : TPoint;
begin
   inherited;
   if Assigned (FOnMW) then begin
      p.X := Message.Pos.x;
      p.Y := Message.Pos.y;
      FOnMW (Message.WheelDelta, Message.XPos, Message.YPos, p);
   end;
end;

procedure   TA2BScreen.WMPaint(var Message: TWMPaint);
begin
   inherited;
end;

end.
