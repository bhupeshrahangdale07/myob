import { LightningElement, wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createUpdateContact from '@salesforce/apex/ContactDynamicController.createUpdateContact';
import LightningConfirm from 'lightning/confirm';
const THOUSAND = 1000,
      TWOHUNDRED = 200;

export default class MyobToSfSyncBtnLwc extends NavigationMixin(LightningElement) {
    recordId;
    showSpinner = true;
    operation = 'CreateOrUpdate';
    currentPagePathName = '';
  
    @wire(CurrentPageReference)
    getStateParameters(currentPageReference) {
        if (currentPageReference) {
            this.recordId = currentPageReference.state.recordId;
            this.currentPagePathName = currentPageReference.state.backgroundContext;
        }
    }
    connectedCallback(){
        if(this.recordId){
            createUpdateContact({ contactId: this.recordId })
                .then(response => {
                    this.handleCalloutResponse(response,false);
                }).catch(error => {
                    this.handleCalloutResponse(error,true);
            });
        }
    }
    //Helper method:for handling the response i.e. after callout from the Server/backend.
    handleCalloutResponse(data, isError) {
    //     if(data){
    //         if (data.status && data.message) {
    //             this.showSpinner = false;
    //             // this.closeQuickAction();
    //             if(data.status === 'Success'){
    //                 this.showToast('Invoiced Sync', data.message, 'success');
    //                 setTimeout(() => {
    //                     // window.open(`https://qbktdev-dev-ed.develop.lightning.force.com/lightning/r/QB_Invoice__c/${this.recordId}/view`, "_self");
    //                     if (typeof window !== 'undefined') {
    //                         window.open(this.currentPagePathName, "_self"); 
    //                     }
    //                 }, THOUSAND);
    //             }else if(data.status === 'Failed') {
    //                 if(data.message.includes('####')){
    //                     const myArray = data.message.split("####");
    //                     myArray.pop();
    //                     myArray.forEach(resp => {
    //                         setTimeout(() => {
    //                             this.showToast('Invoice Sync',resp.replace('####','.'),'error','sticky');
    //                         },TWOHUNDRED);
    //                     });
    //                     this.closeQuickAction();
    //                 }else if(data.isConnectionError === true){
    //                     this.handleAlert('Please go to the SetupPage and complete all connection steps.','Incomplete Connection Setup');    
    //                 }else{
    //                     this.showToast('Invoice Sync',data.message,'error');
    //                     this.closeQuickAction();
    //                 }
    //             }
    //         }
    //     }else if(isError){
    //         this.showSpinner = false;
    //         this.showToast('Invoiced Sync', `Invoiced Synced from Quickbooks Failed , [ ${data.message} ]`, 'error');
    //         this.closeQuickAction();
    //     }
    }

//Helper Method : for closing Record Detail Action Modal and displaying the Toast message.    
    showToast(toastTitle,toastMessage,toastVariant,toastMode) {
        if (typeof window !== 'undefined') {
            const event = new ShowToastEvent({
                message:toastMessage,
                mode:toastMode,
                title: toastTitle,
                variant:toastVariant
            });
            this.dispatchEvent(event);
        }

    }
    closeQuickAction() {
        if (typeof window !== 'undefined') {
            this.dispatchEvent(new CloseActionScreenEvent());
        }
    }

    async handleAlert(msg, lbl) {
        const result = await LightningConfirm.open({
                        label: lbl,
                        message: msg,
                        theme: "error"
                    });

        if(result==true){
            this[NavigationMixin.Navigate]({
                attributes: {
                    apiName:'KTQB__QuickBooks_Setup'
                },
                type: 'standard__navItemPage'
            });
        }else{
            this.closeQuickAction();
        }
    }
}