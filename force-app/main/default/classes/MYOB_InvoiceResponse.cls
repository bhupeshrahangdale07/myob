public without sharing class MYOB_InvoiceResponse {

    public class cls_Invoices{
        public List<cls_Items> Items;
    }
	public class cls_Items {
		public String UID;	//5e79825a-9492-4b14-9773-b69141709949
		public String S_Number;	//00000028
		public String S_Date;	//2017-08-17T00:00:00
		public String CustomerPurchaseOrderNumber;	//
		public cls_Customer Customer;
		public String PromisedDate;
		public Double BalanceDueAmount;	//268.1
		public Double BalanceDueAmountForeign;
		public cls_Lines[] Lines;
		public String Status;	//Open
		public String ShipToAddress;	//A-Z Stationery Supplies 22 Smith Street Carlingford  NSW  2056
		public cls_Terms Terms;
		public Boolean IsTaxInclusive;
		public Double Subtotal;	//360.5
		public Double SubtotalForeign;
		public Double Freight;	//0
		public Double FreightForeign;
		public cls_FreightTaxCode FreightTaxCode;
		public Double TotalTax;	//32.77
		public Double TotalTaxForeign;
		public Double TotalAmount;	//360.5
		public Double TotalAmountForeign;
		public cls_Salesperson Category;
		public cls_Salesperson Salesperson;
		public String Comment;	//We appreciate your business.
		public String ShippingMethod;	//Freight
		public String JournalMemo;	//Sale; A-Z Stationery Supplies
		public String ReferralSource;
		public String InvoiceDeliveryStatus;	//Nothing
		public String LastPaymentDate;	//2018-04-07T00:00:00
		public boolean CanApplySurcharge;
		public boolean CanApplyBPay;
		public cls_Order Order;
		public String OnlinePaymentMethod;
		public cls_ForeignCurrency ForeignCurrency;
		public Double CurrencyExchangeRate;
		public String LastModified;	//1970-01-01T00:00:00
		public String URI;	//https://arl2.api.myob.com/accountright/4ce26d32-1a89-4a90-8b3b-0b292bda43c3/Sale/Invoice/Item/5e79825a-9492-4b14-9773-b69141709949
		public String RowVersion;	//-6909929203269894144
	}
	public class cls_Customer {
		public String UID;	//07763f97-43cc-4149-8c00-d92feb4e1404
		public String Name;	//A-Z Stationery Supplies
		public String DisplayID;	//CUS000001
		public String URI;	//https://arl2.api.myob.com/accountright/4ce26d32-1a89-4a90-8b3b-0b292bda43c3/Contact/Customer/07763f97-43cc-4149-8c00-d92feb4e1404
	}

	public class cls_Lines {
		public Integer RowID;	//21
		public Double ShipQuantity;	//2
		public Double UnitPrice;	//67
		public String UnitOfMeasure;
		public Double UnitCount;
		public Double UnitPriceForeign;
		public Double DiscountPercent;	//0
		public Double CostOfGoodsSold;	//0
		public cls_Item Item;
		public cls_Account Account;
		public cls_Location Location;
		public String Type;	//Transaction
		public String Description;	//1 hour - Cooler Service
		public Double Total;	//134
		public Double TotalForeign;
		public cls_Item Job;
		public cls_TaxCode TaxCode;
		public String RowVersion;	//2386907802506362880
	}

	public class cls_Item {
		public String UID;	//5004caf5-0d9e-485f-84ba-6a6e8225d457
		public String S_Number;	//999
		public String Name;	//1 hour - Cooler Service
		public String URI;	//https://arl2.api.myob.com/accountright/4ce26d32-1a89-4a90-8b3b-0b292bda43c3/Inventory/Item/5004caf5-0d9e-485f-84ba-6a6e8225d457
	}
	public class cls_Account {
		public String UID;	//d3f55ef1-ce77-4ef2-a415-61d04db2c5fc
		public String Name;	//Service - Coolers
		public String DisplayID;	//4-2100
		public String URI;	//https://arl2.api.myob.com/accountright/4ce26d32-1a89-4a90-8b3b-0b292bda43c3/GeneralLedger/Account/d3f55ef1-ce77-4ef2-a415-61d04db2c5fc
	}
	public class cls_Location {
		public String UID;	//49d1d5a3-c6ce-4aa8-bebb-3a9d79bfb0c4
		public String Identifier;	//Location1
		public String Name;	//Primary Location
		public String URI;	//https://arl2.api.myob.com/accountright/4ce26d32-1a89-4a90-8b3b-0b292bda43c3/Inventory/Location/49d1d5a3-c6ce-4aa8-bebb-3a9d79bfb0c4
	}
	public class cls_TaxCode {
		public String UID;	//2ab1cf79-bce8-4da0-986c-a3bbdd1d02bc
		public String Code;	//GST
		public String URI;	//https://arl2.api.myob.com/accountright/4ce26d32-1a89-4a90-8b3b-0b292bda43c3/GeneralLedger/TaxCode/2ab1cf79-bce8-4da0-986c-a3bbdd1d02bc
	}
	public class cls_Terms {
		public String PaymentIsDue;	//DayOfMonthAfterEOM
		public Integer DiscountDate;	//1
		public Integer BalanceDueDate;	//30
		public Double DiscountForEarlyPayment;	//5
		public Double MonthlyChargeForLatePayment;	//8.5
		public String DiscountExpiryDate;	//2017-09-01T00:00:00
		public Double Discount;	//0
		public Double DiscountForeign;
		public String DueDate;	//2017-09-30T00:00:00
		public Double FinanceCharge;	//1916.51
		public Double FinanceChargeForeign;
	}
	public class cls_FreightTaxCode {
		public String UID;	//2ab1cf79-bce8-4da0-986c-a3bbdd1d02bc
		public String Code;	//GST
		public String URI;	//https://arl2.api.myob.com/accountright/4ce26d32-1a89-4a90-8b3b-0b292bda43c3/GeneralLedger/TaxCode/2ab1cf79-bce8-4da0-986c-a3bbdd1d02bc
	}
	public class cls_Salesperson {
		public String UID;	//fd4d9cb3-2290-4351-89a7-2e984ce0590b
		public String Name;	//Mary Jones
		public String DisplayID;	//EMP00001
		public String URI;	//https://arl2.api.myob.com/accountright/4ce26d32-1a89-4a90-8b3b-0b292bda43c3/Contact/Employee/fd4d9cb3-2290-4351-89a7-2e984ce0590b
	}
	public class cls_Order {
	}
	public class cls_ForeignCurrency {
	}
	

	public static List<cls_Items> parse(String jsonText,Boolean isSingleItem){
		List<cls_Items> updatedItems = new List<cls_Items>();
		Map<String,cls_Items> mapUIDItems = new Map<String,cls_Items>();

		//Parsing all the variables which were not be able to parse due to reserved-keyword issue on defined variables.
		if(isSingleItem == true){
			cls_Items item = (cls_Items) System.JSON.deserialize(jsonText, cls_Items.class);

			Map<String, Object> itemMap = (Map<String, Object>) JSON.deserializeUntyped(jsonText);
			item.S_Number = (String) itemMap.get('Number');
			item.S_Date = (String) itemMap.get('Date');
			System.debug('### item ::: '+item);
			updatedItems.add(item);
		}else{
			cls_Invoices parsedInvoices = (cls_Invoices) System.JSON.deserialize(jsonText, cls_Invoices.class);
			for(cls_Items item: parsedInvoices.Items){
				mapUIDItems.put(item.UID,item);
			}

			Map<String, Object> map1 = (Map<String, Object>) JSON.deserializeUntyped(jsonText);
			for(Object itemObj :(List<Object>) map1.get('Items')){
				Map<String, Object> itemMap = (Map<String, Object>) itemObj;
				if(mapUIDItems.containskey((String) itemMap.get('UID'))){
					cls_Items item = mapUIDItems.get((String) itemMap.get('UID'));
					item.S_Number = (String) itemMap.get('Number');
					item.S_Date = (String) itemMap.get('Date');
					updatedItems.add(item);
				}
			}
		}
		System.debug('### updatedItems ::: '+updatedItems);
		return updatedItems;
	}
}