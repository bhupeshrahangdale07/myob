public without sharing class MYOB_ErrorResponse {

    public class ErrorsCls{
        public List<SingleErrorCls> Errors; 
    }
    public class SingleErrorCls{
        public String Name;	//DeveloperInactive
        public String Message;	//API key is missing or inactive
        public String AdditionalDetails;	//Header: x-myobapi-key
        public Integer ErrorCode;	//202
        public String Severity;	//Error
        public String LearnMore;	//[Documentation URI]
    }
    public static ErrorsCls parseJSON(String json){
        return (ErrorsCls) System.JSON.deserialize(json, ErrorsCls.class);
    }
    
}