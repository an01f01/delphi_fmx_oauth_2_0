unit HeaderFooterFormwithNavigation;

interface

uses
  System.SysUtils, System.Types, System.UITypes, System.Classes, System.Variants,
  FMX.Types, FMX.Controls, FMX.Graphics, FMX.Forms, FMX.Dialogs, FMX.TabControl, System.Actions, FMX.ActnList,
  FMX.Objects, FMX.StdCtrls, FMX.Controls.Presentation, FMX.TMSFNCTypes,
  FMX.TMSFNCUtils, FMX.TMSFNCGraphics, FMX.TMSFNCGraphicsTypes,
  FMX.TMSFNCCustomControl, FMX.TMSFNCWebBrowser, System.Net.URLClient, System.NetEncoding,
  REST.Types, REST.Client, Data.Bind.Components, Data.Bind.ObjectScope,
  FMX.Memo.Types, FMX.ScrollBox, FMX.Memo;

type
  THeaderFooterwithNavigation = class(TForm)
    ActionList1: TActionList;
    PreviousTabAction1: TPreviousTabAction;
    TitleAction: TControlAction;
    NextTabAction1: TNextTabAction;
    TopToolBar: TToolBar;
    btnBack: TSpeedButton;
    ToolBarLabel: TLabel;
    btnNext: TSpeedButton;
    TabControl1: TTabControl;
    TabItem1: TTabItem;
    TabItem2: TTabItem;
    BottomToolBar: TToolBar;
    TMSFNCWebBrowser1: TTMSFNCWebBrowser;
    RESTClient1: TRESTClient;
    RESTRequest1: TRESTRequest;
    RESTResponse1: TRESTResponse;
    Memo1: TMemo;
    procedure FormCreate(Sender: TObject);
    procedure TitleActionUpdate(Sender: TObject);
    procedure FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
    procedure OnNavCompleted(Sender: TObject;
      var Params: TTMSFNCCustomWebBrowserNavigateCompleteParams);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  HeaderFooterwithNavigation: THeaderFooterwithNavigation;

implementation

{$R *.fmx}
{$R *.LgXhdpiPh.fmx ANDROID}
{$R *.iPhone4in.fmx IOS}

procedure THeaderFooterwithNavigation.TitleActionUpdate(Sender: TObject);
begin
  if Sender is TCustomAction then
  begin
    if TabControl1.ActiveTab <> nil then
      TCustomAction(Sender).Text := TabControl1.ActiveTab.Text
    else
      TCustomAction(Sender).Text := '';
  end;
end;

procedure THeaderFooterwithNavigation.FormCreate(Sender: TObject);
var
  url: string;
begin
  { This defines the default active tab at runtime }
  TabControl1.First(TTabTransition.None);
  { TODO: Navigate to URL on load }
  url := 'https://www.fitbit.com/oauth2/authorize?response_type=code' +
        '&client_id=<YOUR_CLIENT_ID_FITBIT>' +
        '&redirect_uri=http%3A%2F%2Flocalhost' +
        '&scope=activity%20heartrate%20location%20nutrition%20profile%20settings%20sleep%20social%20weight%20oxygen_saturation%20respiratory_rate%20temperature' +
        '&expires_in=604800';
  TMSFNCWebBrowser1.Visible := true;
  TMSFNCWebBrowser1.Navigate(url);
end;

procedure THeaderFooterwithNavigation.FormKeyUp(Sender: TObject; var Key: Word; var KeyChar: Char; Shift: TShiftState);
begin
  if (Key = vkHardwareBack) and (TabControl1.TabIndex <> 0) then
  begin
    TabControl1.First;
    Key := 0;
  end;
end;

procedure THeaderFooterwithNavigation.OnNavCompleted(Sender: TObject;
  var Params: TTMSFNCCustomWebBrowserNavigateCompleteParams);
var
  s, Encoded, accessToken: string;
	Base64: TBase64Encoding;
	uri: TUri;
begin
  { TODO: On load complete, extract code for https://localhost callback }
  Memo1.Lines.Add(Params.URL);

	if Params.URL.Contains('http://localhost/?code=') then
	begin

		TMSFNCWebBrowser1.StopLoading;
		uri := TUri.Create(Params.URL);
		Memo1.Lines.Add(uri.ParameterByName['code']);

    Memo1.Lines.Add('Extract code');
    s := '<YOUR_CLIENT_ID_FITBIT>' + ':' + '<YOUR_CLIENT_SECRET_FITBIT>';
    Base64 := TBase64Encoding.Create(0);
    Encoded := Base64.Encode(s);
    Memo1.Lines.Add('Basic ' + Encoded);


    RESTClient1.BaseURL := 'https://api.fitbit.com/oauth2/token';
    RESTRequest1.Params.Clear;
    RESTRequest1.AddParameter('Authorization', 'Basic ' + Encoded, TRESTRequestParameterKind.pkHTTPHEADER, [TRESTRequestParameterOption.poDoNotEncode]);

    RESTRequest1.Params.AddItem('client_id', '<YOUR_CLIENT_ID_FITBIT>', TRESTRequestParameterKind.pkQUERY);
    RESTRequest1.Params.AddItem('client_secret', '<YOUR_CLIENT_SECRET_FITBIT>', TRESTRequestParameterKind.pkQUERY);
    RESTRequest1.Params.AddItem('grant_type', 'authorization_code', TRESTRequestParameterKind.pkQUERY);
    RESTRequest1.Params.AddItem('redirect_uri', 'http://localhost', TRESTRequestParameterKind.pkQUERY);
    RESTRequest1.Params.AddItem('code', uri.ParameterByName['code'], TRESTRequestParameterKind.pkQUERY);

    RESTRequest1.Method := TRESTRequestMethod.rmPOST;
    RESTRequest1.Execute;

    Memo1.Lines.Add(RESTResponse1.JSONValue.ToString);
    Memo1.Lines.Add(RESTResponse1.JSONValue.GetValue<string>('access_token'));

    accessToken := RESTResponse1.JSONValue.GetValue<string>('access_token');

    Memo1.Lines.Add('Request Access Token w POST');
    Memo1.Lines.Add('Print Access Token');

    RESTClient1.BaseURL := 'https://api.fitbit.com/1/user/-/profile.json';
    RESTRequest1.Params.Clear;
    RESTRequest1.AddParameter('Authorization', 'Bearer ' + accessToken, TRESTRequestParameterKind.pkHTTPHEADER, [TRESTRequestParameterOption.poDoNotEncode]);

    RESTRequest1.Method := TRESTRequestMethod.rmGET;
    RESTRequest1.Execute;
    Memo1.Lines.Add(RESTResponse1.JSONValue.ToString);
	end;
end;

end.
