unit uMain;

interface

uses
  Winapi.Windows,
  Winapi.Messages,
  System.SysUtils,
  System.Variants,
  System.Classes,
  Vcl.Graphics,
  Vcl.Controls,
  Vcl.Forms,
  Vcl.Dialogs,
  Vcl.StdCtrls,
  Vcl.ExtCtrls,
  System.JSON,
  System.Generics.Collections,
  System.RegularExpressions,
  RESTRequest4D,
  CNPJa.Model.Entity.CNPJa;

type
  TMainForm = class(TForm)
    lblTop: TPanel;
    mmResult: TMemo;
    edtCNPJ: TEdit;
    btnBuscar: TButton;
    Label1: TLabel;
    chkDados: TRadioButton;
    chkComprovante: TRadioButton;
    procedure btnBuscarClick(Sender: TObject);
  private
    function BuscarDadosCNPJa(const pCNPJ: string): TJSONObject;
    function PopularCnpjData(const pJsonObject: TJSONObject; out ErrorMessage: string): TCNPJa;
    function LimparCNPJ(const pCNPJ: string): string;
    function BuscarComprovanteRFB(const pCNPJ: string): Boolean;
    { Private declarations }
  public
    { Public declarations }
  end;

const
  AuthorizationCNPJa: string =  '';

var
  MainForm: TMainForm;

implementation

{$R *.dfm}

{ TMainForm }

procedure TMainForm.btnBuscarClick(Sender: TObject);
var
  lJsonObject: TJSONObject;
  lcnpjData: TCNPJa;
  lCNPJ, lErro: string;
begin
  lCNPJ := LimparCNPJ(edtCNPJ.Text);
  if chkDados.Checked then
  begin
    lJsonObject := BuscarDadosCNPJa(lCNPJ);
    if Assigned(lJsonObject) then
    begin
      try
        lcnpjData := PopularCnpjData(ljsonObject, lErro);
        if lErro > '' then
          raise Exception.Create('Erro: '+lErro)
        else
        begin
          // Utilização do Objeto populado.
        end;
      except
        on E: Exception do
          Writeln(E.ClassName, ': ', E.Message);
      end;
    end;
  end
  else if chkComprovante.Checked then
    BuscarComprovanteRFB(lCNPJ);
end;

function TMainForm.BuscarComprovanteRFB(const pCNPJ: string): Boolean;
var
  lRes: IResponse;
  lBaixouArquivo: Boolean;
  FileStream: TFileStream;
  SaveDialog: TSaveDialog;
  ResponseStream: TMemoryStream;
begin
  Result := False;
  try
    lRes := TRequest
              .New
                .BaseURL('https://api.cnpja.com')
                .Resource('rfb/certificate')
                .AddParam('taxId', pCNPJ)
                .AddHeader('Authorization', AuthorizationCNPJa)
                .Accept('application/pdf')
              //  .Timeout(180000)
                .Get;
    lBaixouArquivo := lRes.StatusCode = 200;
  except
    on E: Exception do
    begin
      ShowMessage('Ocorreu um erro na requisição: ' + E.Message);
      Exit;
    end;
  end;

  if lBaixouArquivo then
  begin
    SaveDialog := TSaveDialog.Create(nil);
    try
      SaveDialog.DefaultExt := 'pdf'; // Define a extensão padrão
      SaveDialog.Filter := 'Arquivos PDF|*.pdf'; // Define o filtro para PDFs
      SaveDialog.FileName := 'ComprovanteRFB.pdf'; // Nome padrão do arquivo

      if SaveDialog.Execute then
      begin
        try
          // Supondo que lRes.Content retorne algo que você pode carregar no TMemoryStream
          ResponseStream := TMemoryStream.Create;
          try
            // Aqui você pode estar utilizando algum método para carregar o stream
            lRes.ContentStream.Position := 0; // Certifique-se de que estamos no início
            ResponseStream.LoadFromStream(lRes.ContentStream);

            FileStream := TFileStream.Create(SaveDialog.FileName, fmCreate);
            try
              ResponseStream.Position := 0;
              FileStream.CopyFrom(ResponseStream, ResponseStream.Size);
              Result := True;
            finally
              FileStream.Free;
            end;
          finally
            ResponseStream.Free;
          end;

          ShowMessage('Arquivo salvo com sucesso em: ' + SaveDialog.FileName);
        except
          on E: Exception do
          begin
            ShowMessage('Erro ao salvar o arquivo: ' + E.Message);
          end;
        end;
      end
      else
      begin
        ShowMessage('Operação de salvamento cancelada pelo usuário.');
      end;
    finally
      SaveDialog.Free;
    end;
  end
  else
  begin
    raise Exception.Create('Erro na requisição. Código de status: ' + lRes.StatusCode.ToString);
  end;
end;

function TMainForm.BuscarDadosCNPJa(const pCNPJ: string): TJSONObject;
var
  lRes: IResponse;
begin
  lRes := TRequest
            .New
              .BaseURL('https://api.cnpja.com')
              .Resource('office/'+pCNPJ)
              .AddParam('simples', 'true')
              .AddParam('registrations', 'BR')
              .AddParam('suframa', 'true')
              .AddParam('maxAge','1')
              .AddHeader('Authorization', AuthorizationCNPJa)
              .Accept('application/json')
              .Retry(2)
          		.Timeout(180000)
              .Get;

  if lRes.StatusCode = 200 then
    Result := TJSONObject.ParseJSONValue(lRes.Content) as TJSONObject
  else
    Result := nil;
end;

function TMainForm.LimparCNPJ(const pCNPJ: string): string;
begin
  if Length(pCNPJ) > 14 then
    Result := TRegEx.Replace(pCNPJ, '\D', '')
  else
    Result := pCNPJ;
end;

function TMainForm.PopularCnpjData(const pJsonObject: TJSONObject; out ErrorMessage: string): TCNPJa;
var
  lCompany, lStatus, lAddress, lmainActivity, lmember, lphone, lemail, lsideActivitie, lRegistration, lSuframa, lSimples, lSimei: TJSONObject;
  lphones, lemails, lsideActivities, lRegistrations, lsuframas, lMembers: TJSONArray;
  cnpjData: TCNPJa;
  i, j: Integer;
  MemberAux: TMember;
  PhoneAux: TPhone;
  EmailAux: TEmail;
  sideActivitieAux: TActivity;
  RegistrationAux: TRegistration;
  SuframaAux: TSuframa;
  IncentivesAux: TIncentives;
  lAux: string;
  lData: TDateTime;
  lDataAux: TDate;
  lVlrAux: Currency;
  lJsonValue: TJSONValue;
begin
  Result := nil;
  if pjsonObject <> nil then
  begin
    try
      cnpjData := TCNPJa.Create;
      cnpjData.updated := pjsonObject.GetValue<TDateTime>('updated');
      cnpjData.taxId := pjsonObject.GetValue<string>('taxId');
      cnpjData.alias := pjsonObject.GetValue<string>('alias');
      cnpjData.founded := pjsonObject.GetValue<TDateTime>('founded');
      cnpjData.head := pjsonObject.GetValue<Boolean>('head');
      cnpjData.statusDate := pjsonObject.GetValue<TDateTime>('statusDate');

      if pjsonObject.TryGetValue<TJSONObject>('company', lCompany) then
      begin
        cnpjData.company := TCompany.Create;
        cnpjData.company.id := lCompany.GetValue<Integer>('id');
        cnpjData.company.name := lCompany.GetValue<string>('name');

        if lCompany.TryGetValue<TJSONValue>('equity', lJsonValue) then
        begin
          if not Assigned(lJsonValue) or (lJsonValue is TJSONNull) then
            lVlrAux := 0 // Or some default/fallback value
          else if lJsonValue.TryGetValue<Currency>(lVlrAux) then
            cnpjData.company.equity := lVlrAux
          else
            cnpjData.company.equity := 0
        end;

        // Nature
        if lCompany.TryGetValue<Integer>('nature.id', i) and lCompany.TryGetValue<string>('nature.text', lAux) then
        begin
          cnpjData.company.nature := TNature.Create;
          cnpjData.company.nature.id := i;
          cnpjData.company.nature.text := lAux;
        end;

        // Size
        if lCompany.TryGetValue<Integer>('size.id', i) and lCompany.TryGetValue<string>('size.acronym', lAux)  then
        begin
          cnpjData.company.size := TSize.Create;
          cnpjData.company.size.id := i;
          cnpjData.company.size.acronym := lAux;
          cnpjData.company.size.text := lCompany.GetValue<string>('size.text');
        end;

        //Simples
        if lCompany.TryGetValue<TJSONObject>('simples', lSimples) then
        begin
          if lSimples.TryGetValue<string>('optant', lAux) and (lAux = 'true') then
          begin
            cnpjData.company.simples := TSimples.Create;
            cnpjData.company.simples.optant := lAux;
            cnpjData.company.simples.since := lSimples.GetValue<TDate>('since');
          end;
        end;

        if lCompany.TryGetValue<TJSONObject>('simei', lSimei) then
        begin
          if lSimei.TryGetValue<string>('optant', lAux) and (lAux = 'true') then
          begin
            cnpjData.company.simei := TSimei.Create;
            cnpjData.company.simei.optant := lAux;
            if lSimei.TryGetValue<TDate>('since', lDataAux) then
              cnpjData.company.simei.since := lDataAux;
          end;
        end;

        // Members (exemplo simplificado, precisa de tratamento para array)
        if lCompany.TryGetValue<TJSONArray>('members', lMembers ) then
        begin
          for i := 0 to lMembers.Count - 1 do
          begin
            lmember := lMembers.Items[i] as TJSONObject;
            if Assigned(lmember) then
            begin
              // Cria o objeto TMember SEM o uso de with
              if lmember.TryGetValue<TDate>('since', lDataAux) then
              begin
                MemberAux := TMember.Create; // Variável temporária para armazenar o membro criado
                try
                  MemberAux.since := lDataAux;
                  if lmember.TryGetValue<Integer>('role.id', j) and lmember.TryGetValue<string>('role.text', lAux) then
                  begin
                    MemberAux.role := TRole.Create;
                    MemberAux.role.id := j;
                    MemberAux.role.text := lAux;
                  end;
                  if lmember.TryGetValue<string>('person.id', lAux) then
                  begin
                    MemberAux.person := TPerson.Create;
                    MemberAux.person.id := lAux;
                    if lmember.tryGetValue<string>('person.type', lAux) then
                      MemberAux.person.ptype := lAux;
                    if lmember.TryGetValue<string>('person.name', lAux) then
                      MemberAux.person.name := lAux;
                    if lmember.TryGetValue<string>('person.taxId', lAux) then
                      MemberAux.person.taxId := lAux;
                    if lmember.TryGetValue<string>('person.age', lAux) then
                      MemberAux.person.age := lAux;
                  end;
                  cnpjData.company.members.Add(MemberAux); // Adiciona o membro à lista
                finally
                end;
              end;
            end;
          end;
        end;

        //Status
        if pjsonObject.TryGetValue<TJSONObject>('status', lStatus) and  lStatus.TryGetValue<integer>('id', i) and lStatus.TryGetValue<string>('text', lAux) then
        begin
          cnpjData.status := TStatus.Create;
          cnpjData.status.id := i;
          cnpjData.status.text := lAux;
        end;

        //Address
        if pjsonObject.TryGetValue<TJSONObject>('address', lAddress) then
        begin
          if lAddress.TryGetValue<integer>('municipality', i) then
          begin
            cnpjData.address := TAddress.Create;
            cnpjData.address.municipality := i;
            if lAddress.TryGetValue<string>('street', lAux) then
              cnpjData.address.street := lAux;
            if lAddress.TryGetValue<string>('number', lAux) then
              cnpjData.address.number := lAux;
            if lAddress.TryGetValue<string>('district', lAux) then
              cnpjData.address.district := lAux;
            if lAddress.TryGetValue<string>('city', lAux) then
              cnpjData.address.city := lAux;
            if lAddress.TryGetValue<string>('state', lAux) then
              cnpjData.address.state := lAux;
            if lAddress.TryGetValue<string>('details', lAux) then
              cnpjData.address.details := lAux;
            if lAddress.TryGetValue<string>('zip', lAux) then
              cnpjData.address.zip := lAux;

            if lAddress.TryGetValue<Integer>('country.id', i) and lAddress.TryGetValue<string>('country.name', lAux) then
            begin
              cnpjData.address.country := TCountry.Create;
              cnpjData.address.country.id := i;
              cnpjData.address.country.name := lAux;
            end;
          end;
        end;

        if pjsonObject.TryGetValue<TJSONObject>('mainActivity', lmainActivity)  and lmainActivity.TryGetValue<integer>('id', i) and lmainActivity.TryGetValue<string>('text', lAux) then
        begin
          cnpjData.mainActivity :=  TActivity.Create;
          cnpjData.mainActivity.id := i;
          cnpjData.mainActivity.text := lAux;
        end;

        if pjsonObject.TryGetValue<TJSONArray>('phones', lphones) then
        begin
          for i := 0 to lphones.Count - 1 do
          begin
            lphone := lPhones.Items[i] as TJSONObject;
            if Assigned(lPhone) then
            begin
              if lphone.TryGetValue<string>('number', lAux) then
              begin
                PhoneAux := TPhone.Create;
                if lphone.TryGetValue<string>('type', lAux) then
                  PhoneAux.ptype := lAux;
                if lphone.TryGetValue<string>('area', lAux) then
                  PhoneAux.area := lAux;
                if lphone.TryGetValue<string>('number', lAux) then
                  PhoneAux.number := lAux;

                cnpjData.phones.Add(PhoneAux);
              end;
            end;
          end;
        end;

        if pjsonObject.TryGetValue<TJSONArray>('emails', lemails) then
        begin
          for i := 0 to lemails.Count - 1 do
          begin
            lemail := lEmails.Items[i] as TJSONObject;
            if Assigned(lemail) and lemail.TryGetValue<string>('address', lAux) then
            begin
              EmailAux := TEmail.Create;
              if lemail.TryGetValue<string>('ownership', lAux) then
                EmailAux.ownership := lAux;
              if lemail.TryGetValue<string>('address', lAux) then
                EmailAux.address := lAux;
              if lemail.TryGetValue<string>('domain', lAux) then
              EmailAux.domain := lAux;

              cnpjData.emails.Add(EmailAux);
            end;
          end;
        end;

        if pjsonObject.TryGetValue<TJSONArray>('sideActivities', lsideActivities) then
        begin
          for i := 0 to lsideActivities.Count - 1 do
          begin
            lsideActivitie := lsideActivities.Items[i] as TJSONObject;
            if Assigned(lsideActivitie) and lsideActivitie.TryGetValue<Integer>('id', j) and lsideActivitie.TryGetValue<string>('text', lAux) then
            begin
              sideActivitieAux := TActivity.Create;
              sideActivitieAux.id := j;
              sideActivitieAux.text := lAux;

              cnpjData.sideActivities.Add(sideActivitieAux);
            end;
          end;
        end;

        if pjsonObject.TryGetValue<TJSONArray>('registrations', lregistrations) then
        begin
          for i := 0 to lregistrations.Count - 1 do
          begin
            lRegistration := lregistrations.Items[i] as TJSONObject;
            if Assigned(lRegistration) then
            begin
              RegistrationAux := TRegistration.Create;
              RegistrationAux.number := lRegistration.GetValue<string>('number');
              RegistrationAux.state := lRegistration.GetValue<string>('state');
              RegistrationAux.enabled := lRegistration.GetValue<string>('enabled');
              RegistrationAux.statusDate := lRegistration.GetValue<TDate>('statusDate');
              RegistrationAux.statusid := lRegistration.GetValue<Integer>('status.id');
              RegistrationAux.statustext := lRegistration.GetValue<string>('status.text');
              RegistrationAux.Typeid := lRegistration.GetValue<Integer>('type.id');
              RegistrationAux.Typetext := lRegistration.GetValue<string>('type.text');
              cnpjData.registrations.Add(RegistrationAux);
            end;
          end;
        end;

        if pjsonObject.TryGetValue<TJSONArray>('suframa', lsuframas) then
        begin
          for i := 0 to lsuframas.Count - 1 do
          begin
            lSuframa := lsuframas.Items[i] as TJSONObject;
            if Assigned(lSuframa) and lSuframa.TryGetValue<string>('status.text', lAux)  and (lAux = 'Ativa') then
            begin
              if lSuframa.TryGetValue<string>('number', lAux) then
              begin
                SuframaAux := TSuframa.Create;
                SuframaAux.number := lAux;
                if lSuframa.TryGetValue<string>('since', lAux) then
                  SuframaAux.since := lAux;
                if lSuframa.TryGetValue<string>('approved', lAux) then
                  SuframaAux.approved := lAux;
                if lSuframa.TryGetValue<TDate>('approvalDate', lDataAux) then
                  SuframaAux.approvalDate := lDataAux;

                if lSuframa.TryGetValue<Integer>('status.id', j) and lSuframa.TryGetValue<string>('status.text', lAux) then
                begin
                  SuframaAux.status := TStatus.Create;
                  SuframaAux.status.id := j;
                  SuframaAux.status.text := lAux;
                end;

                if lSuframa.TryGetValue<string>('tribute', lAux) then
                begin
                  IncentivesAux := TIncentives.Create;
                  IncentivesAux.tribute := lAux;
                  if lSuframa.TryGetValue<string>('benefit', lAux) then
                    IncentivesAux.benefit := lAux;
                  if lSuframa.TryGetValue<string>('purpose', lAux) then
                    IncentivesAux.purpose := lAux;
                  if lSuframa.TryGetValue<string>('basis', lAux) then
                    IncentivesAux.basis := lAux;
                  SuframaAux.incentives.Add(IncentivesAux)
                end;
                cnpjData.suframa.Add(SuframaAux);
              end;
            end;
          end;
        end;
      end;
      Result := cnpjData;
    except
      on E: Exception do
        ErrorMessage := 'Error in PopularCnpjData: ' + E.Message;
    end;
  end;
end;

end.
