unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  Spin, ExtCtrls, XMLPropStorage, Process, DefaultTranslator, LCLTranslator, LCLIntf;

type

  { TMainForm }

  TMainForm = class(TForm)
    Bevel1: TBevel;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    CheckBox1: TCheckBox;
    CheckBox2: TCheckBox;
    ComboBox1: TComboBox;
    ComboBox2: TComboBox;
    ComboBox3: TComboBox;
    Edit1: TEdit;
    Edit2: TEdit;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    Label6: TLabel;
    Label7: TLabel;
    ListBox1: TListBox;
    Shape1: TShape;
    SpinEdit1: TSpinEdit;
    StaticText1: TStaticText;
    Timer1: TTimer;
    XMLPropStorage1: TXMLPropStorage;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure CheckBox1Change(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Label1Click(Sender: TObject);
    procedure Label1MouseEnter(Sender: TObject);
    procedure Label1MouseLeave(Sender: TObject);
    procedure LoadResolvers;
    procedure RunCommandAsync(const CmdLine: string);

  private

  public
    WorkDir: string;

  end;

var
  MainForm: TMainForm;
  HasIPv6: boolean; //IPv6 в системе

resourcestring
  SRootEnvRequired = 'Root environment required!';


implementation

uses PingAndLoadTRD, StatusTRD, Socks5SettingsTRD;

  {$R *.lfm}

  { TMainForm }

//Асинхронное выполнение команд не связанных с графикой
procedure TMainForm.RunCommandAsync(const CmdLine: string);
var
  AProcess: TProcess;
begin
  AProcess := TProcess.Create(nil);
  try
    AProcess.Executable := 'bash';
    AProcess.Parameters.Add('-c');
    AProcess.Parameters.Add(CmdLine);

    // Асинхронный запуск
    AProcess.Options := [poNoConsole];
    AProcess.Execute; // сразу возвращается

  finally
    // Процесс может завершиться позже, освобождать память можно через таймер или событие
    AProcess.Free;

    // Активируем пропсторедж, если нужно
    XMLPropStorage1.Active := True;

    // Сохраняем настройки
    XMLPropStorage1.Save;

    // Можно сразу деактивировать, если не хотим авто-сохранение
    XMLPropStorage1.Active := False;
  end;
end;

//Выборка/загрузка списка НЕЛОГИРУЮЩИХ dns-серверов в зависимости от поддержки IPv6 из /opt/dnscrypt-proxy/dnscrypt-proxy.md
procedure TMainForm.LoadResolvers;
var
  Lines: TStringList;
  i, j: integer;
  Line, AliasLine, LineLower: string;
  IncludeServer, IsIPv6: boolean;
begin
  if not FileExists(WorkDir + '/public-resolvers.md') then Exit;

  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(WorkDir + '/public-resolvers.md');
    ComboBox1.Items.BeginUpdate;
    try
      ComboBox1.Items.Clear;

      i := 0;
      while i < Lines.Count do
      begin
        Line := Trim(Lines[i]);

        //псевдоним начинается с ##
        if Copy(Line, 1, 2) = '##' then
        begin
          AliasLine := Trim(Copy(Line, 3, MaxInt));
          IncludeServer := True;

          IsIPv6 := (Pos('-ipv6', LowerCase(AliasLine)) > 0) or
            (Pos('-ip6', LowerCase(AliasLine)) > 0) or
            ((Length(AliasLine) > 0) and (AliasLine[Length(AliasLine)] = '6'));

          //проверка строк до следующего ##
          j := i + 1;
          while (j < Lines.Count) and (Copy(Lines[j], 1, 2) <> '##') do
          begin
            LineLower := LowerCase(Lines[j]);

            //фильтры... выбирать НЕ логирующие и НЕ фильтрующие DNS
            if ((Pos('logging', LineLower) > 0) and
              (Pos('non-logging', LineLower) = 0) and
              (Pos('no-logging', LineLower) = 0)) then
              IncludeServer := False;

            if ((Pos('blocks', LineLower) > 0) and
              (Pos('non-filtering', LineLower) = 0)) then
              IncludeServer := False;

            Inc(j);
          end;

          //если IPv6 не поддерживается — пропускаем
          if (IsIPv6) and (not HasIPv6) then
            IncludeServer := False;

          //добавляем в ComboBox
          if IncludeServer then
            ComboBox1.Items.Add(AliasLine);

          i := j - 1; //продолжаем с последней строки
        end;

        Inc(i);
      end;

    finally
      ComboBox1.Items.EndUpdate;
      ComboBox2.Items.Assign(ComboBox1.Items);
    end;

  finally
    Lines.Free;
  end;
end;

//Делаем конфиг и перезапускаем
procedure TMainForm.BitBtn2Click(Sender: TObject);
var
  S: TStringList;
begin
  try
    S := TStringList.Create;

    S.Add('## Resolvers');
    S.Add('server_names = [' + '''' + ComboBox1.Text + '''' + ', ' +
      '''' + ComboBox2.Text + '''' + ']');

    //IPv4/IPv6
    S.Add('');
    if not HasIPv6 then
      S.Add('listen_addresses = [' + '''' + Edit1.Text + ':' +
        SpinEdit1.Text + '''' + ']')
    else
      S.Add('listen_addresses = [' + '''' + Edit1.Text + ':' +
        SpinEdit1.Text + '''' + ', ' + '''' + '[::1]:' + SpinEdit1.Text + '''' + ']');

    S.Add('');
    S.Add('max_clients = 250');
    S.Add('ipv4_servers = true');

    if HasIPv6 then
      S.Add('ipv6_servers = true')
    else
      S.Add('ipv6_servers = false');
    S.Add('');
    S.Add('dnscrypt_servers = true');
    S.Add('doh_servers = true');
    S.Add('require_dnssec = false');
    S.Add('require_nolog = true');
    S.Add('require_nofilter = true');
    S.Add('');
    S.Add('timeout = 2500');
    S.Add('cert_refresh_delay = 240');
    S.Add('');

    S.Add('## Bootstrap');
    S.Add('bootstrap_resolvers = [');
    S.Add('''' + '9.9.9.11:53' + '''' + ',');
    S.Add('''' + '149.112.112.11:53' + '''' + ',');
    S.Add('''' + '8.8.8.8:53' + '''' + ',');
    S.Add('''' + '8.8.4.4:53' + '''' + ',');
    S.Add('''' + '1.1.1.1:53' + '''' + ',');
    S.Add('''' + '1.0.0.1:53' + '''' + ',');

    if HasIPv6 then
    begin
      S.Add('''' + '[2620:fe::11]:53' + '''' + ',');
      S.Add('''' + '[2620:fe::fe]:53' + '''' + ',');
      S.Add('''' + '[2001:4860:4860::8888]:53' + '''' + ',');
      S.Add('''' + '[2001:4860:4860::8844]:53' + '''' + ',');
      S.Add('''' + '[2606:4700:4700::1111]:53' + '''' + ',');
      S.Add('''' + '[2606:4700:4700::1001]:53' + '''' + ',');
      S.Add('''' + '[2a02:6b8::feed:0ff]:53' + '''' + ',');
      S.Add('''' + '[2a02:6b8:0:1::feed:0ff]:53' + '''' + ',');
    end;
    S.Add('''' + '77.88.8.8:53' + '''' + ',');
    S.Add('''' + '77.88.8.1:53' + '''');

    S.Add(']');

    S.Add('');
    S.Add('ignore_system_dns = true');
    S.Add('log_files_max_size = 10');
    S.Add('log_files_max_age = 7');
    S.Add('log_files_max_backups = 1');

    S.Add('');
    if HasIPv6 then
      S.Add('block_ipv6 = false')
    else
      S.Add('block_ipv6 = true');

    S.Add('');
    S.Add('cache = true');
    S.Add('cache_size = 256');
    S.Add('cache_min_ttl = 600');
    S.Add('cache_max_ttl = 86400');
    S.Add('cache_neg_ttl = 60');
    S.Add('');

    //force_tcp
    if CheckBox2.Checked then
      S.Add('force_tcp = true')
    else
      S.Add('force_tcp = false');

    //VIA Socks5
    if CheckBox1.Checked then
      S.Add('proxy = ' + '''' + 'socks5://' + Edit2.Text + ':' + ComboBox3.Text + '''');

    S.Add('');
    S.Add('[query_log]');
    S.Add('format = ' + '''' + 'tsv' + '''');
    S.Add('[nx_log]');
    S.Add('format = ' + '''' + 'tsv' + '''');
    S.Add('[blacklist]');
    S.Add('[ip_blacklist]');
    S.Add('[schedules]');

    S.Add('');
    S.Add('[sources]');
    S.Add('[sources.' + '''' + 'public-resolvers' + '''' + ']');
    S.Add('urls = [');
    S.Add('''' +
      'https://raw.githubusercontent.com/DNSCrypt/dnscrypt-resolvers/master/v3/public-resolvers.md'
      + '''' + ',');

    if HasIPv6 then
      S.Add('''' + 'https://ipv6.download.dnscrypt.info/resolvers-list/v3/public-resolvers.md'
        + '''' + ',');

    S.Add('''' + 'https://download.dnscrypt.info/resolvers-list/v3/public-resolvers.md' +
      '''');
    S.Add(']');

    S.Add('');
    S.Add('cache_file = ' + '''' + WorkDir + '/public-resolvers.md' + '''');
    S.Add('minisign_key = ' + '''' +
      'RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3' + '''');
    S.Add('refresh_delay = 72');
    S.Add('prefix = ' + '''' + '''');

    S.Add('');
    S.Add('[static]');

    //Сохраняем файл конфигурации
    S.SaveToFile(WorkDir + '/dnscrypt-proxy.toml');

    //Если с новой конфигурацией запущен, сделать enable, иначе disable
    RunCommandAsync('systemctl --user restart dnscrypt-proxy; ' +
      'if [[ -n $(systemctl --user --type=service --state=running | grep dnscrypt) ]]; '
      +
      'then systemctl --user enable dnscrypt-proxy; else systemctl --user disable dnscrypt-proxy; fi');

  finally
    S.Free;
  end;
end;

//Via Socks5
procedure TMainForm.CheckBox1Change(Sender: TObject);
begin
  if CheckBox1.Checked then
  begin
    Edit2.Enabled := True;
    ComboBox3.Enabled := True;
    CheckBox2.Enabled := True;
    CheckBox2.Checked := True;
  end
  else
  begin
    Edit2.Enabled := False;
    ComboBox3.Enabled := False;
    CheckBox2.Enabled := False;
    CheckBox2.Checked := False;
  end;
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  MainForm.Caption := Application.Title;

  //Рабочая директория
  WorkDir := GetEnvironmentVariable('HOME') + '/.config/dnscrypt-gui';

  //Конфиг
  if not DirectoryExists(WorkDir) then MkDir(WorkDir);

  XMLPropStorage1.FileName := WorkDir + '/dnscrypt-gui.conf';

  XMLPropStorage1.Active := True;
  XMLPropStorage1.Restore;
  XMLPropStorage1.Active := False; // отключаем авто-сохранение
end;

procedure TMainForm.FormShow(Sender: TObject);
begin
  //Проверка NS из /etc/resolv.conf и статуса dnscrypt-proxy.servive
  TStatusTRD.Create;

  //Проверка ipv6 и загрузка/обновление списка dns-серверов (без логирования в зависимости от HasIPV6)
  TPingAndLoad.Create;

  //Поток прокси-настроек Via SOCKS5
  TSocks5SettingsTRD.Create;
end;

//Проверка DNSLeak
procedure TMainForm.Label1Click(Sender: TObject);
begin
  //Перезапускаем, если выбирали новый dns-сервер из списка
  BitBtn2.Click;

  //Проверка DNSLeak
  OpenURL('https://browserleaks.com/dns');
end;

procedure TMainForm.Label1MouseEnter(Sender: TObject);
begin
  Label1.Font.Color := clRed;  //подсветка при наведении
end;

procedure TMainForm.Label1MouseLeave(Sender: TObject);
begin
  Label1.Font.Color := clBlue; //возвращаем исходный цвет
end;

//Stop/Disable dnscrypt-proxy
procedure TMainForm.BitBtn1Click(Sender: TObject);
begin
  RunCommandAsync('systemctl --user stop dnscrypt-proxy; systemctl --user disable dnscrypt-proxy');
end;

end.
