// This Component is a dummy component : Do not include it during packaging.

import { LightningElement } from 'lwc';
import { updateRecord } from "lightning/uiRecordApi";

export default class DummyLwc extends LightningElement {
    customerCreate() {
        const fieldObj = {
            Id: "001al00000wLuQrAAK",
            BillingPostalCode: "111111",
            KTMYOB__Email__c: "test@abc.com"
        };
        const fields = { ...fieldObj };

        const recordOBJ = { fields };

        updateRecord(recordOBJ)
            .then(() => {
                console.log('Record successfully updated in SF');
            })
            .catch((error) => {
                console.error('Record failed to update in SF', error);
            });
    }
}