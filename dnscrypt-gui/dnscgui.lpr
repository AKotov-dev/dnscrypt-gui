program dnscgui;

{$mode objfpc}{$H+}

uses
  {$IFDEF UNIX}
  cthreads,  {$ENDIF}
  Interfaces, // this includes the LCL widgetset
  Forms,
  Unit1,
  Dialogs,
  SysUtils,
  statustrd,
  Socks5SettingsTRD,
  Unit2 { you can add units after this };

  {$R *.res}

begin
  RequireDerivedFormResource := True;
  Application.Title := 'DNSCrypt-GUI v1.6';
  Application.Scaled := True;
  Application.Initialize;
  Application.CreateForm(TMainForm, MainForm);
  Application.CreateForm(TBypassForm, BypassForm);
  Application.Run;
end.
