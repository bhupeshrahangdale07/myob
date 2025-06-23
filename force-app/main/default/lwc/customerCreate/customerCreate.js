import { api, LightningElement,wire,track } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';
import LightningConfirm from 'lightning/confirm';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import checkAuthorizationSteps from '@salesforce/apex/MYOB_Callout_Helper.checkAuthorizationSteps';
import fetchMYOBObCSConfig from '@salesforce/apex/MYOB_Component_Helper_cls.fetchMYOBObCSConfig';
import createUpdateContact from '@salesforce/apex/ContactDynamicController.createUpdateContact';
import fetchSfContact from '@salesforce/apex/ContactDynamicController.fetchSfContact';
import { CloseActionScreenEvent } from 'lightning/actions';


const CUSTOMERTYPEOPTION = [
    { label: 'Company', value: 'Company' },
    { label: 'Individual', value: 'Individual' }
],
COUNTRYOPTION = [
    { label: 'Afghanistan', value: 'Afghanistan' },
    { label: 'Albania', value: 'Albania' },
    { label: 'Algeria', value: 'Algeria' },
    { label: 'Andorra', value: 'Andorra' },
    { label: 'Angola', value: 'Angola' },
    { label: 'Antigua and Barbuda', value: 'AntiguaAndBarbuda' },
    { label: 'Argentina', value: 'Argentina' },
    { label: 'Armenia', value: 'Armenia' },
    { label: 'Australia', value: 'Australia' },
    { label: 'Austria', value: 'Austria' },
    { label: 'Azerbaijan', value: 'Azerbaijan' },
    { label: 'Bahamas', value: 'Bahamas' },
    { label: 'Bahrain', value: 'Bahrain' },
    { label: 'Bangladesh', value: 'Bangladesh' },
    { label: 'Barbados', value: 'Barbados' },
    { label: 'Belarus', value: 'Belarus' },
    { label: 'Belgium', value: 'Belgium' },
    { label: 'Belize', value: 'Belize' },
    { label: 'Benin', value: 'Benin' },
    { label: 'Bhutan', value: 'Bhutan' },
    { label: 'Bolivia', value: 'Bolivia' },
    { label: 'Bosnia and Herzegovina', value: 'BosniaAndHerzegovina' },
    { label: 'Botswana', value: 'Botswana' },
    { label: 'Brazil', value: 'Brazil' },
    { label: 'Brunei', value: 'Brunei' },
    { label: 'Bulgaria', value: 'Bulgaria' },
    { label: 'Burkina Faso', value: 'BurkinaFaso' },
    { label: 'Burundi', value: 'Burundi' },
    { label: 'Cabo Verde', value: 'CaboVerde' },
    { label: 'Cambodia', value: 'Cambodia' },
    { label: 'Cameroon', value: 'Cameroon' },
    { label: 'Canada', value: 'Canada' },
    { label: 'Central African Republic', value: 'CentralAfricanRepublic' },
    { label: 'Chad', value: 'Chad' },
    { label: 'Chile', value: 'Chile' },
    { label: 'China', value: 'China' },
    { label: 'Colombia', value: 'Colombia' },
    { label: 'Comoros', value: 'Comoros' },
    { label: 'Congo (Congo-Brazzaville)', value: 'Congo' },
    { label: 'Costa Rica', value: 'CostaRica' },
    { label: 'Croatia', value: 'Croatia' },
    { label: 'Cuba', value: 'Cuba' },
    { label: 'Cyprus', value: 'Cyprus' },
    { label: 'Czechia', value: 'Czechia' },
    { label: 'Democratic Republic of the Congo', value: 'DemocraticRepublicOfTheCongo' },
    { label: 'Denmark', value: 'Denmark' },
    { label: 'Djibouti', value: 'Djibouti' },
    { label: 'Dominica', value: 'Dominica' },
    { label: 'Dominican Republic', value: 'DominicanRepublic' },
    { label: 'Ecuador', value: 'Ecuador' },
    { label: 'Egypt', value: 'Egypt' },
    { label: 'El Salvador', value: 'ElSalvador' },
    { label: 'Equatorial Guinea', value: 'EquatorialGuinea' },
    { label: 'Eritrea', value: 'Eritrea' },
    { label: 'Estonia', value: 'Estonia' },
    { label: 'Eswatini', value: 'Eswatini' },
    { label: 'Ethiopia', value: 'Ethiopia' },
    { label: 'Fiji', value: 'Fiji' },
    { label: 'Finland', value: 'Finland' },
    { label: 'France', value: 'France' },
    { label: 'Gabon', value: 'Gabon' },
    { label: 'Gambia', value: 'Gambia' },
    { label: 'Georgia', value: 'Georgia' },
    { label: 'Germany', value: 'Germany' },
    { label: 'Ghana', value: 'Ghana' },
    { label: 'Greece', value: 'Greece' },
    { label: 'Grenada', value: 'Grenada' },
    { label: 'Guatemala', value: 'Guatemala' },
    { label: 'Guinea', value: 'Guinea' },
    { label: 'Guinea-Bissau', value: 'GuineaBissau' },
    { label: 'Guyana', value: 'Guyana' },
    { label: 'Haiti', value: 'Haiti' },
    { label: 'Honduras', value: 'Honduras' },
    { label: 'Hungary', value: 'Hungary' },
    { label: 'Iceland', value: 'Iceland' },
    { label: 'India', value: 'India' },
    { label: 'Indonesia', value: 'Indonesia' },
    { label: 'Iran', value: 'Iran' },
    { label: 'Iraq', value: 'Iraq' },
    { label: 'Ireland', value: 'Ireland' },
    { label: 'Israel', value: 'Israel' },
    { label: 'Italy', value: 'Italy' },
    { label: 'Jamaica', value: 'Jamaica' },
    { label: 'Japan', value: 'Japan' },
    { label: 'Jordan', value: 'Jordan' },
    { label: 'Kazakhstan', value: 'Kazakhstan' },
    { label: 'Kenya', value: 'Kenya' },
    { label: 'Kuwait', value: 'Kuwait' },
    { label: 'Latvia', value: 'Latvia' },
    { label: 'Lebanon', value: 'Lebanon' },
    { label: 'Lithuania', value: 'Lithuania' },
    { label: 'Luxembourg', value: 'Luxembourg' },
    { label: 'Madagascar', value: 'Madagascar' },
    { label: 'Malaysia', value: 'Malaysia' },
    { label: 'Malta', value: 'Malta' },
    { label: 'Mexico', value: 'Mexico' },
    { label: 'Netherlands', value: 'Netherlands' },
    { label: 'New Zealand', value: 'NewZealand' },
    { label: 'Nigeria', value: 'Nigeria' },
    { label: 'Norway', value: 'Norway' },
    { label: 'Pakistan', value: 'Pakistan' },
    { label: 'Peru', value: 'Peru' },
    { label: 'Philippines', value: 'Philippines' },
    { label: 'Poland', value: 'Poland' },
    { label: 'Portugal', value: 'Portugal' },
    { label: 'Qatar', value: 'Qatar' },
    { label: 'Romania', value: 'Romania' },
    { label: 'Russia', value: 'Russia' },
    { label: 'Saudi Arabia', value: 'SaudiArabia' },
    { label: 'Singapore', value: 'Singapore' },
    { label: 'South Africa', value: 'SouthAfrica' },
    { label: 'South Korea', value: 'SouthKorea' },
    { label: 'Spain', value: 'Spain' },
    { label: 'Sweden', value: 'Sweden' },
    { label: 'Switzerland', value: 'Switzerland' },
    { label: 'Thailand', value: 'Thailand' },
    { label: 'Turkey', value: 'Turkey' },
    { label: 'Ukraine', value: 'Ukraine' },
    { label: 'United Arab Emirates', value: 'UnitedArabEmirates' },
    { label: 'United Kingdom', value: 'UnitedKingdom' },
    { label: 'United States', value: 'UnitedStates' },
    { label: 'Vietnam', value: 'Vietnam' },
    { label: 'Zimbabwe', value: 'Zimbabwe' }
];

export default class CustomerCreate extends NavigationMixin(LightningElement) {
   
    showLoading = false;
    isShowModal = false;
    customerTypeOption = CUSTOMERTYPEOPTION;
    @track xIconName = "utility:chevronright";
    @track flagForCustomerList = false;
    labelOne = "ABN";
    labelTwo = "Contact ID";
    labelThree = "Country";
    labelFour = "Address";
    labelFive = "Suburb/town/locality";
    labelSix = "State/territory";
    labelSeven = "Postcode";
    labelEight = "Contact person";
    labelNine = "To Email";
    labelTen = "Fax";
    labelEleven = "Phone";
    labelTwelve = "Website";
    labelThirteen = "Same as billing address";
    labelFourteen = "Notes";

    disableCustomerType = false;
    showABNnContactId = false;
    showBillingAddr = false;
    showShippingAddr = false;
    showNotes = false;
    labelshowABNnContactId = 'ABN & Contact Id';

    billingCountryOption = COUNTRYOPTION;
    billingStateOption = [];
    shippingCountryOption = COUNTRYOPTION;
    shippingStateOption = [];
    disableShippingAddr = false;

    @api recordId;
    @api objectApiName;
    customerType;
    customerRecord={};
    allValid=false;
    individualContact = false;

    companyMyobSfFldMapping = {};
    individualMyobSfFldMapping = {};
    contactFieldMappings={};


    connectedCallback(){
        console.log("$$$ customerType", this.customerType);
        console.log("$$$ recordId", this.recordId);
        this.showLoading = true;
        this.getConnectionDetails();
    }

    getConnectionDetails(){
        checkAuthorizationSteps()
        .then(response => {
            if (response.status === 'Success') {
                console.log('### Authorization Successful');
                this.fetchCSConfigs();
                this.fetchSfContactRecord();
            } else if (response.status === 'Failed' && response.isConnectionError) {
                console.error('Authorization Failed: ', response.message);
                this.handleAlert('Authorization Failed: Please complete all connection steps on MYOB Setup Page.','Connection Not Established');
            }
        })
        .catch(error => {
            this.showLoading = false;
            this.isShowModal = false;
            this.showNotification("Error occurred while checking authorization. Contact System Administrator","error");
            this.closeQuickAction();
        });
    }

//fetch Custom Settings data.
    fetchCSConfigs(){
        debugger;
        fetchMYOBObCSConfig()
        .then(response => {
            if(response){
                if(response.contactCompanyObjectApiName === this.objectApiName){
                    this.customerType = 'Company';
                    this.disableCustomerType = true;
                    this.contactFieldMappings = response.mapMYOBApiNameCompanyData;
                }else if(response.contactIndividualObjectApiName === this.objectApiName){
                    this.customerType = 'Individual';
                    this.isIndividualContact = true;
                    this.disableCustomerType = true;
                    this.contactFieldMappings = response.mapMYOBApiNameIndividualData;
                }
            }
        }).catch(error => {
            this.showLoading = false;
            this.isShowModal = false;
            this.showNotification("Error occurred while fetching Custom Setting. Contact System Administrator","error");
            this.closeQuickAction();  
        })
    }

//method : fetch Contact/Account record from salesforce.
    fetchSfContactRecord(){
        fetchSfContact({'contactId': this.recordId,'objectApiName':this.objectApiName,'getNonNullInvoiceFields':false})
        .then(result => {
            if(result){ 
                this.flagForCustomerList = false;
                this.isShowModal = true;
                this.showLoading = false;
                this.customerRecord = {...result[0]};
                this.customerRecord.customerType = this.customerType;
                this.customerRecord.ContactType = 'Customer';
            }  
        }).catch(error => {
            this.showLoading = false;
            this.isShowModal = false;
            this.showNotification("Error occurred while fetching salesforce record. Contact System Administrator","error");
            this.closeQuickAction();
        });
    }

//method: update ContactRecord when user changes the value in the form.
    updateCustomerValues(event){
        try{
            let targetName;
            if(typeof event !==  'undefined') {
                targetName = event.target.name;
            }
            if(targetName === 'customerType'){
                this.customerRecord.customerType = event.target.value;
                if(this.customerRecord.customerType === 'Company'){
                    this.isIndividual = false;
                }else{
                    this.isIndividual = true;
                }
            }
            if(this.contactFieldMappings[targetName]){
                this.customerRecord[targetName] = event.target.value;
            }
            console.log('$$$ this.customerRecord: ', JSON.stringify(this.customerRecord));
        }catch(error){
            this.showLoading = false;
            this.isShowModal = false;
            this.showNotification("Error occurred during user input.Contact System Administrator","error");
            this.closeQuickAction();
        }
    }


//Method: check user input validity and Create/update record in MYOb and then sync in salesforce.
    createUpdateInMYOB(){
        try{
            this.reportFieldValidity();
            if(this.recordId && this.objectApiName && this.customerRecord && this.allValid){
                this.showLoading = true;                
                this.recordId = this.recordId.trim().slice(0, -3);            
                createUpdateContact({
                    'contactId' : this.recordId,
                    'objectApiName' : this.objectApiName,
                    'mapMYOBContactFldNameSfValue' :this.customerRecord,
                    'isIndividual':this.individualContact
                })
                .then(response => {
                    this.showLoading = false;
                    if (response.status === 'Success') {
                        this.showNotification(response.message,'success');
                        this.dispatchEvntOnSuccessOrError('success');
                    } else if (response.status === 'Failed' || response.isConnectionError) {
                        if(response.message){
                            this.showNotification(response.message,'error');
                        }else if (response.multipleMessage){
                            let errrorArr = JSON.parse(response.multipleMessage);
                            errrorArr.forEach(err => {
                                let errorMsg = 
                                'Name      : ' + err.Name + ' | ' +
                                'Message   : ' + err.Message + ' | ' +
                                'ErrorCode : ' + err.ErrorCode;
                                if(err.Severity.toLowerCase() === 'error'){
                                    this.showNotification(errorMsg,'error','sticky');
                                }else if((err.Severity.toLowerCase() === 'warning')){
                                    this.showNotification(errorMsg,'warning','sticky');
                                }
                            });
                        }else{
                            this.showNotification('Unexpected Error : Contact your System Administrator,','error');
                        }    
                        this.closeQuickAction();            
                    }   
                })
                .catch(error => {
                    this.showLoading = false;
                    this.isShowModal = false;
                    this.showNotification('Customer creation in MYOB Failed. Contact System Administrator.','error');
                    this.closeQuickAction();  
                });
            }
        }catch{
            this.showLoading = false;
            this.isShowModal = false;
            this.showNotification("Error while saving record in Salesforce. Contact System Administrator","error");
            this.closeQuickAction();  
        }
     
    }

//helper : disptch event passing success or error message to parent.
    dispatchEvntOnSuccessOrError(msg){
        const selectEvent = new CustomEvent('customercreateupdate', {
            detail: msg,bubbles: true
        });
        this.dispatchEvent(selectEvent);
        this.isShowModal=false;
        this.closeQuickAction();
    }
  

    changeView(event){
        const btName = event.target.dataset.id,
              ele = this.template.querySelector(`[data-id="${btName}"]`),
        {iconName} = ele,
        property = {
            abnnContactId: { showProperty: 'showABNnContactId' },
            billingAddrId: { showProperty: 'showBillingAddr' },
            shippingAddrId: { showProperty: 'showShippingAddr' },
            notesId: { showProperty: 'showNotes' },
        }[btName]?.showProperty;
        if(!ele){
           return '';
        };
        if(iconName === 'utility:chevronright') {
            ele.iconName = 'utility:chevrondown';
            this[property] = true;
        } else {
            ele.iconName = 'utility:chevronright';
            this[property] = false;
        }
    }

//helper : check the validity of the component.
    reportFieldValidity(){
    this.allValid = [...this.template.querySelectorAll("lightning-input")].reduce(
        (validSoFar, inputFields) => {
            inputFields.reportValidity();
            return validSoFar && inputFields.checkValidity();
        },
        true,
        );
    }


//Helper : to close the modal.
    closeQuickAction() {
        if (typeof window !== 'undefined') {
            this.dispatchEvent(new CloseActionScreenEvent());
        } 
    }

//Helper : to show notification and on click of OK button redirect page to the Setup page.
    handleAlert(msg, lbl) {
        LightningConfirm.open({
            label: lbl,
            message: msg,
            theme: "error"
        })
        .then((result) => {
            if (result === true) {
                this[NavigationMixin.Navigate]({
                    attributes: {
                        apiName: 'KTMYOB__MYOB_Setup'
                    },
                    type: 'standard__navItemPage'
                });
            } else {
                this.closeQuickAction();
            }
        })
        .catch((error) => {
            console.error("Error opening alert: ", error);
            this.showNotification("Error Occured while opening an alert.Contact System Administrator","error");
            this.closeQuickAction();
            this.showLoading = false;
            this.isShowModal = false;
        });
    }

//helper : to show notification message.
    showNotification(msg,type,mode) {
        if (typeof window !== 'undefined') {
            this.dispatchEvent(
                new ShowToastEvent({
                title:'Customer Sync',
                message: msg,
                variant: type,
                mode : mode
            }));
        }
    }
}


//Todo :
//1. We would need to create an object/custom setting for storing Country nd its states.
//2. Give options for Tax code and freight code (drop down)
//4. ContactType : Customer,Supplier or personal (Drop down)