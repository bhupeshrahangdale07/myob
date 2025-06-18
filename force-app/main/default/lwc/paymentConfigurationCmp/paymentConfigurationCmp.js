import { LightningElement, track } from 'lwc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import getPaymentConfiguration from "@salesforce/apex/PaymentConfigController.getPaymentConfiguration";
import getObjectList from "@salesforce/apex/PaymentConfigController.getObjectList";
import getPaymentCusSettingFields from "@salesforce/apex/PaymentConfigController.getPaymentCusSettingFields";
import updatePaymentConfig from "@salesforce/apex/PaymentConfigController.updatePaymentConfig";
import saveObjectConfiguration from "@salesforce/apex/PaymentConfigController.saveObjectConfiguration";
const  DELAY1000 = 1000,
       ZERO_NUM = 0;

export default class PaymentConfigurationCmp extends LightningElement {
    @track showPaymentPicklist = false;
    @track MYOBFields = [];
    @track paymentOptions ;
    @track paymentFields = [];
    @track isModalOpen = false;
    showLoading = false;
    componentTitle = "Payment Configuration";
    subTitleOne = "MYOB PAYMENT DEFAULT OBJECT AND FIELD MAPPING SETTING";
    headingOne = "Search and Select Object to store Payment and map Object fields";
    paymentConfig;
    paymentObjectSelected = "";
    oldPaymentObjectSelected = "";
    selectedPaymentLabel = "";
    Objectfields = [];
    paymentObjectFields = [];
    paymentRequiredField = [];
    objectType = "";
    modalHeader = "";
    disableSave = true;

    connectedCallback(){
        console.clear();
        this.showLoading = true;
        this.paymentConfiguration();
        const timevar = setTimeout(
            () => {

                this.showLoading = false;

            },
            DELAY1000
        );
    }

    // Get Invoice Configuration from custom metadata using apex class
    // Return - Custom Setting (KTMYOB__Invoice_Fields_Mapping__c, KTMYOB__LineItem_Fields_Mapping__c & KTMYOB__MYOB_Objects_Configurations__c)
    paymentConfiguration(){
        getPaymentConfiguration({}).
            then((result) => {
                if (result === null) {

                    this.showToastPopMessage(
                        "Something Went Wrong. Please check related Custom Setting.",
                        "error"
                    );
                    this.showLoading = false;

                } else {
                    console.log('$$$ getPaymentConfiguration: ', result);
                    this.paymentConfig = result;
                    this.paymentObjectSelected = result.objConfigSetting.KTMYOB__Payment_Object_Api_Name__c;
                    this.oldPaymentObjectSelected = result.objConfigSetting.KTMYOB__Payment_Object_Api_Name__c;
                    this.selectedPaymentLabel = result.paymentLabelSetting;
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
                this.paymentOptions = sObject;
                this.paymentOptions.sort((ele1, ele2) => ele1.label.localeCompare(ele2.label));
                this.showPaymentPicklist = true;
                if (this.paymentObjectSelected !== null) {

                    this.fetchObjectNfields(
                        this.paymentObjectSelected,
                        "Payment"
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
            getPaymentCusSettingFields({"objectApiName": selectedObject, "type": objectType}).
            then((result) => {
                console.log('### getPaymentCusSettingFields result = ',result);
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
                if (objectType === "Payment") {
                    this.paymentFields = [...this.MYOBFields];
                    if (this.oldPaymentObjectSelected !== this.paymentObjectSelected) {

                        this.paymentFields.forEach((item) => {

                            item.value = "";

                        });
                        this.paymentObjectFields = [];

                    }
                    this.paymentObjectFields = [...this.Objectfields];
                    this.showPaymentPicklist = true;
                    this.paymentRequiredField = this.Objectfields.filter((field) => !field.required && ![
                        "REFERENCE",
                        "BOOLEAN"
                    ].includes(field.fieldType));
                    console.log('$$$ paymentRequiredField = ',this.paymentRequiredField);

                }
            }).
            catch((error) => {

                this.error = error;
                this.showLoading = false;

            });
        }

    }
    
    handlePaymentSelectedOption (event) {
        try{
            this.showLoading = true;
            this.objectType = "Payment";
            this.selectedPaymentLabel = this.paymentOptions[this.paymentOptions.findIndex((row) => row.value === event.detail)].label;
            this.paymentObjectSelected = event.detail;
            if (this.paymentObjectSelected) {
    
                this.fetchObjectNfields(
                    this.paymentObjectSelected,
                    "Payment"
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

    mapPaymentFields (event) {
        try {
            this.selectObjectLabel = this.selectedPaymentLabel;
            this.objectType = "Payment";
            this.modalHeader = "Map Payment Object Fields";
            this.MYOBFields = [...this.paymentFields];
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
        if (this.objectType === "Payment") {

            fieldConfigIndex = this.paymentFields.findIndex((field) => field.label === configName);
            this.paymentFields[fieldConfigIndex].value = selectedValue;

        }
        
    }

    clearMapping () {

        if (this.objectType === "Payment") {

            this.paymentFields = this.MYOBFields.map((field) => ({...field,
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
            if (this.paymentObjectSelected && checkFielding === true) {
                checkFielding = this.paymentRequiredField.every((field) => {

                    requireField = field.label;
                    if (this.selectObjectLabel) {

                        objectName = this.selectObjectLabel;

                    } else {

                        objectName = "";

                    }
                    return this.paymentFields.some((item) => item.value === field.value);

                });

            }
            
            const PaymentRequireField = this.paymentFields.filter((item) => item.require === true && !item.value);
            if (checkFielding === false && objectName !== "" && requireField !== "") {

                const message = `Please map the following required Salesforce fields of ${objectName}: ${requireField}`;
                this.showToastPopMessage(
                    message,
                    "error"
                );
                this.showLoading = false;

            } else if (PaymentRequireField.length > ZERO_NUM) {

                const fieldNames = PaymentRequireField.map((item) => item.label),
                    message = `Please map the following required MYOB Payment fields : ${fieldNames.join(", ")}`;
                this.showToastPopMessage(
                    message,
                    "error"
                );
                this.showLoading = false;

            }else {
                updatePaymentConfig({
                    "paymentObject": this.paymentObjectSelected,
                }).then((result) => {

                    if (result) {
                        this.saveObjectSetting(
                            this.paymentFields,
                            "Payment"
                        );
                        this.showToastPopMessage(
                            "Payment Configuration is Updated",
                            "success"
                        );
                        requireField = "";
                        checkFielding = true;
                        objectName = "";
                        this.showLoading = false;

                    } else {
                        this.showToastPopMessage(
                            "Something went wrong updatePaymentConfig returns False",
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
                "title": "Payment Configuration",
                "variant": variantParam
            }));

        }

    }

}