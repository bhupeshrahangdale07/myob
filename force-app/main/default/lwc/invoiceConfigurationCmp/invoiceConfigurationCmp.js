import { LightningElement, track } from 'lwc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import getInvoiceConfiguration from "@salesforce/apex/InvoiceConfigController.getInvoiceConfiguration";
import getObjectList from "@salesforce/apex/InvoiceConfigController.getObjectList";
import getInvoiceCusSettingFields from "@salesforce/apex/InvoiceConfigController.getInvoiceCusSettingFields";
import updateContactConfig from "@salesforce/apex/InvoiceConfigController.updateContactConfig";
import saveObjectConfiguration from "@salesforce/apex/InvoiceConfigController.saveObjectConfiguration";
import fetchAllTaxCodesFromMYOB from "@salesforce/apex/MYOB_MetaDataDynamicController.fetchAllTaxCodesFromMYOB";
const  DELAY1000 = 1000,
       ZERO_NUM = 0;
       
export default class InvoiceConfigurationCmp extends LightningElement {
    @track saveContactsDifferently = "";
    @track showInvoicePicklist = false;
    //@track showLineItemPicklist = false;
    @track MYOBFields = [];
    @track invoiceOptions ;
    @track lineitemOptions ;
    @track invoiceFields = [];
    @track lineitemFields = [];
    @track isModalOpen = false;
    showLoading = false;
    componentTitle = "Invoice Configuration";
    subTitleOne = "MYOB INVOICE DEFAULT OBJECT AND FIELD MAPPING SETTING";
    headingOne = "Search and Select Object to store Invoice and map Object fields";
    subTitleTwo="Sync all the related items and metatdata from MYOB to Salesforce";
    headingTwo="Click on the sync button to following items and metatdata from MYOB to Salesforce";
    invoiceConfig;
    invoiceObjectSelected = "";
    oldInvoiceObjectSelected = "";
    selectedInvoiceLabel = "";
    lineitemObjectSelected = "";
    oldLineItemObjectSelected = "";
    selectedLineItemLabel = "";
    Objectfields = [];
    invoiceObjectFields = [];
    invoiceRequiredField = [];
    lineitemObjectFields = [];
    lineitemRequiredField = [];
    objectType = "";
    modalHeader = "";
    disableSave = true;

    connectedCallback(){
        console.clear();
        this.showLoading = true;
        this.invoiceConfiguration();
    }

    // Get Invoice Configuration from custom metadata using apex class
    // Return - Custom Setting (KTMYOB__Invoice_Fields_Mapping__c, KTMYOB__LineItem_Fields_Mapping__c & KTMYOB__MYOB_Objects_Configurations__c)
    invoiceConfiguration(){
        getInvoiceConfiguration({}).
        then((result) => {
            if (result === null) {
                this.showToastPopMessage(
                    "Something Went Wrong. Please check related Custom Setting.",
                    "error"
                );
                this.showLoading = false;
            } else {
                console.log('$$$ getInvoiceConfiguration: ', result);
                this.invoiceConfig = result;
                this.invoiceObjectSelected = result.objConfigSetting.KTMYOB__Invoice_Object_Api_Name__c;
                this.oldInvoiceObjectSelected = result.objConfigSetting.KTMYOB__Invoice_Object_Api_Name__c;
                this.selectedInvoiceLabel = result.invoiceLabelSetting;
                this.lineitemObjectSelected = result.objConfigSetting.KTMYOB__LineItem_Object_Api_Name__c;
                this.oldLineItemObjectSelected = result.objConfigSetting.KTMYOB__LineItem_Object_Api_Name__c;
                this.selectedLineItemLabel = result.lineitemLabelSetting;
                this.saveContactsDifferently = result.objConfigSetting.KTMYOB__Save_Contacts_in_Different_Object__c;
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
    getObjectFields () {
        getObjectList({}).
        then((data) => {
            if (data) {
                const sObject = [...data];
                this.invoiceOptions = sObject;
                this.invoiceOptions.sort((ele1, ele2) => ele1.label.localeCompare(ele2.label));
                this.showInvoicePicklist = true;
                if (this.invoiceObjectSelected !== null) {
                    this.fetchObjectNfields(
                        this.invoiceObjectSelected,
                        "Invoice"
                    );
                }
            }
        }).
        catch((error) => {
            console.log('$$$ Error', error);
            this.showToastPopMessage(
                `Something went wrong. Error - ${error}`,
                "error"
            );
            this.showLoading = false;
        });
    }

    fetchObjectNfields (selectedObject, objectType) {
        if (selectedObject) {
            getInvoiceCusSettingFields({"objectApiName": selectedObject, "type": objectType}).
            then((result) => {
                console.log('### getInvoiceCusSettingFields result = ',result);
                this.Objectfields = result.Objectfields;
                console.log('$$$ Objectfields = ',result.Objectfields);
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
                console.log('$$$ MYOBFields = ',JSON.stringify(this.MYOBFields));
                this.MYOBFields.forEach((item) => {
                    const dataType = (item.type || "").split(","),
                            noneOption = {"fieldType": "",
                                        "label": "Select Fields",
                                        "referencedObjectApiName": "",
                                        "required": true,
                                        "value": ""
                                    };
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
                if (objectType === "Invoice") {
                    this.lineitemOptions = aObjectRes.childObjects;
                    this.lineitemOptions.sort((ele1, ele2) => ele1.label.localeCompare(ele2.label));
                    this.lineitemOptions = [
                        {"label": "None",
                            "name": "",
                            "value": ""},
                        ...this.lineitemOptions
                    ];
                    this.invoiceFields = [...this.MYOBFields];
                    console.log('$$$ invoiceFields', JSON.stringify(this.invoiceFields));
                    if (this.oldInvoiceObjectSelected !== this.invoiceObjectSelected) {
                        this.invoiceFields.forEach((item) => {
                            item.value = "";
                        });
                        this.invoiceObjectFields = [];
                    }
                    this.invoiceObjectFields = [...this.Objectfields];
                    this.showInvoicePicklist = true;
                    this.handleLineItemSelectOption();
                    this.invoiceRequiredField = this.Objectfields.filter((field) => !field.required && ![
                        "REFERENCE",
                        "BOOLEAN"
                    ].includes(field.fieldType));
                    //console.log('$$$ invoiceRequiredField = ',JSON.stringify(this.invoiceRequiredField));
                }else if (objectType === "LineItem") {
                    this.lineitemFields = [...this.MYOBFields];
                    console.log('$$$ lineitemFields = ',JSON.stringify(this.lineitemFields));
                    if (this.oldLineItemObjectSelected !== this.lineitemObjectSelected) {
                        this.lineitemFields.forEach((item) => {
                            item.value = "";
                        });
                        this.lineitemObjectFields = [];
                    }
                    this.lineitemObjectFields = [...this.Objectfields];
                    //this.showLineItemPicklist = true;
                    this.showLoading = false;
                    this.lineitemRequiredField = this.Objectfields.filter((field) => !field.required && ![
                        "REFERENCE",
                        "BOOLEAN"
                    ].includes(field.fieldType));
                }
            }).
            catch((error) => {
                this.error = error;
                this.showLoading = false;

            });
        }
    }

    handleInvoiceSelectedOption (event) {
        try{
            this.showLoading = true;
            this.objectType = "Invoice";
            this.selectedInvoiceLabel = this.invoiceOptions[this.invoiceOptions.findIndex((row) => row.value === event.detail)].label;
            this.invoiceObjectSelected = event.detail;
            if (this.invoiceObjectSelected) {
    
                this.fetchObjectNfields(
                    this.invoiceObjectSelected,
                    "Invoice"
                );
    
            }
            this.showLoading = false;
        }
        catch{
            this.showToastPopMessage(
                `Something went wrong. Error - ${error}`,
                "error"
            );
            this.showLoading = false;
        }
    }

    mapInvoiceFields (event) {
        try {
            this.selectObjectLabel = this.selectedInvoiceLabel;
            this.objectType = "Invoice";
            this.modalHeader = "Map Invoice Object Fields";
            if(this.saveContactsDifferently){
                this.MYOBFields = [...this.invoiceFields];
            }else{
                this.MYOBFields = this.invoiceFields.filter(field => field.label !== 'Contact Individual UID');
            }
            this.openModal();
        } catch (error) {
            /* Empty */
        }
    }

    handleLineItemNew(event){
        debugger;
        this.lineitemObjectSelected = event.detail;
        this.lineitemObjectFields = [];
        this.lineitemFields.forEach((item) => {
            item.value = "";
        });
    }

    handleLineItemSelectOption(event){
        debugger;
        this.showLoading = true;
        try{
            if (event) {
                this.selectedLineItemLabel = this.lineitemOptions[this.lineitemOptions.findIndex((row) => row.value === event.detail)].label;
                this.lineitemObjectSelected = event.detail;
            }
            if (this.lineitemObjectSelected) {
                this.fetchObjectNfields(
                    this.lineitemObjectSelected,
                    "LineItem"
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

    mapLineItemFields(){
        this.selectObjectLabel = this.selectedLineItemLabel;
        this.objectType = "LineItem";
        this.modalHeader = "Map LineItem Object Fields";
        this.MYOBFields = [...this.lineitemFields];
        this.openModal();
    }

    openModal () {
        // To open modal set isModalOpen track value as true
        this.isModalOpen = true;
        this.showLoadingModal = false;
    }

    handleFieldChange(event){
        const configName = event.target.dataset.configname,
              selectedValue = event.detail.value;
        let fieldConfigIndex = "";
        if (this.objectType === "Invoice") {

            fieldConfigIndex = this.invoiceFields.findIndex((field) => field.label === configName);
            this.invoiceFields[fieldConfigIndex].value = selectedValue;

        } else if (this.objectType === "LineItem") {

             fieldConfigIndex = this.lineitemFields.findIndex((field) => field.label === configName);
             this.lineitemFields[fieldConfigIndex].value = selectedValue;
        }
    }

    clearMapping () {
        if (this.objectType === "Invoice") {
            this.invoiceFields = this.MYOBFields.map((field) => ({...field,
                "value": ""}));
            this.MYOBFields = this.MYOBFields.map((field) => ({...field,
                "value": ""}));
        } else if (this.objectType === "LineItem") {
            this.lineitemFields = this.MYOBFields.map((field) => ({...field,
                "value": ""}));
            this.MYOBFields = this.MYOBFields.map((field) => ({...field,
                "value": ""}));
        }
    }

    closeModal () {
        this.disableSave = false;
        this.isModalOpen = false;
    }

    cancelModal () {
        this.closeModal();
    }

    handleSave () {
        try {
            this.showLoading = true;
            let checkFielding = true,
                objectName = "",
                requireField = "";
            if (this.invoiceObjectSelected && checkFielding === true) {
                checkFielding = this.invoiceRequiredField.every((field) => {
                    requireField = field.label;
                    if (this.selectObjectLabel) {
                        objectName = this.selectObjectLabel;
                    } else {
                        objectName = "";
                    }
                    return this.invoiceFields.some((item) => item.value === field.value);
                });
            }else if (this.lineitemObjectSelected && checkFielding === true) {
                checkFielding = this.lineitemRequiredField.every((field) => {
                    requireField = field.label;
                    if (this.selectedLineItemLabel) {
                        objectName = this.selectedLineItemLabel;
                    } else {
                        objectName = "";
                    }
                    return this.lineitemFields.some((item) => item.value === field.value);
                });
            }
            const InvoiceRequireField = this.invoiceFields.filter((item) => item.require === true && !item.value),
                  LineItemRequireField = this.lineitemFields.filter((item) => item.require === true && !item.value);
            if (checkFielding === false && objectName !== "" && requireField !== "") {
                const message = `Please map the following required Salesforce fields of ${objectName}: ${requireField}`;
                this.showToastPopMessage(
                    message,
                    "error"
                );
                this.showLoading = false;
            } else if (InvoiceRequireField.length > ZERO_NUM) {
                const fieldNames = InvoiceRequireField.map((item) => item.label),
                    message = `Please map the following required MYOB Invoice fields : ${fieldNames.join(", ")}`;
                this.showToastPopMessage(
                    message,
                    "error"
                );
                this.showLoading = false;
            } else if (LineItemRequireField.length > ZERO_NUM) {
                const fieldNames = LineItemRequireField.map((item) => item.label),
                    message = `Please map the following required MYOB LineItem fields : ${fieldNames.join(", ")}`;
                this.showToastPopMessage(
                    message,
                    "error"
                );
                this.showLoading = false;

            } else {
                updateContactConfig({
                    "invoiceObject": this.invoiceObjectSelected,
                    "lineitemObject": this.lineitemObjectSelected,
                }).then((result) => {

                    if (result) {
                        this.saveObjectSetting(
                            this.invoiceFields,
                            "Invoice"
                        );
                        this.saveObjectSetting(
                            this.lineitemFields,
                            "LineItem"
                        );
                        this.showToastPopMessage(
                            "Invoice Configuration is Updated",
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
                    console.log('### Error: ',error);
                    console.log('### Error: ',JSON.stringify(error));
                    this.showLoading = false;
                    // this.showToastPopMessage(
                    //     error.body.message,
                    //     "error"
                    // );

                });
            }
            this.disableSave = true;
        } catch (error) {
            /* Empty */
        }
    }

    saveObjectSetting (objFields, objType) {
        setTimeout(
            () => {

                /* Do nothing*/
            },
            DELAY1000
        );
        saveObjectConfiguration({
            "objectFields": objFields,
            "objectType": objType
        });

    }

    showToastPopMessage (messageParam, variantParam) {

        if (typeof window !== 'undefined') {

            this.dispatchEvent(new ShowToastEvent({
                "message": messageParam,
                "title": "Invoice Configuration",
                "variant": variantParam
            }));

        }

    }


    get mappingConfirmation(){
        if(this.lineitemObjectSelected && this.invoiceObjectSelected){
            return true;
        }
        return false;
    }

    handleRefresh (event) {
        const {name} = event.target;
        if (name === "taxcodes") {
            this.taxCodeSync();
        }
    }

    taxCodeSync () {
        this.showLoading = true;
        fetchAllTaxCodesFromMYOB({}).
        then((result) => {
            if (result === 'Success') {
                this.showToastPopMessage(
                    "MYOB Tax codes, successfully synced with Salesforce",
                    "success");
            }else if(result === 'Failed') {
                this.showToastPopMessage(
                    "MYOB Tax codes,failed to sync with Salesforce",
                    "error");
            }
            this.showLoading = false;
        }).
        catch((error)=>{
             this.showToastPopMessage(
                `Something went wrong. Error - ${error}`,
                "error");
            this.showLoading = false;
        });
    }

}