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
  RequireDerivedFormResource := True;
  Application.Title:='DNSCrypt-GUI v1.2';
  Application.Scaled:=True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.Run;
end.
