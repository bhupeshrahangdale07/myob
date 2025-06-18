import { NavigationMixin } from 'lightning/navigation';
import { api, LightningElement, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';
import checkAuthorizationSteps from '@salesforce/apex/MYOB_Callout_Helper.checkAuthorizationSteps';
import displayInvoiceNLineItems from '@salesforce/apex/InvoiceDynamicController.displayInvoiceNLineItems';
import getSingleInvoice from '@salesforce/apex/InvoiceDynamicController.getSingleInvoice';
import updateInvoiceInSf from '@salesforce/apex/InvoiceDynamicController.updateInvoiceInSf';
import { CloseActionScreenEvent } from 'lightning/actions';

export default class InvoiceSync extends NavigationMixin(LightningElement) {
    @api recordId;
    @api objectApiName;
    showLoading = false;
    isShowModal = false;
    @track invoiceData = [];
    @track lstLineItemsData = [];
    myobInvoice={};

    mapLineItems = new Map();
    mapLineItemRowID = new Map();
    //for parsing and passing invoice and line items data back to be stored in salesfore as record.
    mapInvoiceKeyData =  new Map();
    mapInvoiceData = new Map();
    mapInvoiceLineKeyData = new Map();
    mapInvoiceLineData = new Map();

    notificationTitle = 'Invoice Sync';

    connectedCallback(){
        this.showLoading = true;
        this.getConnectionDetails();
    }

//Helper: to check if all the connection steps for authorization.
    getConnectionDetails(){
        debugger;
        checkAuthorizationSteps()
        .then(response => {
            if (response.status === 'Success') {
                console.log('### Authorization Successful');
                this.fetchInvoiceMYOBFldValues();
            } else if (response.status === 'Failed' && response.isConnectionError) {
                console.error('Authorization Failed: ', response.message);
                this.handleAlert('Authorization Failed: Please complete all connection steps on MYOB Setup Page.','Connection Not Established');
            }
        })
        .catch(error => {
            console.error('!!! Error occurred while checking authorization: ', error);
            this.showNotification(this.notificationTitle,'Error occurred while checking authorization steps.','error');
            this.showLoading = false;
            this.isShowModal = false;
            this.closeQuickAction();
        });
    }

//Apex Method: to get all the Salesforce records and its mapped fields values.
    fetchInvoiceSfFldValues(){
        this.showLoading = false;
        displayInvoiceNLineItems({invoiceId: this.recordId,getNonNullInvoiceFields:false})
        .then(response => {
            console.log('### Invoice and LineItems data fetched from MYOB ::: '+JSON.stringify(response));
            
            if(response){
            //Preparing the invoice myob and sf fields values to be displayed in datatable in UI.
                this.invoiceData = Object.keys(response.mapInvoiceDetails).map(key => {
                    if (this.myobInvoice[key]) {
                        let value = String(this.myobInvoice[key]);
                        if ((value.includes('\n') || value.includes('\r')) && typeof this.myobInvoice[key] === 'string') {
                            this.myobInvoice[key] = value.replace(/[\n\r]+/g, ' ').trim();
                        }
                        
                        let sameFieldValue = String(response.mapInvoiceDetails[key]).trim().toLowerCase() === String(this.myobInvoice[key]).trim().toLowerCase();
                        console.log('this.myobInvoice[key]- '+this.myobInvoice[key]);
                        return {
                            Key: key,
                            SfFieldvalue: response.mapInvoiceDetails[key],
                            MYOBFieldvalue: this.myobInvoice[key],
                            hasLineItems: false,
                            DoSyncToSf : sameFieldValue,
                            className : sameFieldValue ? 'slds-text-color_success' : 'slds-text-color_error'
                        };
                    }
                    return null;
                }).filter(item => item !== null); // Remove null values

            
            //Creating map for RowID and Myob Line items field values.
                this.mapLineItems =  new Map();
                this.myobInvoice.Lines.forEach(element =>{
                    this.mapLineItems.set(element.RowID,{
                        RowID: element.RowID,
                        Line : element
                    })
                });

            //Based on RowID , we are matching Line Items and updating the salesforce and myob values for the mapped fields.    
                var count =0;
                this.mapLineItemRowID = new Map();
                if(response.lstMapLineItemDetails){
                   var listLineItems =  response.lstMapLineItemDetails.map(element => {
                       let intRowId = parseInt(element.RowID, 10);
                       if(this.mapLineItems.has(intRowId) && typeof intRowId === 'number'){
                            if(element && typeof element === 'object'){
                                var lstSingleLineItemOBJ = Object.keys(element).map(key => {
                                    let sameFieldValue = String(element[key]).trim().toLowerCase() === String(this.mapLineItems.get(intRowId).Line[key]).trim().toLowerCase();
                                    return {
                                        Key: key,
                                        SfFieldvalue: element[key],
                                        MYOBFieldvalue: this.mapLineItems.get(intRowId).Line[key],
                                        DoSyncToSf: sameFieldValue,
                                        className : sameFieldValue ? 'slds-text-color_success' : 'slds-text-color_error'
                                    };
                                });
                            }
                        }
                        count++;
                        let isLineItemNull = !lstSingleLineItemOBJ;
                        this.mapLineItemRowID.set('LineItem-'+count,intRowId);
                        return{
                            Key : 'LineItem-'+count,
                            Fieldvalue : lstSingleLineItemOBJ,
                            lineItemNull : isLineItemNull
                        }
                    });
                }

            //Filter Out those line items fields which has no MYOB value.
                listLineItems.forEach(item => {
                    if (Array.isArray(item.Fieldvalue)) {  
                        item.Fieldvalue = item.Fieldvalue.filter(element => element.MYOBFieldvalue != null);
                    }
                });
                

            //Finally , adding the lineItems Fields Values to the Invoice Data object to be displayed in Table in UI.
                if (listLineItems && listLineItems.length > 0) {
                    this.invoiceData.push({Key:'LineItems',Fieldvalue:[...listLineItems],hasLineItems:true,showLineItems: false});
                }
                console.log('### invoiceData ::: '+JSON.stringify(this.invoiceData));
            }

            //Post Logic for Invoice
            this.mapInvoiceKeyData = new Map();
            this.invoiceData.forEach(element => {
                if(!element.hasLineItems){
                    this.mapInvoiceKeyData.set(element.Key,element);
                }
            });

            //Post Logic for Invoice Line Items
            this.mapInvoiceLineKeyData = new Map();
            this.invoiceData.forEach(element => {
                if(element.hasLineItems){
                    Array.isArray(element.Fieldvalue) && element.Fieldvalue.forEach(lineItem => {
                        let mapKeyLineData = new Map();
                        Array.isArray(lineItem.Fieldvalue) && lineItem.Fieldvalue.forEach(lineField => {
                            mapKeyLineData.set(lineField.Key,lineField);
                        });
                        this.mapInvoiceLineKeyData.set(lineItem.Key,mapKeyLineData);
                    });
                }
            });
            this.showLoading = false;
        })
        .catch(error => {
            console.error('!!! Error occurred while fetching invoice data: ', error);
            this.showNotification(this.notificationTitle,'Error occurred while rendering Invoice and LineItems on table','error');
            this.showLoading = false;
            this.isShowModal = false;
            this.closeQuickAction();
        });
    }

//Apex Method: to get all the Myob record and its mapped fields values.
    fetchInvoiceMYOBFldValues(){
        this.isShowModal = true;
        this.showLoading = true;
        getSingleInvoice({invoiceId: this.recordId})
        .then(response => {
            if(response){
               this.myobInvoice = JSON.parse(response);
               if(this.myobInvoice){
                this.fetchInvoiceSfFldValues();
               }
            }
        })
        .catch(error => {
            console.error('!!! Error occurred while fetching invoice data: ', error);
            this.showNotification(this.notificationTitle,'Error occurred while fetching invoice from MYOB','error');
            this.showLoading = false;
            this.isShowModal = false;
            this.closeQuickAction();
        });
    }


//Toggle Button -  On change handler for Invoice.
    syncInvoiceFieldHandler(event) {
    let invoiceField = event.target.dataset.invoicefield;
    if (event.target.checked) {
        this.mapInvoiceData.set(invoiceField,this.mapInvoiceKeyData.get(invoiceField).MYOBFieldvalue);
    }else if(!event.target.checked){
        if(this.mapInvoiceData.has(invoiceField)){
            this.mapInvoiceData.delete(invoiceField);
        }
    }
    console.log('### mapInvoiceData ::: '+JSON.stringify(this.mapInvoiceData));
}

//Toggle Buttton - On change handler for Invoice Line Items.
    syncLineItemFieldHandler(event) {
        let mapInvoiceSingleLineData = new Map();
        let invoiceLineItem = event.target.dataset.lineitem;
        let invoiceLineItemField = event.target.dataset.lineitemfield;
        if (event.target.checked) {
            let mapKeyLineData = this.mapInvoiceLineKeyData.get(invoiceLineItem);
            if(mapKeyLineData){
                mapInvoiceSingleLineData.set(invoiceLineItemField,mapKeyLineData.get(invoiceLineItemField).MYOBFieldvalue);
            }
        }else if(!event.target.checked){
            if(mapInvoiceSingleLineData.has(invoiceLineItemField)){
                mapInvoiceSingleLineData.delete(invoiceLineItemField);
            }
        }
        
        if(mapInvoiceSingleLineData){
            if(this.mapInvoiceLineData.get(invoiceLineItem)){
                let mapLineItem = this.mapInvoiceLineData.get(invoiceLineItem);
                this.mapInvoiceLineData.set(
                    invoiceLineItem,
                    new Map([...mapLineItem, ...mapInvoiceSingleLineData])
                );
            }else{
                this.mapInvoiceLineData.set(invoiceLineItem,mapInvoiceSingleLineData);
            }
        }else{
            this.mapInvoiceLineData.delete(invoiceLineItem);
        }

        // deleting the lineItem from map by removing any fields that were initially selected but have since been deselected by the user
        if (this.mapInvoiceLineData) {
            for (const [key, value] of this.mapInvoiceLineData) {
                if (value?.size === 0 || !value) {
                    this.mapInvoiceLineData.delete(key);
                }
            }
        }
        
        console.log('### mapInvoiceSingleLineData ::: '+JSON.stringify(mapInvoiceSingleLineData));
        console.log('### mapInvoiceLineData ::: '+JSON.stringify(this.mapInvoiceLineData));
    }


//Apex method: To update the invoice in Salesforce
    upsertInvoiceHandler(event){
        debugger;
        let buttonClicked = event.target.name;
        
        if(this.mapInvoiceData?.size > 0 || this.mapInvoiceLineData?.size > 0){
            let invoiceObj = Object.fromEntries(this.mapInvoiceData);
            let invoiceLineObj = {};
            this.mapInvoiceLineData.forEach((innerMap, key) => {
                invoiceLineObj[key] = Object.fromEntries(innerMap);
            });
            
            let lineItemRowIds = Object.fromEntries(this.mapLineItemRowID);

            updateInvoiceInSf({invoiceMap:invoiceObj, lineItemsMap:invoiceLineObj,lineItemRowIDMap:lineItemRowIds,invoiceId:this.recordId})
            .then(response => {
                if(response){
                    if(response == 'success'){
                        this.showNotification(this.notificationTitle,'Invoice successfully synced from MYOB to Salesforce.','success');
                        if(buttonClicked === 'Proceed'){
                            this.rediretToGenerateInvoice();
                        }else if(buttonClicked === 'Sync'){
                            this.showLoading = false;
                            this.isShowModal = false;
                            this.closeQuickAction();
                        }
                    }else{
                        this.showNotification(this.notificationTitle,'Invoice sync from MYOB to Salesforce failed.','error');
                        this.closeQuickAction();
                    }
                }
            }).catch(error => {
                console.error('!!! Error occurred while upserting invoice data: ', error);
                this.showNotification(this.notificationTitle,'Invoice sync from MYOB to Salesforce failed.','error');
                this.showLoading = false;
                this.isShowModal = false;
                this.closeQuickAction();
            });
        }else{
            if(buttonClicked === 'Proceed'){
                this.rediretToGenerateInvoice();
            }else if(buttonClicked === 'Sync'){
                this.showLoading = false;
                this.isShowModal = false;
            }
        }
    }

//Helper : to close the modal.
    closeQuickAction() {
        if (typeof window !== 'undefined') {
            this.dispatchEvent(new CloseActionScreenEvent());
        } 
    }

//Helper : redirect page to the generate invoice page.
    rediretToGenerateInvoice(){
        this.showLoading = false;
        this[NavigationMixin.Navigate]({
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'KTMYOB__Generate_Invoice',
                state: {
                    c__invoiceId: this.recordId
                }
            },
        });
    }
  
//Helper : to show notification and on click of OK button redirect page to the Setup page.
    handleAlert(msg, lbl) {
        LightningConfirm.open({
            label: lbl,
            message: msg,
            theme: "error"
        })
        .then((result) => {
            if (result === true) {
                this[NavigationMixin.Navigate]({
                    attributes: {
                        apiName: 'KTMYOB__MYOB_Setup'
                    },
                    type: 'standard__navItemPage'
                });
            } else {
                this.closeQuickAction();
            }
        })
        .catch((error) => {
            console.error("Error opening alert: ", error);
            this.showNotification(this.notificationTitle,'Error Occured while opening an alert','error');
            this.showLoading = false;
            this.isShowModal = false;
        });
    }

//helper : To Toggle table of the child records, i.e. Line Items.
    toggleSubTable(event) {
        const key = event.currentTarget.dataset.id;
        this.invoiceData = this.invoiceData.map(item => {
            if (item.Key === key) {
                return { ...item, showLineItems: !item.showLineItems };
            }
            return item;
        });
    }

//helper : to Show notification toast message.
    showNotification(title,msg,type) {
        if (typeof window !== 'undefined') {
            const evt = new ShowToastEvent({
                title: title,
                message: msg,
                variant: type
            });
            this.dispatchEvent(evt);
        }
    }
}


/*
    TODO - Next week till 11 April: 
    1. Add green color for matched one and red for unmatched one fields in the Table  - ✅DONE.
    2. Fix the Modal close i.e. hideModalBox() method. - ✅Done
    3. Do complete testing throughly. - ✅Done
    4. In custom setting for REFERENCE data type field(Taxcode and freightTaxcode) on invoice and Line items, think of a logic. - TODO
    5. Do code optimization of both Js and Apex. - TODO
    6. Do Scanning of the code.
    7. Assign the testing for this component to someone.
    8. Setup testing suite in ZOHO.
*/