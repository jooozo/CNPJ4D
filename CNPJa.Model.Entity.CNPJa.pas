unit CNPJa.Model.Entity.CNPJa;

interface

uses
  System.Generics.Collections;

type
  TStatus = class
  public
    id: Integer;
    text: string;
  end;

  TCountry = class
  public
    id: Integer;
    name: string;
  end;

  TAddress = class
  public
    municipality: Integer;
    street: string;
    number: string;
    details: string;
    district: string;
    city: string;
    state: string;
    zip: string;
    country: TCountry;
  end;

  TPhone = class
  public
    ptype: string;
    area: string;
    number: string;
  end;

  TEmail = class
  public
    ownership: string;
    address: string;
    domain: string;
  end;

  TActivity = class
  public
    id: Integer;
    text: string;
  end;

  TNature = class
  public
    id: Integer;
    text: string;
  end;

  TSize = class
  public
    id: Integer;
    acronym: string;
    text: string;
  end;

  TRole = class
  public
    id: Integer;
    text: string;
  end;

  TType = class
  public
    id: Integer;
    text: string;
  end;

  TPerson = class
  public
    id: string;
    name: string;
    ptype: string;
    taxId: string;
    age: string;
  end;

  TMember = class
  public
    since: TDateTime;
    role: TRole;
    person: TPerson;
  end;

  TSimples = class
  public
    optant: string;
    since: TDate;
  end;

  TSimei = class
  public
		optant: string;
		since: TDate;
  end;

  TCompany = class
  public
    id: Integer;
    name: string;
    equity: Double;
    nature: TNature;
    size: TSize;
    members: TList<TMember>;
    simples: TSimples;
    simei: TSimei;
    constructor Create;
    destructor Destroy; override;
  end;

  TRegistration = class
  public
    number: string;
    state: string;
    enabled: string;
    statusDate: TDate;
    statusid: Integer;
    statustext: string;
    Typeid: Integer;
    Typetext: string;
  end;

  TIncentives = class
  public
    tribute: string;
    benefit: string;
    purpose: string;
    basis: string;
  end;

  TSuframa = class
  public
    number: string;
    since: string;
    approved: string;
    approvalDate: TDate;
    status: TStatus;
    incentives: TList<TIncentives>;
  end;

  TCNPJa = class
  public
    updated: TDateTime;
    taxId: string;
    company: TCompany;
    alias: string;
    founded: TDateTime;
    head: Boolean;
    statusDate: TDateTime;
    status: TStatus;
    address: TAddress;
    phones: TList<TPhone>;
    emails: TList<TEmail>;
    mainActivity: TActivity;
    sideActivities: TList<TActivity>;
    registrations:  TList<TRegistration>;
    suframa: TList<TSuframa>;
    constructor Create;
    destructor Destroy; override;
  end;


implementation

{ TCompany }

constructor TCompany.Create;
begin
  members := TList<TMember>.Create;
end;

destructor TCompany.Destroy;
begin
  members.Free;
  inherited;
end;

{ TCNPJa }

constructor TCNPJa.Create;
begin
  phones  := TList<TPhone>.Create;
  emails := TList<TEmail>.Create;
  sideActivities := TList<TActivity>.Create;
  registrations :=  TList<TRegistration>.Create;;
  suframa := TList<TSuframa>.Create;;
end;

destructor TCNPJa.Destroy;
begin
  phones.Free;
  emails.Free;
  sideActivities.Free;
  registrations.Free;
  suframa.Free;
  inherited;
end;

end.
