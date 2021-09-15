program dnscgui;

{$mode objfpc}{$H+}

uses {$IFDEF UNIX} {$IFDEF UseCThreads}
  cthreads, {$ENDIF} {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  Unit1,
  Dialogs,
  SysUtils { you can add units after this };

{$R *.res}

begin
  if GetEnvironmentVariable('USER') <> 'root' then
  begin
    MessageDlg('Requires root!', mtWarning, [mbOK], 0);
    Halt;
  end;

  RequireDerivedFormResource := True;
  Application.Title:='DNSCrypt-GUI v0.6';
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.

