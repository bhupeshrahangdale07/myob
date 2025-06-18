import HideLightningHeader from '@salesforce/resourceUrl/noHeader';
import { CurrentPageReference } from 'lightning/navigation';
import { loadStyle } from "lightning/platformResourceLoader";
import { LightningElement, track, wire } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkAuthorizationSteps from '@salesforce/apex/MYOB_Callout_Helper.checkAuthorizationSteps';
import createUpdateInvoiceParse from '@salesforce/apex/InvoiceDynamicController.createUpdateInvoiceParse';
import customerList from '@salesforce/apex/GenerateInvoiceController.customerList';
import displayInvoiceNLineItems from '@salesforce/apex/InvoiceDynamicController.displayInvoiceNLineItems';
import productList from '@salesforce/apex/GenerateInvoiceController.productList';

const TAXOPTION = [
        { label: 'Tax inclusive', value: 'taxInclusive'},
        { label: 'Tax exclusive', value: 'taxExclusive' }
    ],
    HUNDRED = 100,
    ONE = 1,
    SIXTEEN = 16,
    THIRTYSIX = 36,
    TWO = 2,
    ZERO = 0;
  
export default class GenerateInvoice extends LightningElement {
    @track flagForCustomerList = false;
    @track flagForLineItemRecords = false;
    @track flagForBilling = false;
    @track existingInvoiceRow = false;
    @track xIconName = "utility:chevronright";
    showLoading = false;
    isLoading = false;
    isSync = false;
    componentTitle = "Generate MYOB Invoice";
    labelOne = "Select Customer";
    labelTwo = "Notes to Customer";
    labelThree = "Subtotal";
    labelFour = "Freight ($)";
    labelFive = "Freight Tax Code";
    labelSix = "Tax";
    labelSeven = "Total";
    labelEight = "Amount paid ($)";
    labelNine = "Balance Due"
    taxOption = TAXOPTION;

    syncDue = '';
    syncTotal = '';
    syncPaid = '';

    //Invoice Details
    @track invoiceData = {};
    selectedCustomer = '';
    customerList = [];
    customerBillingAddr = {};
    flagForCustomerBillingAddr = false;
    @track customerPicklistOrdered = [];
    noOfCompanyRecords = ''; //-------------------------------------------- Check

    /*invoiceNumber = '';
    customerPONumber = '';
    invoiceDate = '';
    invoiceDueDate = '';*/
    amountsAre = '';
    
    //Lineitem
    liDisabledField = true;
    @track lineitemRecords = [];
    productList = [];
    taxList = [];
    itemIdOption = [];
    taxCodeOption = [];

    //Invoice Billing
    billingDisabledFields = true;
    freightTaxOption = [];
    notesToCustomer = '';
    notesToCustomerOption = []; //-------------------------------------------- Check
    invoiceSubtotal = 0.00;
    invoiceFreight = 0.00;
    invoiceFreightTax = 0.00;
    invoiceTax = 0.00;
    invoiceTotal = 0.00;
    invoiceAmountPaid = 0.00;
    invoiceBalanceDue = 0.00;

    //Modal Popup
    isShowModal = false;
    @track customerType = 'Company';
    disableCustomerType = false;
    companyContact = true;
    showABNnContactId = false;
    showBillingAddr = false;
    showShippingAddr = false;
    showNotes = false;
    billingCountryOption = [];
    billingStateOption = [];
    shippingCountryOption = [];
    shippingStateOption = [];
    disableShippingAddr = false;
    emailToCheck = '';

    //Create Invoice
    @track invoiceId = '';
    mapInvoiceDetails;
    lstMapLineItemDetails;
    saveEnable = false;
    saveAndSendEnable = false;
    disableSave = false;
    disableSaveNsend = false;

    // Create/Sync Customer
    isShowModal = false; 
    @track fromGenerateInvoice = false;
    @track customerRec;
    companyMyobSfFldMapping = [];
    individualMyobSfFldMapping = [];
    @track myobSfFldMapping;
    @track customerId;


    @wire(CurrentPageReference)
    currentPageReference({ state }) {
        if (state && state.c__recordId) {
            this.invoiceId = state.c__recordId;
        }
    }
    
    connectedCallback(){
        console.clear();
        this.invoiceData.amountsAre = 'taxInclusive';
        this.showLoading = true;
        this.getConnectionDetails();
    }

    getConnectionDetails(){
        checkAuthorizationSteps()
        .then(response => {
            if (response.status === 'Success') {
                console.log('### Authorization Successful');
                if(this.invoiceId){
                    this.isSync = true;
                    this.existingInvoiceRow = true;
                }
                this.getCustomerPicklist();
            } else if (response.status === 'Failed' && response.isConnectionError) {
                console.error('Authorization Failed: ', response.message);
                this.showNotification('Authorization Failed: Please complete all connection steps on MYOB Setup Page.','error');
            }
        })
        .catch(error => {
            this.showLoading = false;
            console.error('!!! Error occurred while checking authorization: ', error);
        });
    }

    getCustomerPicklist(){
        customerList({
            "searchStr": this.selectedCustomer
        })
        .then(data => {
            if(data){
                console.log('### customerList Return: ', data);
                //this.noOfCompanyRecords = data.companyRecordNo; -------------------------------------------- Check
                this.companyMyobSfFldMapping = data.mapOfMyobFldApiNameNdSfFldApiNameCompany;
                this.individualMyobSfFldMapping = data.mapOfMyobFldApiNameNdSfFldApiNameIndividual;
                console.log('$$$ this.companyMyobSfFldMapping: ', JSON.stringify(this.companyMyobSfFldMapping));
                console.log('$$$ this.individualMyobSfFldMapping: ', JSON.stringify(this.individualMyobSfFldMapping));
                this.customerList = data.listOfMapOfSelectedCustomer;
                this.customerPicklistOrdered = Object.keys(data.listOfMapOfSelectedCustomer).map(Index => {
                    let customerDetails = data.listOfMapOfSelectedCustomer[Index];
                    let label = customerDetails['CompanyName'] ? customerDetails['CompanyName'] : `${customerDetails['FirstName']} ${customerDetails['LastName']}`;
                    return {
                        label: label,
                        value: customerDetails['Id']
                    };
                });
                if(!this.invoiceId){
                    this.customerPicklistOrdered.unshift({
                        label: 'Add New Customer',
                        value: 'add_new_customer'
                    });
                }
                if(this.customerPicklistOrdered){
                    this.handleFlagChange();
                }
                console.log('### Sorted customerPicklistOrdered Data: ', JSON.stringify(this.customerPicklistOrdered));
                this.getProductPicklist();
            }
        })
        .catch((error) => {
            this.showLoading = false;
            console.error('!!! Error in customerList: ', JSON.stringify(error));
            console.error('!!! Error in customerList: ', error);
        });
    }

    handleFlagChange() {
        this.flagForCustomerList = true;
    }

    getProductPicklist(){
        productList({
            "searchStr": ''
        })
        .then(data => {
            if (data) {
                console.log('### productList Data: ', data);
                this.productList = data.listOfMapOfSelectedProduct;
                this.taxList = data.metadataTypeNdRec;
                this.itemIdOption = Object.keys(data.listOfMapOfSelectedProduct).map(Index => {
                    let lineitemDetails = data.listOfMapOfSelectedProduct[Index];
                    return {
                        label: lineitemDetails['Name'],
                        value: lineitemDetails['Id']
                    };
                });
                console.log('### Sorted itemIdOption: ', JSON.stringify(this.itemIdOption));
                this.taxCodeOption = Object.keys(data.metadataTypeNdRec).map(Index => {
                    let taxCodeDetails = data.metadataTypeNdRec[Index];
                    console.log('$$$ taxCodeDetails: ', taxCodeDetails);
                    return {
                        label: `${taxCodeDetails['KTMYOB__Tax_Code__c']} ${taxCodeDetails['KTMYOB__Tax_Type__c']} ${taxCodeDetails['KTMYOB__Tax_Rate__c']}%`,
                        value: taxCodeDetails['KTMYOB__MYOB_Id__c']
                    };
                });
                console.log('### Sorted taxCodeOption: ', JSON.stringify(this.taxCodeOption));
                console.log('### Sorted freightTaxOption: ', JSON.stringify(this.freightTaxOption));
                this.freightTaxOption = this.taxCodeOption;
                this.flagForBilling = true;
                this.preInvoiceSettings();
            }
        })
        .catch((error) => {
            this.showLoading = false;
            console.error('!!! Error in productList: ', JSON.stringify(error));
        });
    }

    preInvoiceSettings(){
        try{
            if(this.isSync){
                this.syncInvoiceRecord();
            }else{
                let initialNullRecord=[];
                const randomId = Math.random() * SIXTEEN;
                initialNullRecord = {id: randomId.toString(THIRTYSIX), Description: "", Category: "", UnitOfMeasure: "", UnitCount: 0, UnitPrice: 0, DiscountPercent: 0, Amount:0, TaxCode: ""};
                this.lineitemRecords.push(initialNullRecord);
                console.log('$$$ this.lineitemRecords: ' + JSON.stringify(this.lineitemRecords));
                this.flagForLineItemRecords = true;
                this.showLoading = false;
            }
        }catch(error){
            this.showLoading = false;
            console.log('!!! Error in preInvoiceSettings(): ' + error);
            this.showNotification(error.body.message, 'error');
        }
    }

    syncInvoiceRecord(){
        displayInvoiceNLineItems({ invoiceId:this.invoiceId , getNonNullInvoiceFields: true})
        .then(result=>{
            console.log('### displayInvoiceNLineItems.result: ', result);

            this.syncInvoiceData = result.mapInvoiceDetails
            this.syncRecordIdLineitemRecords = result.lstMapLineItemDetails;

            this.syncDue = this.syncInvoiceData.BalanceDueAmount;
            this.syncTotal = this.syncInvoiceData.TotalAmount;
            this.syncPaid = this.syncInvoiceData.TotalTax; // -------------------------------------------- Check

            this.invoiceData.invoiceNumber = this.syncInvoiceData.Number;
            this.invoiceData.customerPONumber = this.syncInvoiceData.CustomerPurchaseOrderNumber;
            this.invoiceData.invoiceDate = this.syncInvoiceData.Date;
            this.invoiceData.invoiceDueDate = this.syncInvoiceData.DueDate;
            if(this.syncInvoiceData.IsTaxInclusive){
                this.invoiceData.amountsAre = 'taxInclusive';
            }else{
                this.invoiceData.amountsAre = 'taxExclusive';
            }

            for(let index = 0; index < this.syncRecordIdLineitemRecords.length; index++){
                const liRecord = this.syncRecordIdLineitemRecords[index];
                if(!this.lineitemRecords[index]){
                    this.lineitemRecords[index] = {};
                }
                if(liRecord?.ProductId){
                    const itemId = liRecord.ProductId;
                    this.lineitemRecords[index].itemId = itemId;
                    const selectedProductIndex = this.itemIdOption.findIndex(item => item.value === itemId);
                    if(selectedProductIndex !== -1){
                        const selectedProduct = this.productList[selectedProductIndex];
                        if(selectedProduct?.IncomeAccountName){
                            this.lineitemRecords[index].Category = selectedProduct.IncomeAccountName;
                        }
                    }
                }
                if(liRecord?.Description) this.lineitemRecords[index].Description = liRecord.Description;
                if(liRecord?.UnitOfMeasure) this.lineitemRecords[index].UnitOfMeasure = liRecord.UnitOfMeasure;
                if(liRecord?.ShipQuantity) this.lineitemRecords[index].UnitCount = liRecord.ShipQuantity;
                if(liRecord?.UnitPrice) this.lineitemRecords[index].UnitPrice = liRecord.UnitPrice;
                if(liRecord?.DiscountPercent) this.lineitemRecords[index].DiscountPercent = liRecord.DiscountPercent;
                if(liRecord?.Total) this.lineitemRecords[index].Amount = liRecord.Total;
                
                if(liRecord?.TaxCode){
                    let selectedTax = Object.values(this.taxList).find(ele => ele.Id === liRecord.TaxCode);
                    if(selectedTax){
                        this.lineitemRecords[index].TaxCode = selectedTax.KTMYOB__MYOB_Id__c;
                    }
                }
            }
            console.log('$$$ this.lineitemRecords isSync: ' + JSON.stringify(this.lineitemRecords));
            this.countSubTotal();
            this.calculateFreight();
            //this.calculateTax(); -------------------------------------------- Check
            this.calculateTotal();
            this.calculateBill();
            this.flagForLineItemRecords = true;
            this.showLoading = false;
        })
        .catch(error =>{
            this.showLoading = false;
            console.log('!!! Error in displayInvoiceNLineItems(): ' + error);
        });
    }
    
    updateCustomerValues(event){
        try{
            let targetName;
            if(typeof event !==  'undefined') {
                targetName = event.target.name;
            }
            if(targetName === 'selectCustomer'){
                this.fromGenerateInvoice = true;
                this.customerId = event.detail;
                this.flagForCustomerList =  false;
                this.isShowModal = true;
            }
        }catch(error){
            console.log('!!! Error in updateCustomerValues(): ' + error);
        }
    }

    /*billingAddr(selectedCustomer){
        if(selectedCustomer.BillAddrToEmail){
            this.emailToCheck = this.selectedCustomer.BillAddrToEmail;
        }
        if(selectedCustomer.CompanyName){
            this.invoiceData.CompanyUID = selectedCustomer.Id;
        }else if(selectedCustomer.FirstName || selectedCustomer.LastName){
            this.invoiceData.IndividualUID = selectedCustomer.Id;
        }
        if (selectedCustomer) {
            this.customerBillingAddr = {
                Name : this.selectedCustomerLabel,
                BillAddrStreet : selectedCustomer.BillAddrStreet,
                BillAddrCity: selectedCustomer.BillAddrCity,
                BillAddrState : selectedCustomer.BillAddrState,
                BillAddrPostalCode : selectedCustomer.BillAddrPostalCode,
                BillAddrCountry: selectedCustomer.BillAddrCountry,
            };
            this.flagForCustomerBillingAddr = true;
        }
    }*/

    /*actionInsertContact(){
        this.isLoading = true;
        const inputFields = this.template.querySelectorAll(".newCustomerValidate");
        let isValid = true;
        inputFields.forEach((inputField) => {
            if (!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
        });
        console.log('isValid = ',isValid);
        if(isValid) {
            if(this.newCustomerData){
                /* @@@ ADD addCustomer functioning*/
                /*this.getCustomerPicklist();
                this.customerBillingAddr = {
                    Name : this.companyContact ? this.newCustomerData['companyName'] : `${this.newCustomerData['firstName']} ${this.newCustomerData['lastName']}`,
                    BillAddrStreet : this.newCustomerData.BillAddrStreet,
                    BillAddrCity: this.newCustomerData.BillAddrCity,
                    BillAddrState : this.newCustomerData.BillAddrState,
                    BillAddrPostalCode : this.newCustomerData.BillAddrPostalCode,
                    BillAddrCountry: this.newCustomerData.BillAddrCountry,
                };
                this.flagForCustomerBillingAddr = true;
                this.hideModalBox();
            }
        }else{
            this.showNotification('Please resolved all errors','error');
            this.isLoading = false;
        }
    }*/

    convertDateFormat(dateString) {
        console.log('$$$ dateString: ', dateString);
        const [year, month, day] = dateString.split('-');
        return `${month}/${day}/${year}`;
    }

    updateInvoiceValues(event){
        try{
            let targetName = event.target.name;
            if(targetName === 'invoiceNumber'){
                this.invoiceData.Number = event.target.value;
            }else if(targetName === 'customerPONumber'){
                this.invoiceData.CustomerPurchaseOrderNumber = event.target.value;
            }else if(targetName === 'invoiceDate'){
                this.invoiceData.Date = this.convertDateFormat(event.target.value);
            }else if(targetName === 'invoiceDueDate'){
                this.invoiceData.DueDate = this.convertDateFormat(event.target.value);
            }else if(targetName === 'amountsAre'){
                if(event.target.value === 'taxInclusive'){
                    this.invoiceData.amountsAre = 'taxInclusive';
                }else{
                    this.invoiceData.amountsAre = 'taxExclusive';
                }
                const temparr = this.lineitemRecords;
                let selectedProductTaxRate = 0.00;
                for(let index=ZERO; index<temparr.length; index+=ONE){
                    const unitCount = parseFloat(temparr[index].UnitCount) || 0,
                          unitPrice = parseFloat(temparr[index].UnitPrice) || 0,
                          discountPercent = parseFloat(temparr[index].DiscountPercent) || 0,
                          taxCode = temparr[index].TaxCode || null;
                    if(taxCode){
                        let selectedProductIndex = this.taxCodeOption.findIndex(item => item.value === taxCode);
                        if (selectedProductIndex !== -1) {
                            let selectedTax = Object.values(this.taxList).find(ele => ele.KTMYOB__MYOB_Id__c === temparr[index].TaxCode);
                            selectedProductTaxRate = selectedTax.KTMYOB__Tax_Rate__c;
                            temparr[index].Amount = this.countLineItemAmountValue(unitCount,unitPrice,discountPercent,selectedProductTaxRate);
                        } else {
                            console.error('!!! Error in updateInvoiceValues() taxCode picklist');
                        }
                    }
                }
                this.countSubTotal();
                this.calculateFreight();
                //this.calculateTax();
                this.calculateTotal();
                this.calculateBill();
            }
            console.log('$$$ this.invoiceData: ', JSON.stringify(this.invoiceData));
        }catch(error){
            console.log('!!! Error in updateInvoiceValues(): ' + error);
        }
        this.saveBtnVisibility();
    }

    updateLineItemValues(event){
        this.showLoading = true;
        try{
            let targetName = '',
                selectedProductTaxRate;
            if(typeof event !==  'undefined') {
                targetName = event.target.name;
            }
            const foundelement = this.lineitemRecords.find(ele => ele.id === event.target.dataset.id);
            if(foundelement.TaxCode){
                let selectedProductIndex = this.taxCodeOption.findIndex(item => item.value === foundelement.TaxCode);
                if (selectedProductIndex !== -1) {
                    let selectedTax = Object.values(this.taxList).find(ele => ele.KTMYOB__MYOB_Id__c === foundelement.TaxCode);
                    selectedProductTaxRate = selectedTax.KTMYOB__Tax_Rate__c;
                } else {
                    console.error('!!! Error in updateLineItemValues taxCode picklist');
                }
            }else{
                selectedProductTaxRate = 0.00;
            }
            if(targetName === 'itemId'){
                let selectedProductId = event.detail;
                console.log('$$$ selectedProduct Id: ', JSON.stringify(selectedProductId));
                if(selectedProductId){
                    let selectedProductIndex = this.itemIdOption.findIndex(item => item.value === selectedProductId);
                    if (selectedProductIndex !== -1) {
                        let selectedProductLabel = this.itemIdOption[selectedProductIndex].label;
                        foundelement.ProductId = selectedProductId;
                        console.log('$$$ selectedProduct Label:', selectedProductLabel);
                    } else {
                        console.error('!!! Error in updateLineItemValues itemId picklist');
                    }
                    if(foundelement.ProductId){
                        let selectedProduct = this.productList[selectedProductIndex];
                        console.log('$$$ this.productList: ', JSON.stringify(this.productList));
                        console.log('$$$ this.productList: ', this.productList);
                        console.log('$$$ selectedProduct: ', JSON.stringify(selectedProduct));
                        if (selectedProduct) {
                            foundelement.Category = selectedProduct.IncomeAccountName;
                        }
                    }
                }
            }else if(targetName === 'description'){
                foundelement.Description = event.target.value;
            }else if(targetName === 'unit'){
                foundelement.UnitOfMeasure = event.target.value;
            }else if(targetName === 'noOfUnits'){
                foundelement.UnitCount = event.target.value;
                foundelement.Amount = this.countLineItemAmountValue(foundelement.UnitCount,foundelement.UnitPrice,foundelement.DiscountPercent, selectedProductTaxRate);
            }else if(targetName === 'unitPrice'){
                foundelement.UnitPrice = event.target.value;
                foundelement.Amount = this.countLineItemAmountValue(foundelement.UnitCount,foundelement.UnitPrice,foundelement.DiscountPercent, selectedProductTaxRate);
            }else if(targetName === 'discountPercentage'){
                foundelement.DiscountPercent = event.target.value;
                foundelement.Amount = this.countLineItemAmountValue(foundelement.UnitCount,foundelement.UnitPrice,foundelement.DiscountPercent, selectedProductTaxRate);
            }else if(targetName === 'taxCode'){
                foundelement.TaxCode = event.detail;
                let selectedProductIndex = this.taxCodeOption.findIndex(product => product.value === foundelement.TaxCode);
                if (selectedProductIndex !== -1) {
                    let selectedTax = Object.values(this.taxList).find(ele => ele.KTMYOB__MYOB_Id__c === foundelement.TaxCode);
                    selectedProductTaxRate = selectedTax.KTMYOB__Tax_Rate__c;
                    foundelement.Amount = this.countLineItemAmountValue(foundelement.UnitCount,foundelement.UnitPrice,foundelement.DiscountPercent, selectedProductTaxRate);
                } else {
                    console.error('!!! Error in updateLineItemValues taxCode picklist');
                }
            }
            console.log('$$$ this.lineitemRecords: ', JSON.stringify(this.lineitemRecords));
            this.countSubTotal();
            this.calculateFreight();
            //this.calculateTax();
            this.calculateTotal();
            this.calculateBill();
        }catch(error){
            this.showLoading = false;
            console.log('!!! Error in updateLineItemValues(): ' + error);
        }
        this.showLoading = false;
    }

    updateBillingValues(event){
        this.showLoading = true;
        try{
            let targetName = '';
            if(typeof event !==  'undefined') {
                targetName = event.target.name;
            }
            if(targetName === 'notesToCustomer'){
                this.notesToCustomer = event.target.value;
            }else if(targetName === 'invoiceFreight'){
                this.invoiceFreight = event.target.value;
            }else if(targetName === 'invoiceFreightTax'){
                this.invoiceFreightTax = event.target.value;
            }
        }catch(error){
            this.showLoading = false;
            console.log('!!! Error in updateBillingValues(): ' + error);
        }
        this.showLoading = false;
    }

    countLineItemAmountValue(UnitCount, UnitPrice, DiscountPercent, selectedProductTax){
        try{
            let newAmount  = 0.00,
                discountedNewAmount = 0.00,
                discountedTaxedAmount = 0.00;
            if (UnitCount !== null && UnitPrice !== null && DiscountPercent !== null && selectedProductTax !== null && UnitCount !== 0 && UnitPrice !== 0 && DiscountPercent !== 0 && selectedProductTax!== 0){
                newAmount = (UnitCount * UnitPrice).toFixed(TWO);
                discountedNewAmount = (newAmount - (newAmount * (DiscountPercent/HUNDRED))).toFixed(TWO);
                if(this.invoiceData.amountsAre === 'taxInclusive'){
                    discountedTaxedAmount = (parseFloat(discountedNewAmount) + (parseFloat(discountedNewAmount) * (selectedProductTax/HUNDRED))).toFixed(TWO);
                    return discountedTaxedAmount;
                }else{
                    return discountedNewAmount;
                }
            }else if(UnitCount !== null && UnitPrice !== null && DiscountPercent !== null && UnitCount !== 0 && UnitPrice !== 0 && DiscountPercent !== 0) {
                newAmount = (UnitCount * UnitPrice).toFixed(TWO);
                discountedNewAmount = (newAmount - (newAmount * (DiscountPercent/HUNDRED))).toFixed(TWO);
                return discountedNewAmount;
            }else if(UnitCount !== null && UnitPrice !== null && selectedProductTax !== null && UnitCount !== 0 && UnitPrice !== 0 && selectedProductTax !== 0) {
                newAmount = (UnitCount * UnitPrice).toFixed(TWO);
                if(this.invoiceData.amountsAre === 'taxInclusive'){
                    discountedTaxedAmount = (parseFloat(newAmount) - (parseFloat(newAmount) * (selectedProductTax/HUNDRED))).toFixed(TWO);
                    return discountedTaxedAmount;
                }else{
                    return newAmount;
                }
            }else if(UnitCount !== null && UnitPrice !== null && UnitCount !== 0 && UnitPrice !== 0) {
                newAmount = (UnitCount * UnitPrice).toFixed(TWO);
                return newAmount;
            }else if (UnitCount === null || UnitPrice === null) {
                return newAmount;
            }
        }catch(error){
            console.log('!!! Error in countLineItemAmountValue(): ' + error);
        }
    }

    countSubTotal(){
        try{
            let subTotal = ZERO;
            if(this.lineitemRecords){
                const temparr = this.lineitemRecords;
                for(let index=ZERO;index<temparr.length;index+=ONE){
                    subTotal += parseFloat(temparr[index].Amount) || 0;
                }
                this.invoiceSubtotal = subTotal.toFixed(TWO);
            }
        }catch(error){
            console.error('Error in countSubTotal():', JSON.stringify(error));
        }
    }

    calculateFreight(){
        try{
            const freightValue = parseFloat(this.invoiceFreight) || ZERO,
                  freightValueTax = parseFloat(this.invoiceFreightTax) || ZERO;
    
            this.invoiceFreight = (freightValue - ((freightValue)*(freightValueTax/HUNDRED))).toFixed(TWO);
        }catch(error){
            console.error('Error in calculateFreight():', error);
        } 
    }

    /*calculateTaxableAmt(){
        try{
            let subTotal = ZERO;
            const temparr = this.lineitemRecords;
            for(let index=ZERO;index<temparr.length;index+=ONE){
                if(temparr[index].taxable === ONE || temparr[index].taxable === true){
                    subTotal += Number(temparr[index].Amount);
                }
            }
            this.invoiceTaxableSubtotal = subTotal.toFixed(TWO);
        }catch(error){
            console.error('Error in calculateTaxableAmt():', error);
        } 
    }*/
  
    /*calculateTax(){
        try{
            const discountTotal = parseFloat(this.discountTotal) || ZERO,
                taxableSubtotal = parseFloat(this.taxableSubtotal) || ZERO;
            if(this.discountAfterTax === true){
                this.totalTaxValue = (this.taxableSubtotal * (this.taxValue/HUNDRED)).toFixed(TWO);
            }
            else if(taxableSubtotal === ZERO){
                this.totalTaxValue = ZERO;
            }else{
                let taxDiscount = (discountTotal * taxableSubtotal) / this.invoiceSubtotal,
                    taxAmt = taxableSubtotal + taxDiscount;
                this.totalTaxValue = (taxAmt * (this.taxValue/HUNDRED)).toFixed(TWO);

            }
        }catch(error){
            console.error('Error in calculateTax():', error);
        }
    }*/
   
    calculateTotal(){
        try{
            const invoiceSubtotal = parseFloat(this.invoiceSubtotal) || ZERO,
                  invoiceFreight = parseFloat(this.invoiceFreight) || ZERO,
                  invoiceTax = parseFloat(this.invoiceTax) || ZERO;
            this.invoiceTotal = (invoiceSubtotal + invoiceFreight + invoiceTax).toFixed(TWO);
        }catch(error){
            console.error('Error in calculateTotal():', error);
        }    
    }
    
    calculateBill(){
        try{
            const invoiceTotal = parseFloat(this.invoiceTotal) || ZERO,
                invoiceAmountPaid = parseFloat(this.invoiceAmountPaid) || ZERO;
            this.invoiceBalanceDue = (invoiceTotal - invoiceAmountPaid).toFixed(TWO);
        }catch(error){
            console.error('Error in calculateBill():', error);
        } 
    }

    removeLineItemRow(event){
        this.lineitemRecords.splice(this.lineitemRecords.findIndex(row => row.id === event.target.dataset.id), ONE);
        console.log('this.lineitemRecords = ',this.lineitemRecords);
    }

    addLineItemRow(){
        // In below variable 'a' is added in prefix for code
        const randomId = Math.random() * SIXTEEN,
              nullLineItemRecord = {id: randomId.toString(THIRTYSIX), Description: "", Category: "", UnitOfMeasure: "", UnitCount: 0, UnitPrice: 0, DiscountPercent: 0, Amount:0, TaxCode: ""};
        this.lineitemRecords = [...this.lineitemRecords, nullLineItemRecord];
    }

    createInvoiceHandler(){
        this.showLoading = true;
        const inputFields = this.template.querySelectorAll(".validate");
        let isValid = true;
        inputFields.forEach((inputField) => {
            if (!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
            }
        });
        console.log('isValid = ',isValid);
        if(isValid) {
            if(this.invoiceData && this.lineitemRecords && this.lineitemRecords.length > ZERO){
                console.log('$$$ createInvoiceHandler.invoiceData: ', JSON.stringify(this.invoiceData));
                console.log('$$$ createInvoiceHandler.lineitemRecords: ', JSON.stringify(this.lineitemRecords));
                const invoiceDetailsWrapper = {
                    mapInvoiceDetails: this.invoiceData,
                    lstMapLineItemDetails: this.lineitemRecords,
                    invoiceId: this.invoiceId
                };
                console.log('$$$ createInvoiceHandler.invoiceDetailsWrapper: ', JSON.stringify(invoiceDetailsWrapper));
                createUpdateInvoiceParse({"wrp" : JSON.stringify(invoiceDetailsWrapper)})
                .then(response => {
                    if (response.status === 'Success') {
                        this.showLoading = false;
                        this.showNotification('Invoice synced successfully!', 'success');
                    } else {
                        this.showNotification(response.message, 'error');
                    }
                })
                .catch(error => {
                    this.showNotification('Error syncing the invoice.', 'error');
                    console.error('!!! Error in createUpdateInvoiceInMYOB: ', JSON.stringify(error));
                });
            }else{
                this.isLoading = false;
                this.showNotification('Please add atleast one line item','error');
            }
        }else{
            this.showNotification('Please resolved all errors','error');
            this.isLoading = false;
        }  
    }

    createNsendInvoiceHandler(){
        this.disableSaveNsend = true;
        if(this.emailToCheck === '' || this.emailToCheck === null){
            this.disableSaveNsend = true;
            this.showNotification('Please select the customer with email to Save & Send the invoice.','error');
        }else{
            this.sendInvoice = true; // -------------------------------------------- Check
            this.createInvoiceHandler();
        }
    }

    saveBtnVisibility(){
        try{
            if(this.selectedCustomer && this.invoiceData.Number && this.invoiceData.CustomerPurchaseOrderNumber && this.invoiceData.Date && this.invoiceData.DueDate){
                this.saveEnable = true;
                this.saveAndSendEnable = true;
            }else{
                this.saveEnable = false;
                this.saveAndSendEnable = false;
            }
        }
        catch(error){
            console.error('Error in saveBtnVisibility():', error);
        }
    }

    renderedCallback () {
        Promise.all([
            loadStyle(
                this,
                HideLightningHeader
            )
        ]).then(() => {
            /* CSS loaded */
        }).catch((error) => {
            this.error = error;
            this.showLoading = false;
            this.showToast(
                "Something Went Wrong in Loading 'noHeader' .",
                error,
                "error",
                "dismissable"
            );
        });
        if (typeof window !== 'undefined') {
            const style = document.createElement('style');
            style.innerText = `
            c-sample .slds-text-heading_small {
                color: blue;
            }.customCard .slds-card__header.slds-grid {
                width: fit-content;
            }.customCard span.slds-text-heading_small.slds-truncate {
                font-size: 25px;
            }.customCard .slds-card__body {
                margin: auto;
                margin-top: -25px;
                border: 3px solid #80808033;
                border-top: 10px solid #A336F0;
                padding-bottom: 35px;
                background-color: #fff;
                border-radius: 3px;
            }.slds-modal__content.slds-p-around_medium p{
                text-align: center;
            }
            @media only screen and (max-width: 767px) {
                .customCard .slds-card__body {
                    width: 100%;
                }
            }.slds-form-element__legend{
                font-weight: 400;
                float: left;
            }
            `;
            this.template.querySelector('lightning-card').appendChild(style);
        }
    }

    changeView(event){
        const btName = event.target.dataset.id,
              ele = this.template.querySelector(`[data-id="${btName}"]`),
        {iconName} = ele,
        property = {
            abnnContactId: { showProperty: 'showABNnContactId' },
            billingAddrId: { showProperty: 'showBillingAddr' },
            shippingAddrId: { showProperty: 'showShippingAddr' },
            notesId: { showProperty: 'showNotes' },
        }[btName]?.showProperty;
        if(!ele){
           return '';
        };
        if(iconName === 'utility:chevronright') {
            ele.iconName = 'utility:chevrondown';
            this[property] = true;
        } else {
            ele.iconName = 'utility:chevronright';
            this[property] = false;
        }
    }

    hideModalBox(){
        this.isShowModal = false;
        this.handleFlagChange();
    }

    shippingSameAsBillingHandler(event){
        try{
            let checkboxValue = event.target.checked;
            this.shippingSameAsBilling = checkboxValue;
            if(checkboxValue){
                this.disableShippingAddr = false;
            }else{
                this.disableShippingAddr = false;
            }
        }
        catch(error){
            this.showLoading = false;
        }
    }

    showNotification(msg,type) {
        if (typeof window !== 'undefined') {
            const evt = new ShowToastEvent({
                title:'Invoice Generation',
                message: msg,
                variant: type
            });
            this.dispatchEvent(evt);
        }
    }
}


/* 
    PENDING - 
    1) save(Done need to Test) and sendInvoice Funtionality
    2) Customer Details to display after selection.
*/