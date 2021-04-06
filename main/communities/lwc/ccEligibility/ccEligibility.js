import { LightningElement, api, wire, track } from 'lwc';
// labels
import achieved from '@salesforce/label/c.cc_achieved';
import notAchieved from '@salesforce/label/c.cc_notachieved';
import eligibilityDescriptionWarning from '@salesforce/label/c.CC_EligibilityDescriptionWarning';
// apex methods
import getCriterias from '@salesforce/apex/LWCService.getEligibilitycriterion';

// labels success


export default class CcEligibility extends LightningElement {
  // where the box will be displayed
  @api position = '';
  @api description = '';
  @api memberId = '';
  @api segment = '';

  @track loaded = false;

  // stores if needs to disply the progress or an alternative message
  @track isProgress = false;

  // Expose the labels to use in the template.
  label = {
    achieved,
    notAchieved,
    eligibilityDescriptionWarning
  };

  // param to send to getCriterias
  records = {};


  // criterias list
  criterias = [];

  // class to be appyed to the component
  cssMainClass = 'fielo-cc-progress  slds-text-align--left';

  @wire(getCriterias, { records: '$records' })
  rawCriterias({ error, data }) {
    if (data && this.isProgress) {
      // in criterias saves a new list with the calculated progress

      if (data[this.segment].length === 0) {
        this.description = this.label.eligibilityDescriptionWarning;
        this.isProgress = false;
      } else {
        this.criterias = data[this.segment].map(item => {
          let newItem = JSON.parse(JSON.stringify(item));;
          newItem.progress = '';

          if (item.currentValue && item.goalValue) {
            newItem.progress = item.currentValue * 100 / item.goalValue;
          }
          return newItem;
        });
        // Put all applyed criterias at the top
        this.criterias.sort((a) => (a.applyCriterion) ? -1 : 1);
      }

    } else {
      this.isProgress = false;
    }
    if (error) {
      console.warn(error);
      this.description = error.body.message + ' | ' + error.body.stackTrace;
      this.isProgress = false;
    }
    this.loaded = true;

  }



  // check if the position was configured
  connectedCallback() {
    if (this.description === '') {
      this.isProgress = true;
      this.records[this.memberId] = [this.segment];
    }
    // set position
    switch (this.position) {
      case 'bottom-right':
        this.cssMainClass += ' fielo-cc-progress--position-bottom-right';
        break;

      default:
        break;
    }
  }


}