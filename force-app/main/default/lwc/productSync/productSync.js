import { LightningElement, track} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';
import { NavigationMixin } from 'lightning/navigation';
import checkAuthorizationSteps from '@salesforce/apex/MYOB_Callout_Helper.checkAuthorizationSteps';
import getCustomSettingDetails from '@salesforce/apex/ProductConfigController.getCustomSettingDetails';
import fetchAllMyobProducts from '@salesforce/apex/ProductDynamicController.fetchAllMyobProducts';


export default class ProductSync extends NavigationMixin(LightningElement) {
    @track isActive = false;
    @track selectedValue = 'All';
    @track isModalOpen = false;
    @track confirmationMessage = '';

    showModal= false;
    title = '';
    body = '';
    showPositiveButton = false;
    showNegativeButton = false;
    positiveButtonLabel = '';
    negativeButtonLabel = '';

    connectedCallback(){
        
      
    }

    // Options for dropdown
    get options() {
        return [
            { label: 'All', value: 'All' },
            { label: 'Items I Sell', value: 'IsSold' },
            { label: 'Items I Buy', value: 'IsBought' },
            { label: 'Item in Inventoried', value: 'IsInventoried' }
        ];
    }

    // Handle checkbox change
    handleCheckboxChange(event) {
        this.isActive = event.target.checked;
    }

    getCustomSetting(){
        getCustomSettingDetails()
        .then(result => {
            console.log('### getCustomSettingDetails result : ',result);
            if(result.KTMYOB__Product_Object_Api_Name__c){
this.confirmation = true;
}
        })
        .catch(error => {
            this.isLoading = false;
            console.error('!!! Error occurred while getting Custom Setting: ', error);
        });
    } 

    // Handle dropdown change
    handleDropdownChange(event) {
        this.selectedValue = event.target.value;
    }

    // Handle Sync Button Click (Opens Confirmation Modal)
    handleSync() {
        //this.generateConfirmationMessage();
        this.showModal = true;
        this.title = 'Confirm Sync';
        this.body = this.generateConfirmationMessage();
        console.log('body value',this.body);
        this.showPositiveButton = true;
        this.positiveButtonLabel = 'Confirm';
        this.showNegativeButton = true;
        this.negativeButtonLabel = 'Cancel';
    }

    // Generate Dynamic Confirmation Message
    generateConfirmationMessage() {
        let action = '';
        if (this.selectedValue === 'IsSold') {
            action = 'products you sell';
        } else if (this.selectedValue === 'IsBought') {
            action = 'products you buy';
        } else if (this.selectedValue === 'IsInventoried') {
            action = 'inventoried products';
        } else {
            action = 'all products';
        }

        if (this.isActive) {
            return `Are you sure you want to sync all the active ${action}?`;
        } else {
            return `Are you sure you want to sync all the inactive ${action}?`;
        }
    }

    // Close Modal
    closeModal() {
        this.showModal = false;
    }

    // Confirm Sync (Trigger Actual Sync Logic)
    confirmSync() {
        this.showModal = false;
        console.log('Syncing Data to Salesforce...');
        console.log(`Active: ${this.isActive}, Selected Option: ${this.selectedValue}`);

        // 01 Pooja checkAuthorizationSteps() : on sucess do callout , failure navigate to Setuppage

          this.getConnectionDetails();

        //Calling the method from ProductDynamicController
       


    }

     getConnectionDetails(){
        checkAuthorizationSteps()
        .then(response => {
            if (response.status === 'Success') {
                console.log('### Authorization Successful');
                // Mangesh to Review
                fetchAllMyobProducts('',false,this.isActive,this.selectedValue)
        .then(result => {
            console.log('Fetch successful:', result);
            // Handle success - maybe process the result
            // 02 Pooja  : based on ComponentResponse class  , based on status show toast message
        })
        .catch(error => {
            console.error('Error fetching products:', error);
            // Handle error - maybe show an error message
        });

            } else if (response.status === 'Failed' && response.isConnectionError) {
                console.error('Authorization Failed: ', response.message);
                //this.showNotification('Authorization Failed: Please complete all connection steps on MYOB Setup Page.','error');
                this.handleAlert('Authorization Failed: Please complete all connection steps on MYOB Setup Page.','Connection Not Established');
            }
        })
        .catch(error => {
            this.showLoading = false;
            console.error('!!! Error occurred while checking authorization: ', error);
        });
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
            } else if (msg === 'Invoice MYOB ID is not present. Unable to sync Product.') {
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
                    title:'Invoice Generation',
                    message: msg,
                    variant: type
                });
                this.dispatchEvent(evt);
    
            }
        }

}