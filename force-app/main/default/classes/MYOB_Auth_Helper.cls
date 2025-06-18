global with sharing class MYOB_Auth_Helper extends Auth.AuthProviderPluginClass {
     
    public String redirectUrl; // Use this URL for the endpoint that the authentication provider calls back to for configuration.
    private String key;
    private String secret;
    private String scope;
    private String authorizationURL; // authentication and authorization.

            
    // URI to get the new access token from concur using the GET verb.
    private String accessTokenUrl; 
    
    // Api name for the custom metadata type created for this auth provider.
    private String customMetadataTypeApiName = 'KTMYOB__MYOB_Credentials__mdt'; 
    
    // Api URL to access the user in Concur
    private String userAPIUrl;

    global String getCustomMetadataType() {
        return customMetadataTypeApiName;
    } 

    global PageReference initiate(Map<string,string> authProviderConfiguration, String stateToPropagate){ 

        System.debug('### authProviderConfiguration ::: '+authProviderConfiguration);
        key = authProviderConfiguration.get('KTMYOB__Client_Id__c'); 
        authorizationURL = authProviderConfiguration.get('KTMYOB__Authorization_URL__c'); 
        scope = authProviderConfiguration.get('KTMYOB__Scope__c'); 
        redirectUrl = authProviderConfiguration.get('KTMYOB__Callback_URL__c'); 

        String url=authorizationURL+'?client_id='+key+'&redirect_uri='+redirectUrl+'+&response_type=code&scope='+scope+'&state='+stateToPropagate;
        System.debug('### Url ::: '+url);
        return new PageReference(url); 
    } 

    global Auth.AuthProviderTokenResponse handleCallback(Map<string,string> authProviderConfiguration, Auth.AuthProviderCallbackState state ) { 
        key = authProviderConfiguration.get('KTMYOB__Client_Id__c'); 
        secret = authProviderConfiguration.get('KTMYOB__Client_Secret__c'); 
        authorizationURL = authProviderConfiguration.get('KTMYOB__Authorization_URL__c'); 
        accessTokenUrl = authProviderConfiguration.get('KTMYOB__AccessToken_URL__c'); 
        scope = authProviderConfiguration.get('KTMYOB__Scope__c'); 
        redirectUrl = authProviderConfiguration.get('KTMYOB__Callback_URL__c');
    
        Map<String,String> queryParams = state.queryParameters; 
        String code = queryParams.get('code'); 
        String sfdcState = queryParams.get('state'); 

        string AuthHeader = 'Basic '+EncodingUtil.base64Encode(Blob.valueOf(key+':'+secret));
        String body = 'client_id='+key+'&client_secret='+secret+'&grant_type=authorization_code&code='+code+'&redirect_uri='+redirectUrl;
        System.debug('### AccessToken Body ::: '+body);
    
        BearerTokenWrapper wrapper = autheticationCalloutHelper(accessTokenUrl,AuthHeader,body);
        return new Auth.AuthProviderTokenResponse('MYOB', wrapper.access_token, wrapper.refresh_token, sfdcState); 
    } 

    global override Auth.OAuthRefreshResult refresh(Map<String,String> authProviderConfiguration, String refreshToken){
        key = authProviderConfiguration.get('KTMYOB_Client_Id__c'); 
        secret = authProviderConfiguration.get('Client_Secret__c'); 
        accessTokenUrl = authProviderConfiguration.get('KTMYOB__AccessToken_URL__c'); 

        string AuthHeader = 'Basic '+EncodingUtil.base64Encode(Blob.valueOf(key+':'+secret));
        String body = 'client_id='+key+'&client_secret='+secret+'&refresh_token='+refreshToken;

        BearerTokenWrapper wrapper = autheticationCalloutHelper(accessTokenUrl,AuthHeader,body);
        return (new Auth.OAuthRefreshResult(wrapper.access_token, wrapper.refresh_token)); 
    }


    global Auth.UserData getUserInfo(Map<string,string> authProviderConfiguration,Auth.AuthProviderTokenResponse response){
        System.debug('### guest user config ::: '+authProviderConfiguration);
        System.debug('### guest user detials ::: '+response);
        return (new Auth.UserData('fakeid', 'firstname', 'lastname', 'fullname','email', 'emailLink', 'locale', null, 'MYOB_Auth','provMap',null)); 
    }


    public static BearerTokenWrapper autheticationCalloutHelper(String accessTokenUrl,String AuthHeader,String body){
        HttpRequest req = new HttpRequest(); 
        req.setEndpoint(accessTokenUrl); 
        req.setHeader('Authorization',AuthHeader); 
        req.setHeader('Accept','application/json'); 
        req.setHeader('Content-Type','application/x-www-form-urlencoded'); 
        req.setBody(body);
        req.setMethod('POST'); 

        Http http = new Http(); 
        HTTPResponse res = http.send(req); 
        String responseBody = res.getBody(); 
        System.debug('### Auth Response ::: '+responseBody);
        return (BearerTokenWrapper) System.JSON.deserialize(responseBody,BearerTokenWrapper.class);
    }

    public class BearerTokenWrapper{
        public String access_token{get;set;}
	    public String refresh_token{get;set;}	
	    public String token_type;	
	    public String expires_in;	
	    public String scope;	
    }

}