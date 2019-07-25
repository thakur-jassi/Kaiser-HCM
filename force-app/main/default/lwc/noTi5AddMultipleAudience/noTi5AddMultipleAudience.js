import { LightningElement, track, wire, api } from 'lwc';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { getObjectInfo } from 'lightning/uiObjectInfoApi';
import AUDIENCE_OBJECT from '@salesforce/schema/Audience__c';
import Type_FIELD from '@salesforce/schema/Audience__c.Type__c';

import { ShowToastEvent } from 'lightning/platformShowToastEvent';

/** LookupController.search() Apex method */
import apexSearch from '@salesforce/apex/Noti5_LookupController.search';

import createAudienceRecords from '@salesforce/apex/Noti5_addAudienceController.createAudienceRecords';

export default class noTi5AddMultipleAudience extends LightningElement {
    
    @track addState = false;
    @track value='';
    @track records = [{value:'',initialSelection:[], isAddVisible: true, isDelVisible: false, errors: []}];
    @api notificationId;

    @wire(getObjectInfo, { objectApiName: AUDIENCE_OBJECT })
    objectInfo;

    @wire(getPicklistValues, { recordTypeId: '$objectInfo.data.defaultRecordTypeId', fieldApiName: Type_FIELD})
    TypePicklistValues;

    // Use alerts instead of toast to notify user using this variable
    @api notifyViaAlerts = false;
    @api recordId;
    
    @track isMultiEntry = false;
    @track errors = [];
    @track finalRecords =[];
    @track recordCount = 1;

    //Get pickilist values for type
    get options(){
        if(this.TypePicklistValues.data !== undefined)
            return this.TypePicklistValues.data.values;
        return '';
    }

    //Method to change the selected audience to balnk when type changes
    handleChange(event) {
        this.value = event.detail.value;
            
        if(this.template.querySelectorAll('c-no-ti5-lookup')[this.records.length - 1].getSelection() !== undefined){
            
            this.template.querySelectorAll('c-no-ti5-lookup')[this.records.length - 1].setSelection([]);
        }
        
    }

    //Method to get search results on the Role/Profile/Queue/Permission Set/Public Group
    handleSearch(event) {
        apexSearch(event.detail)
            .then(results => {
                this.template.querySelectorAll('c-no-ti5-lookup')[this.recordCount-1].setSearchResults(results);
            })
            .catch(error => {
                this.notifyUser('Lookup Error', 'An error occured while searching with the lookup field.', 'error');
                // eslint-disable-next-line no-console
                console.error('Lookup error', JSON.stringify(error));
                this.records[this.recordCount-1].errors = [error];
            });
    }

    handleSelectionChange() {
        this.records[this.recordCount-1].errors = [];
             
    }

    // Method to add now audience Row
    handleSubmit() {
        
        this.checkForErrors();
        if (this.records[this.recordCount-1].errors === undefined || this.records[this.recordCount-1].errors.length === 0) {
            
            this.records.splice(this.recordCount-1, 0, {value: this.value,initialSelection: this.template.querySelectorAll('c-no-ti5-lookup')[this.recordCount-1].getSelection(), isAddVisible: false, isDelVisible: true, id: this.template.querySelectorAll('c-no-ti5-lookup')[this.recordCount-1].getSelection()[0].id, errors: []});
            this.recordCount = this.records.length;
            this.records[this.recordCount-1] = {value:'',initialSelection:[], isAddVisible: true, isDelVisible: false, errors: []};
            
        }
    }

    checkForErrors() {
        const selection = this.template.querySelectorAll('c-no-ti5-lookup')[this.recordCount-1].getSelection();
        if (selection.length === 0) {
            this.records[this.recordCount -1].errors = [
                { message: 'Group selection is Mandatory' }
            ];
        } else {
            this.records[this.recordCount -1].errors = [];
        }
    }

    //Send Notification to the User
    notifyUser(title, message, variant) {
        if (this.notifyViaAlerts){
            // Notify via alert
            // eslint-disable-next-line no-alert
            alert(`${title}\n${message}`);
        } else {
            // Notify via toast
            const toastEvent = new ShowToastEvent({ title, message, variant });
            this.dispatchEvent(toastEvent);
        }
    }

    //Method to remove the Audience from the selected list
    handleRemove(event){
        var id;
        if(event.target.id.includes('-'))
            id = event.target.id.split('-')[0];
        else
            id = event.target.id;

        for(let i=0; i<this.records.length ;i++ ){
            if(this.records[i].initialSelection[0] !== undefined && this.records[i].initialSelection[0].id === id){
                
                this.records.splice(i,1);
                i--;
            }
        }
        this.recordCount = this.records.length;
    }

    //Method to save all the selected audiences to the Notification
    handleSave(){
        const selection = this.template.querySelectorAll('c-no-ti5-lookup')[this.recordCount-1].getSelection();
        if(selection.length === 0 && this.records.length < 2){
            this.records[0].errors = [
                { message: 'Group selection is Mandatory' }
            ];
        }
        else{
            if(selection.length === 0 && this.records.length > 1){
                for(let i=0; i<this.recordCount-1 ;i++){
                    this.finalRecords.push({Type:this.records[i].value,GroupId: this.records[i].id,title: this.records[i].initialSelection[0].title});
                }
            }else{
                this.records[this.recordCount-1] = {value: this.value,initialSelection: this.template.querySelectorAll('c-no-ti5-lookup')[this.recordCount-1].getSelection(), isAddVisible: false, isDelVisible: true, id: this.template.querySelectorAll('c-no-ti5-lookup')[this.recordCount-1].getSelection()[0].id, errors: []};
                for(let i=0; i<this.records.length ;i++){
                    this.finalRecords.push({Type:this.records[i].value,GroupId: this.records[i].id,title: this.records[i].initialSelection[0].title});
                }
            }
            
            if(this.finalRecords.length > 0){
                createAudienceRecords({NotificationId : this.notificationId,listWrap : JSON.stringify(this.finalRecords)})
                .then(result =>{
                    this.records = [{value:'',initialSelection:[], isAddVisible: true, isDelVisible: false, errors: []}];
                    this.finalRecords = [];
                    this.dispatchEvent(
                        new ShowToastEvent({
                            title: 'Success',
                            message: 'Audiences Created',
                            variant: 'success',
                        }),
                    );
                    this.dispatchEvent(new CustomEvent('save'));
                })
                .catch(error=>{
                    
                });
            }
        }
                
    }
}