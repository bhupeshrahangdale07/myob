import { api, LightningElement } from 'lwc';

export default class ConfirmationModalPopup extends LightningElement {
    isShowModal = false;
    @api title = '';
    @api body = '';
    @api showPositive;
    @api positiveButtonLabel;
    @api showNegative;
    @api negativeButtonLabel;
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