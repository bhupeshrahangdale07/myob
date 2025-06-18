public with sharing class MYOB_ProductResponse {
    public static List<cls_Items> updatedItemsLst = new List<cls_Items>();

    public class cls_Products{
        public List<cls_Items> Items;
		public String NextPageLink;
        public Integer Count;
    }

	public class cls_Items {
		public String UID;	//90dfd167-a13f-4706-8207-1f60944f85ad
		public String S_Number;	//10800000000
		public String Name;	//Cooler Large
		public boolean IsActive;
		public String Description;	//
		public boolean UseDescription;
		public Double QuantityOnHand;	//41
		public Double QuantityCommitted;	//0
		public Double QuantityOnOrder;	//1
		public Double QuantityAvailable;	//42
		public Double AverageCost;	//211.58
		public Double CurrentValue;	//8674.78
		public Double BaseSellingPrice;	//520
		public boolean IsBought;
		public boolean IsSold;
		public boolean IsInventoried;
		public cls_Account ExpenseAccount;
		public cls_Account CostOfSalesAccount;
		public cls_Account IncomeAccount;
		public cls_Account AssetAccount;
		public cls_BuyingDetails BuyingDetails;
		public cls_SellingDetails SellingDetails;
		public cls_LocationDetails[] LocationDetails;
		public String LastModified;	//2024-07-26T09:29:37.8
		public String URI;	//https://arl2.api.myob.com/accountright/4ce26d32-1a89-4a90-8b3b-0b292bda43c3/Inventory/Item/90dfd167-a13f-4706-8207-1f60944f85ad
		public String RowVersion;	//2709480324840030208
	}

	public class cls_Account {
		public String UID;	//0a2c732a-1283-48b7-9958-4035f1fda92f
		public String Name;	//Equipment
		public String DisplayID;	//5-1100
		public String URI;	//https://arl2.api.myob.com/accountright/4ce26d32-1a89-4a90-8b3b-0b292bda43c3/GeneralLedger/Account/0a2c732a-1283-48b7-9958-4035f1fda92f
	}
	public class cls_BuyingDetails {
		public Double LastPurchasePrice;	//230
		public Double StandardCost;	//0
		public String BuyingUnitOfMeasure;	//1
		public Double ItemsPerBuyingUnit;	//1
		public cls_TaxCode TaxCode;
		public cls_RestockingInformation RestockingInformation;
		public boolean StandardCostTaxInclusive;
	}
	public class cls_TaxCode {
		public String UID;	//2ab1cf79-bce8-4da0-986c-a3bbdd1d02bc
		public String Code;	//GST
		public String URI;	//https://arl2.api.myob.com/accountright/4ce26d32-1a89-4a90-8b3b-0b292bda43c3/GeneralLedger/TaxCode/2ab1cf79-bce8-4da0-986c-a3bbdd1d02bc
	}
	public class cls_RestockingInformation {
		public Double MinimumLevelForRestockingAlert;	//3
		public cls_Supplier Supplier;
		public String SupplierItemNumber;	//DV100
		public String DefaultOrderQuantity;	//10
	}
	public class cls_Supplier {
		public String UID;	//238808d8-9199-4f61-9536-242cf8294693
		public String Name;	//Underwater Springs Pty Ltd
		public String DisplayID;	//SUPP000009
		public String URI;	//https://arl2.api.myob.com/accountright/4ce26d32-1a89-4a90-8b3b-0b292bda43c3/Contact/Supplier/238808d8-9199-4f61-9536-242cf8294693
	}
	public class cls_SellingDetails {
		public Double BaseSellingPrice;	//520
		public String SellingUnitOfMeasure;	//1
		public Double ItemsPerSellingUnit;	//1
		public cls_TaxCode TaxCode;
		public boolean IsTaxInclusive;
		public String CalculateSalesTaxOn;	//ActualSellingPrice
		public String PriceMatrixURI;	//https://arl2.api.myob.com/accountright/4ce26d32-1a89-4a90-8b3b-0b292bda43c3/Inventory/ItemPriceMatrix/90dfd167-a13f-4706-8207-1f60944f85ad
	}
	public class cls_LocationDetails {
		public cls_Location Location;
		public Double QuantityOnHand;	//41
	}
	public class cls_Location {
		public String UID;	//49d1d5a3-c6ce-4aa8-bebb-3a9d79bfb0c4
		public String Identifier;	//Location1
		public String Name;	//Primary Location
		public String URI;	//https://arl2.api.myob.com/accountright/4ce26d32-1a89-4a90-8b3b-0b292bda43c3/Inventory/Location/49d1d5a3-c6ce-4aa8-bebb-3a9d79bfb0c4
	}

	public static List<cls_Items> parse(String jsonText,Boolean isSingleItem){
		//Parsing all the variables which were not be able to parse due to reserved-keyword issue on defined variables.
		if(isSingleItem == true){
			cls_Items item = (cls_Items) System.JSON.deserialize(jsonText, cls_Items.class);

			Map<String, Object> itemMap = (Map<String, Object>) JSON.deserializeUntyped(jsonText);
			item.S_Number = (String) itemMap.get('Number');
			updatedItemsLst.add(item);
		}else{
			parseMultipleProducts(jsonText);
		}
		return updatedItemsLst;
	}

//Helper : For handling multiple products sync.
	public static List<cls_Items> parseMultipleProducts(String jsonText){
		cls_Products parsedProducts = (cls_Products) System.JSON.deserialize(jsonText, cls_Products.class);
		String nextpageUrl = parsedProducts.NextPageLink;
		Integer TotalRecordsCount = parsedProducts.Count;
		Map<String,cls_Items> mapUIDItems = new Map<String,cls_Items>();

		for(cls_Items item: parsedProducts.Items){
			mapUIDItems.put(item.UID,item);
		}

		Map<String, Object> map1 = (Map<String, Object>) JSON.deserializeUntyped(jsonText);
		for(Object itemObj :(List<Object>) map1.get('Items')){
			Map<String, Object> itemMap = (Map<String, Object>) itemObj;
			if(mapUIDItems.containskey((String) itemMap.get('UID'))){
				cls_Items item = mapUIDItems.get((String) itemMap.get('UID'));
				item.S_Number = (String) itemMap.get('Number');
				updatedItemsLst.add(item);
			}
		}

		if(String.isNotBlank(nextpageUrl)){
			calloutforNextSetOfProducts(nextpageUrl);
		}
		
		if(String.isBlank(nextpageUrl) && (TotalRecordsCount == updatedItemsLst.size()) ){
			return updatedItemsLst;
		}else{
			return new List<cls_Items>();
		}
	}

//Helper : For handling multiple products sync.
	public static void calloutforNextSetOfProducts(String nextpageUrl){
		//1. Encoding the Nextpagelink url,recieved from the callout.
		if(String.isNotBlank(nextpageUrl)){
			Integer splitIndex = nextpageUrl.indexOf('/Item?');
			String baseUrl='';
			if(splitIndex > 0){
				// baseUrl = nextpageUrl.substring(0,splitIndex + 6);
				String queryUrl = nextpageUrl.substring(splitIndex + 6);
				Integer querySplitIndex = queryUrl.indexOf('$filter=');
				if(querySplitIndex > 0){
					String nextPageParams =queryUrl.substring(0,querySplitIndex + 8); 
					String queryParams=  queryUrl.substring(querySplitIndex + 8);
					String encodedQueryParams = EncodingUtil.urlEncode((EncodingUtil.urlDecode(queryParams,'UTF-8')),'UTF-8');
					if(String.isNotBlank(encodedQueryParams)){
						baseUrl=nextPageParams+encodedQueryParams;
					}
				}
			}
			System.debug('@@@ baseUrl: '+baseUrl);
			if(String.isNotBlank(baseUrl)){
				//2. Preparing for Callout
                MYOB_Callout_Helper.CalloutDetails calloutWrapper = new MYOB_Callout_Helper.CalloutDetails();
                calloutWrapper.helper = 'ProductDynamicController.fetchAllMyobProducts()';
                calloutWrapper.requestMethod = 'GET';  
                calloutWrapper.requestEndpoint='/Inventory/Item?'+baseUrl;

				//3. Generic method for Syncing MYOB Products to Salesforce.
                MYOB_Callout_Helper.HTTPModel objHTTP = MYOB_Callout_Helper.genericCalloutMethod(calloutWrapper.requestBody,new Map<String,String>(),calloutWrapper);
                if (!objHTTP.isCalloutException && !objHTTP.isLogException) {
					parseMultipleProducts(objHTTP.response);
				}
			}
		}
	}


}