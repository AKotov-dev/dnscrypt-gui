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
    Label5: TLabel;
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
    procedure Timer1Timer(Sender: TObject);
  private

  public

  end;

var
  MainForm: TMainForm;

implementation

{$R *.lfm}

{ TMainForm }

//systemctl list-units  --type=service  --state=running

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

    //IPv6 включен?
    RunCommand('bash', ['-c', 'ip -br a show lo | grep "::"'], output);

    S.Add('server_names = [' + '''' + ComboBox1.Text + '''' + ']');

    //IPv4 vs IPv6
    if Trim(output) = '' then
      S.Add('listen_addresses = [' + '''' + Edit1.Text + ':' +
        SpinEdit1.Text + '''' + ']')
    else
      S.Add('listen_addresses = [' + '''' + Edit1.Text + ':' +
        SpinEdit1.Text + '''' + ', ' + '''' + '[::1]:' + SpinEdit1.Text + '''' + ']');

    S.Add('max_clients = 250');
    S.Add('ipv4_servers = true');
    S.Add('ipv6_servers = false');
    S.Add('dnscrypt_servers = true');
    S.Add('doh_servers = true');
    S.Add('require_dnssec = false');
    S.Add('require_nolog = true');
    S.Add('require_nofilter = true');

    S.Add('timeout = 2500');
    S.Add('cert_refresh_delay = 240');
    S.Add('bootstrap_resolvers = [' + '''' + ComboBox2.Text + ':53' + '''' + ']');
    S.Add('ignore_system_dns = false');
    S.Add('log_files_max_size = 10');
    S.Add('log_files_max_age = 7');
    S.Add('log_files_max_backups = 1');
    S.Add('block_ipv6 = false');
    S.Add('cache = true');
    S.Add('cache_size = 256');
    S.Add('cache_min_ttl = 600');
    S.Add('cache_max_ttl = 86400');
    S.Add('cache_neg_ttl = 60');

    //force_tcp
    if CheckBox2.Checked then
      S.Add('force_tcp = true')
    else
      S.Add('force_tcp = false');

    //VIA Socks5
    if CheckBox1.Checked then
      S.Add('proxy = ' + '''' + 'socks5://' + Edit2.Text + ':' + ComboBox3.Text + '''');

    S.Add('[query_log]');
    S.Add('format = ' + '''' + 'tsv' + '''');
    S.Add('[nx_log]');
    S.Add('format = ' + '''' + 'tsv' + '''');
    S.Add('[blacklist]');
    S.Add('[ip_blacklist]');
    S.Add('[schedules]');
    S.Add('[sources]');
    S.Add('[sources.' + '''' + 'public-resolvers' + '''' + ']');
    S.Add('url = ' + '''' +
      'https://download.dnscrypt.info/resolvers-list/v2/public-resolvers.md' + '''');

    S.Add('cache_file = ' + '''' + 'public-resolvers.md' + '''');
    S.Add('minisign_key = ' + '''' +
      'RWQf6LRCGA9i53mlYecO4IzT51TGPpvWucNSCh1CBM0QTaLn73Y7GFO3' + '''');
    S.Add('refresh_delay = 72');
    S.Add('prefix = ' + '''' + '''');
    S.Add('[static]');

    S.SaveToFile('/etc/dnscrypt-proxy.toml');

    //Патч /usr/lib/systemd/system/dnscrypt-proxy.socket; https://forums.linuxmint.com/viewtopic.php?t=261453
    //error: sockets.target/start deleted при перезагрузке
    //upd: 19.01.2021 - mask dnscrypt-proxy.socket
    RunCommand('bash', ['-c',
      'if [[ -n $(cat /usr/lib/systemd/system/dnscrypt-proxy.service | grep "dnscrypt-proxy.socket") ]]; then '
      + 'sed -i ' + '''' + '/dnscrypt-proxy.socket/d' + '''' +
      ' /usr/lib/systemd/system/dnscrypt-proxy.service; systemctl daemon-reload; ' +
      'systemctl mask dnscrypt-proxy.socket; fi'],
      output);

    //Если с новой конфигурацией запущен, сделать enable, иначе disable
    RunCommand('bash', ['-c', 'systemctl restart dnscrypt-proxy; ' +
      'if [[ -n $(systemctl --type=service --state=running | grep dnscrypt) ]]; ' +
      'then systemctl enable dnscrypt-proxy; else systemctl disable dnscrypt-proxy; fi'],
      output);

  finally
    S.Free;
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

procedure TMainForm.FormCreate(Sender: TObject);
begin
  MainForm.Caption := Application.Title;

  //Конфиг
  if not DirectoryExists(GetEnvironmentVariable('HOME') + '/.config') then
    MkDir(GetEnvironmentVariable('HOME') + '/.config');
  XMLPropStorage1.FileName := GetEnvironmentVariable('HOME') +
    '/.config/dnscrypt-gui.conf';
end;

procedure TMainForm.FormShow(Sender: TObject);
var
  S: ansistring;
begin
  //Via SOCKS5
  RunCommand('/bin/bash', ['-c', 'grep "^proxy = ' + '''' +
    'socks5:" /etc/dnscrypt-proxy.toml'], S);
  if Trim(S) <> '' then
  begin
    CheckBox1.Checked := True;
    Edit2.Enabled := True;
    ComboBox3.Enabled := True;
    //Server
    if RunCommand('/bin/bash',
      ['-c', 'grep "socks5" /etc/dnscrypt-proxy.toml | tr -d "/\' +
      '''' + '" | cut -f2 -d":"'], S) then
      Edit2.Text := Trim(S);
    //Port
    if RunCommand('/bin/bash',
      ['-c', 'grep "socks5" /etc/dnscrypt-proxy.toml | tr -d "/\' +
      '''' + '" | cut -f3 -d":"'], S) then
      ComboBox3.Text := Trim(S);
  end
  else
  begin
    CheckBox1.Checked := False;
    Edit2.Enabled := False;
    ComboBox3.Enabled := False;
  end;

  //force_tcp
  RunCommand('/bin/bash', ['-c',
    'grep "^force_tcp = true" /etc/dnscrypt-proxy.toml'], S);
  if Trim(S) <> '' then
    CheckBox2.Checked := True
  else
    CheckBox2.Checked := False;
end;

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
