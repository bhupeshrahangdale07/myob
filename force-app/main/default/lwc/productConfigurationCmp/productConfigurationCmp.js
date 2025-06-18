import { LightningElement, track, wire } from 'lwc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import getProductConfiguration from "@salesforce/apex/ProductConfigController.getProductConfiguration";
import getObjectList from "@salesforce/apex/ProductConfigController.getObjectList";
import getInvoiceCusSettingFields from "@salesforce/apex/ProductConfigController.getInvoiceCusSettingFields";
import updateProductConfig from "@salesforce/apex/ProductConfigController.updateProductConfig";
import saveObjectConfiguration from "@salesforce/apex/ProductConfigController.saveObjectConfiguration";
import isProductSyncComponentVisible from '@salesforce/apex/ProductConfigController.isProductSyncComponentVisible';
const  DELAY1000 = 1000,
       ZERO_NUM = 0;

export default class ProductConfigurationCmp extends LightningElement {
    @track showProductPicklist = false;
    @track MYOBFields = [];
    @track productOptions ;
    @track productFields = [];
    @track isModalOpen = false;
    showLoading = false;
    componentTitle = "Product Configuration";
    subTitleOne = "MYOB PRODUCT DEFAULT OBJECT AND FIELD MAPPING SETTING";
    subTitleTwo = "SELECT ITEMS WITH CONFIGURATIONS";
    headingOne = "Search and Select Object to store Product and map Object fields";
    headingTwo = "Select Item Type from below List";
    productConfig;
    productObjectSelected = "";
    oldProductObjectSelected = "";
    selectedProductLabel = "";
    Objectfields = [];
    invoiceObjectFields = [];
    invoiceRequiredField = [];
    objectType = "";
    modalHeader = "";
    disableSave = true;
    mappingConfirmation = false;

    isVisible=false;

    connectedCallback(){
        console.clear();
        this.showLoading = true;
        this.fetchVisibility();
        this.productConfiguration();
        const timevar = setTimeout(
            () => {

                this.showLoading = false;

            },
            DELAY1000
        );
    }

    // Get Invoice Configuration from custom metadata using apex class
    // Return - Custom Setting (KTMYOB__Invoice_Fields_Mapping__c, KTMYOB__LineItem_Fields_Mapping__c & KTMYOB__MYOB_Objects_Configurations__c)
    productConfiguration(){
        getProductConfiguration({}).
        then((result) => {

            if (result === null) {

                this.showToastPopMessage(
                    "Something Went Wrong. Please check related Custom Setting.",
                    "error"
                );
                this.showLoading = false;

            } else {
                console.log('$$$ getProductConfiguration: ', result);
                this.productConfig = result;
                this.productObjectSelected = result.objConfigSetting.KTMYOB__Product_Object_Api_Name__c;
                if(this.productObjectSelected){
                    this.mappingConfirmation = true;
                }
                this.oldProductObjectSelected = result.objConfigSetting.KTMYOB__Product_Object_Api_Name__c;
                this.selectedProductLabel = result.productLabelSetting;
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
                this.productOptions = sObject;
                this.productOptions.sort((ele1, ele2) => ele1.label.localeCompare(ele2.label));
                this.showProductPicklist = true;
                if (this.productObjectSelected !== null) {

                    this.fetchObjectNfields(
                        this.productObjectSelected,
                        "Product"
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
                if (objectType === "Product") {
                    this.productFields = [...this.MYOBFields];
                    if (this.oldProductObjectSelected !== this.productObjectSelected) {

                        this.productFields.forEach((item) => {

                            item.value = "";

                        });
                        this.invoiceObjectFields = [];

                    }
                    this.invoiceObjectFields = [...this.Objectfields];
                    this.showProductPicklist = true;
                    this.invoiceRequiredField = this.Objectfields.filter((field) => !field.required && ![
                        "REFERENCE",
                        "BOOLEAN"
                    ].includes(field.fieldType));
                    console.log('$$$ invoiceRequiredField = ',this.invoiceRequiredField);

                }

            }).
            catch((error) => {

                this.error = error;
                this.showLoading = false;

            });
        }

    }
    
    handleProductSelectedOption (event) {
        try{
            this.showLoading = true;
            this.objectType = "Product";
            this.selectedProductLabel = this.productOptions[this.productOptions.findIndex((row) => row.value === event.detail)].label;
            this.productObjectSelected = event.detail;
            if (this.productObjectSelected) {
    
                this.fetchObjectNfields(
                    this.productObjectSelected,
                    "Product"
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

    mapProductFields (event) {
        try {
            this.selectObjectLabel = this.selectedProductLabel;
            this.objectType = "Product";
            this.modalHeader = "Map Product Object Fields";
            this.MYOBFields = [...this.productFields];
            this.openModal();

        } catch (error) {

            /* Empty */
        }
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
        if (this.objectType === "Product") {

            fieldConfigIndex = this.productFields.findIndex((field) => field.label === configName);
            this.productFields[fieldConfigIndex].value = selectedValue;

        }
        
    }

    clearMapping () {

        if (this.objectType === "Product") {

            this.productFields = this.MYOBFields.map((field) => ({...field,
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
            debugger;
            this.showLoading = true;
            
            let checkFielding = true,
                objectName = "",
                requireField = "";
            if (this.productObjectSelected && checkFielding === true) {
                checkFielding = this.invoiceRequiredField.every((field) => {

                    requireField = field.label;
                    if (this.selectObjectLabel) {

                        objectName = this.selectObjectLabel;

                    } else {

                        objectName = "";

                    }
                    return this.productFields.some((item) => item.value === field.value);

                });

            }

            const ProductRequireField = this.productFields.filter((item) => item.require === true && !item.value);
            if (checkFielding === false && objectName !== "" && requireField !== "") {

                const message = `Please map the following required Salesforce fields of ${objectName}: ${requireField}`;
                this.showToastPopMessage(
                    message,
                    "error"
                );
                this.showLoading = false;

            } else if (ProductRequireField.length > ZERO_NUM) {

                const fieldNames = ProductRequireField.map((item) => item.label),
                    message = `Please map the following required MYOB Product fields : ${fieldNames.join(", ")}`;
                this.showToastPopMessage(
                    message,
                    "error"
                );
                this.showLoading = false;

            }else {
                updateProductConfig({
                    "productObject": this.productObjectSelected,
                }).
                then((result) => {

                    if (result) {
                        this.saveObjectSetting(
                            this.productFields,
                            "Product"
                        );
                        this.showToastPopMessage(
                            "Product Configuration is Updated",
                            "success"
                        );
                        requireField = "";
                        checkFielding = true;
                        objectName = "";
                        this.showLoading = false;

                    } else {
                        this.showToastPopMessage(
                            "Something went wrong updateProductConfig returns False",
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
                "title": "Product Configuration",
                "variant": variantParam
            }));

        }

    }

    // Mangesh Review
    fetchVisibility() {
        isProductSyncComponentVisible()
            .then(data => {
                this.isVisible = data; // True or False from Apex
                console.log('value: ', this.isVisible);
            })
            .catch(error => {
                console.error('Error fetching custom setting:', error);
            });
    }
   // Mangesh Review

}