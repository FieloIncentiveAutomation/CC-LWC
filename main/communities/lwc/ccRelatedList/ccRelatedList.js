import { LightningElement, api, wire, track } from 'lwc';
import getWiredFieldSet from '@salesforce/apex/AuraService.getWiredFieldSet';
import getRecords from '@salesforce/apex/AuraService.getWiredRecords';
import { refreshApex } from '@salesforce/apex';

export default class CcRelatedList extends LightningElement {
    @api fieldSetName = 'FieloPLT__ccPayoutItems';
    @api objectName = 'FieloPLT__Point__c';
    @api recordsPerPage = 5;
    @api showCheckbox = false;
    @api filter = '{}';
    
    @track fields = '';
    @track fieldMap = {};
    @track title = 'Payout Items';
    @track records;

    @track hasColumns = false;
    @track hasRecords = false;
    @track tableReady = false;

    wiredFields;
    wiredRecords;
    limitClause = 5;

    fieldMap = {};

    @track columns = [{
        label: 'Name',
        fieldName: 'Name',
        edit: false
    }];

    @track offset = 0; // Offset of the resulted records 
    @track disablePrevious = true; // Check if there's a Next page of records
    @track disableNext = true; // Check if there's a Next page of records
    

    @wire(getWiredFieldSet, {
        objectApiName: '$objectName',
        fieldSetName: '$fieldSetName'
    })
    getFields(value) {
        this.wiredFields = value;
        const { data, error } = value;
        if (data) {
            if (data.fieldMap) {
                this.fieldMap = Object.assign({}, data.fieldMap);
            }
            if (data.columns && data.columns.length) {
                this.columns = [...data.columns];
                this.hasColumns = true;
            }
            if (data.fieldSet && data.fieldSet.length) {
                this.fields = data.fieldSet.join(',');
                this.limitClause = this.recordsPerPage + 1;

                console.log(JSON.stringify(
                    {
                        fields: this.fields,
                        objectName: this.objectName,
                        dataFilters: this.filter,
                        recordsPerPage: this.limitClause,
                        offset: this.offset
                    }
                    ,null,2
                ));
                refreshApex(this.wiredRecords);
            }
        } else if (error) {
            console.error(error);
        }
    }

    @wire(getRecords, {
        fields: '$fields',
        objectName: '$objectName',
        dataFilters: '$filter',
        recordsPerPage: '$limitClause',
        offset: '$offset'
    })
    recordsResults(value) {
        this.wiredRecords = value;
        const { data, error } = value;
        if (data) {
            // Set previous status
            if (this.offset) {
                this.disablePrevious = false;
            } else {
                this.disablePrevious = true;
            }

            if (data.length === this.recordsPerPage + 1) {
                this.records = [...data.slice(0, this.recordsPerPage)];
                // Set next status
                this.disableNext = false;
            } else {
                this.records = [...data];
                // Set next status
                this.disableNext = true;
            }
            this.hasRecords = true;

            if (this.hasRecords && this.hasColumns) {
                this.tableReady = true;
            }
            this.setLookupFields();
        } else if (error) {
            console.log(error);
        }
    }

    setLookupFields() {
        if (this.records && this.records.length) {
            var newRecords = [];
            this.records.forEach(record => {
                var newRecord = JSON.parse(JSON.stringify(record));
                Object.keys(record).forEach(fieldName => {
                    if (typeof record[fieldName] == 'object') {
                        Object.keys(record[fieldName]).forEach(relField => {
                            newRecord[fieldName + '.' + relField] = record[fieldName][relField];
                        });
                    }
                });
                newRecords.push(newRecord);
            });
            this.records = newRecords;
        }
    }

    connectedCallback() {
        refreshApex(this.wiredFields);
    }

    handlePrevious() {
        this.offset -= this.recordsPerPage;
        refreshApex(this.wiredRecords);
    }

    handleNext() {
        this.offset += this.recordsPerPage;
        refreshApex(this.wiredRecords);
    }
}