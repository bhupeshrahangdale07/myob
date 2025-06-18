public without sharing class MYOB_CompanyFiles_Response {

    public class XCompanyFileDetails{
		@AuraEnabled public String Id;
		@AuraEnabled public String Name;
		@AuraEnabled public String LibraryPath;
		@AuraEnabled public String ProductVersion;
		@AuraEnabled public String Uri;
		@AuraEnabled public String Country;
		@AuraEnabled public String LauncherId;
		@AuraEnabled public String SerialNumber;
		@AuraEnabled public Integer UIAccessFlags;
    }

    public static List<XCompanyFileDetails> parseJSON(String json){
		return (List<XCompanyFileDetails>) System.JSON.deserialize(json, List<XCompanyFileDetails>.class);
	}
}