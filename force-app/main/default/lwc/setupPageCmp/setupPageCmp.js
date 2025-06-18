import {LightningElement, track} from "lwc";
import FORM_FACTOR from "@salesforce/client/formFactor";
import HideLightningHeader from "@salesforce/resourceUrl/noHeader";
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import getSetupConfiguration from "@salesforce/apex/SetupConfigController.getSetupConfiguration";
import {loadStyle} from "lightning/platformResourceLoader";
import myobLogo from "@salesforce/resourceUrl/logo2";
import saveUIToSf from "@salesforce/apex/SetupConfigController.saveUIToSf";

const FOURCOMPLETEDSTEPS = 4;

export default class SetupPageCmp extends LightningElement {
    
    myobLogo = myobLogo;
    @track showLoading = false; 
    @track setupConfigCmp = true;
    @track contactConfigCmp = false;
    @track productConfigCmp = false;
    @track invoiceConfigCmp = false;
    @track currencyConfigCmp = false;
    @track paymentConfigCmp = false;
    @track permissionSetCmp = false;
    @track troubleshootingCmp = false;
    @track helpSupportCmp = false;
    @track disableTab = true;
    defaultSelectedSection = 'setupConfigCmp';
    config = {};
    setupConfig = {};

    get isDesktop () {
        return FORM_FACTOR === "Large";
    }
    get isMobile () {
        return FORM_FACTOR === "Small";
    }
    get isTablet () {
        return FORM_FACTOR === "Medium";
    }

    connectedCallback () {
        if (typeof window !== 'undefined') {
            document.title = "MYOB Setup | Salesforce";
        }
        this.getConfiguration();
    }

    getConfiguration(){
        getSetupConfiguration({})
        .then((result) => {
            this.config = result;
            if (this.config?.completedSteps === FOURCOMPLETEDSTEPS) {
                this.disableTab = false;
            }
        })
        .catch((error) => {
            console.log('!!! Error getSetupConfiguration: ', error);
            this.showToast(error,'dismissable','Something Went Wrong in getSetupConfiguration','error');
        });
    }

    setDefault () {
        this.setupConfigCmp = false;
        this.contactConfigCmp = false;
        this.productConfigCmp = false;
        this.invoiceConfigCmp = false;
        this.currencyConfigCmp = false;
        this.paymentConfigCmp = false;
        this.permissionSetCmp = false;
        this.troubleshootingCmp = false;
        this.helpSupportCmp = false;
    }

    handleSelect(event){
        console.log('### handleSelect event: ', event);
        console.log('### handleSelect event: ', JSON.stringify(event));
        this.setDefault();
        const targetName = event?.detail?.name,
              alwaysEnabled = ['setupConfigCmp', 'helpSupportCmp'],
              conditionallyEnabled = {
                    contactConfigCmp: 'Contact Configuration is disabled',
                    productConfigCmp: 'Product Configuration is disabled',
                    invoiceConfigCmp: 'Invoice Configuration is disabled',
                    currencyConfigCmp: 'Currency Configuration is disabled',
                    paymentConfigCmp: 'Payment Configuration is disabled',
                    permissionSetCmp: 'Permission Set is disabled',
                    troubleshootingCmp: 'Troubleshooting is disabled',
                };

        if (alwaysEnabled.includes(targetName)){
            this[targetName] = true;
        } else if (targetName in conditionallyEnabled){
            if (!this.disableTab) {
                this[targetName] = true;
            } else {
                this.showErrorMessage(conditionallyEnabled[targetName]);
            }
        }
    }

    handleEnabledTabs (event) {
        this.disableTab = event.detail;
    }

    handleConnectionTab (event) {
        if (event.detail) {
            this.setupConfigCmp = false;
            this.troubleshootingCmp = true;
        }
    }

    handlePermissionTab (event) {
        if (event.detail) {
            this.setupConfigCmp = false;
            this.permissionSetCmp = true;
        }
    }

    renderedCallback () {
        Promise.all([
            loadStyle(
                this,
                HideLightningHeader
            )
        ]).then(() => {
            /* Empty */
        }).catch((error) => {
            this.error = error;
            this.showLoading = false;
            this.showToast(
                "Something Went Wrong in Loading 'noHeader' .",
                error,
                "error",
                "dismissable"
            );
        });
    }

    showErrorMessage (title) {
        const message = "Please complete all 'Setup And Configuration' steps first.",
            mode = "dismissable",
            variant = "error";
        this.dispatchEvent(new ShowToastEvent({message,
            mode,
            title,
            variant}));
    }

    showToast (msg, mod, tle, vrt) {
        if (typeof window !== 'undefined') {
            const evt = new ShowToastEvent({
                "message": msg,
                "mode": mod,
                "title": tle,
                "variant": vrt
            });
            this.dispatchEvent(evt);
        }
    }
}