unit Unit1;

{$mode objfpc}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons,
  Spin, ExtCtrls, XMLPropStorage, Process, DefaultTranslator, LCLTranslator;

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
    procedure FormClose(Sender: TObject; var CloseAction: TCloseAction);
    procedure FormCreate(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure Label1Click(Sender: TObject);
    procedure Label1MouseEnter(Sender: TObject);
    procedure Label1MouseLeave(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure LoadResolvers;

  private

  public

  end;

var
  MainForm: TMainForm;
  HasIPv6: boolean; //IPv6 в системе

resourcestring
  SRootEnvRequired = 'Root environment required!';


implementation

uses PingAndLoadTRD;

  {$R *.lfm}

  { TMainForm }

//Выборка/загрузка списка НЕЛОГИРУЮЩИХ dns-серверов в зависимости от поддержки IPv6 из /opt/dnscrypt-proxy/dnscrypt-proxy.md
procedure TMainForm.LoadResolvers;
var
  Lines: TStringList;
  i, j: integer;
  Line, AliasLine, LineLower: string;
  IncludeServer, IsIPv6: boolean;
begin
  if not FileExists('/opt/dnscrypt-gui/public-resolvers.md') then Exit;

  Lines := TStringList.Create;
  try
    Lines.LoadFromFile('/opt/dnscrypt-gui/public-resolvers.md');
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

//Состояние /etc/resolv.conf и dnscrypt-proxy
procedure TMainForm.Timer1Timer(Sender: TObject);
var
  S: TStringList;
  ExProcess: TProcess;
begin
  S := TStringList.Create;
  ExProcess := TProcess.Create(nil);
  try
    ExProcess.Executable := 'bash';
    ExProcess.Parameters.Add('-c');
    ExProcess.Parameters.Add('cat /etc/resolv.conf | grep nameserver');
    ExProcess.Options := ExProcess.Options + [poUsePipes];
    ExProcess.Execute;

    S.LoadFromStream(ExProcess.Output);

    if S.Count <> 0 then
      ListBox1.Items.Assign(S);

    ExProcess.Parameters.Delete(1);
    ExProcess.Parameters.Add('systemctl --type=service --state=running | grep dnscrypt');

    Exprocess.Execute;
    S.LoadFromStream(ExProcess.Output);

    if S.Count <> 0 then
      Shape1.Brush.Color := clLime
    else
      Shape1.Brush.Color := clYellow;

  finally
    S.Free;
    ExProcess.Free;
  end;
end;

//Делаем конфиг и перезапускаем
procedure TMainForm.BitBtn2Click(Sender: TObject);
var
  S: TStringList;
  output: ansistring;
begin
  Screen.Cursor := crHourGlass;
  Application.ProcessMessages;
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
    S.Add('cache_file = ' + '''' + '/opt/dnscrypt-gui/public-resolvers.md' + '''');
    S.Add('minisign_key = ' + '''' +
      'RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3' + '''');
    S.Add('refresh_delay = 72');
    S.Add('prefix = ' + '''' + '''');

    S.Add('');
    S.Add('[static]');

    //Сохраняем файл конфигурации
    S.SaveToFile('/opt/dnscrypt-gui/dnscrypt-proxy.toml');

    //Если с новой конфигурацией запущен, сделать enable, иначе disable
    RunCommand('bash', ['-c', 'systemctl restart dnscrypt-proxy; ' +
      'if [[ -n $(systemctl --type=service --state=running | grep dnscrypt) ]]; ' +
      'then systemctl enable dnscrypt-proxy; else systemctl disable dnscrypt-proxy; fi'],
      output);

  finally
    S.Free;

    // Активируем пропсторедж, если нужно
    XMLPropStorage1.Active := True;

    // Сохраняем свойства
    XMLPropStorage1.Save;

    // Можно сразу деактивировать, если не хотим авто-сохранение
    XMLPropStorage1.Active := False;

    Screen.Cursor := crDefault;
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

procedure TMainForm.FormClose(Sender: TObject; var CloseAction: TCloseAction);
begin
  //Очистка временных файлов для безопасности
  DeleteFile('/tmp/dnscrypt-gui_REAL_USER');
end;

procedure TMainForm.FormCreate(Sender: TObject);
begin
  MainForm.Caption := Application.Title;

  //Конфиг
  if not DirectoryExists(GetEnvironmentVariable('HOME') + '/.config') then
    MkDir(GetEnvironmentVariable('HOME') + '/.config');
  XMLPropStorage1.FileName := GetEnvironmentVariable('HOME') +
    '/.config/dnscrypt-gui.conf';

  XMLPropStorage1.Active := True;
  XMLPropStorage1.Restore;
  XMLPropStorage1.Active := False; // отключаем авто-сохранение
end;

procedure TMainForm.FormShow(Sender: TObject);
var
  S: ansistring;
begin
  //Проверка ipv6 и загрузка/обновление списка dns-серверов (без логирования в зависимости от HasIPV6)
  TPingAndLoad.Create;

  //Via SOCKS5
  RunCommand('bash', ['-c', 'grep "^proxy = ' + '''' +
    'socks5:" /opt/dnscrypt-gui/dnscrypt-proxy.toml'], S);
  if Trim(S) <> '' then
  begin
    CheckBox1.Checked := True;
    Edit2.Enabled := True;
    ComboBox3.Enabled := True;
    //Server
    if RunCommand('bash', ['-c',
      'grep "socks5" /opt/dnscrypt-gui/dnscrypt-proxy.toml | tr -d "/\' +
      '''' + '" | cut -f2 -d":"'], S) then
      Edit2.Text := Trim(S);
    //Port
    if RunCommand('bash', ['-c',
      'grep "socks5" /opt/dnscrypt-gui/dnscrypt-proxy.toml | tr -d "/\' +
      '''' + '" | cut -f3 -d":"'], S) then
      ComboBox3.Text := Trim(S);
  end
  else
  begin
    CheckBox1.Checked := False;
    CheckBox2.Enabled := False;
    Edit2.Enabled := False;
    ComboBox3.Enabled := False;
  end;

  //force_tcp
  RunCommand('bash', ['-c',
    'grep "^force_tcp = true" /opt/dnscrypt-gui/dnscrypt-proxy.toml'], S);
  if Trim(S) <> '' then
    CheckBox2.Checked := True
  else
    CheckBox2.Checked := False;
end;

//Читаем файлы для REAL_USER, DISPLAY_VAL, XAUTH_VAL
function ReadFileFirstLine(const FileName: string): string;
var
  SL: TStringList;
begin
  Result := '';
  if FileExists(FileName) then
  begin
    SL := TStringList.Create;
    try
      SL.LoadFromFile(FileName);
      if SL.Count > 0 then Result := Trim(SL[0]);
    finally
      SL.Free;
    end;
  end;
end;

//Открываем URL под юзером из root-сессии
procedure OpenURLFromUserSession(const AURL: string);
var
  P: TProcess;
  REAL_USER, cmd: string;
begin
  REAL_USER := ReadFileFirstLine('/tmp/dnscrypt-gui_REAL_USER');

  if (REAL_USER = '') or (AURL = '') then Exit;

  cmd := Format('xdg-open %s', [QuotedStr(AURL)]);

  P := TProcess.Create(nil);
  try
    P.Executable := 'su';
    P.Parameters.Add('-l');
    P.Parameters.Add(REAL_USER);
    P.Parameters.Add('-c');
    P.Parameters.Add(cmd);

    P.Options := P.Options + [poNoConsole, poNewProcessGroup];

    P.Execute;
  finally
    P.Free;
  end;
end;

//Проверка DNSLeak
procedure TMainForm.Label1Click(Sender: TObject);
begin
  //Перезапускаем, если выбирали новый dns-сервер из списка
  BitBtn2.Click;

  //Проверка DNSLeak
  OpenURLFromUserSession('https://browserleaks.com/dns');
end;

procedure TMainForm.Label1MouseEnter(Sender: TObject);
begin
  Label1.Font.Color := clRed;  // подсветка при наведении
end;

procedure TMainForm.Label1MouseLeave(Sender: TObject);
begin
  Label1.Font.Color := clBlue; // возвращаем исходный цвет
end;

//Stop/Disable dnscrypt-proxy
procedure TMainForm.BitBtn1Click(Sender: TObject);
var
  s: ansistring;
begin
  Screen.Cursor := crHourGlass;
  Application.ProcessMessages;
  RunCommand('bash', ['-c',
    'systemctl stop dnscrypt-proxy; systemctl disable dnscrypt-proxy'], s);
  Screen.Cursor := crDefault;
end;

end.
