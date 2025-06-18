import { LightningElement, track } from 'lwc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import createAuthProvider from '@salesforce/apex/SetupConfigController.createAuthProvider';
import getSetupConfiguration from '@salesforce/apex/SetupConfigController.getSetupConfiguration';
import fetchCompanyFiles from '@salesforce/apex/MYOB_Component_Helper_cls.fetchCompanyFiles';
import saveUIToSf from '@salesforce/apex/SetupConfigController.saveUIToSf';
const ZERO = 0;

export default class ConnectionResetCmp extends LightningElement {

    showMYOBConnection = false;
    showMYOBCompanyFile = false;

    subTitleOne = "RESET CONNECTION";
    subTitleTwo = "RESET COMPANYFILE CONNECTION";
    subSubtitleOne = "MYOB ACCOUNT CONNECTION";
    descriptionOne = "Please provide necessary details in case of resetting connection between Salesforce and Quickbook.";
    descriptionTwo = "To connect your Salesforce Org account and MYOB account, please input the Quickbook CLient ID below. Please click the \"Show Instructions\" button below to view the directions for getting this.";
    descriptionThree = "Please provide necessary details in case of resetting MYOB company file connection with Salesforce.";
    descriptionFour = "Steps for Resetting MYOBs ComapnyFile Connection with Salesforce:";
    
    @track showLoading;
    consumerId;
    consumerSecret;
    disableInput = true;
    disableCompanyFileInput = true;
    showAuthReset = true;
    showAuthSaveBtn = false;
    showFileReset = true;
    showFileSaveBtn = false;
    disableAuthSaveBtn = true;
    disableFileSaveBtn = true;
    companyFileValue;
    companyFileOptions = [];
    baseUrl;

    connectedCallback () {
        this.disableInput = true;
        this.disableCompanyFileInput = true;
        this.showWebhookSteps = false;
        this.showModal = false;
        this.showLoading = true;
        if (typeof window !== 'undefined') {
            //this.redirectUrl = `${window.location.origin}/apex/MYOB_OAuth_RedirectPage`;
            this.redirectUrl = `https://myob-d-dev-ed--ktmyob.develop.vf.force.com/apex/MYOB_OAuth_RedirectPage`;
        }
        this.redirectUrlLabel = `Copy Redirect URL ${  this.redirectUrl } into the Redirect Url in MYOB setting`;
        this.getConfiguration();
    }
    
    getConfiguration(){
        getSetupConfiguration({})
        .then(result => {
            if(result){
                this.setupConfig = result;
                this.consumerId = result.clientId;
                this.consumerSecret = result.clientSecret;
                this.baseUrl = result.baseUrl;
                this.fetchAllCompanyFiles();
			}
        })
		.catch(error => {
            this.error = error;
            this.showLoading = false;
            this.showToast(error, 'dismissable', 'Something Went Wrong in getSetupConfiguration','error');
        })
	}

    updateAuthValue(event){
        if(event.target.name === 'Client ID'){
            this.consumerId = event.target.value.trim();
        }else if(event.target.name === 'Client Secret'){
            this.consumerSecret = event.target.value.trim();
        }
        if(this.consumerId !== null && this.consumerId !== '' && typeof this.consumerId !== 'undefined' &&
            this.consumerSecret !== null && this.consumerSecret !== '' &&  typeof this.consumerSecret !== 'undefined'){
                this.showAuthSaveBtn = true;
                this.disableAuthSaveBtn = false;
                this.showAuthReset = true;
        }else{
            this.showAuthSaveBtn = false;
            this.showAuthReset = false;
        }
    }

    handleAuthReset(){
        this.showAuthReset = false;
        this.disableInput = false;
        this.showAuthSaveBtn = false;
        this.consumerId = "";
        this.consumerSecret = "";
    }

    handleAuthSave(){
        this.showLoading = true;
        if(this.consumerId !== null && this.consumerSecret !== null){
            this.authProviderCreation();
        }else if(this.consumerId === null || this.consumerSecret === null){
            this.showToast('','dismissable','Enter valid value for Client Id and Client Secret','error');
        }
        this.disableInput = true;
        this.showAuthReset = false;
        this.showLoading = false;
    }

    authProviderCreation(){
        createAuthProvider({
            clientId: this.consumerId,
            clientSecret: this.consumerSecret,
            companyFileValue : this.companyFileId,
            baseUrl: this.baseUrl,
            redirectUrl: this.redirectUrl,
            progressValue : 100,
            connectionStep : 4,
            totalConnectionStep: 4
        })
        .then(result => {
            if(result){
                console.log('$$$ createAuthProvider: ', JSON.stringify(result));
                const redirectUrlToVFP = `${result}/apex/MYOB_OAuth_RedirectPage`;
                if (typeof window !== 'undefined') {
                    window.open(redirectUrlToVFP);
                }
                this.disableAuthSaveBtn = true;
            }
        })
        .catch(error => {
            this.error = error;
            this.showToast(error,'dismissable','Something Went Wrong in createAuthProvider','error');
            this.showLoading = false;
        })
    }

    fetchAllCompanyFiles(){
        fetchCompanyFiles()
        .then(result => {
            console.log('$$$ fetchCompanyFiles: ', JSON.stringify(result));
            if(result?.length > ZERO){
                this.companyFileOptions = result.map(element => {
                    return {
                        label: element.Name,
                        value: JSON.stringify({ id: element.Id, uri: element.Uri })
                    };
                });
                console.log('$$$ companyFileOptions: ',this.companyFileOptions);
                const selected = this.companyFileOptions.find(option => {
                    const parsedValue = JSON.parse(option.value);
                    return parsedValue.id === this.setupConfig.companyFile;
                });
                
                if(selected) {
                    this.companyFileValue = selected.value; 
                    this.companyFileId = JSON.parse(selected.value).id;
                }else if(this.setupConfig.companyFile){
                    this.companyFileValue = null;
                    this.showToast('The previously saved Company File is no longer available in the current list.','dismissable','Missing Company File','error');
                }
            }
            this.showMYOBConnection = true;
            this.showMYOBCompanyFile = true;
            this.showLoading = false;
        })
        .catch(error => {
            this.error = error;
            this.showToast(error,'dismissable','Something Went Wrong in fetchCompanyFiles','error');
            this.showLoading = false;
        })
    }

    handleCompanyFileReset(){
        this.showFileReset = false;
        this.disableCompanyFileInput = false;
        this.showFileSaveBtn = true;
        this.companyFileValue = "";
    }

    updateCompanyFileValue(event){
        if(event.target.name === 'CompanyFiles'){
            if (event.target.value) {
                const selected = JSON.parse(event.target.value);
                this.companyFileId = selected.id;
                if (selected.uri) {
                    this.baseUrl = selected.uri.substring(0, selected.uri.lastIndexOf('/') + 1);
                }
            }
        }
        if(this.companyFileValue !== null && this.companyFileValue !== '' && typeof this.companyFileValue !== 'undefined'){
            this.disableFileSaveBtn = false;
            this.showFileReset = true;
        }
    }

    syncCompanyFileSave(){
        this.showLoading = true;
        this.disableFileSaveBtn = true;
        this.setupConfig.baseUrl = this.baseUrl;
        this.setupConfig.companyFile = this.companyFileId;
        saveUIToSf({
            setupConfig: JSON.stringify(this.setupConfig)
        })
        .then(result => {
            if(result === true){
                this.disableCompanyFileInput = true;
                this.showFileReset = true;
                this.showFileSaveBtn = false;
            }
            this.showLoading = false;
        })
        .catch(error => {
            this.error = error;
            this.showToast(error,'dismissable','Something Went Wrong in saveUIToSf','error');
            this.showLoading = false;
        })
    }

    showToast(msg, mod, tle, vrt) {
        if (typeof window !== 'undefined') {
            const evt = new ShowToastEvent({
                message: msg,
                mode: mod,
                title: tle,
                variant: vrt
            });
            this.dispatchEvent(evt);
        }
    }
}