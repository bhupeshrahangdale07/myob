import { api, LightningElement } from 'lwc';
import hideCloseIcon from '@salesforce/resourceUrl/hideCloseIcon';
import { loadStyle } from "lightning/platformResourceLoader";

export default class ConfirmationModalPopup extends LightningElement {
    isShowModal = false;
    @api title = '';
    @api body = '';
    @api showPositive;
    @api positiveButtonLabel;
    @api showNegative;
    @api negativeButtonLabel;
    @api fromSetupPage;
    //@api showModal;

    /*constructor() {
        super();
        this.showNegative = true;
        this.showPositive = true;
        this.showModal = false;
    }*/

    connectedCallback(){
        this.isShowModal = true;
    }
    renderedCallback(){
            Promise.all([
                loadStyle(
                    this,
                    hideCloseIcon
                )
            ]).then(() => {
                /* CSS loaded */
            }).catch((error) => {
                this.error = error;
                this.showLoading = false;
                
                this.showNotification("Something Went Wrong in Loading css .",error,'error');
            });
        }

    hideModalBox(){
        this.isShowModal = false;
    }

    handlePositive() {
        this.dispatchEvent(new CustomEvent('positive'));
    }

    handleNegative() {
        this.dispatchEvent(new CustomEvent('negative'));
    }
    
    handleClose() {
        this.dispatchEvent(new CustomEvent('close'));
    }
}