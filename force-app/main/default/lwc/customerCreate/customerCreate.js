import { CurrentPageReference, NavigationMixin } from 'lightning/navigation';
import { api, LightningElement,wire,track } from 'lwc';
//import HideLightningHeader from '@salesforce/resourceUrl/noHeader';
//import { loadStyle } from "lightning/platformResourceLoader";
import checkAuthorizationSteps from '@salesforce/apex/MYOB_Callout_Helper.checkAuthorizationSteps';
import getCustomSettingDetails from '@salesforce/apex/GenerateInvoiceController.getCustomSettingDetails';
import LightningConfirm from 'lightning/confirm';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import createCustomerInSF from '@salesforce/apex/ContactDynamicController.createCustomerInSF';
import createUpdateContact from '@salesforce/apex/ContactDynamicController.createUpdateContact';
import customerList from '@salesforce/apex/GenerateInvoiceController.customerList';
import { createRecord,updateRecord } from "lightning/uiRecordApi";



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
    // @track newCustomerData = {}; 
    //customerBillingAddr = {};
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
    billingCountryOption = COUNTRYOPTION;
    billingStateOption = [];
    shippingCountryOption = COUNTRYOPTION;
    shippingStateOption = [];
    disableShippingAddr = false;

    customerId = '';
    // @api fromGenerateInvoice = false; 
    // @api customerRec;
    //@api myobSfFldMapping = [];
    

    //mamgesh varaiables:
    @api recordId;
    @api objectApiName;
    @api customerType;
    @api myobSfFldMapping;
    @track customerRecord={};
    oldCustomerRecord={};
    allValid=false;
    // sfFieldMap = {};
    individualContact = false;

    companyMyobSfFldMapping = {};
    individualMyobSfFldMapping = {};

    connectedCallback(){
        console.log("$$$ customerType", this.customerType);
        console.log("$$$ recordId", this.recordId);
        this.showLoading = true;
        // this.getConnectionDetails(); // Uncomment later
        this.fetchCustomerDetails(this.recordId);
    }

    getConnectionDetails(){
        checkAuthorizationSteps()
        .then(response => {
            if (response.status === 'Success') {
                console.log('### Authorization Successful');
                this.fetchCustomerDetails(this.recordId);
            } else if (response.status === 'Failed' && response.isConnectionError) {
                console.error('Authorization Failed: ', response.message);
                this.handleAlert('Authorization Failed: Please complete all connection steps on MYOB Setup Page.','Connection Not Established');
            }
        })
        .catch(error => {
            this.showLoading = false;
            console.error('!!! Error occurred while checking authorization: ', error);
        });
    }

    fetchCustomerDetails(recordId){
        customerList({
            "searchStr": '',
            "customerID" : recordId
        }).then(response => {
            this.flagForCustomerList = false;
            this.isShowModal = true;
            this.showLoading = false;
            if(response.companyRecordNo === 1){
                this.customerRecord ={...response.listOfMapOfSelectedCustomer[0]};
                this.oldCustomerRecord ={...this.customerRecord};
            }
            if(this.customerType === 'Company'){
                this.companyMyobSfFldMapping = response.mapOfMyobFldApiNameNdSfFldApiNameCompany;
                this.customerRecord.customerType = 'Company';
                this.individualContact = false;
                this.disableCustomerType = true;
            }else if(this.customerType === 'Individual'){
                this.individualMyobSfFldMapping = response.mapOfMyobFldApiNameNdSfFldApiNameIndividual;
                this.customerRecord.customerType = 'Individual';
                this.individualContact = true;
                this.disableCustomerType = true;
            }
        }).catch(error => {
            console.error('!!! Error occurred while fetching customer details: ', error);
        });
    }


    updateUserInputValues(){
        //1. First check if the old values and the new values are same or changed. 
        //2. If changed the only send that field value to update.
        //3. Use the companyMyobSfFldMapping or individualMyobSfFldMapping and customerRecord to map Sf field and the values.
        //4. Once field and values are mapped, the use LDS method for update.
        //5. At the end once update is successfull, then call ContactDynamicController.createUpdateContact(String contactId,String objectApiName)
        debugger;
        try{
            this.reportFieldValidity();
            // let sfFieldApiValueObj = {};
            // if(this.customerRecord && this.allValid){
            //     this.showLoading = true;
            //     Object.entries(this.customerRecord).forEach(([key, value]) => {
            //         let checkSame = String(this.customerRecord[key]).toLowerCase() === String(this.oldCustomerRecord[key]).toLowerCase();
            //         if(!checkSame){
            //             if(this.customerType === 'Company' && this.companyMyobSfFldMapping[key]){
            //                 sfFieldApiValueObj[ this.companyMyobSfFldMapping[key]] = this.customerRecord[key];
            //             }
            //             else if(this.customerType === 'Individual' && this.individualMyobSfFldMapping[key]){
            //                 sfFieldApiValueObj[ this.companyMyobSfFldMapping[key]] = this.customerRecord[key];
            //             }
            //         }
            //     });
            // }
            // if (Object.keys(sfFieldApiValueObj).length > 0) {
            //     // if(this.recordId === 'add_new_customer'){
            //     //     // const fields = {...sfFieldApiValueObj};
            //     //     // const recordInput = {apiName: this.objectApiName,fields};
            //     //     // createRecord(recordInput).then(()=>{
            //     //     //     console.log('record Created in SF');
            //     //     //     this.creteUpdateInMYOB();
            //     //     // }).catch(error => {
            //     //     //     this.showLoading = false;
            //     //     //     this.showNotification('Error while creating record in Salesforce. Contact System Administrator','error');
            //     //     // });
            //     // }
            //     if(this.recordId !== 'add_new_customer'){
            //         sfFieldApiValueObj["Id"] = this.recordId;
            //         // if(sfFieldApiValueObj.Id){
            //             // const fields = {...sfFieldApiValueObj}
            //             // const recordInput = {fields};
            //             // updateRecord(recordInput)
            //             // .then(() => {
            //             //     console.log('record updated in SF');
            //             //     this.creteUpdateInMYOB();
            //             // })
            //             // .catch((error) => {
            //             //     this.showLoading = false;
            //             //     this.showNotification("Error while updating record in Salesforce. Contact System Administrator","error")
            //             // });
            //         // }
            //     }
                // this.sfFieldMap = {...sfFieldApiValueObj};
                if(this.recordId && this.objectApiName && this.customerRecord && this.allValid){
                    this.showLoading = true;
                    this.customerRecord.ContactType = 'Customer';
                    this.creteUpdateInMYOB();
                }
            // }
        }catch{
            this.showLoading = false;
            this.showNotification("Error while saving record in Salesforce. Contact System Administrator","error")
        }
    }

    creteUpdateInMYOB(){
        this.recordId = this.recordId.trim().slice(0, -3);
        console.log(`### recordID trim ::: `+this.recordId);
        
        createUpdateContact({
            'contactId' : this.recordId,
            'objectApiName' : this.objectApiName,
            // 'fieldMap' : this.sfFieldMap,
            'mapMYOBContactFldNameSfValue' :this.customerRecord,
            'isIndividual':this.individualContact
        })
        .then(response => {
            this.showLoading = false;
            if (response.status === 'Success') {
                this.showNotification(response.message,'success');
            } else if (response.status === 'Failed' || response.isConnectionError) {
                this.showNotification(response.message,'error');
                //TODO: create an helper method for parsing the multiple error message, ex: [{"Severity":"Error","Name":"IncorrectRowVersionSu…":null,"ErrorCode":111,"AdditionalDetails":null}];
            }
        })
        .catch(error => {
            this.showLoading = false;
            console.error('!!! Error occurred while creating customer in MYOB: ', error);
            this.showNotification('Customer creation in MYOB Failed. Contact System Administrator.','error');
        });
     
    }

    // prePopulateCustomerDetailsHavingNoUID(customer, customerType){
    //     if(customerType === 'Company'){
    //         this.customerRecord.customerType = 'Company';
    //         this.companyContact = true;
    //         this.disableCustomerType = true;
    //         this.customerRecord.companyName = customer.CompanyName;
    //     }else if(customerType === 'Individual'){
    //         this.customerRecord.customerType = 'Individual';
    //         this.companyContact = false;
    //         this.disableCustomerType = true;
    //         this.customerRecord.firstName = customer.FirstName;
    //         this.customerRecord.lastName = customer.LastName;
    //     }
    //     this.customerRecord.notes = customer.Notes;
    // }

    // getCustomSetting(){
    //     getCustomSettingDetails()
    //     .then(result => {
    //         console.log('### getCustomSettingDetails result : ',result);
    //         console.log('###recordId :',this.recordId);
    //         console.log('###objectApiName :',this.objectApiName);
    //         if(result.KTMYOB__Contact_Company_Object_Api_Name__c === this.objectApiName){
    //             this.customerRecord.customerType = 'Company';
    //             this.isShowModal = true;
    //             this.showLoading = false;
    //             this.companyContact = true;
    //         }else if(result.KTMYOB__Contact_Individual_Object_Api_Name__c === this.objectApiName){
    //             this.customerRecord.customerType = 'Individual';
    //             this.isShowModal = true;
    //             this.showLoading = false;
    //             this.companyContact = false;
    //         }else{
    //             this.isShowModal = false;
    //             this.handleAlert('Please complete the mapping in Contact Configuration on the MYOB Setup page.','Mapping incomplete');
    //         }
    //     })
    //     .catch(error => {
    //         this.showLoading = false;
    //         console.error('!!! Error occurred while getting Custom Setting: ', error);
    //     });
    // } 

    updateCustomerValues(event){
        try{
            debugger;
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
            if(this.companyMyobSfFldMapping[targetName]|| this.individualMyobSfFldMapping[targetName]){
                this.customerRecord[targetName] = event.target.value;
            }
            
            // else if(targetName === 'companyName'){
            //     this.customerRecord.CompanyName = event.target.value;
            // }else if(targetName === 'firstName'){
            //     this.customerRecord.FirstName = event.target.value;
            // }else if(targetName === 'lastName'){
            //     this.customerRecord.LastName = event.target.value;
            // }else if(targetName === 'abn'){ //todo
            //     this.customerRecord.abn = event.target.value;
            // }else if(targetName === 'contactId'){ //todo
            //     this.customerRecord.contactId = event.target.value;
            // }else if(targetName === 'billingCountry'){
            //     this.customerRecord.BillAddrCountry = event.target.value;
            // }else if(targetName === 'billingAddress'){
            //     this.customerRecord.BillAddrStreet = event.target.value;
            // }else if(targetName === 'billingLocality'){
            //     this.customerRecord.BillAddrCity = event.target.value;
            // }else if(targetName === 'billingState'){
            //     this.customerRecord.BillAddrState = event.target.value;
            // }else if(targetName === 'billingPostcode'){
            //     this.customerRecord.BillAddrPostalCode = event.target.value;
            // }else if(targetName === 'billingContactPerson'){
            //     this.customerRecord.BillAddrContactPerson = event.target.value;
            // }else if(targetName === 'billingToEmail'){
            //     this.customerRecord.BillAddrToEmail = event.target.value; 
            //     this.emailToCheck = event.target.value;
            // }else if(targetName === 'billingFax'){
            //     this.customerRecord.BillAddrFax = event.target.value;
            // }else if(targetName === 'billingPhone'){
            //     this.customerRecord.BillAddrPhone = event.target.value;
            // }else if(targetName === 'billingWebsite'){
            //     this.customerRecord.BillAddrWebsite = event.target.value;
            // }else if(targetName === 'shippingCountry'){
            //     this.customerRecord.ShipAddrCountry = event.target.value;
            // }else if(targetName === 'shippingAddress'){
            //     this.customerRecord.ShipAddrStreet = event.target.value;
            // }else if(targetName === 'shippingLocality'){
            //     this.customerRecord.ShipAddrCity = event.target.value;
            // }else if(targetName === 'shippingState'){
            //     this.customerRecord.ShipAddrState = event.target.value;
            // }else if(targetName === 'shippingPostcode'){
            //     this.customerRecord.ShipAddrPostalCode = event.target.value;
            // }else if(targetName === 'shippingContactPerson'){
            //     this.customerRecord.ShipAddrContactPerson = event.target.value;
            // }else if(targetName === 'shippingToEmail'){
            //     this.customerRecord.ShipAddrToEmail = event.target.value;
            // }else if(targetName === 'shippingFax'){
            //     this.customerRecord.ShipAddrFax = event.target.value;
            // }else if(targetName === 'shippingPhone'){
            //     this.customerRecord.ShipAddrPhone = event.target.value;
            // }else if(targetName === 'shippingWebsite'){
            //     this.customerRecord.ShipAddrWebsite = event.target.value;
            // }else if(targetName === 'notes'){ //todo
            //     this.customerRecord.notes = event.target.value;
            // }
            console.log('$$$ this.customerRecord: ', JSON.stringify(this.customerRecord));
        }catch(error){
            console.log('!!! Error in updateCustomerValues(): ' + error);
        }
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

    reportFieldValidity(){
    this.allValid = [...this.template.querySelectorAll("lightning-input")].reduce(
        (validSoFar, inputFields) => {
            inputFields.reportValidity();
            return validSoFar && inputFields.checkValidity();
        },
        true,
        );
    }

    hideModalBox(){
        this.isShowModal = false;
        this.flagForCustomerList = true;
        this.dispatchEvent(new CustomEvent('flagchange'));
        //this.template.querySelector('.slds-backdrop').classList.remove('slds-backdrop_open');
        const backdrop = this.template.querySelector('.slds-backdrop');
        if (backdrop) {
            backdrop.classList.remove('slds-backdrop_open');
        }
    }

    // actionInsertContact(){
    //     this.showLoading = true;
    //     const inputFields = this.template.querySelectorAll(".newCustomerValidate");
    //     let isValid = true;
    //     inputFields.forEach((inputField) => {
    //         if (!inputField.checkValidity()) {
    //             inputField.reportValidity();
    //             isValid = false;
    //         }
    //     });
    //     console.log('isValid = ',isValid);
    //     if(isValid) {
    //         if(this.customerRecord){
    //             console.log('$$$ this.customerRecord: ', JSON.stringify(this.customerRecord));

    //             createCustomerInSF({
    //                 'objectApiName' : this.objectApiName,
    //                 'customerData' : JSON.stringify(this.customerRecord)
    //             })
    //             .then(result => {
    //                 if(result){
    //                     console.log('### result: ', result);
    //                     this.flagForCustomerList = true;
    //                     this.customerId = result;
    //                 }else{
    //                     console.error('Customer creation in SF Failed');
    //                     this.showNotification('Customer creation in SF Failed: Please complete all connection steps on MYOB Setup Page.','error');
    //                 }
    //             })
    //             .catch(error => {
    //                 this.showLoading = false;
    //                 console.error('!!! Error occurred while creating customer in SF: ', error);
    //             });

    //             createUpdateContact({
    //                 'contactId' : this.customerId,
    //                 'objectApiName' : this.objectApiName
    //             })
    //             .then(response => {
    //                 if (response.status === 'Success') {
    //                     console.log('Customer creation in MYOB Successfull: ', response.message);
    //                 } else if (response.status === 'Failed' && response.isConnectionError) {
    //                     console.error('Customer creation in MYOB Failed: ', response.message);
    //                     this.showNotification('Customer creation in MYOB Failed: Please complete all connection steps on MYOB Setup Page.','error');
    //                 }
    //             })
    //             .catch(error => {
    //                 this.showLoading = false;
    //                 console.error('!!! Error occurred while creating customer in MYOB: ', error);
    //             });

    //             /*this.getCustomerPicklist();
    //             this.customerBillingAddr = {
    //                 Name : this.companyContact ? this.customerRecord['companyName'] : `${this.customerRecord['FirstName']} ${this.customerRecord['LastName']}`,
    //                 BillAddrStreet : this.customerRecord.BillAddrStreet,
    //                 BillAddrCity: this.customerRecord.BillAddrCity,
    //                 BillAddrState : this.customerRecord.BillAddrState,
    //                 BillAddrPostalCode : this.customerRecord.BillAddrPostalCode,
    //                 BillAddrCountry: this.customerRecord.BillAddrCountry,
    //             };
    //             this.flagForCustomerBillingAddr = true;*/
    //             this.hideModalBox();
    //         }
    //     }else{
    //         this.showNotification('Please resolved all errors','error');
    //         this.showLoading = false;
    //     }
    // }

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
            } else if (msg === 'Customer MYOB ID is not present. Unable to create Customer.') {
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
                title:'Customer Creation',
                message: msg,
                variant: type
            });
            this.dispatchEvent(evt);
        }
    }
}


//Todo :
// 1. Give options for Tax code and freight code (drop down)
// 2. ContactType : Customer,Supplier or personal (Drop down)