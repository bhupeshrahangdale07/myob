import { LightningElement, track } from 'lwc';
import {ShowToastEvent} from "lightning/platformShowToastEvent";
import deleteLogs from "@salesforce/apex/TroubleshootingController.deleteAllLogs";
import getScheduleData from "@salesforce/apex/TroubleshootingController.getScheduleData";
import getLogConfig from "@salesforce/apex/TroubleshootingController.getSetupConfiguration";
import getLogData from "@salesforce/apex/TroubleshootingController.getLogData";
import updateLogConfig from "@salesforce/apex/TroubleshootingController.updateLogConfig";

const DAYOPTIONS = [
    {"label": "Daily",
        "value": "Daily"},
    {"label": "Weekly",
        "value": "Weekly"},
    {"label": "Monthly",
        "value": "Monthly"},
    {"label": "Every 6 Months",
        "value": "6 Months"},
    {"label": "Yearly",
        "value": "Yearly"},
    {"label": "I will do it Manually",
        "value": "None"}
],
ELEVEN = 11,
MINUS_ONE = -1,
ONE = 1,
ZERO = 0;


export default class TroubleShootingLogCmp extends LightningElement {
    @track logConfig ={};
    @track scheduleData;

    @track showTime = true;
    @track savedisable = true;
    @track deleteMessage;
    @track deleteDisable = false;
    manualDeleteSelected = false;
    daysOptions = DAYOPTIONS;

    connectedCallback () {

        this.getLogConfiguration();
        
    }

    getSchedule (doGetLogs) {

        this.isLoading = true;
        getScheduleData({
            "scheduleName": "LogBatchDeleteSchedule"
        }).
            then((result) => {

                const schedule = JSON.stringify(result);
                this.scheduleData = JSON.parse(schedule);
                this.isLoading = false;
                if (doGetLogs) {

                    this.getLogs();
            
                }
        
            }).
            catch((error) => {

                this.isLoading = false;
                this.showToast(
                    `Something Went Wrong. Error - ${ error}`,
                    "dismissable",
                    "Error",
                    "error"
                );
                if (doGetLogs) {

                    this.getLogs();
            
                }
        
            });
    
    }

    handleSave () {

        this.isLoading = true;
        updateLogConfig({
            "configData": JSON.stringify(this.logConfig),
            "scheduleJobId": this.scheduleData.id
        }).
            then((result) => {

                if (result) {

                    this.showToast(
                        "Logs Configuration is Updated",
                        "dismissable",
                        "Logs Configuration",
                        "success"
                    );
                    this.savedisable = true;
                    this.getSchedule(false);
            
                } else {

                    this.showToast(
                        "Something went wrong",
                        "dismissable",
                        "Logs Configuration",
                        "error"
                    );
            
                }
                this.isLoading = false;
                this.activeTab = "log";
        
            }).
            catch((error) => {

                this.isLoading = false;
                this.showToast(
                    `Something went wrong ${error.body.message}`,
                    "dismissable",
                    "Logs Configuration",
                    "error"
                );
        
            });
    
    }

    getLogConfiguration () {

        this.isLoading = true;
        getLogConfig({}).
            then((result) => {
                if (result === null || result === "") {

                    this.showToast(
                        "Something Went Wrong",
                        "dismissable",
                        "Error",
                        "error"
                    );
                    this.isLoading = false;
                } else {

                    const logConfigData = JSON.stringify(result);
                    this.logConfig = JSON.parse(logConfigData);
                    if (this.logConfig.deleteLog === "None") {
                        this.manualDeleteSelected = true;
                        this.showTime = false;
                
                    }
                    this.getSchedule(true);
            
                }
                
        
            }).
            catch((error) => {

                this.isLoading = false;
                this.getSchedule(true);
                this.showToast(
                    `Something Went Wrong. Error - ${ error}`,
                    "dismissable",
                    "Error",
                    "error"
                );
        
            });
    
    }
    
    handledayChange (event) {

        this.savedisable = false;
        this.logConfig.deleteLog = event.detail.value;
        this.manualDeleteSelected = (event.detail.value === 'None');
        if (event.detail.value === "None") {

            this.showTime = false;
        
        } else {

            this.showTime = true;
        
        }
    
    }

    handleDeleteLogs () {

        this.isLoading = true;
        const tobeDeleted = [];
        this.tableData.forEach((element) => {

            tobeDeleted.push(element.id);
        
        });
        deleteLogs({
            "deleteList": tobeDeleted
        }).
            then((result) => {

                if (result) {

                    this.showToast(
                        "All logs are deleted",
                        "dismissable",
                        "Logs Configuration",
                        "success"
                    );
                    this.getLogs();
            
                } else {

                    this.showToast(
                        "Something went wrong",
                        "dismissable",
                        "Logs Configuration",
                        "error"
                    );
            
                }
                this.isLoading = false;
                this.activeTab = "log";
        
            }).
            catch((error) => {

                this.isLoading = false;
                this.showToast(
                    `Something went wrong ${error}`,
                    "dismissable",
                    "Logs Configuration",
                    "error"
                );
        
            });
    
    }

    getLogs () {

        this.isLoading = true;
        getLogData({}).
            then((result) => {

                if (result && result.length > ZERO) {

                    this.totalRecords = result.length;
                    this.deleteMessage = `Delete ${result.length} Logs`;
                    this.tableData = result;
                    const maxDate = new Date(Math.max(...result.map((element) => new Date(element.createdDate)))),
                        minDate = new Date(Math.min(...result.map((element) => new Date(element.createdDate))));
                    this.maxDate = maxDate.getDate();
                    this.maxMonth = maxDate.getMonth() + ONE;
                    this.maxYear = maxDate.getFullYear();
                    this.minDate = minDate.getDate();
                    this.minMonth = minDate.getMonth() + ONE;
                    this.minYear = minDate.getFullYear();
                    if (result.length > this.pageSize) {

                        this.showPagination = true;
                        this.records = this.tableData.slice(
                            ONE,
                            this.pageSize
                        );
                
                    } else {

                        this.showPagination = false;
                        this.records = result;
                
                    }
            
                } else {

                    this.deleteDisable = true;
                    this.deleteMessage = "No log data found";
                    this.tableData = null;
            
                }
                this.isLoading = false;
        
            }).
            catch((error) => {

                this.isLoading = false;
                this.showToast(
                    `Something Went Wrong. Error - ${ error}`,
                    "dismissable",
                    "Error",
                    "error"
                );
        
            });
    
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