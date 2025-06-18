public with sharing class MYOB_CustomerResponse {

    public class cls_Contacts{
        public List<cls_Items> Items;
        public cls_NextPageLink NextPageLink;
        public Integer Count;	//173
    }
    public class cls_Items {
        public String UID;	//07763f97-43cc-4149-8c00-d92feb4e1404
        public String CompanyName;	//A-Z Stationery Supplies
        public String FirstName;	//A-Z Stationery Supplies
        public String LastName;	    //A-Z Stationery Supplies
        public boolean IsIndividual;
        public String DisplayID;	//CUS000001
        public boolean IsActive;
        public List<cls_Addresses> Addresses;
        public String Notes;	//
        public cls_Identifiers Identifiers;
        public cls_CustomList1 CustomList1;
        public cls_CustomList2 CustomList2;
        public cls_CustomList3 CustomList3;
        public cls_CustomField1 CustomField1;
        public cls_CustomField2 CustomField2;
        public cls_CustomField3 CustomField3;
        public Double CurrentBalance;	//1523.63
        public cls_SellingDetails SellingDetails;
        public cls_PaymentDetails PaymentDetails;
        public cls_ForeignCurrency ForeignCurrency;
        public String LastModified;	//1970-01-01T00:00:00
        public cls_PhotoURI PhotoURI;
        public String URI;	//https://arl2.api.myob.com/accountright/4ce26d32-1a89-4a90-8b3b-0b292bda43c3/Contact/Customer/07763f97-43cc-4149-8c00-d92feb4e1404
        public String RowVersion;	//7072621739808653312
    }
    public class cls_Addresses {
        public Integer Location;	//1
        public String Street;	//5/76 Readen Road
        public String City;	//Bondi
        public String State;	//NSW
        public String PostCode;	//2026
        public String Country;	//Australia
        public String Phone1;	//02 9452 1235
        public String Phone2;	//02 9452 1237
        public String Phone3;	//02 9452 1233
        public String Fax;	//02 9452 1236
        public String Email;	//AZ@ozemail.com.au
        public String Website;	//www.myob.com.au
        public String ContactName;	//Charles
        public String Salutation;	//
    }
    public class cls_Identifiers {
    }
    public class cls_CustomList1 {
    }
    public class cls_CustomList2 {
    }
    public class cls_CustomList3 {
    }
    public class cls_CustomField1 {
    }
    public class cls_CustomField2 {
    }
    public class cls_CustomField3 {
    }
    public class cls_SellingDetails {
        public String SaleLayout;	//Item
        public String PrintedForm;	//MYOB's Plain Paper Invoice
        public String InvoiceDelivery;	//Print
        public cls_ItemPriceLevel ItemPriceLevel;
        public cls_IncomeAccount IncomeAccount;
        public String ReceiptMemo;	//
        public cls_SalesPerson SalesPerson;
        public String SaleComment;	//We appreciate your business.
        public String ShippingMethod;	//Freight
        public Double HourlyBillingRate;	//0
        public String ABN;	//45 676 343 223
        public String ABNBranch;	//014
        public cls_TaxCode TaxCode;
        public cls_FreightTaxCode FreightTaxCode;
        public boolean UseCustomerTaxCode;
        public cls_Terms Terms;
        public cls_Credit Credit;
        public String TaxIdNumber;	//123456987
        public String Memo;	//
    }
    public class cls_ItemPriceLevel {
    }
    public class cls_IncomeAccount {
        public String UID;	//10587df6-d558-4bdd-86e4-35a1780dc9c6
        public String Name;	//Sales - Stands
        public String DisplayID;	//4-1500
        public String URI;	//https://arl2.api.myob.com/accountright/4ce26d32-1a89-4a90-8b3b-0b292bda43c3/GeneralLedger/Account/10587df6-d558-4bdd-86e4-35a1780dc9c6
    }
    public class cls_SalesPerson {
    }
    public class cls_TaxCode {
        public String UID;	//2ab1cf79-bce8-4da0-986c-a3bbdd1d02bc
        public String Code;	//GST
        public String URI;	//https://arl2.api.myob.com/accountright/4ce26d32-1a89-4a90-8b3b-0b292bda43c3/GeneralLedger/TaxCode/2ab1cf79-bce8-4da0-986c-a3bbdd1d02bc
    }
    public class cls_FreightTaxCode {
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
        public Double VolumeDiscount;	//0
    }
    public class cls_Credit {
        public Double xLimit;	//55000
        public Double Available;	//53476.37
        public Double PastDue;	//1486.23
        public boolean OnHold;
    }
    public class cls_PaymentDetails {
    }
    public class cls_ForeignCurrency {
    }
    public class cls_PhotoURI {
    }
    public class cls_NextPageLink {
    }

    public static cls_Contacts parseListOfContacts(String json){
        return (cls_Contacts) System.JSON.deserialize(json, cls_Contacts.class);
    }

    public static cls_Items parseContact(String json){
        return (cls_Items) System.JSON.deserialize(json, cls_Items.class);
    }

}