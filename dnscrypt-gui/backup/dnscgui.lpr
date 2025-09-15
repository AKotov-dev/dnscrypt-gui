program dnscgui;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  Unit1,
  Dialogs,
  SysUtils { you can add units after this };

  {$R *.res}

begin
{  if GetEnvironmentVariable('USER') <> 'root' then
  begin
    MessageDlg(SRootEnvRequired, mtWarning, [mbOK], 0);
    Halt;
  end;
 }
  RequireDerivedFormResource := True;
  Application.Title := 'DNSCrypt-GUI v1.0';
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
