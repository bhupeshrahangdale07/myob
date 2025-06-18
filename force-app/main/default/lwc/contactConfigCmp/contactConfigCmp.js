import { LightningElement, track } from 'lwc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import getContactConfiguration from "@salesforce/apex/ContactConfigController.getContactConfiguration";
import getObjectList from "@salesforce/apex/ContactConfigController.getObjectList";
import getContactCusSettingFields from "@salesforce/apex/ContactConfigController.getContactCusSettingFields";
import updateContactConfig from "@salesforce/apex/ContactConfigController.updateContactConfig";
import saveObjectConfiguration from "@salesforce/apex/ContactConfigController.saveObjectConfiguration";

const ZERO_NUM = 0,
      allObjects = [{label: "No Data Found",value: ""}],
      individualAllObjects = [{label: "No Data Found",value: ""}];

export default class ContactConfigCmp extends LightningElement {
    @track saveContactsDifferently = true;
    @track showCompanyPicklist = false;
    @track showIndividualPicklist = false;
    @track options = allObjects;
    @track individualOptions = individualAllObjects;
    @track MYOBFields = [];
    @track companyFields = [];
    @track individualFields = [];
    @track isModalOpen = false;
    showLoading = false;
    componentTitle = "Contact Configuration";
    subTitleOne = "MYOB CONTACT DEFAULT OBJECT AND FIELD MAPPING SETTING";
    headingOne = "Search and Select Object to store Contact and map Object fields";
    labelOne = "Save Contacts in Different Object";
    contactConfig;
    selectedValue = "";
    oldSelectedValue = "";
    individualSelectedValue = "";
    oldIndividualSelectedValue = "";
    Objectfields = [];
    companyObjectFields = [];
    companyRequiredField = [];
    individualObjectFields = [];
    individualRequiredField = [];
    objectType = "";
    selectObjectLabel = "";
    modalHeader = "";
    placeHolder = "";
    label="";
    selectedCompanyLabel =''
    selectedIndividualLabel=''
    disableSave = true;
    
    connectedCallback(){
        console.clear();
        this.showLoading = true;
        this.contactConfiguration();
    }

    // Get Contact Configuration from custom metadata using apex class
    // Return - Custom Setting (KTMYOB__Contact_Company_Fields_Mapping__c, KTMYOB__Contact_Individual_Fields_Mapping__c & KTMYOB__MYOB_Objects_Configurations__c)
    contactConfiguration(){
        getContactConfiguration({}).
        then((result) => {
            if (result === null) {
                this.showToastPopMessage(
                    "Something Went Wrong. Please check related Custom Setting.",
                    "error"
                );
                this.showLoading = false;
            } else {
                this.contactConfig = result;
                this.selectedValue = result.objConfigSetting.KTMYOB__Contact_Company_Object_Api_Name__c;
                this.oldSelectedValue = result.objConfigSetting.KTMYOB__Contact_Company_Object_Api_Name__c;
                this.individualSelectedValue = result.objConfigSetting.KTMYOB__Contact_Individual_Object_Api_Name__c;
                this.oldIndividualSelectedValue = result.objConfigSetting.KTMYOB__Contact_Individual_Object_Api_Name__c;
                this.saveContactsDifferently = result.objConfigSetting.KTMYOB__Save_Contacts_in_Different_Object__c;
                if(this.saveContactsDifferently){
                    this.placeHolder = "Please Select Contact Company Object";
                    this.label = "Search and Select Object to store Company";
                    this.selectedCompanyLabel = result.objConfigSetting.KTMYOB__Contact_Company_Object_Api_Name__c;
                    this.selectedIndividualLabel = result.objConfigSetting.KTMYOB__Contact_Individual_Object_Api_Name__c;
                }else{
                    this.selectedCompanyLabel = result.objConfigSetting.KTMYOB__Contact_Company_Object_Api_Name__c;
                    this.placeHolder = "Please Select Contact Object for both Company and Individual";
                    this.label = "Search and Select Object to store Company and Individual";
                }
                this.getObjectFields();
            }
        }).
        catch((error) => {
            this.error = error;
            this.showToastPopMessage(
                error.body.message,
                "error"
            );
            this.showLoading = false;
        });
    }

    // Get All Object using apex class
    // Return - All Object List
    getObjectFields(){
        getObjectList({}).
        then((data) => {
            if (data) {
                const sObject = [...data];
                this.options = sObject;
                this.options.sort((ele1, ele2) => ele1.label.localeCompare(ele2.label));
                this.showCompanyPicklist = true;
                if (this.selectedValue !== null) {
                    this.fetchObjectNfields(
                        this.selectedValue,
                        "Company"
                    );
                }
            }
        }).
        catch((error) => {
            this.showToastPopMessage(
                `Something went wrong. Error - ${error}`,
                "error"
            );
            this.showLoading = false;
        });
    }

    fetchObjectNfields (selectedValue, objectType) {
        if (selectedValue) {
            getContactCusSettingFields({"objectApiName": selectedValue, "type": objectType}).
            then((result) => {
                console.log('getContactCusSettingFields result = ',result);
                console.log('getContactCusSettingFields result = ',JSON.stringify(result));
                this.Objectfields = result.Objectfields;
                const aObjectRes = result,
                    groupedByFieldType = this.Objectfields.reduce(
                        (aObjectRes, current) => {
                            const {fieldType} = current;
                            if (!aObjectRes[fieldType]) {
                                aObjectRes[fieldType] = [];
                            }
                            aObjectRes[fieldType].push(current);
                            return aObjectRes;
                        },
                        {}
                    );
                this.MYOBFields = [...aObjectRes.customSettingObjectFields];
                this.MYOBFields.forEach((item) => {
                    const dataType = (item.type || "").split(","),
                        noneOption = {"fieldType": "",
                            "label": "Select Fields",
                            "referencedObjectApiName": "",
                            "required": true,
                            "value": ""};
                    dataType.forEach((typ) => {
                        if (item.options && groupedByFieldType[typ.trim()]) {
                            item.options = [
                                ...item.options,
                                ...groupedByFieldType[typ.trim()]
                            ];
                        } else {
                            item.options = groupedByFieldType[typ.trim()];
                        }
                    });
                    if (item.options) {
                        item.options.sort((ele1, ele2) => ele1.label.localeCompare(ele2.label));
                        item.options = [
                            noneOption,
                            ...item.options
                        ];
                    }
                });
                if (objectType === "Company") {
                    this.individualOptions = aObjectRes.childObjects;
                    this.individualOptions.sort((ele1, ele2) => ele1.label.localeCompare(ele2.label));
                    this.individualOptions = [
                        {"label": "None",
                            "name": "",
                            "value": ""},
                        ...this.individualOptions
                    ];
                    this.companyFields = [...this.MYOBFields];
                    if (this.oldSelectedValue !== this.selectedValue) {
                        this.companyFields.forEach((item) => {
                            item.value = "";
                        });
                        this.companyObjectFields = [];
                    }
                    this.companyObjectFields = [...this.Objectfields];
                    this.handleIndividualSelectOption();
                    this.companyRequiredField = this.Objectfields.filter((field) => !field.required && ![
                        "REFERENCE",
                        "BOOLEAN"
                    ].includes(field.fieldType));
                    this.showCompanyPicklist = true;
                } else if (objectType === "Individual") {
                    this.individualFields = [...this.MYOBFields];
                    if (this.oldIndividualSelectedValue !== this.individualSelectedValue) {
                        this.individualFields.forEach((item) => {
                            item.value = "";
                        });
                        this.individualObjectFields = [];
                    }
                    this.individualObjectFields = [...this.Objectfields];
                    this.individualRequiredField = this.Objectfields.filter((field) => !field.required && ![
                        "REFERENCE",
                        "BOOLEAN"
                    ].includes(field.fieldType));
                    this.showIndividualPicklist = true;
                }
                if(!(this.saveContactsDifferently) && objectType === "Company"){
                    this.showLoading = false;
                }else if((this.saveContactsDifferently) && objectType === "Individual"){
                    this.showLoading = false;
                }
            }).
            catch((error) => {
                this.error = error;
                this.showLoading = false;
            });
        }
    }

    comboBoxContactLabels(event){
        this.showLoading = true;
        this.disableSave = false;
        try{
            var checkboxValue = event.target.checked;
            this.saveContactsDifferently = checkboxValue;
            if(checkboxValue){
                this.placeHolder = "Please Select Contact Company Object";
                this.label = "Search and Select Object to store Company";
            }else{
                this.placeHolder = "Please Select Contact Object for both Company and Individual";
                this.label = "Search and Select Object to store Company and Individual";
            }
        }
        catch(error){
            this.showLoading = false;
        }
        this.showLoading = false;
    }

    handleCompanySelectOption (event) {
        try{
            this.showLoading = true;
            this.objectType = "Company";
            this.selectedCompanyLabel = this.options[this.options.findIndex((row) => row.value === event.detail)].label;
            this.selectedValue = event.detail;
            if (this.selectedValue) {
                this.fetchObjectNfields(
                    this.selectedValue,
                    "Company"
                );
            }
            this.showLoading = false;
        }
        catch(error){
            this.showToastPopMessage(
                `Something went wrong. Error - ${error}`,
                "error"
            );
            this.showLoading = false;
        }
    }

    mapCompanyFields (event) {
        try {
            this.selectObjectLabel = this.selectedCompanyLabel;
            this.objectType = "Company";
            this.modalHeader = "Map Company Object Fields";
            if(this.saveContactsDifferently){
                this.MYOBFields = this.companyFields.filter(field => field.label !== 'First Name' && field.label !== 'Last Name');
            }else{
                this.MYOBFields = [...this.companyFields];
            }
            this.openModal();
        } catch (error) {
            /* Empty */
        }
    }

    handleIndividualNew (event) {
        debugger;
        this.individualSelectedValue = event.detail;
        this.individualObjectFields = [];
        this.individualFields.forEach((item) => {
            item.value = "";
        });
    }

    handleIndividualSelectOption (event) {
        this.showLoading = true;
        if (event) {
            this.selectedIndividualLabel = this.options[this.options.findIndex((row) => row.value === event.detail)].label;
            this.individualSelectedValue = event.detail;
        }
        if (this.individualSelectedValue) {
            this.fetchObjectNfields(
                this.individualSelectedValue,
                "Individual"
            );
        }
        this.showLoading = false;
    }

    mapIndividualFields(){
        this.selectObjectLabel = this.selectedIndividualLabel;
        this.objectType = "Individual";
        this.modalHeader = "Map Individual Object Fields";
        this.MYOBFields = [...this.individualFields];
        this.openModal();
    }

    handleFieldChange(event){
        debugger;
        const configName = event.target.dataset.configname,
              selectedValue = event.detail.value;
        let fieldConfigIndex = "";
        if (this.objectType === "Company") {

            fieldConfigIndex = this.companyFields.findIndex((field) => field.label === configName);
            this.companyFields[fieldConfigIndex].value = selectedValue;

        } else if (this.objectType === "Individual") {

            fieldConfigIndex = this.individualFields.findIndex((field) => field.label === configName);
            this.individualFields[fieldConfigIndex].value = selectedValue;

        }
        
    }

    openModal () {

        // To open modal set isModalOpen track value as true
        this.isModalOpen = true;
        this.showLoadingModal = false;

    }

    closeModal () {

        this.disableSave = false;
        this.isModalOpen = false;

    }

    cancelModal () {

        this.closeModal();

    }

    clearMapping () {

        if (this.objectType === "Company") {

            this.companyFields = this.MYOBFields.map((field) => ({...field,
                "value": ""}));
            this.MYOBFields = this.MYOBFields.map((field) => ({...field,
                "value": ""}));

        } else if (this.objectType === "Individual") {

            this.individualFields = this.MYOBFields.map((field) => ({...field,
                "value": ""}));
            this.MYOBFields = this.MYOBFields.map((field) => ({...field,
                "value": ""}));

        }

    }

    handleSave () {
        try {
            this.showLoading = true;
            let checkFielding = true,
                objectName = "",
                requireField = "";
            if (this.selectedValue && checkFielding === true) {
                checkFielding = this.companyRequiredField.every((field) => {
                    requireField = field.label;
                    if (this.selectObjectLabel) {
                        objectName = this.selectObjectLabel;
                    } else {
                        objectName = "";
                    }
                    return this.companyFields.some((item) => item.value === field.value);
                });
            }else if (this.individualSelectedValue && checkFielding === true) {
                checkFielding = this.individualRequiredField.every((field) => {
                    requireField = field.label;
                    if (this.individualSelectedLabel) {
                        objectName = this.individualSelectedLabel;
                    } else {
                        objectName = "";
                    }
                    return this.individualFields.some((item) => item.value === field.value);
                });
            }
            const CompanyRequireField = this.companyFields.filter((item) => item.require === true && !item.value),
                  IndividualRequireField = this.individualFields.filter((item) => item.require === true && !item.value);
            if (checkFielding === false && objectName !== "" && requireField !== "") {
                const message = `Please map the following required Salesforce fields of ${objectName}: ${requireField}`;
                this.showToastPopMessage(
                    message,
                    "error"
                );
                this.showLoading = false;
            } else if (CompanyRequireField.length > ZERO_NUM) {
                const fieldNames = CompanyRequireField.map((item) => item.label),
                    message = `Please map the following required MYOB Company fields : ${fieldNames.join(", ")}`;
                this.showToastPopMessage(
                    message,
                    "error"
                );
                this.showLoading = false;
            } else if (IndividualRequireField.length > ZERO_NUM) {
                const fieldNames = IndividualRequireField.map((item) => item.label),
                    message = `Please map the following required MYOB Individual fields : ${fieldNames.join(", ")}`;
                this.showToastPopMessage(
                    message,
                    "error"
                );
                this.showLoading = false;
            } else {
                updateContactConfig({
                    "companyObject": this.selectedValue,
                    "individualObject": this.individualSelectedValue,
                    "saveContactsDifferently": this.saveContactsDifferently}).
                    then((result) => {
                    if (result) {
                        console.log('$$$ this.companyFields: ', this.companyFields);
                        console.log('$$$ this.companyFields: ', JSON.stringify(this.companyFields));
                        this.saveObjectSetting(
                            this.companyFields,
                            "Company" 
                        );
                        this.saveObjectSetting(
                            this.individualFields,
                            "Individual"
                        );
                        this.showToastPopMessage(
                            "Contact Configuration is Updated",
                            "success"
                        );
                        requireField = "";
                        checkFielding = true;
                        objectName = "";
                        this.showLoading = false;
                    } else {
                        this.showToastPopMessage(
                            "Something went wrong updateContactConfig returns False",
                            "error"
                        );
                        this.showLoading = false;
                    }
                    this.closeModal();
                }).
                catch((error) => {
                    this.showLoading = false;
                    this.showToastPopMessage(
                        error.body.message,
                        "error"
                    );
                });
            }
            this.disableSave = true;
        } catch (error) {
            /* Empty */
        }
    }

    saveObjectSetting (objFields, objType) {
        saveObjectConfiguration({
            "objectFields": objFields,
            "objectType": objType
        });

    }


    showToastPopMessage (messageParam, variantParam) {

        if (typeof window !== 'undefined') {

            this.dispatchEvent(new ShowToastEvent({
                "message": messageParam,
                "title": "Contact Configuration",
                "variant": variantParam
            }));

        }

    }
}