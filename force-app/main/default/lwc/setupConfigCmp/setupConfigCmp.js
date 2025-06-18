import { LightningElement, track} from 'lwc';
import {ShowToastEvent} from 'lightning/platformShowToastEvent';
import createAuthProvider from '@salesforce/apex/SetupConfigController.createAuthProvider';
import fetchPermission from '@salesforce/apex/SetupConfigController.fetchPermission';
import getSetupConfiguration from '@salesforce/apex/SetupConfigController.getSetupConfiguration';
import saveUIToSf from '@salesforce/apex/SetupConfigController.saveUIToSf';
import fetchCompanyFiles from '@salesforce/apex/MYOB_Component_Helper_cls.fetchCompanyFiles';
const FOURCOMPLETEDSTEPS = 4,
      ONECOMPLETEDSTEPS = 1,
      THREECOMPLETEDSTEPS = 3,
      TWOCOMPLETEDSTEPS = 2,
      ZERO = 0;

export default class SetupConfigCmp extends LightningElement {
    @track showLoading = false;
    @track completedSteps = ZERO;
    @track progressValue = ZERO;
    @track progressAuth = ZERO;
    @track progressCompanyFile = ZERO;
    @track progressPermission = ZERO;
    @track progressLayout = ZERO;
    @track showMYOBConnection = false;
    @track showMYOBCompanyFile = false;
    @track showMYOBPermission = false;
    @track showOpportunity = false;
    @track xciconName = "utility:chevronright";
    @track firstStep ;
    @track secondStep ;
    @track thirdStep ;
    @track fourthStep ;
    showModal = false;
    consumerSecret;
    consumerId;
    companyFileValue;
    redirectUrl = '';
    redirectUrlLabel = '';
    disableSnCSave = true;
    disableRedirectUrlInput = true;
    disableCompanyFileInput = false;
    disableSyncSave = true;
    showSiteCreation = false;
    disablePS = false;
    disableLayoutSave = false;
    disableInput = false;
    isAuthenticated  = false ;
    companyFileOptions = [];

    get progressRingStyleStep1() {
        return this.progressAuth === 1 ? 'background:purple;' : '';
    }
    get progressRingStyleStep2() {
        return this.progressCompanyFile === 1 ? 'background:purple;' : '';
    }
    get progressRingStyleStep3() {
        return this.progressPermission === 1 ? 'background:purple;' : '';
    }
    get progressRingStyleStep4() {
        return this.progressLayout === 1 ? 'background:purple;' : '';
    }

    connectedCallback(){
        this.showLoading = true;
        this.getConfiguration();
        if (typeof window !== 'undefined') {
            //this.redirectUrl = `${window.location.origin}/apex/MYOB_OAuth_RedirectPage`;
            this.redirectUrl = `https://myob-d-dev-ed--ktmyob.develop.vf.force.com/apex/MYOB_OAuth_RedirectPage`;
        }
        this.redirectUrlLabel = `Copy Redirect URL ${  this.redirectUrl } into the Redirect Url in MYOB setting`;
    }

    get progressStyle() {
        return `width: ${this.progressValue}%`;
    }

    getConfiguration(){
        this.showLoading = true;
        getSetupConfiguration({})
        .then(result => {
            if(result){
                console.log('### this.setupConfig: ', result);
                this.setupConfig = result;
                //this.setupConfigId = this.setupConfig.id;
                if(typeof this.setupConfig.progressValue === 'undefined'){
                    this.completedSteps = 0;
                    this.progressValue = 0;
                }else{
                    this.completedSteps = this.setupConfig.completedSteps;
                    this.progressValue = this.setupConfig.progressValue;
                }
                const preAuthFields = ['clientId', 'clientSecret'];
                if (preAuthFields.every(field => result[field] !== null && String(result[field]).trim() !== '' && typeof result[field] !== 'undefined')) {
                    console.log('field');
                    this.consumerId = result.clientId;
                    this.consumerSecret = result.clientSecret;
                    this.disableInput = true;
                }
                if(this.completedSteps === ONECOMPLETEDSTEPS){
                    if(this.disableInput === true){
                        this.showToast('Please proceed to second step.', 'dismissable', 'MYOB - Salesforce Authorization Completed Succesfully', 'success');
                    }else if(this.disableInput === false){
                            this.completedSteps = 0;
                            this.setupConfig.completedSteps = 0;
                            this.progressValue = 0;
                            this.setupConfig.progressValue = 0;
                            this.showToast('Please review first step.', 'dismissable', 'MYOB - Salesforce Authorization Failed', 'error');
                    }
                }if(this.completedSteps === TWOCOMPLETEDSTEPS){
                     this.showToast('Please proceed to third step.', 'dismissable', 'MYOB - Salesforce Sync Completed Succesfully', 'success');
                }if(this.completedSteps === THREECOMPLETEDSTEPS){
                     this.showToast('Please proceed to fourth step.', 'dismissable', 'Permission Sets Assigned Succesfully', 'success');
                }if(this.completedSteps === FOURCOMPLETEDSTEPS && this.disableInput === false){
                    this.disableInput = true;
                    this.showToast('Please troubleshoot the connection issue.','dismissable','MYOB - Salesforce Authorization Failed','error');
                }
                if(this.setupConfig.companyFile){
                    this.companyFileValue = this.setupConfig.companyFile;
                    this.disableCompanyFileInput = true;
                    this.getPermissionSets();
                }
                if(this.completedSteps === FOURCOMPLETEDSTEPS && (this.setupConfig.companyFile === null || this.setupConfig.companyFile === '' || typeof this.setupConfig.companyFile === 'undefined') && (this.setupConfig.syncSite === null || this.setupConfig.syncSite === '' || typeof this.setupConfig.syncSite === 'undefined')){
                    this.disableCompanyFileInput = true;
                    this.showToast('Please troubleshoot the connection issue.','dismissable','MYOB - Salesforce Sync Failed','error');
                }
                const stepConfigurations = [
                    { firstStep: false, secondStep: true, thirdStep: true, fourthStep: true, showMYOBConnection:true, showMYOBCompanyFile:false, showMYOBPermission:false, showOpportunity:false},
                    { progressAuth: 1, firstStep: false, secondStep: false, thirdStep: true, fourthStep: true, showMYOBConnection:false, showMYOBCompanyFile:true, showMYOBPermission:false, showOpportunity:false },
                    { progressAuth: 1, progressCompanyFile: 1, firstStep: false, secondStep: false, thirdStep: false, fourthStep: true, showMYOBConnection:false, showMYOBCompanyFile:false, showMYOBPermission:true, showOpportunity:false },
                    { progressAuth: 1,  progressCompanyFile: 1, progressPermission: 1, firstStep: false, secondStep: false, thirdStep: false , fourthStep: false, showMYOBConnection:false, showMYOBCompanyFile:false, showMYOBPermission:false, showOpportunity:true, disablePS:true},
                    { progressAuth: 1, progressCompanyFile: 1, progressPermission: 1, progressLayout: 1, firstStep: false, secondStep: false, thirdStep: false ,fourthStep: false, showMYOBConnection:false, showMYOBCompanyFile:false, showMYOBPermission:false, showOpportunity:false, disablePS: true, disableLayoutSave: true},
                ],
                    config = stepConfigurations[this.completedSteps];
                if (config) {
                    Object.assign(this, config);
                } else if(result.completedSteps === FOURCOMPLETEDSTEPS){
                    this.showLoading = false;
                    this.showToast('Success', 'dismissable', 'All Steps Completed Successfully','success');
                }
                if(result.completedSteps >= ONECOMPLETEDSTEPS){
                    this.isAuthenticated = true;
                    this.fetchAllCompanyFiles();
                } else if(result.completedSteps === ZERO){
                    this.isAuthenticated = false;
                }
                this.consumerId = result.clientId;
                this.consumerSecret = result.clientSecret;
                this.companyFileValue = result.companyFile;

                this.showLoading = false;
            }
        })
        .catch(error => {
            this.error = error;
            this.showLoading = false;
            this.showToast(error, 'dismissable', 'Something Went Wrong in getSetupConfiguration','error');
        })
    }

    fetchAllCompanyFiles(){
        this.showLoading = true;
        fetchCompanyFiles()
        .then(result => {
            console.log('$$$ fetchCompanyFiles: ', result);
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
            this.showLoading = false;
        })
        .catch(error => {
            this.error = error;
            this.showLoading = false;
            this.showToast(error,'dismissable','Something Went Wrong in fetchCompanyFiles','error');
        })
    }
    getPermissionSets(){
        this.showLoading = true;
        fetchPermission({})
        .then(result => {
            if(result.length > ZERO){
                const pMap = new Map();
                result.forEach(ele => {
                    pMap.set(ele.name, ele.setupUrl);
                });
                this.permissionSets = pMap;
            }
        })
        .catch(error => {
            this.error = error;
            this.showLoading = false;
            this.showToast(error,'dismissable','Something Went Wrong','error');
        })
        this.showLoading = false;

    }
    
    renderedCallback(){
        if(this.showMYOBConnection){
            const ele = this.template.querySelector('[data-id="myobConnection"]');
            if(ele !== null) {
                ele.iconName = "utility:chevrondown";
            }
        }
        if(this.showQBWebhook){
            const ele = this.template.querySelector('[data-id="companyFileBtn"]');
            if(ele !== null) {
                ele.iconName = "utility:chevrondown";
            }
        }
        if(this.showMYOBPermission){
            const ele = this.template.querySelector('[data-id="permissionBtn"]');
            if(ele !== null) {
                ele.iconName = "utility:chevrondown";
            }
        }
        if(this.showOpportunity){
            const ele = this.template.querySelector('[data-id="opportunityBtn"]');
            if(ele !== null) {
                ele.iconName = "utility:chevrondown";
            }
        }
    }  
    changeView(event){
        const btName = event.target.dataset.id,
              ele = this.template.querySelector(`[data-id="${btName}"]`),
        {iconName} = ele,
        property = {
            opportunityBtn: { showProperty: 'showOpportunity' },
            permissionBtn: { showProperty: 'showMYOBPermission' },
            myobConnection: { showProperty: 'showMYOBConnection' },
            companyFileBtn: { showProperty: 'showMYOBCompanyFile' },
        }[btName]?.showProperty;
        if(!ele){
           return '';
        };
        if (iconName === 'utility:chevronright') {
            ele.iconName = 'utility:chevrondown';
            this[property] = true;
        } else {
            ele.iconName = 'utility:chevronright';
            this[property] = false;
        }
    }
    updateValue(event){
        if(event.target.name === 'Client ID'){
            this.consumerId = event.target.value.trim();
        }else if(event.target.name === 'Client Secret'){
            this.consumerSecret = event.target.value.trim();
        }
        if(this.consumerId !== null && this.consumerId !== '' && typeof this.consumerId !== 'undefined' &&
            this.consumerSecret !== null && this.consumerSecret !== '' && typeof this.consumerSecret !== 'undefined'){
            this.disableSnCSave = false;
        }else{
            this.disableSnCSave = true;
        }
    }
    updateCompanyFileValue(event){
        if(event.target.name === 'CompanyFiles'){
            if (event.target.value) {
                const selected = JSON.parse(event.target.value);
                this.companyFileValue = selected.id;
    
                if (selected.uri) {
                    this.baseUrl = selected.uri.substring(0, selected.uri.lastIndexOf('/') + 1);
                }
            }
        }
        if(this.companyFileValue !== null && this.companyFileValue !== '' &&  typeof this.companyFileValue !== 'undefined'){
            this.disableSnCSave = false;
        }else{
            this.disableSnCSave = true;
        }
    }
    showInstruction(){
        this.showModal = true;
        this.showPositiveButton = true;
        this.showNegativeButton = false;
        this.positiveButtonLabel = 'Close';
    }
    closeModal() {
        this.showModal = false;
    }
    saveConnect(){
        if(this.consumerId !== null && this.consumerSecret !== null){
            this.authProviderCreation();
        }else if(this.consumerId === null || this.consumerSecret === null){
            this.showToast('','dismissable','Enter valid value for Client Id and Client Secret','error');
        }
        this.disableInput = true;
        this.disableSnCSave = true;
        
    }

    saveValuesInSf(){
        this.showLoading = true;
        saveUIToSf({
            setupConfig: JSON.stringify(this.setupConfig)
        })
        .then(result => {
            if(result === true){
                this.getConfiguration();
            }
        })
        .catch(error => {
            this.error = error;
            this.showLoading = false;
            this.showToast(error,'dismissable','Something Went Wrong in saveUIToSf','error',);
        })
    }

    handleConnectionLink () {
        this.dispatchEvent(new CustomEvent(
            "connectiontab",
            {
                "detail": true
            }
        ));
    }

    authProviderCreation(){
        this.showLoading = true;
        createAuthProvider({
            clientId: this.consumerId,
            clientSecret: this.consumerSecret,
            companyFileValue : this.companyFileId,
            baseUrl: this.baseUrl,
            redirectUrl: this.redirectUrl,
            progressValue : 25,
            connectionStep :1,
            totalConnectionStep:4
        })
        .then(result => {
            if(result){
                const redirectUrlToVFP = `${result}/apex/MYOB_OAuth_RedirectPage`;
                if (typeof window !== 'undefined') {
                    window.open(redirectUrlToVFP);
                }
            }
            this.showLoading = false;
        })
        .catch(error => {
            this.error = error;
            this.showLoading = false;
            this.showToast(error,'dismissable','Something Went Wrong in createAuthProvider','error');
        })
    }

    syncCompanyFileSave(){
        this.showLoading = true;
        this.disableSyncSave = true;
        this.setupConfig.progressValue = 50;
        this.setupConfig.completedSteps = 2;
        this.setupConfig.baseUrl = this.baseUrl;
        this.setupConfig.companyFile = this.companyFileValue;

        saveUIToSf({
            setupConfig: JSON.stringify(this.setupConfig)
        })
        .then(result => {
            if(result === true){
                this.disableCompanyFileInput = true;
                this.getConfiguration();
            }
        })
        .catch(error => {
            this.error = error;
            this.showLoading = false;
            this.showToast(error,'dismissable','Something Went Wrong in saveUIToSf','error');
        })
    }

    handlePermission(event){
        const permission = event.target.value,
            url = this.permissionSets.get(permission);
            if (typeof window !== 'undefined') {
                window.open(url, "_blank");  
            }
    }
    handlePermissionLink () {
        this.dispatchEvent(new CustomEvent(
            "permissiontab", { "detail": true }
        ));
    }
    handleSavePermission(){
        this.setupConfig.progressValue = 75;
        this.setupConfig.completedSteps = 3;
        this.saveValuesInSf();
        this.showToast('Please proceed to fourth step.','dismissable','Permission Sets Assigned Succesfully','success');
        this.disablePS = true;
    }
    get selectedValues() {
        return this.value.join(",");
    }
    handleChange(evt) {
        this.value = evt.detail.value;
    }
    layoutUpdated(){
        this.showLoading = true;
        this.setupConfig.progressValue = 100;
        this.setupConfig.completedSteps = 4;
        this.saveValuesInSf();
        this.dispatchEvent(new CustomEvent(
            "enabletabs", { "detail": false }
        ));
        this.showToast('Please proceed to other section.','dismissable','Opportunity Page-Layout Setup Completed Successfully','success');
        this.showLoading = false;
        this.disableLayoutSave = true;
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