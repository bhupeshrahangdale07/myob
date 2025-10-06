import { LightningElement,track,wire } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { CurrentPageReference } from 'lightning/navigation';
import getRecordDetails from '@salesforce/apex/ContactDynamicController.getRecordDetails';

export default class QuickActionGenerateInvoive extends LightningElement {

    @track wireRecordId;
    @track objectApiName;
    @track UID;

    @wire(CurrentPageReference)
        getStateParameters(currentPageReference) {
            if (currentPageReference) {
                console.log('currentPageReference ', currentPageReference);
                //it gets executed before the connected callback and avilable to use
                this.wireRecordId = currentPageReference.state.recordId;
                let quickActionPath = currentPageReference.attributes.apiName;
                const apiField = quickActionPath;
                const objectName = apiField.split('.')[0];
                this.objectApiName = objectName;
                console.log(objectName); // Outputs: "Contact"
            }
        }

    connectedCallback(){
        debugger;
        this.dispatchEvent(new CloseActionScreenEvent());
        getRecordDetails({recordId: this.wireRecordId, objectApiName: this.objectApiName}).then(result => {
            console.log(result);
            if(result != '' || result != 'Failed'){
                this.UID = result;
            }else if(result == ''){
                this.UID = '';
            }
            let url = '/lightning/n/KTMYOB__Generate_Invoice?c__objrecordId='+this.wireRecordId+'&c__UID='+this.UID;
            window.location.href = url;
        }).catch(error => {})
        
    }
}