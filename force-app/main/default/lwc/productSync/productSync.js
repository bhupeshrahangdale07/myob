import { LightningElement, track,api} from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import LightningConfirm from 'lightning/confirm';
import { NavigationMixin } from 'lightning/navigation';
import checkAuthorizationSteps from '@salesforce/apex/MYOB_Callout_Helper.checkAuthorizationSteps';
import fetchAllMyobProducts from '@salesforce/apex/ProductDynamicController.fetchAllMyobProducts';
import fetchMYOBObCSConfig from '@salesforce/apex/MYOB_Component_Helper_cls.fetchMYOBObCSConfig';
import { CloseActionScreenEvent } from 'lightning/actions';
import { updateRecord } from 'lightning/uiRecordApi';


export default class ProductSync extends NavigationMixin(LightningElement) {
    @api objectApiName;
    @api recordId;
    @track isActive = false;
    @track selectedValue = 'All';
    @track isModalOpen = false;
    @track confirmationMessage = '';
    @track isSetupPage = true;

    showAllFilter=true;
    showModal= false;
    showLoading=false;
    title = '';
    body = '';
    showPositiveButton = false;
    showNegativeButton = false;
    positiveButtonLabel = '';
    negativeButtonLabel = '';
    isProductMapped = false;

//Getter: Options for dropdown
    get options() {
        return [
            { label: 'All', value: 'All' },
            { label: 'Items I Sell', value: 'IsSold' },
            { label: 'Items I Buy', value: 'IsBought' },
            { label: 'Item in Inventoried', value: 'IsInventoried' }
        ];
    }

    connectedCallback() {
        this.fetchCSConfigs();
    }

// method : Fetch all the custom settings to get mappings.
    fetchCSConfigs(){
        this.showLoading = true;
        fetchMYOBObCSConfig()
        .then(response => {
            if(response){
                if(response.productObjectApiName && response.mapMYOBApiNameProductData!=null){
                    this.isProductMapped = true;
                    if(this.objectApiName && this.recordId){
                        if(this.objectApiName === response.productObjectApiName){
                        this.showAllFilter=false;
                        this.isSetupPage = false;
                        this.handleSync();
                        }
                    }
                }
            }
            this.showLoading = false
        }).catch(error => {
            this.showLoading = false;
            console.error('!!! Error occurred while getting Custom Setting: ', error);
            this.showNotification('An unexpected error occurred while retrieving the Custom Setting to check the mappings. Contact System Administrator.','error');
        })
    }

//method: Handle active checkbox change
    handleCheckboxChange(event) {
        this.isActive = event.target.checked;
    }

//Method: Handle dropdown change
    handleDropdownChange(event) {
        this.selectedValue = event.target.value;
    }

//Method: Check for Connection Steps before processing Sync.
    getConnectionDetails(){
        checkAuthorizationSteps()
        .then(response => {
            if (response.status === 'Success'){
                console.log('### Authorization Successful'); 
                this.fetchAllProductsToSf();
            } else if (response.status === 'Failed' && response.isConnectionError){
                console.error('Authorization Failed: ', response.message);
                this.handleAlert('Authorization Failed: Please complete all connection steps on MYOB Setup Page.','Connection Not Established');
            }
        })
        .catch(error => {
            this.showLoading = false;
            this.showNotification('Unexpected error occurred while checking authorization. Contact System Administrator.','error');
        });
    }

//method: Fetch all the prdocut from MYOB as per user inputs.
    fetchAllProductsToSf() {
    return new Promise((resolve, reject) => {
        debugger;
        let requestObj = {};
        if (this.showAllFilter === false) {
            requestObj = {'productId': this.recordId, 'syncSingleProduct': true};
        } else {
            requestObj = {
                'syncSingleProduct': false,
                'isItemActive': this.isActive,
                'itemType': this.selectedValue
            };
        }
        
        fetchAllMyobProducts({...requestObj})      
        .then(async response => {
            if (response.status === 'Success') {
                await this.showNotification(response.message, 'success');
                updateRecord({ fields: { Id: this.recordId }})
                
                // Close quick action after success and before resolving
                if (this.showAllFilter === false) {
                    await this.closeQuickAction();
                }
                resolve(response);
                
            } else if (response.status === 'Failed' || response.isConnectionError) {
                if (response.message) {
                    this.showNotification(response.message, 'error');
                } else if (response.multipleMessage) {
                    let errrorArr = JSON.parse(response.multipleMessage);
                    errrorArr.forEach(err => {
                        let errorMsg = 
                        'Name      : ' + err.Name + ' | ' +
                        'Message   : ' + err.Message + ' | ' +
                        'ErrorCode : ' + err.ErrorCode;
                        if (err.Severity.toLowerCase() === 'error') {
                            this.showNotification(errorMsg, 'error', 'sticky');
                        } else if ((err.Severity.toLowerCase() === 'warning')) {
                            this.showNotification(errorMsg, 'warning', 'sticky');
                        }
                    });
                } else {
                    this.showNotification('Unexpected Error : Contact your System Administrator.', 'error');
                }
                
                // Close quick action after error handling and before resolving
                if (this.showAllFilter === false) {
                    await this.closeQuickAction();
                }
                resolve(response);
            }
            this.showLoading = false;
        }).catch(async error => {
            this.showLoading = false;
            this.showNotification('Product Sync from Salesforce to MYOB Failed. Contact System Administrator.', 'error');
            
            // Close quick action even on catch
            if (this.showAllFilter === false) {
                await this.closeQuickAction();
            }
            reject(error);
        });
        
        // REMOVED: this.closeQuickAction(); from here - it was executing immediately
    });
}

    

//method: Handle Sync Button Click (Opens Confirmation Modal)
    handleSync() {
        if(this.isProductMapped){
            this.showModal = true;
            this.title = 'Confirm Sync';
            this.body = this.generateConfirmationMessage();
            console.log('body value',this.body);
            this.showPositiveButton = true;
            this.positiveButtonLabel = 'Confirm';
            this.showNegativeButton = true;
            this.negativeButtonLabel = 'Cancel';
        }else {
            this.showNotification('Please ensure that the product and its required fields are mapped before proceeding with the sync.','error');
        }
    }

//helper: Generate Dynamic Confirmation Message
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

        if(this.showAllFilter === false){
            return 'Are you sure you want to sync the product from MYOB to Salesforce?';
        }else if (this.isActive) {
            return `Are you sure you want to sync all the active ${action}?`;
        } else {
            return `Are you sure you want to sync all the inactive ${action}?`;
        }
    }

//helper: Close Modal
    closeModal() {
        this.showModal = false;
        if(this.showAllFilter ===false){
            this.closeQuickAction();
        }
    }

//helper: Confirm Sync (Trigger Actual Sync Logic)
    confirmSync(event) {
        const data = event.detail;
        this.showLoading = true;
        this.showModal = false;
        this.getConnectionDetails();
    }

//helper : to show alert when th authorizaton steps not completed.
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

//helper : to show toast messag.    
    showNotification(msg,type) {
        if (typeof window !== 'undefined') {
            const evt = new ShowToastEvent({
                title:'Product Sync',
                message: msg,
                variant: type
            });
            this.dispatchEvent(evt);
        }
    }
 //Helper : to close the modal.
    closeQuickAction() {
        if (typeof window !== 'undefined') {
            this.dispatchEvent(new CloseActionScreenEvent());
        } 
    }

}



//TODO : 
// 1. Fix the apex method products getting sync succesfully, but Logsnot getting generated.
// 2. Fix the code and add proper loading and imporve UX.
// 3. Fix th ConfirmationModalPopup child component.
// 4. Review ProductDynamicController class.
// 4. Fix the desiging at the end.