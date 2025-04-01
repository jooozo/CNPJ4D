object MainForm: TMainForm
  Left = 0
  Top = 0
  Caption = 'MainForm'
  ClientHeight = 695
  ClientWidth = 826
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object lblTop: TPanel
    Left = 0
    Top = 0
    Width = 826
    Height = 53
    Align = alTop
    TabOrder = 0
    object Label1: TLabel
      Left = 4
      Top = 4
      Width = 27
      Height = 15
      Caption = 'CNPJ'
    end
    object edtCNPJ: TEdit
      Left = 0
      Top = 24
      Width = 201
      Height = 23
      TabOrder = 0
    end
    object btnBuscar: TButton
      Left = 468
      Top = 22
      Width = 75
      Height = 25
      Caption = 'Buscar'
      TabOrder = 1
      OnClick = btnBuscarClick
    end
    object chkDados: TRadioButton
      Left = 216
      Top = 24
      Width = 113
      Height = 17
      Caption = 'Dados'
      TabOrder = 2
    end
    object chkComprovante: TRadioButton
      Left = 312
      Top = 24
      Width = 113
      Height = 17
      Caption = 'Comprovante'
      TabOrder = 3
    end
  end
  object mmResult: TMemo
    Left = 0
    Top = 53
    Width = 826
    Height = 642
    Align = alClient
    Lines.Strings = (
      'mmResult')
    TabOrder = 1
    ExplicitLeft = 208
    ExplicitTop = 296
    ExplicitWidth = 185
    ExplicitHeight = 89
  end
end
