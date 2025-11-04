import { NavigationMixin } from 'lightning/navigation';
import { api, LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';
import checkAuthorizationSteps from '@salesforce/apex/MYOB_Callout_Helper.checkAuthorizationSteps';
import fetchSfContact from '@salesforce/apex/ContactDynamicController.fetchSfContact';
import fetchSingleContactFromMYOB from '@salesforce/apex/ContactDynamicController.fetchSingleContactFromMYOB';
import updateContactInSF from '@salesforce/apex/ContactDynamicController.updateContactInSF';
import fetchMYOBObCSConfig from '@salesforce/apex/MYOB_Component_Helper_cls.fetchMYOBObCSConfig';
import { CloseActionScreenEvent } from 'lightning/actions';
import { RefreshEvent } from 'lightning/refresh';
import { updateRecord } from 'lightning/uiRecordApi';

export default class InvoiceSync extends LightningElement {
    @api recordId;
    @api objectApiName;
    customerType;
    showLoading = false;
    isShowModal = false;
    objFieldMappings = [];
    recordData={};
   
    contactFieldMappings={};
    sfContactRecord={};    
    myobContactRecord={};   
    datatableRows = [];     
    mappedContactFields={};
    isIndividualContact=false;
    notificationTitle='';
    isShowCreateModal = false;
    isShowbackdrop = false;

    connectedCallback(){
        this.showLoading = true;
        this.getConnectionDetails();
    }

    getConnectionDetails(){
        checkAuthorizationSteps()
        .then(response => {
            if (response.status === 'Success'){
                console.log('### Authorization Successful'); 
                this.fetchCSConfigs();
                //this.fetchSfContactRecord();
            } else if (response.status === 'Failed' && response.isConnectionError){
                console.error('Authorization Failed: ', response.message);
                this.handleAlert('Authorization Failed: Please complete all connection steps on MYOB Setup Page.','Connection Not Established');
            }
        })
        .catch(error => {
            this.showLoading = false;
            console.error('!!! Error occurred while checking authorization: ', error);
        });
    }

    fetchCSConfigs(){
        debugger;
        fetchMYOBObCSConfig()
        .then(response => {
            if(response){
                if(response.contactCompanyObjectApiName === this.objectApiName){
                    this.customerType = 'Company';
                    this.contactFieldMappings = response.mapMYOBApiNameCompanyData;
                }else if(response.contactIndividualObjectApiName === this.objectApiName){
                    this.customerType = 'Individual';
                    this.isIndividualContact = true;
                    this.contactFieldMappings = response.mapMYOBApiNameIndividualData;
                }else{
                    this.showNotification('Customer Sync','This object is not mapped as a Company or Individual Customer in Salesforce. Please add this button to a correctly mapped object or contact your system administrator for assistance.','error');
                    this.closeQuickAction();
                }
                this.fetchSfContactRecord();
            }
        }).catch(error => {
            this.showLoading = false;
            console.error('!!! Error occurred while getting Custom Setting: ', error);
        })
    }


    fetchSfContactRecord(){
        fetchSfContact({'contactId': this.recordId,'objectApiName':this.objectApiName,'getNonNullInvoiceFields':false})
        .then(result => {
            if(result){ 
               this.sfContactRecord = {...result[0]};
               this.fetchMYOBContactRecord();
            }  
        }).catch(error => {
            this.showLoading = false;
            console.error('!!! Error occurred while getting record data: ', error);
        });
    }

    fetchMYOBContactRecord(){
        if(this.sfContactRecord?.UID && this.contactFieldMappings){
            fetchSingleContactFromMYOB({'contactMYOBId':this.sfContactRecord?.UID})
            .then(result => {
                this.myobContactRecord = {...JSON.parse(result)};
                if(this.myobContactRecord){
                    this.prepareDataTable();
                }
            }).catch(error => { 
                this.showLoading = false;
                console.error('!!! Error occurred while getting record data: ', error);
            });
        } else {
            this.showNotification('Customer Sync','Customer failed to synced from MYOB to Salesforce','error');
            this.closeQuickAction();
        }
    }

    prepareDataTable(){
        if(this.sfContactRecord){
            for (const key in this.myobContactRecord) {
                let sameFieldValue=false;
                if(this.sfContactRecord[key]){
                    sameFieldValue = String(this.sfContactRecord[key]).trim().toLowerCase() === String(this.myobContactRecord[key]).trim().toLowerCase();
                    this.datatableRows.push({
                        Key: key,
                        SfFieldvalue: this.sfContactRecord[key],
                        MYOBFieldvalue:this.myobContactRecord[key],
                        DoSyncToSf: sameFieldValue,
                        className : sameFieldValue ? 'slds-text-color_success' : 'slds-text-color_error'
                    }); 
                }else if(this.myobContactRecord[key] && this.contactFieldMappings[key]?.KTMYOB__Field_API_Name__c){ 
                    this.datatableRows.push({
                        Key: key,
                        SfFieldvalue: '',
                        MYOBFieldvalue:this.myobContactRecord[key],
                        DoSyncToSf: sameFieldValue,
                        className : sameFieldValue ? 'slds-text-color_success' : 'slds-text-color_error'
                    })
            };
        }
        if(this.datatableRows.length > 0){
            this.showLoading = false;
            this.isShowModal = true;
        }
    }
}

handleCustomerCreateUpdate(event){
    if(event.detail ==='success'){
        this.showLoading = true;
        this.closeQuickAction();
            this.showLoading = false;
            //window.location.reload();
            updateRecord({ fields: { Id: this.recordId }})

    }
}

//Toggle Button -  On change handler for Invoice.
    syncContactFieldHandler(event) {
        let contactField = event.target.dataset.invoicefield;
        if (event.target.checked){
            this.mappedContactFields[contactField]=this.myobContactRecord[contactField];
        }else if(!event.target.checked){
            this.mappedContactFields[contactField]=this.sfContactRecord[contactField];
        }
    }

    upsertContactHandler(event){
        //TODO : do a normal sync from MYOb to Sf
        let buttonClicked = event.target.name;
        this.showLoading = true;
        this.iscustomersync = true;
        updateContactInSF({
            'contactMap' : this.mappedContactFields,
            'contactId' : this.recordId,
            'isIndividual' : this.isIndividualContact
        }).then( result=>{
            if(result === 'success'){
                this.isShowModal = false;
                if(buttonClicked === 'Proceed'){
                    this.isShowCreateModal = true;
                }else if(buttonClicked === 'Sync'){
                     this.closeQuickAction();
                    this.showNotification('Customer Sync','Customer was successfully synced from MYOB to Salesforce','success');
                    
                     updateRecord({ fields: { Id: this.recordId }})
                }    
            }else{
                this.showNotification('Customer Sync','Customer failed to synced from MYOB to Salesforce','error');
            }
        }).catch(error=>{
            this.showNotification('Customer Sync',error,'error');
            this.showLoading = false;
            console.error('!!! Error occurred while getting record data: ', error);
        })
        this.showLoading = false;
    }

    //Helper : to close the modal.
  closeQuickAction() {
        if (typeof window !== 'undefined') {
            this.dispatchEvent(new CloseActionScreenEvent());
        }
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

}

//TODO: 
// 1. Check Prior that OjectApiname is the same as mapped .[Done but To be tested]
// 2. Check that all the fields from the Mapping are visible in datatable  + only show the non-null data from MYOB in datatable and for Sf you can display nulls.s