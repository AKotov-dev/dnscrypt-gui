unit Unit2;

{$mode ObjFPC}{$H+}

interface

uses
  Classes, SysUtils, Forms, Controls, Graphics, Dialogs, StdCtrls, Buttons, LazUTF8;

type

  { TBypassForm }

  TBypassForm = class(TForm)
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    FindDialog1: TFindDialog;
    SaveBtn: TBitBtn;
    Memo1: TMemo;
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure FindDialog1Find(Sender: TObject);
    procedure FindDialog1Show(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
    procedure SaveBtnClick(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: boolean);
    procedure FormShow(Sender: TObject);
    procedure Memo1Change(Sender: TObject);
  private

    Modified: boolean;
    FLastPos: integer;
    // Хранит позицию последнего найденного вхождения

  public

  end;

var
  BypassForm: TBypassForm;

implementation

uses
  unit1;

  {$R *.lfm}

  { TBypassForm }

//Load
procedure TBypassForm.FormShow(Sender: TObject);
begin
  Memo1.Lines.LoadFromFile(MainForm.WorkDir + '/forwarding-rules.txt');

  //В центр MainForm
  BypassForm.Left := Self.Left + (Self.Width - BypassForm.Width) div 2;
  BypassForm.Top := Self.Top + (Self.Height - BypassForm.Height) div 2;

  Modified := False;
end;

procedure TBypassForm.Memo1Change(Sender: TObject);
begin
  Modified := True;
end;

//Save
procedure TBypassForm.SaveBtnClick(Sender: TObject);
begin
  Memo1.Lines.SaveToFile(GetUserDir + '.config/dnscrypt-gui/forwarding-rules.txt');

  MainForm.RestartBtn.Click;
  Modified := False;

  BypassForm.Close;
end;

procedure TBypassForm.FormCloseQuery(Sender: TObject; var CanClose: boolean);
var
  Reply: integer;
begin
  CanClose := True;

  if Modified then
  begin
    Reply := MessageDlg(SSaveRules, mtConfirmation, [mbYes, mbNo, mbCancel], 0);

    case Reply of
      mrYes:
        SaveBtn.Click;
      // Если пользователь отменил — не закрываем
      mrNo:
        CanClose := True;        // Закрываем без сохранения
      mrCancel:
        CanClose := False;       // Отменяем закрытие формы
    end;
  end;
end;

//Default
procedure TBypassForm.BitBtn1Click(Sender: TObject);
begin
  if MessageDlg(SDefaultRules, mtWarning, [mbOK, mbCancel], 0) <> mrOk then Exit;

  MainForm.CreateForwardingRules;
  Memo1.Lines.LoadFromFile(MainForm.WorkDir + '/forwarding-rules.txt');
end;

procedure TBypassForm.BitBtn2Click(Sender: TObject);
begin
  // Сбрасываем позицию поиска при новом открытии (или начинаем с позиции курсора)
  FLastPos := Memo1.SelStart + Memo1.SelLength;

  //Показать диалог поиска
  FindDialog1.Execute;
end;

procedure TBypassForm.FindDialog1Find(Sender: TObject);
var
  SearchText, SourceText, SubText: string;
  FoundPos: SizeInt;
begin
  SearchText := FindDialog1.FindText;
  SourceText := Memo1.Text;

  // Если галочка "Учитывать регистр" (frMatchCase) НЕ стоит, приводим всё к нижнему регистру
  if not (frMatchCase in FindDialog1.Options) then
  begin
    SearchText := UTF8LowerCase(SearchText);
    SourceText := UTF8LowerCase(SourceText);
  end;

  // Берем часть текста, начиная после предыдущего найденного слова
  SubText := UTF8Copy(SourceText, FLastPos + 1, UTF8Length(SourceText));

  // Ищем вхождение части слова
  FoundPos := UTF8Pos(SearchText, SubText);

  if FoundPos > 0 then
  begin
    // Вычисляем реальную позицию в исходном тексте (в символах UTF-8)
    FLastPos := FLastPos + FoundPos - 1;

    // Выделяем найденный фрагмент в Memo1
    Memo1.SetFocus;
    Memo1.SelStart := FLastPos;
    Memo1.SelLength := UTF8Length(FindDialog1.FindText);

    // Сдвигаем указатель за найденное слово для кнопки "Найти далее"
    FLastPos := FLastPos + UTF8Length(FindDialog1.FindText);
  end
  else
  begin
    ShowMessage(SSearchComplete);
    FLastPos := 0;
    // Сбрасываем в начало для следующего круга
  end;
end;

//Диалог поиска в центр формы
procedure TBypassForm.FindDialog1Show(Sender: TObject);
begin
  FindDialog1.Left := Self.Left + (Self.Width - FindDialog1.Width) div 2;
  FindDialog1.Top := Self.Top + (Self.Height - FindDialog1.Height) div 2;
end;

//Ctrl+F
procedure TBypassForm.FormKeyUp(Sender: TObject; var Key: word; Shift: TShiftState);
begin
  if (Key = Ord('F')) and (ssCtrl in Shift) then
    BitBtn2.Click;
end;

end.
