unit Socks5SettingsTRD;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Process, Forms, Controls;

type
  TSocks5SettingsTRD = class(TThread)
  private
    S: TStringList;
  protected
    procedure Execute; override;
    procedure UpdateGUI;
  public
    constructor Create;
    destructor Destroy; override;
  end;

implementation

uses unit1;

  { TStatusProxyTRD }

constructor TSocks5SettingsTRD.Create;
begin
  inherited Create(False); // запускаем поток сразу
  FreeOnTerminate := True; // освобождение автоматически
  S := TStringList.Create;
end;

destructor TSocks5SettingsTRD.Destroy;
begin
  S.Free;
  inherited Destroy;
end;

// Обёртка для запуска bash-команд
function RunCommandBash(const Command: string; Output: TStringList): boolean;
var
  P: TProcess;
begin
  Result := False;
  Output.Clear;
  P := TProcess.Create(nil);
  try
    P.Executable := 'bash';
    P.Parameters.Add('-c');
    P.Parameters.Add(Command);
    P.Options := [poUsePipes, poWaitOnExit];
    try
      P.Execute;
      Output.LoadFromStream(P.Output);
      Result := True;
    except
      Result := False;
    end;
  finally
    P.Free;
  end;
end;

procedure TSocks5SettingsTRD.Execute;
begin
  // Запуск через Synchronize, чтобы безопасно обновить GUI
  RunCommandBash('grep "^proxy = ''socks5:" ' + MainForm.WorkDir +
    '/dnscrypt-proxy.toml', S);
  Synchronize(@UpdateGUI);
end;

procedure TSocks5SettingsTRD.UpdateGUI;
var
  SServer, SPort: TStringList;
begin
  SServer := TStringList.Create;
  SPort := TStringList.Create;
  try
    if Trim(S.Text) <> '' then
    begin
      MainForm.CheckBox1.Checked := True;
      MainForm.Edit2.Enabled := True;
      MainForm.ComboBox3.Enabled := True;

      // Server
      if RunCommandBash('grep "socks5" ' + MainForm.WorkDir +
        '/dnscrypt-proxy.toml | tr -d "/''" | cut -f2 -d":"', SServer) then
        MainForm.Edit2.Text := Trim(SServer.Text);

      // Port
      if RunCommandBash('grep "socks5" ' + MainForm.WorkDir +
        '/dnscrypt-proxy.toml | tr -d "/''" | cut -f3 -d":"', SPort) then
        MainForm.ComboBox3.Text := Trim(SPort.Text);
    end
    else
    begin
      MainForm.CheckBox1.Checked := False;
      MainForm.CheckBox2.Enabled := False;
      MainForm.Edit2.Enabled := False;
      MainForm.ComboBox3.Enabled := False;
    end;

    // force_tcp
    if RunCommandBash('grep "^force_tcp = true" ' + MainForm.WorkDir +
      '/dnscrypt-proxy.toml', S) then
      if Trim(S.Text) <> '' then
        MainForm.CheckBox2.Checked := True
      else
        MainForm.CheckBox2.Checked := False;

  finally
    SServer.Free;
    SPort.Free;
  end;
end;

end.
