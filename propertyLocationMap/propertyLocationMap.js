import { LightningElement, wire, api, track } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';

import STREET_FIELD from "@salesforce/schema/Property__c.Address_Line_1__c";
import CITY_FIELD from "@salesforce/schema/Property__c.City__c";
import STATE_FIELD from "@salesforce/schema/Property__c.State__c";
import ZIP_FIELD from "@salesforce/schema/Property__c.Zipcode__c";
import TITLE_FIELD from "@salesforce/schema/Property__c.Name";
import DESC_FIELD from "@salesforce/schema/Property__c.Property_Type__c";

export default class PropertyLocationMap extends LightningElement {

    @track mapMarkers;
    @track zoomLevel;
    @track record;

    @api recordId;

    @wire(getRecord, { recordId: '$recordId', fields: [STREET_FIELD, CITY_FIELD, STATE_FIELD, ZIP_FIELD, TITLE_FIELD, DESC_FIELD] })
    wiredProject({ error, data }) {
        if (data) {
            this.record = data;
            this.mapMarkers = [
                {
                    location: {
                        Street: this.record.fields.Address_Line_1__c.value,
                        City: this.record.fields.City__c.value,
                        State: this.record.fields.State__c.value,
                        PostalCode: this.record.fields.Zipcode__c.value,
                    },
                    title: this.record.fields.Name.value,
                    description: this.record.fields.Property_Type__c.value,
                },
            ];
            this.zoomLevel = 15;
            this.error = undefined;
        } else if (error) {
            this.error = error;
            this.record = undefined;
        }
    }
}