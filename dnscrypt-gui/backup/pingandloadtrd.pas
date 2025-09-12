unit PingAndLoadTRD;

{$mode objfpc}{$H+}

interface

uses
  Classes, Process, SysUtils;

type
  TPingAndLoad = class(TThread)
  private
    FHasIPv6: Boolean;
    procedure LoadComboBox;
  protected
    procedure Execute; override;
  public
    constructor Create;
  end;

implementation

uses
  Unit1;

{ TPingAndLoad }

constructor TPingAndLoad.Create;
begin
  inherited Create(False); // сразу запускаем поток
  FreeOnTerminate := True; // уничтожаем поток автоматически
end;

procedure TPingAndLoad.Execute;
var
  ExProcess: TProcess;
begin
  FHasIPv6 := False;

  ExProcess := TProcess.Create(nil);
  try
    ExProcess.Executable := 'ping';
    ExProcess.Parameters.Add('-6');
    ExProcess.Parameters.Add('-c3');
    ExProcess.Parameters.Add('-W2');
    ExProcess.Parameters.Add('2001:4860:4860::8888');
//    ExProcess.Parameters.Add('8.8.8.8');
    ExProcess.Options := [poWaitOnExit, poNoConsole];

    ExProcess.Execute;

    if ExProcess.ExitStatus = 0 then
      FHasIPv6 := True;

    // синхронизация с GUI
    Synchronize(@LoadComboBox);

  finally
    ExProcess.Free;
  end;
end;

procedure TPingAndLoad.LoadComboBox;
begin
  // присвоим глобальной переменной HasIPv6 значение из потока
  HasIPv6 := FHasIPv6;

  // загрузка списка серверов
  MainForm.LoadResolvers;
end;

end.

