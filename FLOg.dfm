object frmLog: TfrmLog
  Left = 215
  Top = 110
  Width = 544
  Height = 375
  Caption = 'LOG'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  PixelsPerInch = 96
  TextHeight = 13
  object txtLog: TMemo
    Left = 0
    Top = 33
    Width = 536
    Height = 308
    Align = alClient
    Color = clBlack
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWhite
    Font.Height = -11
    Font.Name = 'MS Sans Serif'
    Font.Style = []
    ImeName = #54620#44397#50612'('#54620#44544') (MS-IME98)'
    ParentFont = False
    ScrollBars = ssVertical
    TabOrder = 0
  end
  object Panel1: TPanel
    Left = 0
    Top = 0
    Width = 536
    Height = 33
    Align = alTop
    TabOrder = 1
    object Button1: TButton
      Left = 16
      Top = 3
      Width = 75
      Height = 25
      Caption = 'Clear'
      TabOrder = 0
      OnClick = Button1Click
    end
    object Button2: TButton
      Left = 96
      Top = 3
      Width = 75
      Height = 25
      Caption = 'Save'
      TabOrder = 1
      OnClick = Button2Click
    end
    object Button3: TButton
      Left = 176
      Top = 3
      Width = 75
      Height = 25
      Caption = 'Init'
      TabOrder = 2
      OnClick = Button3Click
    end
    object SpinEdit1: TSpinEdit
      Left = 384
      Top = 4
      Width = 49
      Height = 22
      MaxValue = 1000
      MinValue = 0
      TabOrder = 3
      Value = 10
      OnChange = SpinEdit1Change
    end
    object CheckBox1: TCheckBox
      Left = 360
      Top = 8
      Width = 17
      Height = 17
      TabOrder = 4
      OnClick = CheckBox1Click
    end
  end
end
