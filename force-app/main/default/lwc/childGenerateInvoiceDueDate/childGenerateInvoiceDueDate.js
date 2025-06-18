import { LightningElement, track } from 'lwc';
const DUEDATEOPTIONS = [
    { label: 'Due on this day', value: 'dueOnThisDay'},
    { label: 'Prepaid', value: 'prepaid' },
    { label: 'Due in a number of days after the issue date', value: 'dueInANumberOfDaysAfterTheIssueDate'},
    { label: 'Cash on delivery', value: 'cashOnDelivery'},
    { label: 'Due on a date of next month', value: 'dueOnADateOfNextMonth'},
    { label: 'Due in a number of days after the end of the month', value: 'dueInANumberOfDaysAfterTheEndOfTheMonth'},
],
ONE = 1,
THIRTY = 30,
ZERO = 0;

export default class ChildGenerateInvoiceDueDate extends LightningElement {
    showLoading = false;
    dueDateOptions = DUEDATEOPTIONS;
    labelOne = 'Payment is';
    isDueOnThisDay = false;
    isPrepaid = false;
    isDueInANumberOfDaysAfterTheIssueDate = false;
    isCashOnDelivery = false;
    isDueOnADateOfNextMonth = false;
    isDueInANumberOfDaysAfterTheEndOfTheMonth = false;
    @track dueDateData = {};
    dayOptions = [];

    connectedCallback(){
        this.showLoading = true;
        this.getPreSavedDetails();
    }

    getPreSavedDetails(){
        //debugger;
        /*preSavedDetails()
        .then(result => {
            if(result){
                this.dueDateValue = result.field;
            }else{
                this.dueDateValue = 'dueInANumberOfDaysAfterTheIssueDate';
                this.isDueInANumberOfDaysAfterTheIssueDate = true;
            }
            this.preDueDateSettings();
        })
        .catch(error => {
            this.showLoading = false;
            console.error('!!! Error preSavedDetails(): ', error);
        });*/

        for (let i = ONE; i <= THIRTY; i++) {
            this.dayOptions.push({ label: i.toString(), value: i.toString() });
        }

        // Get last day of the current month
        const today = new Date();
        const lastDay = new Date(today.getFullYear(), today.getMonth() + ONE, ZERO).getDate();

        // Add "Last Day" option
        this.dayOptions.push({ label: "Last Day", value: lastDay.toString() });
        console.log('### this.dayOptions: ' ,JSON.stringify(this.dayOptions));
        this.dueDateValue = 'dueInANumberOfDaysAfterTheIssueDate';
        this.isDueInANumberOfDaysAfterTheIssueDate = true;

        this.preDueDateSettings();
    }

    preDueDateSettings(){         
        try{
            /*if(this.dueDateValue === 'dueOnThisDay'){
                this.isDueOnThisDay = true;
                this.isPrepaid = false;
                this.isDueInANumberOfDaysAfterTheIssueDate = false;
                this.isCashOnDelivery = false;
                this.isDueOnADateOfNextMonth = false;
                this.isDueInANumberOfDaysAfterTheEndOfTheMonth = false;
            }else if(this.dueDateValue === 'prepaid'){
                this.isDueOnThisDay = false;
                this.isPrepaid = true;
                this.isDueInANumberOfDaysAfterTheIssueDate = false;
                this.isCashOnDelivery = false;
                this.isDueOnADateOfNextMonth = false;
                this.isDueInANumberOfDaysAfterTheEndOfTheMonth = false;
            }else if(this.dueDateValue === 'dueInANumberOfDaysAfterTheIssueDate'){
                this.isDueOnThisDay = false;
                this.isPrepaid = false;
                this.isDueInANumberOfDaysAfterTheIssueDate = true;
                this.isCashOnDelivery = false;
                this.isDueOnADateOfNextMonth = false;
                this.isDueInANumberOfDaysAfterTheEndOfTheMonth = false;
            }else if(this.dueDateValue === 'cashOnDelivery'){
                this.isDueOnThisDay = false;
                this.isPrepaid = false;
                this.isDueInANumberOfDaysAfterTheIssueDate = false;
                this.isCashOnDelivery = true;
                this.isDueOnADateOfNextMonth = false;
                this.isDueInANumberOfDaysAfterTheEndOfTheMonth = false;
            }else if(this.dueDateValue === 'dueOnADateOfNextMonth'){
                this.isDueOnThisDay = false;
                this.isPrepaid = false;
                this.isDueInANumberOfDaysAfterTheIssueDate = false;
                this.isCashOnDelivery = false;
                this.isDueOnADateOfNextMonth = true;
                this.isDueInANumberOfDaysAfterTheEndOfTheMonth = false;
            }else if(this.dueDateValue === 'dueInANumberOfDaysAfterTheEndOfTheMonth'){
                this.isDueOnThisDay = false;
                this.isPrepaid = false;
                this.isDueInANumberOfDaysAfterTheIssueDate = false;
                this.isCashOnDelivery = false;
                this.isDueOnADateOfNextMonth = false;
                this.isDueInANumberOfDaysAfterTheEndOfTheMonth = true;
            }else {

            }*/
            const dueDateOptions = {
                dueOnThisDay: 'isDueOnThisDay',
                prepaid: 'isPrepaid',
                dueInANumberOfDaysAfterTheIssueDate: 'isDueInANumberOfDaysAfterTheIssueDate',
                cashOnDelivery: 'isCashOnDelivery',
                dueOnADateOfNextMonth: 'isDueOnADateOfNextMonth',
                dueInANumberOfDaysAfterTheEndOfTheMonth: 'isDueInANumberOfDaysAfterTheEndOfTheMonth'
            };
        
            Object.keys(dueDateOptions).forEach(key => {
                this[dueDateOptions[key]] = key === this.dueDateValue;
            });
            this.showLoading = false;
        }catch(error){
            this.showLoading = false;
            console.log('!!! Error in preDueDateSettings(): ' + error);
        }
    }

    handleChange(event) {
        console.log('### In handleChange()');
        this.dueDateValue = event.detail.value;
        this.preDueDateSettings();


    }

    handleSecondTier(event){
        console.log('### In handleSecondTier()');
        //debugger;
        let targetName;

        if(typeof event !==  'undefined') {
            targetName = event.target.name;
        }
        
        if(targetName === 'isDueOnThisDay'){

        }else if(targetName === 'isDueInANumberOfDaysAfterTheIssueDate'){
            
        }else if(targetName === 'isDueOnADateOfNextMonth'){
            
        }else if(targetName === 'isDueInANumberOfDaysAfterTheEndOfTheMonth'){
            
        }else{

        }
    }

    handleSave(){
        console.log('### In handleSave()');
    }
}