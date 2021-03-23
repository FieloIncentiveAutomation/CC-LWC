import { LightningElement, track, api, wire } from 'lwc';
import getAgreements from '@salesforce/apex/CcMemberAgreementController.getAgreements';
import acceptAgreement from '@salesforce/apex/AgreementService.acceptAgreement';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';

// Labels
import agree from '@salesforce/label/c.Agree';
import agreement from '@salesforce/label/c.Agreement';
import genericError from '@salesforce/label/c.GenericError';
import incentives from '@salesforce/label/c.Incentives';
import program from '@salesforce/label/c.Program';

export default class CcMemberAgreement extends LightningElement {

  @api member;
  @track showMemberAgreements = false;
  @track showProgramAgreement = false;
  @track showIncentivesAgreements = false;
  @track memberAgreements = {};

  // used to show a spinner while loading data
  @track loaded = true;

  // Custom labels
  label = {
    agree,
    agreement,
    genericError,
    incentives,
    program
  }

  wireAgreements;

  @wire(getAgreements, { memberId: '$member' })
  agreements (value) {
    this.wireAgreements = value; // track the provisioned value
    const {data,error} = value; // destructure the provisioned value
    if (error){
      console.log(error);
    }
    if (data){
      this.memberAgreements = {};
      this.showMemberAgreements = false;

      if (data.incentives.length){
        this.showMemberAgreements = true;
        this.showIncentivesAgreements = true;
      }
      if (data.program.agreementId){
        this.showMemberAgreements = true;
        this.showProgramAgreement = true;
      }
      if (this.showMemberAgreements) {
        this.memberAgreements = JSON.parse(JSON.stringify(data));
      }
    }
  }

  handleClickAgree(event) {
    this.loaded = false;
    let button = event.currentTarget;
    button.disabled = true;
    
    acceptAgreement({
      agreementId: button.dataset.agreement,
      memberId: button.dataset.member,
      recordId: button.dataset.record
    })
    .then(result => {
      if (button.dataset.type === 'program') {
        this.memberAgreements.program.memberAgreed = true;
      }else{
        this.memberAgreements[button.dataset.type][button.dataset.index].memberAgreed = true;
      }
      this.loaded = true;
      refreshApex(this.wireAgreements);
    })
    .catch(error => {
      console.log(error);
      const toast = new ShowToastEvent({
        title: this.label.genericError,
        variant: 'error'
      });
      this.dispatchEvent(toast);
      this.loaded = true;
    });
  }

  handleClickCloseModal() {
    this.showMemberAgreements = false;
  }

}