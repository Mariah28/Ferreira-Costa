unit UnitConsulta;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.StdCtrls,
  Vcl.WinXCalendars, Vcl.ComCtrls, Data.DB, Vcl.Grids, Vcl.DBGrids,
  Datasnap.DBClient, Data.Win.ADODB, Vcl.Mask, Vcl.DBCtrls, Vcl.Buttons,
  Vcl.WinXPickers;

type
  TForm1 = class(TForm)
    Panel1: TPanel;
    Label2: TLabel;
    Label3: TLabel;
    Label7: TLabel;
    EditNota: TEdit;
    Panel2: TPanel;
    Label11: TLabel;
    DBGridItens: TDBGrid;
    Conexao: TADOConnection;
    ADOMaster: TADOQuery;
    DSItens: TDataSource;
    DSMaster: TDataSource;
    DBGridMaster: TDBGrid;
    ADOItens: TADOQuery;
    Label5: TLabel;
    Label6: TLabel;
    Label8: TLabel;
    CalendarPickerInicio: TCalendarPicker;
    CalendarPickerFim: TCalendarPicker;
    ADOItensCodigo: TAutoIncField;
    ADOItensProduto: TWideStringField;
    ADOItensDescricao: TWideStringField;
    ADOItensQtde: TIntegerField;
    ADOItensPrecoUnit: TBCDField;
    ADOItensICMS: TBCDField;
    ADOItensIPI: TBCDField;
    ADOItensTotal: TFMTBCDField;
    BtnLimpar: TBitBtn;
    BtnConsultar: TBitBtn;
    BtnCancelar: TBitBtn;
    EditCliente: TEdit;
    Label1: TLabel;
    ADOMasterNota: TWideStringField;
    ADOMasterDataMovim: TDateField;
    ADOMasterValorTotal: TBCDField;
    ADOMasterLoja: TIntegerField;
    ADOMasterCliente: TWideStringField;
    procedure ConsultarClick(Sender: TObject);
    procedure CarregarItens(Sender: TObject; Field: TField);
    procedure FormCreate(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure LimparClick(Sender: TObject);
    procedure BtnCancelarClick(Sender: TObject);
  private
    procedure LimparGrids;
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

// Configura��es iniciais do formul�rio
procedure TForm1.FormCreate(Sender: TObject);
begin
  ADOMaster.Close;
  ADOItens.Close;
  CalendarPickerInicio.Date := Now;
  CalendarPickerFim.Date := Now;
end;

// Atalhos do teclado
procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  // Atalho para consultar F2
  if Key = VK_F2 then
  begin
    ConsultarClick(Sender);
  end;
  //Atalho para limpar F5
  if Key = VK_F5 then
  begin
    LimparGrids;
  end;
  if Key = VK_F3 then // tecla F3
  begin
    BtnCancelarClick(Sender);
  end;
end;

procedure TForm1.LimparClick(Sender: TObject);
begin
  LimparGrids;
end;

procedure TForm1.BtnCancelarClick(Sender: TObject);
begin
  ShowMessage('Opera��o cancelada. Retornando � tela principal.');
  Close;
end;


// Limpa os grids e redefine os campos do form para valores iniciais
procedure TForm1.LimparGrids;
begin
  ADOItens.Close;
  ADOMaster.Close;

  DBGridItens.DataSource := nil;
  DBGridMaster.DataSource := nil;

  EditNota.Text := '';
  EditCliente.Text := '';
  CalendarPickerInicio.Date := Now;
  CalendarPickerFim.Date := Now;

end;

// Consulta registros no banco com base nos filtros fornecidos
procedure TForm1.ConsultarClick(Sender: TObject);
var
  Nota, Cliente: string;
  DataInicio, DataFim: TDateTime;
begin
  Nota := EditNota.Text;
  Cliente := EditCliente.Text;
  DataInicio := CalendarPickerInicio.Date;
  DataFim := CalendarPickerFim.Date;

   if (DataInicio > 0) and (DataFim > 0) and (DataInicio > DataFim) then
    begin
      ShowMessage('O intervalo de datas est� incorreto. A data inicial n�o pode ser maior que a data final.');
      Exit;
    end;

   // Consulta no banco de dados
   with ADOMaster do
   begin
     Close;
     SQL.Clear;
     SQL.Add('SELECT Nota, DataMovim, ValorTotal,Loja, Cliente FROM SfcPedidoVenda WHERE (1 = 1)');

     // Filtro por n�mero de notas
     if Nota <> '' then
     begin
       SQL.Add('AND Nota LIKE :Nota');
       Parameters.ParamByName('Nota').Value := '%' + Nota + '%';
     end;

     // Filtro por nome do cliente
     if Cliente <> '' then
     begin
       SQL.Add('AND Cliente LIKE :Cliente');
       Parameters.ParamByName('Cliente').Value := '%' + Cliente + '%';
     end;

     // Filtro por intervalo de datas
     if (DataInicio > 0) and (DataFim > 0) then
     begin
       SQL.Add('AND DataMovim BETWEEN :DataInicio AND :DataFim');
       Parameters.ParamByName('DataInicio').Value := DataInicio;
       Parameters.ParamByName('DataFim').Value := DataFim;
     end;

     open;
   end;

   // Verifica se h� registros retornados
   if ADOMaster.IsEmpty then
   begin
    ADOItens.Close;
    DBGridMaster.DataSource := nil;
    ShowMessage('Nenhum registro encontrado.');
  end
  else
  begin
    DBGridMaster.DataSource := DSMaster;
    CarregarItens(Sender, nil);
  end;

end;


// Carrega os itens que foi selecionado no grid principal

procedure TForm1.CarregarItens(Sender: TObject; Field: TField);
begin

  if ADOMaster.Active and not ADOMaster.IsEmpty then
  begin
    With ADOItens do
    begin
      Close;
      SQL.Clear;
      SQL.Add('SELECT p.Codigo, p.Nome AS Produto, p.Descricao, i.Qtde, i.PrecoUnit, i.ICMS, i.IPI, i.Total');
      SQL.Add('FROM SfcPedidoVendaIt i');
      SQL.Add('INNER JOIN  Produto p ON p.Nome = i.Produto');
      SQL.Add('INNER JOIN SfcPedidoVenda s ON i.PedidoId = s.Nota');
      SQL.Add('WHERE  i.PedidoId = :PedidoId;');
      Parameters.ParamByName('PedidoId').Value := ADOMaster.FieldByName('Nota').AsString;
      Open;
    end;

    DBGridItens.DataSource := DSItens;
  end
  else
  begin
    ADOItens.Close;
    DBGridItens.DataSource := nil;
  end;

end;

end.
