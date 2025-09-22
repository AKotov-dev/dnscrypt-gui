unit StatusTRD;

{$mode objfpc}{$H+}

interface

uses
  Classes, Forms, Controls, SysUtils, Process, Graphics;

type
  TStatusTRD = class(TThread)
  private
    S: TStringList;
  public
    constructor Create;
    destructor Destroy; override;
  protected
    procedure Execute; override;
    procedure ShowResolvConf;
    procedure ShowRunningStatus;
  end;

implementation

uses unit1;

  { TStatusTRD }

constructor TStatusTRD.Create;
begin
  inherited Create(False); // сразу запускаем поток
  FreeOnTerminate := True; // уничтожаем поток автоматически
  S := TStringList.Create;
end;

destructor TStatusTRD.Destroy;
begin
  S.Free;
  inherited Destroy;
end;

procedure TStatusTRD.Execute;
var
  ExProcess: TProcess;
begin
  ExProcess := TProcess.Create(nil);
  try
    ExProcess.Executable := 'bash';
    ExProcess.Options := [poUsePipes, poWaitOnExit];

    while not Terminated do
    begin
      // --- resolv.conf ---
      ExProcess.Parameters.Clear;
      ExProcess.Parameters.Add('-c');
      ExProcess.Parameters.Add(
        'if [ -f /etc/resolv.conf ]; then grep nameserver /etc/resolv.conf; fi');
      ExProcess.Execute;

      S.LoadFromStream(ExProcess.Output);
      Synchronize(@ShowResolvConf);

      // --- dnscrypt ---
      ExProcess.Parameters.Clear;
      ExProcess.Parameters.Add('-c');
      ExProcess.Parameters.Add(
        'systemctl --user --type=service --state=running | grep dnscrypt');
      ExProcess.Execute;

      S.LoadFromStream(ExProcess.Output);
      Synchronize(@ShowRunningStatus);

      Sleep(1000); // чуть реже опрашиваем
    end;
  finally
    ExProcess.Free;
  end;
end;

procedure TStatusTRD.ShowResolvConf;
begin
  if S.Count <> 0 then
    MainForm.ListBox1.Items.Assign(S);
end;

procedure TStatusTRD.ShowRunningStatus;
begin
  if S.Count <> 0 then
    MainForm.Shape1.Brush.Color := clLime
  else
    MainForm.Shape1.Brush.Color := clYellow;

  MainForm.Shape1.Repaint;
end;

end.
