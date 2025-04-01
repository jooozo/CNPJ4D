program CNPJa4D;

uses
  Vcl.Forms,
  uMain in 'uMain.pas' {MainForm},
  CNPJa.Model.Entity.CNPJa in 'CNPJa.Model.Entity.CNPJa.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
