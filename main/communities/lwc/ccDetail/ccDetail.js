import { LightningElement, api, wire, track } from 'lwc';
import getWiredFieldSet from '@salesforce/apex/AuraService.getWiredFieldSet';
import getRecords from '@salesforce/apex/AuraService.getWiredRecords';
import { refreshApex } from '@salesforce/apex';

export default class CcDetail extends LightningElement {
    @api fieldSetName = 'FieloPLT__ccPayoutDetail';
    @api objectName = 'FieloPLT__Payout__c';
    @api record = {};
    @track fields = [];
    @track fieldMap = {};
    @track title = 'Payout Record';
    @track hasFields = false;
    @api columns = 2;
    
    wiredFields;
    wiredRecords;

    @track fieldset = '';
    @track limitClause = 1;
    @track offset = 0;

    @wire(getWiredFieldSet, {
        objectApiName: '$objectName',
        fieldSetName: '$fieldSetName'
    })
    getFields( value ) {
        this.wiredFields = value;
        const { data, error } = value;
        if (data && data.fieldSet && data.fieldSet.length) {
            this.hasFields = true;
            var fieldList = [];
            data.fieldSet.forEach(field => {
                var fieldObject = Object.assign({},data.fieldMap[field]);
                this.fields.push(fieldObject);
                this.fieldMap[field] = fieldObject;
                fieldList.push(field);
            });
            this.fieldset = fieldList.join(',');
            if (this.record.Name) {
                this.title = this.record.Name;
            }
            refreshApex(this.wiredRecords);
        } else if(error) {
            console.error(error);
        }
    }

    @wire(getRecords, {
        fields: '$fieldset',
        objectName: '$objectName',
        dataFilters: '$filter',
        recordsPerPage: '$limitClause',
        offset: '$offset'
    })
    recordsResults(value) {
        this.wiredRecords = value;
        const { data, error } = value;
        if (data) {
            this.records = [...data];
            this.setLookupFields();
            this.setFieldValues();
        } else if (error) {
            console.log(error);
        }
    }

    connectedCallback() {
        this.filter = JSON.stringify({Id:this.record.Id});
        refreshApex(this.wiredFields);
    }

    setLookupFields() {
        if (this.records && this.records.length) {
            var newRecords = [];
            this.records.forEach(record => {
                var newRecord = JSON.parse(JSON.stringify(record));
                Object.keys(record).forEach(fieldName => {
                    if (this.fieldMap[fieldName] && this.fieldMap[fieldName].type == 'reference') {
                        Object.keys(record[this.fieldMap[fieldName].relationshipName]).forEach(relField => {
                            let path = this.fieldMap[fieldName].relationshipName.replace('__c$', '__r');
                            newRecord[this.fieldMap[fieldName].relationshipName + '.' + relField] = record[this.fieldMap[fieldName].relationshipName][relField];
                        });
                    }
                });
                newRecords.push(newRecord);
            });
            this.records = newRecords;
        }
    }

    setFieldValues() {
        if (this.records && this.records.length) {
            for (var i = 0; i < this.fields.length; i++) {
                if (this.records[0][this.fields[i].name]) {
                    if (this.fields[i].type == 'reference') {
                        this.fields[i].value = this.records[0][this.fields[i].relationshipName + '.' + this.fields[i].referenceToNameField];
                    } else {
                        this.fields[i].value = this.records[0][this.fields[i].name];
                    }
                } else {
                    this.fields[i].value = null;
                }
            }
        }
    }
}