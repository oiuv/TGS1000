unit A2Form;

interface

uses
  Windows, Messages, SysUtils, Classes, Controls, StdCtrls, ExtCtrls, Forms,
  Graphics, Buttons, A2Img, CommCtrl, comctrls;

const
   EDIT_TOGGLE_TIME = 500;

   IMG_LT     = 0;
   IMG_TOP    = 1;
   IMG_RT     = 2;
   IMG_LEFT   = 3;
   IMG_BODY   = 4;
   IMG_RIGHT  = 5;
   IMG_LB     = 6;
   IMG_BOTTOM = 7;
   IMG_RB     = 8;

   IMG_DOWN   = 9;
   IMG_UP     = 10;

   IMG_BLOCK_SIZE = 12;

   XCENTER = -12;

type
  TOnAdxPaint = procedure (aAnsImage: TA2Image) of object;
  TShowMethod = (FSM_NONE, FSM_DITHER, FSM_DARKEN);

  TA2Form = class (TComponent)
  private
    Hintx, Hinty:integer;
    Hintstr : string;
    CurFrame : integer;
    FShowMethod : TShowMethod;
    boShowed : Boolean;

    ComponentList : TList;
    FSurface : TA2Image;
    FImageSurface : TA2Image;

    FUpBoxImage : TA2Image;
    FRightBoxImage : TA2Image;
    FDownBoxImage : TA2Image;
    FLeftBoxImage : TA2Image;

    FColor : TColor;
    FImageFileName : string;
    FUpBoxFileName : string;
    FDownBoxFileName : string;
    FLeftBoxFileName : string;
    FRightBoxFileName : string;

    FTransParent : Boolean;

    FOnAdxPaint : TOnAdxPaint;
    FOnAdxPaintStart: TOnAdxPaint;
     
    FOnShow  : procedure (Sender: TObject) of object;
    FOnHide  : procedure (Sender: TObject) of object;

    procedure Show(Sender: TObject);
    procedure Hide(Sender: TObject);
    procedure DrawDispath;
    procedure TimerTimer (Sender: TObject);
  protected
    procedure Loaded; override;
  public
    property Surface : TA2Image read FSurface write FSurface;
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AdxPaint(aSurface: TA2Image);
    procedure ShowHint (ax, ay:integer; Hstr:string);
    procedure SetBackImageFile (aFileName: string);
  published
    property Color : TColor read FColor write FColor;
    property OnAdxPaint : TOnAdxPaint read FOnAdxPaint write FOnAdxPaint;
    property OnAdxPaintStart : TOnAdxPaint read FOnAdxPaintStart write FOnAdxPaintStart;
    property ImageFileName : string read FImageFileName write FImageFileName;

    property UpBoxFileName : string read FUpBoxFileName write FUpBoxFileName;
    property DownBoxFileName : string read FDownBoxFileName write FDownBoxFileName;
    property LeftBoxFileName : string read FLeftBoxFileName write FLeftBoxFileName;
    property RightBoxFileName : string read FRightBoxFileName write FRightBoxFileName;
    property ShowMethod : TShowMethod read FShowMethod write FShowMethod;
    property TransParent : Boolean read FTransParent write FTransParent;
  end;

  TA2Label = class (TLabel)
  private
    FPicture: TPicture;
    boEntered : Boolean;
    FADXForm : TA2Form;
    FFontColor : Word;
    procedure SetCaption (Value: string);
    function  GetCaption: string;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure SetPicture(Value: TPicture);
    procedure SetFontColor(Value: Word);
  protected
    procedure Loaded; override;
    procedure paint; override;
  public
    constructor Create (AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AdxPaint; dynamic;
  published
    property ADXForm : TA2Form read FADXForm write FADXForm;
    property Caption : string read GetCaption write SetCaption;
    property Picture: TPicture read FPicture write SetPicture;
    property FontColor : Word read FFontColor write SetFontColor;

  end;

  TA2Panel = class (TPanel)
  private
    FPicture: TPicture;
    FADXForm : TA2Form;
    procedure SetPicture(Value: TPicture);
  protected
    procedure Paint; override;
  public
    constructor Create (AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AdxPaint; dynamic;
  published
    property ADXForm : TA2Form read FADXForm write FADXForm;
    property Picture: TPicture read FPicture write SetPicture;
  end;

  TA2ILabel = class (TLabel)
  private
    FPicture: TPicture;
    boEntered : Boolean;
    FADXForm : TA2Form;

    FA2Image : TA2Image;

    FBColor : word;
    BaseImage : TA2Image;
    FOnPaint : TNotifyEvent;
    FGreenCol : integer;
    FGreenadd : integer;
    procedure Setcolor (Value: word);
    procedure SetImage (Value: TA2Image);

    procedure SetCaption (Value: string);
    function  GetCaption: string;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
    procedure SetPicture(Value: TPicture);
  protected
    procedure Loaded; override;

   procedure Paint; override;
   procedure Draw;

  public
    constructor Create (AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AdxPaint; dynamic;
    property A2Image: TA2Image read FA2Image write SetImage;
    property BColor : word read FBColor write SetColor;
    property GreenCol : integer read FGreenCol write FGreenCol;
    property GreenAdd : integer read FGreenAdd write FGreenAdd;
    // add by minds 20020611
    // TA2ILabel위에 마우스가 올려져 있는지 체크하기위해 property추가
    // 기존 소스에 영향을 주지 않기위해 별다른 작업없음.. 
    property boEnter: Boolean read boEntered write boEntered;
  published
    property ADXForm : TA2Form read FADXForm write FADXForm;
    property Caption : string read GetCaption write SetCaption;
    property Picture: TPicture read FPicture write SetPicture;

    property OnPaint: TNotifyEvent read FOnPaint write FOnPaint;
  end;


  TA2Button = class (TLabel)
  private
    FUpImage: TPicture;
    FDownImage: TPicture;
    FUpA2Image: TA2Image;
    FDownA2Image: TA2Image;
    FDown : Boolean;
    FOldDown : Boolean;
    FCaptured : Boolean;
    boEntered : Boolean;
    FFontColor: integer;
    FFontSelColor: integer;
    FADXForm : TA2Form;

    procedure SetCaption (Value: string);
    function  GetCaption: string;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;

    procedure WMLButtonDown(var Message: TWMLButtonDown); message WM_LBUTTONDOWN;
    procedure WMMouseMove(var Message: TWMMouseMove); message WM_MOUSEMOVE;
    procedure WMLButtonUp(var Message: TWMLButtonUp); message WM_LBUTTONUP;

    procedure SetUpImage(Value: TPicture);
    procedure SetDownImage(Value: TPicture);
  protected
    procedure Loaded; override;
    procedure paint; override;
  public
    constructor Create (AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AdxPaint; dynamic;

    procedure SetUpA2Image(Value: TA2Image);
    procedure SetDownA2Image(Value: TA2Image);

  published
    property ADXForm : TA2Form read FADXForm write FADXForm;
    property Caption : string read GetCaption write SetCaption;
    property FontColor: integer read FFontColor write FFontColor;
    property FontSelColor: integer read FFontSelColor write FFontSelColor;

    property UpImage: TPicture read FUpImage write SetUpImage;
    property DownImage: TPicture read FDownImage write SetDownImage;
  end;

  TA2Edit = class (TEdit)
  private
    OldText : string;
    boTail : Boolean;
    FTransParent : Boolean;
    FOnEnter : procedure (Sender: TObject) of object;
    FOnExit : procedure (Sender: TObject) of object;
    FOnChange : procedure (Sender: TObject) of object;
    FOnKeyDown : procedure (Sender: TObject; var Key: Word; Shift: TShiftState) of object;

    Timer : TTimer;
    FADXForm : TA2Form;
    FFontColor : integer;
    FPassChar : char;
    procedure FocusEnter (Sender: TObject);
    procedure FocusExit (Sender: TObject);

    procedure TextChange (Sender: TObject);
    procedure SelfKeyDown (Sender: TObject; var Key: Word; Shift: TShiftState);

    procedure TimerTimer (Sender: TObject);
  protected
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AdxPaint;
    procedure SetFontColor(value: integer);
  published
    property ADXForm : TA2Form read FADXForm write FADXForm;
    property TransParent : Boolean read FTransParent write FTransParent;
    property FontColor : integer read FFontColor write SetFontColor;
    property PassChar : char read FPassChar write FPassChar;
  end;

  TDrawItemState = (TIS_None, TIS_Select, TIS_Over);
  TDrawScrollState = (TSS_None, TSS_TopMoving, TSS_BottomMoving, TSS_TrackMoving, TSS_TopClick, TSS_BottomClick, TSS_TrackClick);
  TOnAdxDrawItem = procedure (ASurface: TA2Image; Index:integer; aStr: string; Rect: TRect; State: TDrawItemState) of Object;
  TOnAdxScrollDraw = procedure (ASurface: TA2Image; Rect: TRect; State:TDrawScrollState) of Object;

  TA2ListBox = class(TWinControl)
    private
       FCanvas : TCanvas;
       FADXForm : TA2Form;
       FOverIndex : integer;
       FSurface : TA2Image;
       FStringList : TStringList;
       FScrollTop : TA2Image; //UpImage
       FScrollTrack : TA2Image; //UpImage
       FScrollBottom : TA2Image; //UpImage
       FScrollDTop : TA2Image; // DownImage
       FScrollDTrack : TA2Image; // DownImage
       FScrollDBottom : TA2Image; // DownImage
       FScrollBackImg : TA2Image;

       FFontColor : integer;
       FFontSelColor : integer;
       FEmphasis : Boolean;

       FItemIndex : integer;
       FViewIndex : integer;
       ViewItemCount : integer;
       FScrollTrackTopPos : integer;
       FScrollTrackingPos : integer;

       FItemHeight : Word;
       FItemMerginX : Word;
       FItemMerginY : Word;

       FScrollBarView : Boolean;
       ScrollBarWidth : Word;
       ScrollBarHeight : Word;
       ScrollBarTrackHeight : Word;
       CurXMouse, CurYMouse : integer;
       boScrollTop, boScrollTrack, boScrollBottom : Boolean;

       FOnAdxDrawItem : TOnAdxDrawItem;
       FOnAdxScrollDraw : TOnAdxScrollDraw;
    protected
       procedure   AdxPaint; dynamic;
       procedure   Paint;
       procedure   Loaded; override;
       procedure   Resize; override;
       procedure   MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
       procedure   MouseMove(Shift: TShiftState; X, Y: Integer); override;
       procedure   MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer); override;
       procedure   KeyDown(var Key: Word; Shift: TShiftState); override;
       procedure   KeyUp(var Key: Word; Shift: TShiftState); override;
       procedure   KeyPress(var Key: Char); override;
       procedure   DblClick; override;
       procedure   WndProc (var Message : TMessage); override;
       procedure   CreateParams(var Params: TCreateParams); override;
       procedure   WMMouseWheel(var Message: TWMMouseWheel); message WM_MOUSEWHEEL;

       procedure   CreateWnd; override;
       procedure   DestroyWnd; override;
    private
       procedure   IncItem (value: integer);
       procedure   DecItem (value: integer);
       procedure   IncItemIndex (value: integer);
       procedure   DecItemIndex (value: integer);
    public
       constructor Create(AOwner: TComponent); override;
       destructor  Destroy; override;
       procedure   Clear;

       procedure   AddItem (aStr : string);
       function    GetItem (Value : integer): string;
       procedure   SetItem (Value : integer; aItem: string);
       procedure   DeleteItem (Value : integer);
       function    Count : integer;

       procedure   DrawItem (aSurface: TA2Image);
       procedure   DrawScrollBar (aSurface: TA2Image);

       procedure   SetBackImage (value : TA2Image);
       procedure   SetScrollTopImage (UpImage, DownImage : TA2Image);
       procedure   SetScrollTrackImage (UpImage, DownImage : TA2Image);
       procedure   SetScrollBottomImage (UpImage, DownImage : TA2Image);
       procedure   SetScrollBackImage (value : TA2Image);

       property    Canvas: TCanvas read FCanvas;
       property    OverIndex : integer read FOverIndex;
       property    ItemIndex : integer read FItemIndex write FItemIndex;
       property    ViewIndex : integer read FViewIndex write FViewIndex;
       property    Items [value : integer] : String read GetItem write SetItem;

    published
       property    ADXForm : TA2Form read FADXForm write FADXForm;
       property    FontColor : integer read FFontColor write FFontColor;
       property    FontSelColor : integer read FFontSelColor write FFontSelColor;
       property    ItemHeight : Word read FItemHeight write FItemHeight;
       property    ItemMerginX : Word read FItemMerginX write FItemMerginX;
       property    ItemMerginY : Word read FItemMerginY write FItemMerginY;
       property    FontEmphasis : Boolean read FEmphasis write FEmphasis;
       property    ScrollBarView : Boolean read FScrollBarView write FScrollBarView;
       property    Visible;

       property    OnClick;
       property    OnDblClick;
       property    OnDragDrop;
       property    OnDragOver;
       property    OnEndDrag;
       property    OnStartDrag;
       property    OnKeyDown;
       property    OnKeyPress;
       property    OnKeyUp;
       property    OnEnter;
       property    OnExit;
       property    OnMouseMove;
       property    OnMouseDown;
       property    OnMouseUp;
       property    OnAdxDrawItem : TOnAdxDrawItem read FOnAdxDrawItem write FOnAdxDrawItem;
       property    OnAdxScrollDraw : TOnAdxScrollDraw read FOnAdxScrollDraw write FOnAdxScrollDraw;
  end;

{
  TOnAdxDrawItem = procedure (ASurface:TA2Image; index:integer; Rect:TRect; State: Integer) of object;

  TA2ListBox = class (TListBox)
  private
    Ans2ImageLib : TA2ImageLib;
    FAtzFileName : string;
    FADXForm : TA2Form;
    FTransParent : Boolean;
    FOnAdxDrawItem : TOnAdxDrawItem;
  protected
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AdxPaint;
    procedure DrawScrollBar;
  published
    property ADXForm : TA2Form read FADXForm write FADXForm;
    property OnAdxDrawItem: TOnAdxDrawItem read FOnAdxDrawItem write FOnAdxDrawItem;
    property TransParent : Boolean read FTransParent write FTransParent;
    property AtzFileName : string read FAtzFileName write FAtzFileName;
  end;
}
  TA2ComboBox = class (TComboBox)
  private
    FPicture: TPicture;
    FADXForm : TA2Form;
    procedure SetPicture(Value: TPicture);
  protected
    procedure Loaded; override;
  public
    constructor Create (AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AdxPaint; dynamic;
  published
    property ADXForm : TA2Form read FADXForm write FADXForm;
    property Picture: TPicture read FPicture write SetPicture;
  end;

  TA2Memo = class (TEdit)
  private
    OldText : string;
    boTail : Boolean;
    FTransParent : Boolean;
    FLineMax : Integer;

    FOnEnter : procedure (Sender: TObject) of object;
    FOnExit : procedure (Sender: TObject) of object;
    FOnChange : procedure (Sender: TObject) of object;

    Timer : TTimer;
    FADXForm : TA2Form;
    procedure FocusEnter (Sender: TObject);
    procedure FocusExit (Sender: TObject);

    procedure TextChange (Sender: TObject);

    procedure TimerTimer (Sender: TObject);
  protected
    procedure Loaded; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AdxPaint;
//    procedure GetLineColumn(Sender: TMemo; var iLin: Integer; var iCol:Integer);
  published
    property ADXForm : TA2Form read FADXForm write FADXForm;
    property TransParent : Boolean read FTransParent write FTransParent;
//    property LineMax : Integer read FLineMax write FLineMax;
  end;

  TA2AnimateButton = class (TPanel)
  private
    Timer : TTimer;
    CurFrame : integer;
    boUpProcess : Boolean;
    FAtzImageCount : integer;
    FADXForm : TA2Form;
    Ans2ImageLib : TA2ImageLib;
    FAtzFileName : string;
    procedure CMMouseEnter(var Message: TMessage); message CM_MOUSEENTER;
    procedure CMMouseLeave(var Message: TMessage); message CM_MOUSELEAVE;
  protected
    procedure Loaded; override;
    procedure paint; override;
    procedure TimerTimer (Sender: TObject);

  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AdxPaint; dynamic;
  published
    property ADXForm : TA2Form read FADXForm write FADXForm;
    property AtzFileName : string read FAtzFileName write FAtzFileName;
    property AtzImageCount : integer read FAtzImageCount write FAtzImageCount;
  end;

  TA2ProgressBar = class (TA2Label)
  private
    FMinValue : integer;
    FMaxValue : integer;
    FValue : integer;
    FPicture: TPicture;
    procedure SetPicture(Value: TPicture);
  protected
    procedure Loaded; override;
    procedure paint; override;
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AdxPaint; override;
  published
    property Picture: TPicture read FPicture write SetPicture;
    property MinValue: integer read FMinValue write FMinValue;
    property MaxValue: integer read FMaxValue write FMaxValue;
    property Value: integer read FValue write FValue;
  end;

  TA2AnimateImage = class (TPanel)
  private
    Timer : TTimer;
    CurFrame : integer;
    FAtzImageCount : integer;
    FADXForm : TA2Form;
    Ans2ImageLib : TA2ImageLib;
    FAtzFileName : string;
  protected
    procedure Loaded; override;
    procedure paint; override;
    procedure TimerTimer (Sender: TObject);
  public
    constructor Create(AOwner: TComponent); override;
    destructor Destroy; override;
    procedure AdxPaint; dynamic;
  published
    property ADXForm : TA2Form read FADXForm write FADXForm;
    property AtzFileName : string read FAtzFileName write FAtzFileName;
    property AtzImageCount : integer read FAtzImageCount write FAtzImageCount;
  end;
  
procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('A2Ctrl', [TA2Form]);
  RegisterComponents('A2Ctrl', [TA2Label]);
  RegisterComponents('A2Ctrl', [TA2ILabel]);
  RegisterComponents('A2Ctrl', [TA2Panel]);
  RegisterComponents('A2Ctrl', [TA2Button]);
  RegisterComponents('A2Ctrl', [TA2Edit]);
  RegisterComponents('A2Ctrl', [TA2ListBox]);
  RegisterComponents('A2Ctrl', [TA2ComboBox]);
  RegisterComponents('A2Ctrl', [TA2Memo]);
  RegisterComponents('A2Ctrl', [TA2AnimateButton]);
  RegisterComponents('A2Ctrl', [TA2AnimateImage]);
  RegisterComponents('A2Ctrl', [TA2ProgressBar]);
end;

//////////////////////////////////////////
//            TA2Form
//////////////////////////////////////////

constructor TA2Form.Create(AOwner: TComponent);
begin
  	inherited Create(AOwner);
   ComponentList := TList.Create;
   boShowed := FALSE;
   FColor := 0;
   FSurface := nil;
   FImageSurface := nil;

   FUpBoxImage := nil;
   FRightBoxImage := nil;
   FDownBoxImage := nil;
   FLeftBoxImage := nil;

   CurFrame := 4;
end;

destructor TA2Form.Destroy;
begin
   if FSurface <> nil then FSurface.Free;
   if FImageSurface <> nil then FImageSurface.Free;
   if FUpBoxImage <> nil then FUpBoxImage.Free;
   if FRightBoxImage <> nil then FRightBoxImage.Free;
   if FDownBoxImage <> nil then FDownBoxImage.Free;
   if FLeftBoxImage <> nil then FLeftBoxImage.free;

   ComponentList.Free;
   inherited Destroy;
end;

procedure TA2Form.ShowHint (ax, ay:integer; Hstr:string);
begin
   Hintx := ax; Hinty := ay; Hintstr := hstr;
end;

procedure TA2Form.Loaded;
var
   i : integer;
   compo : TComponent;
begin
   inherited Loaded;
   if not ( csDesigning in ComponentState) (*and Assigned (FDxDraw)*) then begin

      FOnShow := TForm (Owner).OnShow;
      FOnHide := TForm (Owner).OnHide;
      TForm (Owner).OnShow := Show;
      TForm (Owner).OnHide := Hide;

      if FUpBoxFileName <> '' then begin FUpBoxImage := TA2Image.Create(4, 4, 0, 0); FUpBoxImage.LoadFromFile (FUpBoxFileName); end;
      if FDownBoxFileName <> '' then begin FDownBoxImage := TA2Image.Create(4, 4, 0, 0); FDownBoxImage.LoadFromFile (FUpBoxFileName); end;
      if FLeftBoxFileName <> '' then begin FLeftBoxImage := TA2Image.Create(4, 4, 0, 0); FLeftBoxImage.LoadFromFile (FUpBoxFileName); end;
      if FRightBoxFileName <> '' then begin FRightBoxImage := TA2Image.Create(4, 4, 0, 0); FRightBoxImage.LoadFromFile (FUpBoxFileName); end;

      if FImageFileName <> '' then begin
         FImageSurface := TA2Image.Create(4, 4, 0, 0);
         FImageSurface.LoadFromFile (FImageFileName);
      end;

      FSurface := TA2Image.Create(TForm(Owner).Width, TForm(Owner).Height, 0, 0);
      FSurface.Clear (FColor);

      ComponentList.Clear;
      for i := 0 to Owner.ComponentCount -1 do begin
         Compo := Owner.Components[i];
         if Compo is TA2Label         then ComponentList.Add (Compo);
         if Compo is TA2ILabel        then ComponentList.Add (Compo);
         if Compo is TA2Panel         then ComponentList.Add (Compo);
         if Compo is TA2Button        then ComponentList.Add (Compo);
         if Compo is TA2Edit          then ComponentList.Add (Compo);
         if Compo is TA2Listbox       then ComponentList.Add (Compo);
         if Compo is TA2ComboBox      then ComponentList.Add (Compo);

         if Compo is TA2animateImage  then ComponentList.Add (Compo);
         if Compo is TA2animateButton then ComponentList.Add (Compo);
         if Compo is TA2Memo          then ComponentList.Add (Compo);
         if Compo is TA2ProgressBar   then ComponentList.Add (Compo);
      end;
   end;
end;

procedure TA2Form.SetBackImageFile (aFileName: string);
begin
   if FImageSurface = nil then FImageSurface := TA2Image.Create(4, 4, 0, 0);

   if aFileName <> '' then
      FImageSurface.LoadFromFile (aFileName)
   else
      FImageSurface.Clear(0);
end;

procedure TA2Form.Show(Sender: TObject);
begin
   if assigned (FOnShow) then FOnShow (Sender);
   boShowed := TRUE;
   DrawDispath;
end;

procedure TA2Form.Hide(Sender: TObject);
begin
   boShowed := FALSE;
   if assigned (FOnHide) then FOnHide (Sender);
end;

procedure TA2Form.DrawDispath;
var
   i : integer;
   Compo : TComponent;
begin
   if ComponentList = nil then exit;
   // add by minds 0724
   if assigned (FOnAdxPaintStart) then FOnAdxPaintStart(FSurface);
   for i := 0 to ComponentList.Count -1 do begin
      compo := ComponentList[i];
      if Compo is TA2Label then TA2Label(Compo).adxPaint;
      if Compo is TA2ILabel then TA2ILabel(Compo).adxPaint;
      if Compo is TA2Panel  then TA2Panel(Compo).adxPaint;
      if Compo is TA2Button then TA2Button(Compo).adxPaint;
      if Compo is TA2ListBox then TA2ListBox(Compo).adxPaint;
      if Compo is TA2ComboBox then TA2ComboBox(Compo).adxPaint;
      if Compo is TA2Edit then TA2Edit(Compo).adxPaint;
      if Compo is TA2ProgressBar then TA2ProgressBar (Compo).adxpaint;

//      if Compo is TA2animateImage then TA2animateImage(Compo).adxPaint;
//      if Compo is TA2animateButton then TA2animateButton(Compo).adxPaint;
      if Compo is TA2Memo then TA2Memo(Compo).adxPaint;
   end;
   if assigned (FOnAdxPaint) then FOnAdxPaint (FSurface);
end;

procedure TA2Form.TimerTimer (Sender: TObject);
begin
   if FShowMethod = FSM_NONE then exit;

   if boShowed then CurFrame := CurFrame - 1
   else CurFrame := CurFrame + 1;

   if CurFrame > 4 then CurFrame := 4;
   if CurFrame < 0 then begin
      CurFrame := 0;
   end;
end;

procedure TA2Form.AdxPaint(aSurface: TA2Image);
var
   w : integer;
   R: TRect;
begin
   Hintstr := '';

   TimerTimer(self);
   if boShowed then begin
      if Assigned (FImageSurface) then FSurface.DrawImage (FImageSurface, 0, 0, FALSE)
      else if FSurface <> nil then FSurface.Clear (FColor) else exit;

      DrawDispath;

      case FShowMethod of
         FSM_NONE  : aSurface.DrawImage (FSurface, TForm(Owner).Left, TForm(Owner).Top, FTransparent);
         FSM_DITHER: aSurface.DrawImageDither (FSurface, TForm(Owner).Left, TForm(Owner).Top, CurFrame, FTransparent);
         FSM_DARKEN : aSurface.DrawImageKeyColor (FSurface, TForm(Owner).Left, TForm(Owner).Top, 31, @DECRGBdarkentbl);
      end;

      if Assigned (FUpBoxImage) then begin
         aSurface.DrawImage (FUpBoxImage, TForm(Owner).Left, TForm(Owner).Top - FUpBoxImage.Height, TRUE);
      end;

      if HintStr <> '' then begin
         w := ATextWidth (HintStr);
         R := Rect (Hintx, Hinty-10, Hintx + w, Hinty+6);
         OffsetRect (R, TForm(Owner).Left, TForm(Owner).Top);

         ATextOut (aSurface, R.Left, R.Top, WinRGB(1,1,1) ,HintStr);

         OffsetRect (R, -1, -1);
         ATextOut (aSurface, R.Left, R.Top, WinRGB(31,31,31) ,HintStr);
      end;
   end else begin
      if CurFrame <> 4 then begin
         if Assigned (FImageSurface) then FSurface.DrawImage (FImageSurface, 0, 0, FALSE)
         else if FSurface <> nil then FSurface.Clear (FColor) else exit;

         DrawDispath;

         case FShowMethod of
            FSM_NONE  : aSurface.DrawImage (FSurface, TForm(Owner).Left, TForm(Owner).Top, FTransparent);
            FSM_DITHER: aSurface.DrawImageDither (FSurface, TForm(Owner).Left, TForm(Owner).Top, CurFrame, FTransparent);
            FSM_DARKEN : aSurface.DrawImageKeyColor (FSurface, TForm(Owner).Left, TForm(Owner).Top, 31, @DECRGBdarkentbl);
         end;
      end;
   end;
end;

//////////////////////////////////////////
//            TA2Label
//////////////////////////////////////////

constructor TA2Label.Create (AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPicture := TPicture.Create;
  FFontColor := WinRGB(31,31,31);
end;

destructor TA2Label.Destroy;
begin
  FPicture.Free;
  inherited destroy;
end;

procedure TA2Label.SetPicture(Value: TPicture);
begin
  FPicture.Assign(Value);
end;

procedure TA2Label.SetFontColor(Value: Word);
begin
   FFontColor := Value;
end;

procedure TA2Label.CMMouseEnter(var Message: TMessage);
begin
   inherited;
   boEntered := TRUE;
end;

procedure TA2Label.CMMouseLeave(var Message: TMessage);
begin
   inherited;
   boEntered := FALSE;
end;

procedure TA2Label.SetCaption (Value: string);
begin
   inherited Caption := Value;
   boEntered := FALSE;
   AdxPaint;
end;

function  TA2Label.GetCaption: string;
begin
   Result := inherited Caption;
end;

procedure TA2Label.AdxPaint;
var
  R: TRect;
  Can : TCanvas;
  xx, yy: integer;
begin
   if (csDesigning in ComponentState) or not Assigned (FADXForm) then exit;
   if not Visible then exit;
   if (Parent <> Owner) and (Parent.visible <> TRUE) then exit;

   Can := A2GetCanvas;
   Can.FillRect (Self.ClientRect);

   if Assigned (FPicture.Graphic) then begin
      Can.Draw (0, 0, FPicture.Graphic);
      R := Self.ClientRect;
      OffsetRect(R, left, top);
      A2DrawCanvas (FADXForm.FSurface, R.Left, R.Top, Width, Height, TRUE);
   end;

   if Text <> '' then begin
      R := ClientRect;
      OffsetRect(R, left, top);
      if Parent <> Owner then OffsetRect (R, Parent.Left, Parent.Top);
//      ATextOut (FADXForm.FSurface, R.Left, R.Top, WinRGB(31,31,31),Text);
//      ATextOut (FADXForm.FSurface, R.Left, R.Top, Font.Color,Text);
      ATextOut (FADXForm.FSurface, R.Left, R.Top, FFontColor,Text);
   end;

   if (Hint <> '') and boEntered then begin
      xx := left;
      yy := Top;
      if Parent <> Owner then begin inc (xx, Parent.Left); inc (yy, Parent.Top); end;
      FADXForm.ShowHint (xx, yy, Hint);
   end;
end;

procedure TA2Label.paint;
begin
   if Assigned (FPicture.Graphic) then begin
      Canvas.Draw (0, 0, FPicture.Graphic);
   end else inherited paint;
end;

procedure TA2Label.Loaded;
begin
   inherited Loaded;
end;

//////////////////////////////////////////
//            TA2Panel
//////////////////////////////////////////

constructor TA2Panel.Create (AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPicture := TPicture.Create;
end;

destructor TA2Panel.Destroy;
begin
  FPicture.Free;
  inherited destroy;
end;

procedure TA2Panel.SetPicture(Value: TPicture);
begin
  FPicture.Assign(Value);
end;

procedure TA2Panel.AdxPaint;
var
  R: TRect;
  Can : TCanvas;
begin
   if (csDesigning in ComponentState) or not Assigned (FADXForm) then exit;
   if not Visible then exit;

   Can := A2GetCanvas;
   Can.FillRect (Self.ClientRect);

   if Assigned (FPicture.Graphic) then begin
      Can.Draw (0, 0, FPicture.Graphic);
      R := Self.ClientRect;
      OffsetRect(R, left, top);
      A2DrawCanvas (FADXForm.FSurface, R.Left, R.Top, Width, Height, TRUE);
   end;

   if Text <> '' then begin
      R := ClientRect;
      OffsetRect(R, left, top);
      ATextOut (FADXForm.FSurface, R.Left, R.Top, WinRGB(31,31,31), Text);
   end;
end;

procedure TA2Panel.paint;
begin
   if Assigned (FPicture.Graphic) then begin
      Canvas.Draw (0, 0, FPicture.Graphic);
   end else inherited paint;
end;


//////////////////////////////////////////
//            TA2ILabel
//////////////////////////////////////////

constructor TA2ILabel.Create (AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPicture := TPicture.Create;
  FA2Image := nil;
  BaseImage := nil;
end;

destructor TA2ILabel.Destroy;
begin
  FPicture.Free;
  inherited destroy;
end;

procedure TA2ILabel.SetPicture(Value: TPicture);
begin
  FPicture.Assign(Value);
end;

procedure TA2ILabel.CMMouseEnter(var Message: TMessage);
begin
   boEntered := TRUE;
end;

procedure TA2ILabel.CMMouseLeave(var Message: TMessage);
begin
   boEntered := FALSE;
end;

procedure TA2ILabel.SetCaption (Value: string);
begin
   inherited Caption := Value;
   boEntered := FALSE;
   AdxPaint;
end;

function  TA2ILabel.GetCaption: string;
begin
   Result := inherited Caption;
end;

procedure TA2ILabel.AdxPaint;
const
  Alignments: array[TAlignment] of Word = (DT_LEFT, DT_RIGHT, DT_CENTER);
  WordWraps: array[Boolean] of Word = (0, DT_WORDBREAK);
var
  R: TRect;
  xx, yy: integer;
  Can : TCanvas;

  x, y: integer;
begin
   if (csDesigning in ComponentState) or not Assigned (FADXForm) then exit;
   if not Visible then exit;
   if (Parent <> Owner) and (Parent.visible <> TRUE) then exit;

   Can := A2GetCanvas;
   Can.FillRect (Self.ClientRect);

   if Assigned (FPicture.Graphic) then begin
      Can.Draw (0, 0, FPicture.Graphic);
      R := Self.ClientRect;
      OffsetRect(R, left, top);
      A2DrawCanvas (FADXForm.FSurface, R.Left, R.Top, Width, Height, TRUE);
   end;

   if assigned (FA2image) then begin
      BaseImage.Clear (FBColor);
      x := (Width - FA2image.Width) div 2;
      y := (Height - FA2image.Height) div 2;

      BaseImage.DrawImageGreenConvert (FA2image, x, y, FGreenCol, FGreenAdd);

      R := Self.ClientRect;
      OffsetRect(R, left, top);
      if Parent <> Owner then OffsetRect (R, Parent.Left, Parent.Top);
      FADXForm.FSurface.DrawImage (BaseImage, R.Left, R.Top, TRUE);
   end;

   if Text <> '' then begin
      R := ClientRect;
      OffsetRect(R, left, top);
      if Parent <> Owner then OffsetRect (R, Parent.Left, Parent.Top);
      ATextOut (FADXForm.FSurface, R.Left, R.Top, WinRGB(31,31,31), Text);
   end;

   if (Hint <> '') and boEntered then begin
      xx := left;
      yy := Top;
      if Parent <> Owner then begin inc (xx, Parent.Left); inc (yy, Parent.Top); end;
      FADXForm.ShowHint (xx, yy, Hint);
   end;
end;

procedure TA2ILabel.paint;
var x, y: integer;
begin
   Inherited Paint;
   if assigned (FA2image) then begin
      BaseImage.Clear (FBColor);
      x := (Width - FA2image.Width) div 2;
      y := (Height - FA2image.Height) div 2;

      BaseImage.DrawImageGreenConvert (FA2image, x, y, FGreenCol, FGreenAdd);
      A2DrawImage ( Canvas, 0, 0, BaseImage);
   end;
   if assigned (FOnPaint) then FOnPaint(self);
end;

procedure TA2ILabel.Loaded;
begin
   inherited Loaded;
end;

procedure TA2ILabel.SetImage (Value: TA2Image);
begin
   FA2Image := Value;
   if BaseImage <> nil then begin BaseImage.Free; BaseImage := nil; end;
   if FA2Image <> nil then BaseImage := TA2Image.Create (Width, Height, 0, 0);
   Draw;
end;

procedure TA2ILabel.Setcolor (Value: word);
begin
   FBColor := Value;
   Draw;
end;

procedure TA2ILabel.Draw;
var x, y: integer;
begin
   Inherited Paint;
   if assigned (FA2image) then begin
      BaseImage.Clear (FBColor);
      x := (Width - FA2image.Width) div 2;
      y := (Height - FA2image.Height) div 2;
      BaseImage.DrawImageGreenConvert (FA2image, x, y, FGreenCol, FGreenAdd);
      A2DrawImage ( Canvas, 0, 0, BaseImage);
   end;
   if assigned (FOnPaint) then FOnPaint(self);
end;

//////////////////////////////////////////
//            TA2Button
//////////////////////////////////////////

constructor TA2Button.Create (AOwner: TComponent);
begin
  inherited Create(AOwner);
  AutoSize := FALSE;
  FDown := FALSE;
  FOldDown := FALSE;
  FCaptured := FALSE;
  FUpImage := TPicture.Create;
  FDownImage := TPicture.Create;
  FUpA2Image := nil;
  FDownA2Image := nil;
  FFontColor := WinRGB (31,31,31);
  FFontSelColor := WinRGB (0,0,31);
end;

destructor TA2Button.Destroy;
begin
  FDownImage.Free;
  FUpImage.Free;
//  if FUpA2Image <> nil then FUpA2Image.Free;
//  if FDownA2Image <> nil then FDownA2Image.Free;
  inherited destroy;
end;

procedure TA2Button.SetUpImage(Value: TPicture);
begin
  FUpImage.Assign(Value);
  AutoSize := FALSE;
  Width := FUpImage.Width;
  Height := FUpImage.Height;
end;

procedure TA2Button.SetDownImage(Value: TPicture);
begin
  FDownImage.Assign(Value);
  AutoSize := FALSE;
  Width := FUpImage.Width;
  Height := FUpImage.Height;
end;

procedure TA2Button.SetUpA2Image(Value: TA2Image);
begin
//   FUpA2Image := TA2Image.Create (Width,Height,0,0);
   FUpA2Image := Value;
   AutoSize := FALSE;
end;

procedure TA2Button.SetDownA2Image(Value: TA2Image);
begin
//   FDownA2Image := TA2Image.Create (Width,Height,0,0);
   FDownA2Image := Value;
   AutoSize := FALSE;
end;

procedure TA2Button.SetCaption (Value: string);
begin
   inherited Caption := Value;
   boEntered := FALSE;
   AdxPaint;
end;

function  TA2Button.GetCaption: string;
begin
   Result := inherited Caption;
end;

procedure TA2Button.CMMouseEnter(var Message: TMessage);
begin
   inherited;
   boEntered := TRUE;
end;

procedure TA2Button.CMMouseLeave(var Message: TMessage);
begin
   inherited;
   boEntered := FALSE;
end;

procedure TA2Button.WMLButtonDown(var Message: TWMLButtonDown);
begin
   inherited;
   FCaptured := TRUE;
   FDown := TRUE;

   if FOldDown <> FDOWN then begin FOldDown := FDown; paint; end;
end;

procedure TA2Button.WMMouseMove(var Message: TWMMouseMove);
begin
   inherited;
   if FCaptured then begin
      if (Message.XPos < 0) or (Message.XPos > Width) or
         (Message.YPos < 0) or (Message.YPos > Height) then FDown := FALSE
      else FDown := TRUE;
   end;
   if FOldDown <> FDOWN then begin FOldDown := FDown; paint; end;
end;

procedure TA2Button.WMLButtonUp(var Message: TWMLButtonUp);
begin
   inherited;
   FDown := FALSE;
   FCaptured := FALSE;
   if FOldDown <> FDOWN then begin FOldDown := FDown; paint; end;
end;

procedure TA2Button.AdxPaint;
const
  Alignments: array[TAlignment] of Word = (DT_LEFT, DT_RIGHT, DT_CENTER);
  WordWraps: array[Boolean] of Word = (0, DT_WORDBREAK);
var
  R: TRect;
  Can : TCanvas;
begin
   if (csDesigning in ComponentState) or not Assigned (FADXForm) then exit;
   if not Visible then exit;

   if not FDown then begin
      if Assigned (FUpImage.Graphic) then begin
         Can := A2GetCanvas;
         Can.FillRect (Self.ClientRect);
         Can.Draw (0, 0, FUpImage.Graphic);
         R := Self.ClientRect;
         OffsetRect(R, left, top);
         A2DrawCanvas (FADXForm.FSurface, R.Left, R.Top, Width, Height, TransParent);
      end else begin
         if FUpA2Image <> nil then begin
            R := Self.ClientRect;
            OffsetRect(R, left, top);
            FADXForm.FSurface.DrawImage (FUpA2Image,R.Left, R.Top, TransParent);
         end;
      end;
   end else begin
      if Assigned (FDownImage.Graphic) then begin
         Can := A2GetCanvas;
         Can.FillRect (Self.ClientRect);
         Can.Draw (0, 0, FDownImage.Graphic);
         R := Self.ClientRect;
         OffsetRect(R, left, top);
         A2DrawCanvas (FADXForm.FSurface, R.Left, R.Top, Width, Height, TransParent);
      end else begin
         if FDownA2Image <> nil then begin
            R := Self.ClientRect;
            OffsetRect(R, left, top);
            FADXForm.FSurface.DrawImage (FDownA2Image,R.Left, R.Top, TransParent);
         end;
      end;
   end;

   if Text <> '' then begin
      R := ClientRect;

      OffsetRect(R, left, top);

      //change by minds
      if boEntered then
         ATextOut (FADXForm.FSurface, R.Left, R.Top, FFontSelColor, Text)
      else
         ATextOut (FADXForm.FSurface, R.Left, R.Top, FFontColor, Text);
   end;

   if (Hint <> '') and boEntered then FADXForm.ShowHint (Left, Top, Hint);
end;

procedure TA2Button.paint;
begin
   if FDown then begin
      if Assigned (FDownImage.Graphic) then
         Canvas.Draw (0, 0, FDownImage.Graphic)
      else if FDownA2Image <> nil then
         A2DrawImage(Canvas, 0, 0, FDownA2Image);
   end else begin
      if Assigned (FUpImage.Graphic) then
         Canvas.Draw (0, 0, FUpImage.Graphic)
      else if FUpA2Image <> nil then
         A2DrawImage(Canvas, 0, 0, FUpA2Image);
   end;

   if not (Assigned(FUpImage.Graphic) or (FUpA2Image <> nil)) then
      inherited paint; 
end;

procedure TA2Button.Loaded;
begin
   inherited Loaded;
end;

//////////////////////////////////////////
//            TA2IEdit
//////////////////////////////////////////

constructor TA2Edit.Create(AOwner: TComponent);
begin
   inherited Create (AOwner);

   OldText := '';
   if not (csDesigning in ComponentState) then begin
      Timer := TTimer.Create (AOwner);
      Timer.Enabled := TRUE;
      Timer.Interval := 400;
      Timer.OnTimer := TimerTimer;
   end;
   FFontColor := clWhite;
   FPassChar := #0;
end;

destructor TA2Edit.Destroy;
begin
   if not (csDesigning in ComponentState) then Timer.Free;
   inherited Destroy;
end;

procedure TA2Edit.AdxPaint;
var
   i : integer;
   str, tmpStr : string;
   R : TRect;
   Can : TCanvas;
begin // TEdit
   if not Visible then exit;
   if not Assigned (FADXForm) then exit;

   Can := A2GetCanvas;
   Can.Font.Name := Font.Name;
   Can.Font.Color := FFontColor;
   Can.Font.Size := Font.Size;
   with Can do begin
      FillRect (ClientRect);
      R := Self.ClientRect;
      str := text;
      if (passwordchar <> char(0)) and (text <> '') then begin
         for i := 1 to Length(text) do str[i] := passwordchar;
      end;
      if FPassChar <> #0 then begin
         for i := 1 to Length(text) do str[i] := FPassChar;
      end;
      if TextWidth (str) > Width - 8 then begin
         text := OldText;
         SelStart := Length(text);
      end else OldText := text;
      str := text;
      if (passwordchar <> char(0)) and (text <> '') then begin
         for i := 1 to Length(text) do str[i] := passwordchar;
      end;
      if FPassChar <> #0 then begin
         for i := 1 to Length(text) do str[i] := FPassChar;
      end;

      tmpStr := str;
      if boTail then begin
         if SelStart < Length(str) then
            Insert('&', tmpStr, SelStart+1)
         else
            tmpStr := tmpStr + '& ';
      end;
      DrawText(Handle, PChar(tmpStr), Length(tmpStr), R, DT_VCENTER or DT_SINGLELINE);
   end;

   if SelLength <> 0 then begin
      SelStart := SelStart + SelLength;
      Sellength := 0;
   end;

   R := Self.ClientRect;
   OffsetRect(R, left, top);
   A2DrawCanvas (FADXForm.FSurface, R.Left, R.Top, Width, Height, TRUE);
end;

procedure TA2Edit.SetFontColor(value: integer);
begin
   FFontColor := value;
end;

procedure TA2Edit.TimerTimer (Sender: TObject);
var fh : THandle;
begin
   fh := GetFocus;
   if Handle = fh then begin
      boTail := not boTail;
      AdxPaint;
   end else begin
      FocusExit(self);
   end;
end;

procedure TA2Edit.FocusEnter (Sender: TObject);
begin
   TimerTimer(self);
   boTail := TRUE;
   Adxpaint;
   if assigned (FOnEnter) then FOnEnter (Sender);
end;

procedure TA2Edit.FocusExit (Sender: TObject);
begin
   boTail := FALSE;
   Adxpaint;
   if assigned (FOnExit) then FOnExit (Sender);
end;

procedure TA2Edit.TextChange (Sender: TObject);
begin
   AdxPaint;
   if assigned (FOnChange) then FOnChange (Sender);
end;

procedure TA2Edit.SelfKeyDown (Sender: TObject; var Key: Word; Shift: TShiftState);
begin
   if (key = VK_LEFT) or (key = VK_RIGHT) or (key = VK_UP) or (key = VK_DOWN) then AdxPaint;
   if assigned (FOnKeyDown) then FOnKeyDown (Sender, Key, Shift);
end;

procedure TA2Edit.Loaded;
begin
   inherited loaded;
   if not (csDesigning in ComponentState) then begin
      FOnEnter := OnEnter;
      FOnExit := OnExit;
      FOnChange := OnChange;
      FOnKeyDown := OnKeyDown;

      OnEnter := FocusEnter;
      OnExit := FocusExit;
      OnChange := TextChange;
      OnKeyDown := SelfKeyDown;
   end;
end;

//////////////////////////////////////////
//            TA2Memo
//////////////////////////////////////////

constructor TA2Memo.Create(AOwner: TComponent);
begin
   inherited Create (AOwner);
   FLineMax := 4;
   OldText :='';
//   WordWrap := FALSE;
   if not (csDesigning in ComponentState) then begin
      Timer := TTimer.Create (AOwner);
      Timer.Enabled := FALSE;
      Timer.Interval := 400;
      Timer.OnTimer := TimerTimer;
   end;
end;

destructor TA2Memo.Destroy;
begin
   if not (csDesigning in ComponentState) then Timer.free;
   inherited Destroy;
end;
{
procedure TA2Memo.GetLineColumn(Sender: TMemo; var iLin: Integer; var iCol:Integer);
var
   lLin, lCol: Longint;
begin
   lLin := SendMessage(Sender.Handle, EM_LINEFROMCHAR, Sender.SelStart, 0);
   lCol := SendMessage(Sender.Handle, EM_LINEINDEX, lLin, 0);
   iCol := Sender.SelStart - lCol + 1;
   iLin := lLin + 1;
end;
}

procedure TA2Memo.AdxPaint;
var
   myY, TextH : integer;
   str, addstr : String;
   tempstr : string;
begin
   if (csDesigning in ComponentState) or not Assigned (FADXForm) then exit;
   if not Visible then exit;

   myY := Self.Top;
   TextH := ATextHeight('안');
//   for i := 0 to Self.Lines.Count -1 do begin
//   str := Lines[i];
   str := Self.Text;
   if boTail then begin // 수정해야 함 현제 테스트용
      tempstr := Copy (str, 1, Self.SelStart);
      tempstr := tempstr + '&' + Copy (str, Self.SelStart+1, Length(str));
      str := tempstr;
   end;
   while TRUE do begin
      addstr := CutLengthString (str, Width-4);
      ATextOut (FADXForm.FSurface, Self.Left+2, myY, 1057, addstr);
      if str = '' then break;
      myY := myY + TextH + 1;
   end;

//   myY := myY + TextH + 1;
//   end;
{
   SelS := 0;
   for i := 0 to Self.Lines.Count -1 do begin
      SelS := SelS + (Length(Lines[i]))+1;
   end;
   Self.SelStart := Sels;
}
{
   for i := 0 to Lines.Count -1 do begin
      Can.TextOut (2,mY, Lines[i]);
      mY := mY + Can.TextHeight (Lines[i]);
   end;
   OffsetRect (R, Left, Top);
   A2DrawCanvas (FADXForm.FSurface, R.Left, R.Top, Width, Height, TRUE);
}
{
var
   i : integer;
   flag : Boolean;
   str : string;
   R : TRect;
   Can : TCanvas;
begin // TMemo
   if not Visible then exit;
//   R := ClientRect;
   Can := A2GetCanvas;
   Can.Fillrect (ClientRect);

   with Can do begin
      R := ClientRect;
      OffsetRect(R, left, top);
      if not Transparent then begin
         Brush.Color := Self.Color;
         Brush.Style := bsSolid;
         FillRect(R);
      end;
      Brush.Style := bsClear;
      Font := Self.Font;

      flag := FALSE;
      for i := 0 to Lines.Count -1 do begin
         if TextWidth (Lines[i]) > Width-8 then flag := TRUE;
      end;
      if FLineMax < Lines.Count then flag := TRUE;

      if flag then begin text := OldText; SelStart := Length(text); end
      else OldText := text;

      str := text;
      if boTail then begin
         str := Copy (text, 1, SelStart);
         str := str + '&' + Copy (text, SelStart+1, Length(text));
      end;
      DrawText(Handle, PChar(str), Length(str), R, 64);
   end;
   if SelLength <> 0 then begin
      SelStart := SelStart + SelLength;
      Sellength := 0;
   end;
   A2DrawCanvas (FADXForm.FSurface, R.Left, R.Top, Width, Height, TRUE);
}
end;

procedure TA2Memo.TimerTimer (Sender: TObject);
begin
   boTail := not boTail;
   AdxPaint;
end;

procedure TA2Memo.FocusEnter (Sender: TObject);
begin
   Timer.Enabled := TRUE;
   boTail := TRUE;
   Adxpaint;
   if assigned (FOnEnter) then FOnEnter (Sender);
end;

procedure TA2Memo.FocusExit (Sender: TObject);
begin
   Timer.Enabled := FALSE;
   boTail := FALSE;
   Adxpaint;
   if assigned (FOnExit) then FOnExit (Sender);
end;

procedure TA2Memo.TextChange (Sender: TObject);
begin
   AdxPaint;
   if assigned (FOnChange) then FOnChange (Sender);
end;

procedure TA2Memo.Loaded;
begin
   inherited loaded;
   if not (csDesigning in ComponentState) then begin
      FOnEnter := OnEnter;
      FOnExit := OnExit;
      FOnChange := OnChange;
      OnEnter := FocusEnter;
      OnExit := FocusExit;
      OnChange := TextChange;
   end;
end;

////////////////////////////////////////////////////////////////////////////////
//
////////////////////////////////////////////////////////////////////////////////
constructor TA2ProgressBar.Create(AOwner: TComponent);
begin
   inherited Create (AOwner);
   FPicture := TPicture.Create;
   FADXForm := nil;
   FMinValue := 0;
   FMaxValue := 100;
   FValue := 0;
   Caption := '';
   Width := 100;
   Height := 20;
end;

destructor TA2ProgressBar.Destroy;
begin
  FPicture.Free;
  inherited Destroy;
end;

procedure TA2ProgressBar.Loaded;
begin
   inherited Loaded;
end;

procedure TA2ProgressBar.paint;
var
   R : TRect;
begin
   inherited paint;
   Canvas.FillRect (ClientRect);

   if Assigned (FPicture) then begin
      R := ClientRect;
      R.Right := R.Left + FValue*Width div FMaxValue;
      Canvas.StretchDraw (R, FPicture.Graphic);
   end;
end;

procedure TA2ProgressBar.SetPicture(Value: TPicture);
begin
  FPicture.Assign(Value);
  if FPicture.Graphic <> nil then begin
     Width := FPicture.Width;
     Height := FPicture.Height;
  end;
end;

procedure TA2ProgressBar.AdxPaint;
var
   R : TRect;
   Can : TCanvas;
begin
   if (csDesigning in ComponentState) or not Assigned (FADXForm) then exit;
   if not Visible then exit;
   R := ClientRect;
   R.Right := R.Left + FValue*Width div FMaxValue;

   Can := A2GetCanvas;
   Can.Fillrect (ClientRect);
//   Can.StretchDraw (R, FPicture.Graphic);
   Can.CopyRect(R, FPicture.Bitmap.Canvas, Rect(0, 0, FValue*Width div FMaxValue, Height));

   OffsetRect (R, Left, Top);
   A2DrawCanvas (FADXForm.FSurface, R.Left, R.Top, Width, Height, TRUE);
end;


//////////////////////////////////////////
//     TA2AnimateButton : TLabel
//////////////////////////////////////////

constructor TA2AnimateButton.Create(AOwner: TComponent);
begin
   inherited Create (AOwner);
   FAtzFileName := '';
   Ans2ImageLib := TA2ImageLib.Create;
   Caption := '';
   CurFrame := 0;
   boUpProcess := FALSE;
   if not (csDesigning in ComponentState) then begin
      Timer := TTimer.Create (AOwner);
      Timer.Enabled := TRUE;
      Timer.Interval := 80;
      Timer.OnTimer := TimerTimer;
   end;
end;

destructor TA2AnimateButton.Destroy;
begin
   Ans2ImageLib.Free;
   if not (csDesigning in ComponentState) then Timer.Free;
   inherited Destroy;
end;

procedure TA2AnimateButton.AdxPaint;
begin
   if (csDesigning in ComponentState) or not Assigned (FADXForm) then exit;
   if not Visible then exit;
   if Ans2ImageLib.count <> 0 then
      FADXForm.Surface.DrawImage (Ans2ImageLib.Images[CurFrame], Left, Top, TRUE);
end;

procedure TA2AnimateButton.paint;
begin
   inherited paint;
   if ans2ImageLib.Count <> 0 then A2DrawImage (Canvas, 0,0,Ans2ImageLib[CurFrame]);
end;

procedure TA2AnimateButton.TimerTimer (Sender: TObject);
begin
   if boUpProcess then CurFrame := CurFrame + 1
   else CurFrame := CurFrame -1;

   if CurFrame > AtzImageCount-1 then CurFrame := AtzImagecount;
   if CurFrame < 0 then begin
      Timer.Enabled := FALSE;
      CurFrame := 0;
   end;
end;

procedure TA2AnimateButton.Loaded;
begin
   inherited Loaded;
   if FAtzFileName <> '' then begin
      Ans2ImageLib.LoadFromFile (FAtzFileName);
      if ans2Imagelib.count <> 0 then begin
         Width := Ans2ImageLib.Images[0].Width;
         Height := Ans2ImageLib.Images[0].Height;
      end;
   end;
end;

procedure TA2AnimateButton.CMMouseEnter(var Message: TMessage);
begin
  inherited;
  boUpProcess := TRUE;
  Timer.Enabled := TRUE;
end;

procedure TA2AnimateButton.CMMouseLeave(var Message: TMessage);
begin
  inherited;
  boUpProcess := FALSE;
end;

//////////////////////////////////////////
//     TA2AnimateImage : TLabel
//////////////////////////////////////////

constructor TA2AnimateImage.Create(AOwner: TComponent);
begin
   inherited Create (AOwner);
   FAtzFileName := '';
   Ans2ImageLib := TA2ImageLib.Create;
   Caption := '';
   CurFrame := 0;
   if not (csDesigning in ComponentState) then begin
      Timer := TTimer.Create (AOwner);
      Timer.Enabled := TRUE;
      Timer.Interval := 100;
      Timer.OnTimer := TimerTimer;
   end;
end;

destructor TA2AnimateImage.Destroy;
begin
   Ans2ImageLib.Free;
   if not (csDesigning in ComponentState) then Timer.Free;
   inherited Destroy;
end;

procedure TA2AnimateImage.AdxPaint;
begin
   if (csDesigning in ComponentState) or not Assigned (FADXForm) then exit;
   if not Visible then exit;
   if Ans2ImageLib.count <> 0 then
      FADXForm.Surface.DrawImage (Ans2ImageLib.Images[CurFrame], Left, Top, TRUE);
end;

procedure TA2AnimateImage.paint;
begin
   inherited paint;
   if ans2ImageLib.Count <> 0 then A2DrawImage (Canvas, 0,0,Ans2ImageLib[CurFrame]);
end;

procedure TA2AnimateImage.TimerTimer (Sender: TObject);
begin
   CurFrame := CurFrame + 1;
   if CurFrame > AtzImageCount-1 then CurFrame := 0;
end;

procedure TA2AnimateImage.Loaded;
begin
   inherited Loaded;
   if FAtzFileName <> '' then begin
      Ans2ImageLib.LoadFromFile (FAtzFileName);
      if ans2Imagelib.count <> 0 then begin
         Width := Ans2ImageLib.Images[0].Width;
         Height := Ans2ImageLib.Images[0].Height;
      end;
   end;
end;

//////////////////////////////////////////
//            TA2ListBox : TListBox
//////////////////////////////////////////
function  calculation4 (xMax,xValue,yMax,yValue,aResult : integer): integer;
begin
   Result := 0;
   case aResult of
      1 : Result := (xValue*yMax) div yValue;
      2 : Result := (xMax*yValue) div yMax;
      3 : Result := (xMax*yValue) div xValue;
      4 : Result := (xValue*yMax) div xMax;
   end;
end;

constructor TA2ListBox.Create(AOwner: TComponent);
begin
   inherited Create (AOwner);
   Width := 144;
   Height := 200;
   FOverIndex := 0;
   FItemHeight := 12;
   FItemMerginX := 3;
   FItemMerginY := 3;

   ScrollBarWidth := 16;
   ScrollBarHeight := 16;
   ScrollBarTrackHeight := 16;

   FCanvas := TControlCanvas.Create;
   TControlCanvas(FCanvas).Control := Self;
   FCanvas.Brush.Color := clGray;

   FStringList := TStringList.Create;
   FItemIndex := 0;
   FViewIndex := 0;
   FFontColor := WinRGB (31,31,31);
   FFontSelColor := WinRGB (0,0,255);
   FEmphasis := FALSE;
   FScrollBarView := TRUE;

   FScrollTrackTopPos := ScrollBarHeight;
   FScrollTrackingPos := ScrollBarHeight;
end;

destructor  TA2ListBox.Destroy;
begin
   inherited destroy;
   FCanvas.Free;
   FStringList.Free;
end;

procedure   TA2ListBox.Loaded;
begin
   inherited loaded;
   if (csDesigning in ComponentState) or not Assigned (FAdxForm) then exit;
   FSurface := nil;
   FScrollTop := nil;
   FScrollTrack := nil;
   FScrollBottom := nil;
   FScrollBackImg := nil;

   ViewItemCount := (Height- (FItemMerginY * 2)) div FItemHeight;

   FItemHeight := Self.ItemHeight;
   FItemMerginX := Self.ItemMerginX;
   FItemMerginY := Self.ItemMerginY;
   FFontColor := Self.FontColor;
   FFontSelColor := Self.FontSelColor;
   FEmphasis := Self.FontEmphasis;
   FScrollBarView := Self.ScrollBarView;
end;

procedure TA2ListBox.Resize;
begin
   inherited;
   ViewItemCount := (Height- (FItemMerginY * 2)) div FItemHeight;
end;

procedure   TA2ListBox.Clear;
begin
   FStringList.Clear;
   FViewIndex := 0;
   FScrollTrackingPos := ScrollBarHeight;
end;

procedure   TA2ListBox.Paint;
begin
end;

procedure   TA2ListBox.AdxPaint;
begin
   if not Assigned (FAdxForm) then exit;
   if not Visible then exit;
   DrawItem(FAdxForm.Surface);
   if FScrollBarView then DrawScrollBar(FAdxForm.Surface);
end;

procedure   TA2ListBox.DrawItem (aSurface: TA2Image);
var
   i, xx, yy, aColor : integer;
   R : TRect;
   TmpImg : TA2Image;
   DIS: TDrawItemState;
begin
   R := Self.ClientRect;
   OffsetRect(R, left, top);
   xx := FItemMerginX + R.Left;
   yy := FItemMerginY + R.Top;
   if FSurface <> nil then aSurface.DrawImage (FSurface, R.Left, R.Top, TRUE);

   if FScrollBarView then TmpImg := TA2Image.Create (Width-ScrollBarWidth-FItemMerginX,ItemHeight+2,0,0)
   else TmpImg := TA2Image.Create (Width-(FItemMerginX*2),ItemHeight+2,0,0);

   for i := FViewIndex to ViewItemCount+FViewIndex -1 do begin
      if i > FStringList.Count -1 then break;
      TmpImg.Clear (0);
      R := Rect (0,0,TmpImg.Width,TmpImg.Height);
      if i = FItemIndex then begin
         aColor := FFontSelColor;
         DIS := TIS_Select;
      end else begin
         aColor := FFontColor;
         DIS := TIS_None;
      end;
      if FEmphasis then ATextOut (TmpImg, 1, 1, WinRGB (1, 1, 1), FStringList[i]);

      if Assigned(FOnAdxDrawItem) then
         FOnAdxDrawItem (TmpImg, i, FStringList[i], R, DIS)
      else
         ATextOut (TmpImg, 0, 0, aColor, FStringList[i]);

      aSurface.DrawImage (TmpImg,xx,yy,TRUE);
      inc (yy, FItemHeight);
   end;
   TmpImg.Free;
end;

procedure   TA2ListBox.DrawScrollBar (aSurface: TA2Image);
var
   R : TRect;
   DrawScrollState : TDrawScrollState;
   x, y, TrackerHeight: integer;
begin
   R := Self.ClientRect;
   OffsetRect(R, left, top);

   DrawScrollState := TSS_None;
   //BackImg
   if FScrollBackImg <> nil then begin
      x := (R.Left+Width) - (ScrollBarWidth+FScrollBackImg.Width) div 2;
      y := R.Top + (Height - FScrollBackImg.Height) div 2;
      aSurface.DrawImage (FScrollBackImg, x, y, TRUE);
   end;
   //top
   if FScrollTop <> nil then begin
      x := (R.Left+Width) - (ScrollBarWidth+FScrollTop.Width) div 2;
      y := R.Top + (ScrollBarHeight - FScrollTop.Height) div 2;
      if boScrollTop then begin
         aSurface.DrawImage(FScrollTop, x, y, True);
         DrawScrollState := TSS_TopClick;
      end else if FScrollDTop <> nil then
         aSurface.DrawImage(FScrollDTop, x, y, True)
   end;
   {
   if FScrollTop <> nil then begin
      if boScrollTop then begin
         aSurface.DrawImage (FScrollTop, (R.Left+Width)-ScrollBarWidth, R.Top, TRUE);
         DrawScrollState := TSS_TopClick;
      end else if FScrollDTop <> nil then
         aSurface.DrawImage (FScrollDTop, (R.Left+Width)-ScrollBarWidth, R.Top, TRUE);
   end;
   }
   //bottom
   if FScrollBottom <> nil then begin
      x := (R.Left+Width) - (ScrollBarWidth+FScrollBottom.Width) div 2;
      y := (R.Top+Height) - (ScrollBarHeight+FScrollBottom.Height) div 2;
      if boScrollBottom then begin
         aSurface.DrawImage (FScrollBottom, x, y, TRUE);
         DrawScrollState := TSS_BottomClick;
      end else
         aSurface.DrawImage (FScrollDBottom, x, y, TRUE);
   end;
   {
   if FScrollBottom <> nil then begin
      if boScrollBottom then begin
         aSurface.DrawImage (FScrollBottom, (R.Left+Width)-ScrollBarWidth, (R.Top+Height)-ScrollBarHeight, TRUE);
         DrawScrollState := TSS_BottomClick;
      end else
         aSurface.DrawImage (FScrollDBottom, (R.Left+Width)-ScrollBarWidth, (R.Top+Height)-ScrollBarHeight, TRUE);
   end;
   }
   //Track
   if FScrollTrack <> nil then begin

      if Assigned(FScrollTrack) then TrackerHeight := FScrollTrack.Height
                                else TrackerHeight := ScrollBarTrackHeight;

      if (FStringList.Count-ViewItemCount) > 0 then begin
         FScrollTrackingPos := calculation4 (FStringList.Count-ViewItemCount,
                                             FViewIndex,
                                             Height-ScrollBarHeight*2-TrackerHeight,
                                             0, 4) + ScrollBarHeight;
      end else begin
         FScrollTrackingPos := ScrollBarHeight;
      end;

      x := (R.Left+Width) - (ScrollBarWidth+FScrollTrack.Width) div 2;
      y := R.Top+FScrollTrackingPos;
      if boScrollTrack then begin
         aSurface.DrawImage (FScrollTrack, x, y, TRUE);
         DrawScrollState := TSS_TrackClick;
      end else begin
         aSurface.DrawImage (FScrollDTrack, x, y, TRUE);
      end;
   end;
   R := Rect ((R.Left+Width)-ScrollBarWidth,R.Top,R.Left+Width,R.Top+Height);
   if Assigned (FOnAdxScrollDraw) then FOnAdxScrollDraw (aSurface, R, DrawScrollState);
end;

procedure   TA2ListBox.SetBackImage (value : TA2Image);
begin
   FSurface := value;
end;

procedure   TA2ListBox.SetScrollTopImage (UpImage, DownImage : TA2Image);
begin
   FScrollTop := UpImage;
   FScrollDTop := DownImage;
end;

procedure   TA2ListBox.SetScrollTrackImage (UpImage, DownImage : TA2Image);
begin
   FScrollTrack := UpImage;
   FScrollDTrack := DownImage;
end;

procedure   TA2ListBox.SetScrollBottomImage (UpImage, DownImage : TA2Image);
begin
   FScrollBottom := UpImage;
   FScrollDBottom := DownImage;
end;

procedure   TA2ListBox.SetScrollBackImage (value : TA2Image);
begin
   FScrollBackImg := value;
end;

var
   OrY : integer;
   TrackCount : integer = 0;

procedure   TA2ListBox.DecItem (value: integer);
var
   TrackerHeight: integer;
begin
   if (csDesigning in ComponentState) then exit;
   Dec(FViewIndex, value);
   if FViewIndex <= 0 then begin
      FViewIndex := 0;
      FScrollTrackingPos := ScrollBarHeight;
      exit;
   end;
   if Assigned(FScrollTrack) then TrackerHeight := FScrollTrack.Height
                             else TrackerHeight := ScrollBarTrackHeight;
   FScrollTrackingPos := calculation4 (FStringList.Count-ViewItemCount, FViewIndex, Height-ScrollBarHeight*2-TrackerHeight, 0, 4);
   FScrollTrackingPos := FScrollTrackingPos+ScrollBarHeight;
end;

procedure   TA2ListBox.IncItem (value: integer);
var
   TrackerHeight: integer;
begin
   if Assigned(FScrollTrack) then TrackerHeight := FScrollTrack.Height
                             else TrackerHeight := ScrollBarTrackHeight;

   if (csDesigning in ComponentState) then exit;
   inc(FViewIndex, value);
   if FViewIndex+ViewItemCount > FStringList.Count-1 then begin
      FViewIndex := FStringList.Count - ViewItemCount;
      FScrollTrackingPos := Height-ScrollBarHeight-TrackerHeight;
      exit;
   end;
   FScrollTrackingPos := calculation4 (FStringList.Count-ViewItemCount, FViewIndex, Height-ScrollBarHeight*2-TrackerHeight, 0, 4);
   FScrollTrackingPos := FScrollTrackingPos+ScrollBarHeight;
end;

procedure   TA2ListBox.IncItemIndex (value: integer);
begin
   if (csDesigning in ComponentState) then exit;
   inc (FItemIndex, value);
   if FStringList.Count -1 < ViewItemCount then begin
      if FItemIndex > FStringList.Count-1 then begin
         FItemIndex := FStringList.Count-1;
         exit;
      end;
   end;
   if FItemIndex >= ViewItemCount then begin
      if FItemIndex > FStringList.Count-1 then FItemIndex := FStringList.Count-1;
      IncItem(value);
   end;
end;

procedure   TA2ListBox.DecItemIndex (value: integer);
begin
   if (csDesigning in ComponentState) then exit;
   Dec (FItemIndex, value);
   if (FStringList.Count -1 < ViewItemCount) or (FItemIndex < 0) then begin
      if FItemIndex < 0 then begin
         FItemIndex := 0; DecItem(value); exit;
      end;
   end;
   if FItemIndex = FViewIndex-1 then begin
      if FItemIndex < 0 then begin
         FItemIndex := 0; exit;
      end;
      DecItem(value); exit;
   end;
   if value > 1 then DecItem(value);
end;

procedure   TA2ListBox.MouseDown(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
   if (x>FItemMerginX) and (x<(Width-ScrollBarWidth-FItemMerginX)) and (y>FItemMerginY) and (y<Height-FItemMerginY) then begin
      // Item을 클릭시
      FItemIndex := FViewIndex + (y-FItemMerginY) div ItemHeight;
      inherited MouseDown (Button, Shift, x,y);
   end else if (x>Width-ScrollBarWidth) and (x<Width) then begin
      // 스크롤바쪽 클릭
      // Top Scroll Image
      if (y>0) and (y<ScrollBarHeight) then begin
         boScrollTop := TRUE;
         DecItem(1)
      end else
      // Bottom Scroll Image
      if (y>Height-ScrollBarHeight) and (y<Height) then begin
         boScrollBottom := TRUE;
         IncItem(1);
      end else
      // Tracking
      if Assigned(FScrollTrack) and (y>FScrollTrackingPos) and (y<FScrollTrackingPos+FScrollTrack.Height) then begin
         boScrollTrack := TRUE;
         OrY := y - FScrollTrackingPos;
      end;
   end;
   if FStringList.Count -1 < ViewItemCount then begin
      FViewIndex := 0;
      FScrollTrackingPos := ScrollBarHeight;
   end;
end;

procedure   TA2ListBox.MouseMove(Shift: TShiftState; X, Y: Integer);
var
   TrackerHeight: integer;
begin
   CurXMouse := x;
   CurYMouse := y;

   if (x>FItemMerginX) and (x<(Width-ScrollBarWidth-FItemMerginX)) and (y>FItemMerginY) and (y<Height-FItemMerginY) then begin
      FOverIndex := FViewIndex + (y-FItemMerginY) div ItemHeight;
   end;

   if Assigned(FScrollTrack) then TrackerHeight := FScrollTrack.Height
                             else TrackerHeight := ScrollBarTrackHeight;
   if boScrollTrack then begin
      FScrollTrackingPos := y - Ory;
      FScrollTrackTopPos := y - ScrollBarHeight;
      if FScrollTrackTopPos < ScrollBarHeight then FScrollTrackTopPos := ScrollBarHeight;
      if FScrollTrackTopPos > Height-(ScrollBarHeight*2 + TrackerHeight) then FScrollTrackTopPos := Height-(ScrollBarHeight + TrackerHeight);

      if FScrollTrackingPos < ScrollBarHeight then FScrollTrackingPos := ScrollBarHeight;
      if FScrollTrackingPos > Height-(ScrollBarHeight + TrackerHeight) then FScrollTrackingPos := Height-(ScrollBarHeight + TrackerHeight);
      if FStringList.Count -1 > ViewItemCount then begin
         FViewIndex := calculation4 (FStringList.Count-ViewItemCount, 0, Height-(ScrollBarHeight*2)-TrackerHeight, FScrollTrackingPos-ScrollBarHeight, 2);
      end;
   end;
   inherited MouseMove (Shift,x,y);
end;

procedure   TA2ListBox.MouseUp(Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
   boScrollTop := FALSE;
   boScrollTrack := FALSE;
   boScrollBottom := FALSE;
   inherited MouseUp (Button, Shift, x, y);
end;

procedure   TA2ListBox.KeyDown(var Key: Word; Shift: TShiftState);
begin
   inherited KeyDown (Key, Shift);
end;

procedure   TA2ListBox.KeyUp(var Key: Word; Shift: TShiftState);
begin
   inherited Keyup (Key, Shift);
end;

procedure   TA2ListBox.KeyPress(var Key: Char);
begin
   inherited KeyPress (Key);
end;

procedure   TA2ListBox.DblClick;
begin
   if (CurXMouse>FItemMerginX) and (CurXMouse<(Width-ScrollBarWidth-FItemMerginX))
   and (CurYMouse>FItemMerginY) and (CurYMouse<Height-FItemMerginY) then begin
      FItemIndex := FViewIndex + (CurYMouse-FItemMerginY) div ItemHeight;
      if (FItemIndex >= 0) and (FItemIndex < FStringList.Count) then inherited DblClick;
   end;
end;

procedure   TA2ListBox.WndProc (var Message : TMessage);
var akey : Word;
begin
   inherited WndProc(Message);
   case Message.Msg of
//      WM_LBUTTONDOWN, WM_LBUTTONDBLCLK :
      WM_LBUTTONDOWN :
         begin
            if not (csDesigning in ComponentState) and not Focused then begin
//            if not (csDesigning in ComponentState) then begin
//               if not FboFocus then begin
                  Windows.SetFocus (Handle);
//                  FboFocus := TRUE;
//               end;
               if not Focused then exit;
            end;
         end;
      WM_KEYDOWN, WM_SYSKEYDOWN :
         begin
            if not (csDesigning in ComponentState) then begin
               DoKeyDown(TWMKey(Message));
               aKey := TWMKey(Message).CharCode;
               case aKey of
                  VK_PRIOR : DecItemIndex(ViewItemCount);
                  VK_NEXT  : IncItemIndex(ViewItemCount);
                  VK_END   : IncItemIndex(FStringList.Count);
                  VK_HOME  : DecItemIndex(FStringList.Count);
                  VK_LEFT, VK_UP: DecItemIndex(1);
                  VK_RIGHT, VK_DOWN : IncItemIndex(1);
               end;
            end;
         end;
   end;
end;

procedure   TA2ListBox.WMMouseWheel(var Message: TWMMouseWheel);
begin
   if ViewItemCount > FStringList.Count then exit;
   if Message.WheelDelta > 0 then begin
      DecItem(3)
   end else begin
      IncItem(3)
   end;
end;

procedure   TA2ListBox.CreateWnd;
begin
   inherited CreateWnd;
end;

procedure   TA2ListBox.DestroyWnd;
begin
   inherited DestroyWnd;
end;

procedure   TA2ListBox.CreateParams(var Params: TCreateParams);
type
  PSelects = ^TSelects;
  TSelects = array[Boolean] of DWORD;
const
  BorderStyles: array[TBorderStyle] of DWORD = (0, WS_BORDER);

  Styles: array[TListBoxStyle] of DWORD =
    (0, LBS_OWNERDRAWFIXED, LBS_OWNERDRAWVARIABLE, 0, 0);
  Sorteds: array[Boolean] of DWORD = (0, LBS_SORT);
  MultiSelects: array[Boolean] of DWORD = (0, LBS_MULTIPLESEL);
  ExtendSelects: array[Boolean] of DWORD = (0, LBS_EXTENDEDSEL);
  IntegralHeights: array[Boolean] of DWORD = (LBS_NOINTEGRALHEIGHT, 0);
  MultiColumns: array[Boolean] of DWORD = (0, LBS_MULTICOLUMN);
  TabStops: array[Boolean] of DWORD = (0, LBS_USETABSTOPS);
  CSHREDRAW: array[Boolean] of DWORD = (CS_HREDRAW, 0);
var
  Selects: PSelects;
begin
  inherited CreateParams(Params);
  CreateSubClass(Params, 'LISTBOX');
  with Params do
  begin
    Selects := @ExtendSelects;
    Style := Style or (WS_HSCROLL or WS_VSCROLL or LBS_HASSTRINGS or
      LBS_NOTIFY) or Styles[lbStandard] or Sorteds[FALSE] or
      Selects^[FALSE] or IntegralHeights[FALSE] or
      MultiColumns[FALSE] or BorderStyles[bsSingle] or
      TabStops[FALSE];
      Style := Style and not WS_BORDER;
      ExStyle := ExStyle or WS_EX_CLIENTEDGE;
    WindowClass.style := WindowClass.style and not (CSHREDRAW[UseRightToLeftAlignment] or CS_VREDRAW);
  end;
end;

procedure   TA2ListBox.AddItem (aStr : string);
begin
   FStringList.Add (aStr);
end;

function    TA2ListBox.GetItem (Value : integer): string;
begin
   Result := '';
   if (Value < 0) or (Value > FStringList.Count-1) then exit;
   Result := FStringList[Value];
end;

procedure   TA2ListBox.SetItem (Value : integer; aItem: string);
begin
   if (Value < 0) or (Value > FStringList.Count-1) then exit;
   FStringList[Value] := aItem;
end;

procedure   TA2ListBox.DeleteItem (Value : integer);
begin
   FStringList.Delete(Value);
end;

function    TA2ListBox.Count : integer;
begin
   Result := FStringList.Count;
end;

{
constructor TA2ListBox.Create(AOwner: TComponent);
begin
   inherited Create (AOwner);
   FAtzFileName := '';
   Ans2ImageLib := TA2ImageLib.Create;
end;

destructor  TA2ListBox.Destroy;
begin
   Ans2ImageLib.Free;
   inherited Destroy;
end;

procedure   TA2ListBox.Loaded;
begin
   inherited loaded;
   if (csDesigning in ComponentState) or not Assigned (FAdxForm) then exit;
   if FAtzFileName <> '' then Ans2ImageLib.LoadFromFile (FAtzFileName);
end;

procedure   TA2ListBox.DrawScrollBar;
var
   i, h, t : integer;
   R, RB : TRect;
   Scrollinfo : TScrollinfo;
begin
   if Items.Count <= 0 then exit;
   if Width = ClientRect.Right - ClientRect.Left then exit;

   R := ClientRect;
   OffsetRect (R, Left, Top);
   for i := 1 to Height div 16-1 do     // bottom img
      FADXForm.Surface.DrawImage (Ans2ImageLib.Images[2], R.Right, R.Top+i*16, FALSE);

   FADXForm.Surface.DrawImage (Ans2ImageLib.Images[0], R.Right, R.Top, FALSE); //Top arrow
   FADXForm.Surface.DrawImage (Ans2ImageLib.Images[1], R.Right, R.Bottom-16, FALSE); // Bottom arrow

   h := (Height div FItemHeight) * (Height-32) div Items.Count -4;

   t := TopIndex * (Height-32) div Items.Count;

   GetScrollinfo (handle, 0, Scrollinfo);

   RB.Top := R.Top + 16+t;
   RB.Left := R.Right;
   RB.Right := R.Right + 16;
   RB.Bottom := R.Top + 16 + h+t;

   for i := 1 to (RB.Bottom-RB.Top) div 16-1 do
      FADXForm.Surface.DrawImage (Ans2ImageLib.Images[4], RB.Left, RB.Top+i*16, FALSE); // middle scrollbar

   FADXForm.Surface.DrawImage (Ans2ImageLib.Images[3], RB.Left, RB.Top, FALSE); // top scrollbar
   FADXForm.Surface.DrawImage (Ans2ImageLib.Images[5], RB.Left, RB.Bottom-16, FALSE); // bottom scrollbar
end;

procedure   TA2ListBox.AdxPaint;
var
   i : integer;
   str : string;
   R : TRect;
   State : Integer;
   FColor, BColor: TColor;
   Can : TCanvas;
begin // TListbox
   if (csDesigning in ComponentState) or not Assigned (FAdxForm) then exit;
   if not Visible then exit;
   DrawScrollBar;
//   R := ClientRect;
//   OffsetRect (R, Left, Top);
   R := ClientRect;

   Can := A2GetCanvas;
   with Can do begin
      if not Transparent then begin
         Brush.Color := Self.Color;
         Brush.Style := bsSolid;
         FillRect(R);
      end;
   end;
   Can.Font := Font;
   Can.Brush := Canvas.Brush;
   Can.Brush.Color := Color;
   Can.Brush.Style := bsClear;

   FColor := Can.Font.Color;
   BColor := Can.Brush.Color;

   for i := TopIndex to Items.Count -1 do begin
      R.Bottom := R.Top + FItemHeight;
      if R.Bottom > Height + Top then break;
      if Assigned (FOnAdxDrawItem) then begin
         if i = ItemIndex then State := 1
         else State := 0;
         FOnAdxDrawItem ( FAdxForm.Surface, i, R, State);
      end else begin
         with Can do begin
            str := Items[i];
            if i = ItemIndex then begin
               Font.Color := BColor;
               Brush.Color := FColor;
               if Transparent then Brush.Style := bsClear
               else begin
                  Brush.Color := clActiveCaption;
                  Brush.Style := bsSolid;
                  FillRect(R);
               end;
               DrawText(Handle, PChar(str), Length(str), R, 64);
               Font.Color := FColor;
               Brush.Color := BColor;
            end else begin
               if Transparent then Brush.Style := bsClear
               else begin
                  Brush.Color := Self.Color;
                  Brush.Style := bsSolid;
                  FillRect(R);
               end;
               DrawText(Handle, PChar(str), Length(str), R, 64);
            end;
         end;
      end;
      R.Top := R.Top + FItemHeight;
   end;

   R := Self.ClientRect;
   OffsetRect(R, left, top);
   A2DrawCanvas (FADXForm.FSurface, R.Left, R.Top, Width, Height, TRUE);

   Can.Font.Color := clWhite;
   Can.Brush.Color := clBlack;
end;
}
//////////////////////////////////////////
//            TA2ComboBox
//////////////////////////////////////////

constructor TA2ComboBox.Create (AOwner: TComponent);
begin
  inherited Create(AOwner);
  FPicture := TPicture.Create;
end;

destructor TA2ComboBox.Destroy;
begin
  FPicture.Free;
  inherited destroy;
end;

procedure TA2ComboBox.SetPicture(Value: TPicture);
begin
  FPicture.Assign(Value);
end;

procedure TA2ComboBox.Loaded;
begin
   inherited Loaded;
end;

procedure TA2ComboBox.AdxPaint;
var
  R: TRect;
  Can : TCanvas;
begin
   if (csDesigning in ComponentState) or not Assigned (FADXForm) then exit;
   if not Visible then exit;

   Can := A2GetCanvas;
   Can.FillRect (Self.ClientRect);

   if Assigned (FPicture.Graphic) then begin
      Can.Draw (Width-FPicture.Width, 0, FPicture.Graphic);
      R := Self.ClientRect;
      OffsetRect(R, left, top);
      A2DrawCanvas (FADXForm.FSurface, R.Left, R.Top, Width, Height, TRUE);
   end;

   if Text <> '' then begin
      R := ClientRect;
      OffsetRect(R, left, top);
      ATextOut (FADXForm.FSurface, R.Left+2, R.Top+2, WinRGB(31,31,31), Text);
   end;
end;

end.
