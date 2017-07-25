object FormMain: TFormMain
  Left = 382
  Top = 199
  Width = 803
  Height = 559
  Caption = 'Surface de R'#233'volution'
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'MS Sans Serif'
  Font.Style = []
  OldCreateOrder = False
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  PixelsPerInch = 96
  TextHeight = 13
  object StatusBar: TStatusBar
    Left = 0
    Top = 506
    Width = 795
    Height = 19
    Panels = <>
  end
  object ToolBar: TToolBar
    Left = 0
    Top = 0
    Width = 795
    Height = 29
    Caption = 'ToolBar'
    ParentShowHint = False
    ShowHint = True
    TabOrder = 1
    object ToolButtonDrawPoints: TToolButton
      Left = 0
      Top = 2
      Hint = 'Dessiner en Mode Points'
      Caption = 'ToolButtonDrawPoints'
      ImageIndex = 0
      OnClick = ToolButtonDrawPointsClick
    end
    object ToolButtonDrawLines: TToolButton
      Left = 23
      Top = 2
      Hint = 'Dessiner en Mode Lignes'
      Caption = 'ToolButtonDrawLines'
      ImageIndex = 1
      OnClick = ToolButtonDrawLinesClick
    end
    object ToolButtonDrawFilled: TToolButton
      Left = 46
      Top = 2
      Hint = 'Dessiner en Mode Volumes Pleins'
      Caption = 'ToolButtonDrawFilled'
      Down = True
      ImageIndex = 2
      OnClick = ToolButtonDrawFilledClick
    end
    object Separator1: TToolButton
      Left = 69
      Top = 2
      Width = 8
      Caption = 'Separator1'
      ImageIndex = 3
      Style = tbsSeparator
    end
    object ToolButtonOrtho: TToolButton
      Left = 77
      Top = 2
      Hint = 'Dessiner en Projection Orthogonale'
      Caption = 'ToolButtonOrtho'
      Down = True
      ImageIndex = 3
      OnClick = ToolButtonOrthoClick
    end
    object ToolButtonPersp: TToolButton
      Left = 100
      Top = 2
      Hint = 'Dessiner en projection Perspective'
      Caption = 'ToolButtonPersp'
      ImageIndex = 4
      OnClick = ToolButtonPerspClick
    end
    object Separator2: TToolButton
      Left = 123
      Top = 2
      Width = 8
      Caption = 'Separator2'
      ImageIndex = 5
      Style = tbsSeparator
    end
    object ToolButtonNbPoints: TToolButton
      Left = 131
      Top = 2
      Hint = 'D'#233'finir le nombre de points composant le Profil'
      Caption = 'ToolButtonNbPoints'
      ImageIndex = 5
      OnClick = ToolButtonNbPointsClick
    end
    object Separator3: TToolButton
      Left = 154
      Top = 2
      Width = 8
      Caption = 'Separator3'
      ImageIndex = 6
      Style = tbsSeparator
    end
    object ToolButtonNew: TToolButton
      Left = 162
      Top = 2
      Hint = 'Nouveau mod'#232'le'
      Caption = 'ToolButtonNew'
      ImageIndex = 6
      OnClick = ToolButtonNewClick
    end
  end
end
