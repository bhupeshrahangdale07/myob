public without sharing class Utils {
    public static Boolean checkTokenExpiry(DateTime lastRefreshDate){
        Boolean flag = false;
        try{
            DateTime currDt = System.now();
            Long previousDate = lastRefreshDate.getTime();
            Long currentDate = currDt.getTime();
            if(currDt.isSameDay(lastRefreshDate)){
                Long milliseconds = currentDate - previousDate;
                Long hours = (milliseconds / 60000) / 60;
                if(hours <= 0){
                    Long mins = milliseconds / 60000;
                    if(mins <= 25){
                        flag = true;
                    }
                }
            }
        }catch(Exception e){
            flag = false;
        }
        return flag;
    }
    @AuraEnabled
    public static boolean getIsMultiCurrencyOrg() {
        boolean isMultiCurrecyOrg = false;
        try {
            isMultiCurrecyOrg = Schema.getGlobalDescribe()
                .containsKey('CurrencyType');
        } catch (Exception e) {
            HandleCustomException.LogException(e);
        }
        return isMultiCurrecyOrg;
    }
    public static String processDecryption(string encryptedData){ 

        String decryptedData = ''; 
        String expMsg = '';
        
        try{ 

            if(String.isNotBlank(encryptedData)){
                Blob data = EncodingUtil.base64Decode (encryptedData); 
                
                // Get the hex key from the encrypted field
                KTMYOB__Encryption_Configuration__c  setting = KTMYOB__Encryption_Configuration__c.getOrgDefaults();
                Blob cryptoKey = EncodingUtil.base64Decode(setting.KTMYOB__Encryption_Key__c);
                Blob dataToDecrypt = Crypto.decryptWithManagedIV ('AES256', cryptoKey, data); 
                decryptedData = dataToDecrypt.toString(); 
            }

        }catch(Exception e){ 

            expMsg = e.getMessage();
        } 

        return (String.isEmpty(expMsg) ?  decryptedData :  null);  

    }
     public static String processEncryption(String decryptedData){ 

        String b64Data = '';
        String expMsg = '';
        try{
            
            if(String.isNotBlank(decryptedData)){
                KTMYOB__Encryption_Configuration__c setting = KTMYOB__Encryption_Configuration__c.getOrgDefaults();
                String strKey = setting.KTMYOB__Encryption_Key__c;
                Blob cryptoKey = EncodingUtil.base64Decode(strKey);
        
        
                Blob data = Blob.valueOf(decryptedData); 
        
                Blob encryptedData = Crypto.encryptWithManagedIV('AES256', cryptoKey, data ); 
        
                b64Data = EncodingUtil.base64Encode (encryptedData);  
            }

        }catch(Exception e){
            expMsg = e.getMessage();
        }
        
        return (String.isEmpty(expMsg) ?  b64Data :  null);
    } 

}