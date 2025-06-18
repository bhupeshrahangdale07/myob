import { NavigationMixin } from 'lightning/navigation';
import { api, LightningElement } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';
import checkAuthorizationSteps from '@salesforce/apex/MYOB_Callout_Helper.checkAuthorizationSteps';
import getCustomSettingDetails from '@salesforce/apex/GenerateInvoiceController.getCustomSettingDetails';
import getCustomerFieldsFromCSDetails from '@salesforce/apex/ContactDynamicController.getCustomerFieldsFromCSDetails';

export default class InvoiceSync extends LightningElement {
    @api recordId;
    @api objectApiName;
    showLoading = false;
    isShowModal = false;
    data = [];

    connectedCallback(){
        this.showLoading = true;
        this.getConnectionDetails();
    }

    getConnectionDetails(){
        checkAuthorizationSteps()
        .then(response => {
            if (response.status === 'Success'){
                console.log('### Authorization Successful'); 
                this.getCustomSetting();
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

    getCustomSetting(){
        getCustomSettingDetails()
        .then(result => {
            console.log('### getCustomSettingDetails result : ',result);
            console.log('###recordId :',this.recordId);
            console.log('###objectApiName :',this.objectApiName);
            if(result.KTMYOB__Contact_Company_Object_Api_Name__c === this.objectApiName){
                this.customerType = 'Company';
                this.isShowModal = true;
                this.getCustomerFieldsFromCS(this.type, this.objectApiName, this.recordId);

            }else if(result.KTMYOB__Contact_Individual_Object_Api_Name__c === this.objectApiName){
                this.customerType = 'Individual';
                this.isShowModal = true;
                this.getCustomerFieldsFromCS(this.type, this.objectApiName, this.recordId);
            }else{
                this.isShowModal = false;
                this.showLoading = false;
                this.handleAlert('Please complete the mapping in Contact Configuration on the MYOB Setup page.','Mapping incomplete');
            }
        })
        .catch(error => {
            this.showLoading = false;
            console.error('!!! Error occurred while getting Custom Setting: ', error);
        });
    }

    getCustomerFieldsFromCS(type, objectApiName, recordId){
        getCustomerFieldsFromCSDetails({ 'type':type,
                                         'objectApiName':objectApiName,
                                         'recordId':recordId })
        .then(result => {
            console.log('### getCustomerFieldsFromCSDetails result : ', result);
            if(type === 'Company'){
                this.data = result.contactCompanyFieldsMapping;
            }else if(type === 'Individual'){
                this.data = result.contactIndividualFieldsMapping;
            }else if(type === 'Invoice'){
                this.data = result.invoiceFieldsMapping;
            }
            //this.data.forEach(item => {item.KTMYOB__MYOB_Field_Api_Name__c === 'UID'
            this.showLoading = false;
        })
        .catch(error => {
            this.showLoading = false;
            console.error('!!! Error occurred while getting Custom Setting: ', error);
        });
    }

    hideModalBox(){
        this.isShowModal = false;
        //this.template.querySelector('.slds-backdrop').classList.remove('slds-backdrop_open');
        const backdrop = this.template.querySelector('.slds-backdrop');
        if (backdrop) {
            backdrop.classList.remove('slds-backdrop_open');
        }
    }
    
    handleAlert(msg, lbl) {
        LightningConfirm.open({
            label: lbl,
            message: msg,
            theme: "error"
        })
        .then((result) => {
            if (result) {
                // Handle the case where result is true (if needed)
                console.error("opening confirm: ");
            } else if (msg === 'Customer MYOB ID is not present. Unable to sync Customer.') {
                this.backBtnHandler();
            } else {
                this[NavigationMixin.Navigate]({
                    attributes: {
                        apiName: 'KTMYOB__MYOB_Setup'
                    },
                    type: 'standard__navItemPage'
                });
            }
        })
        .catch((error) => {
            console.error("Error opening confirmation/alert: ", error);
            this.showNotification('Error occured while opening an confirmation/alert.', error);
        });
    }

    backBtnHandler(){
        const pageReference = {
            attributes: {
                actionName: 'view',
                objectApiName: this.objectApiName,
                recordId: this.recordId
            },
            type: 'standard__recordPage',
        };
        this[NavigationMixin.Navigate](pageReference);
    }
    
    showNotification(msg,type) {
        if (typeof window !== 'undefined') {
            const evt = new ShowToastEvent({
                title:'Customer Sync',
                message: msg,
                variant: type
            });
            this.dispatchEvent(evt);
        }
    }
}