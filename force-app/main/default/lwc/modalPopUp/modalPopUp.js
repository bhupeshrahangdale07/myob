import { LightningElement,api } from 'lwc';

export default class ModalPopUp extends LightningElement {
    @api showPositive;
    @api showNegative;
    @api positiveButtonLabel;
    @api negativeButtonLabel;
    @api showModal;

    constructor() {
        super();
        this.showNegative = true;
        this.showPositive = true;
        this.showModal = false;
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