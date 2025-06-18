import { LightningElement, track } from 'lwc';

export default class InvoiceSync extends LightningElement {
    @track isShowModal = true;
    @track showLoading = false;
    @track invoiceData = [
        {
            Key: 'Invoice Number',
            Fieldvalue: 'INV-123',
            hasLineItems: false,
        },
        {
            Key: 'Customer Name',
            Fieldvalue: 'John Doe',
            hasLineItems: false,
        },
        {
            Key: 'LineItems',
            Fieldvalue: 'Click to expand',
            hasLineItems: true,
            showLineItems: false,
            lineItems: [
                { Key: 'Item 1', Fieldvalue: 'Product A - $50' },
                { Key: 'Item 2', Fieldvalue: 'Product B - $100' }
            ]
        }
    ];

    toggleSubTable(event) {
        const key = event.currentTarget.dataset.id;
        this.invoiceData = this.invoiceData.map(item => {
            if (item.Key === key) {
                return { ...item, showLineItems: !item.showLineItems };
            }
            return item;
        });
    }

    hideModalBox() {
        this.isShowModal = false;
    }

    actionInsertContact() {
        console.log('Sync initiated');
    }
}