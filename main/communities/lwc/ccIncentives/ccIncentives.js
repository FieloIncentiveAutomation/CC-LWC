import { LightningElement, track, api, wire } from 'lwc';
import getIncentives from '@salesforce/apex/CcIncentivesController.getIncentives';
import getIncentiveDetail from '@salesforce/apex/CcIncentivesController.getIncentiveDetail';
import enroll from '@salesforce/apex/CcIncentivesController.enroll';
import getMissionLeaderboard from '@salesforce/apex/CcIncentivesController.getMissionLeaderboard';
import getFieldData from '@salesforce/apex/LWCService.getWiredFieldData';
import getFieldSet from '@salesforce/apex/LWCService.getFieldSet';
import LANGUAGE from '@salesforce/i18n/lang';
import getLabel from '@salesforce/apex/LWCService.getLabel';
import getRecords from '@salesforce/apex/LWCService.getRecords';
import { CurrentPageReference } from 'lightning/navigation';
//import { registerListener, unregisterAllListeners, fireEvent } from 'c/pubsub';
import { refreshApex } from '@salesforce/apex';
import { ShowToastEvent } from 'lightning/platformShowToastEvent'


// Static Resource
//import DEFAULT_INCENTIVE_IMAGE from '@salesforce/resourceUrl/FieloPlt_Salesforce';

// Labels
/*import noResultsFound from '@salesforce/label/c.Cc_NoResultsFound';
import description from '@salesforce/label/c.CC_Description';
import missions from '@salesforce/label/c.CC_Missions';
import rules from '@salesforce/label/c.CC_Rules';
import seeMore from '@salesforce/label/c.CC_SeeMore';
import seeLess from '@salesforce/label/c.CC_SeeLess';
import sortByDisabled from '@salesforce/label/c.CC_SortByDisabled';
import sortByNewestFirst from '@salesforce/label/c.CC_SortByNewestFirst';
import sortByOldestFirst from '@salesforce/label/c.CC_SortByOldestFirst';
import myRecentActivity from '@salesforce/label/c.CC_MyRecentActivity';
import myPastActivity from '@salesforce/label/c.CC_MyPastActivity';
import sortBy from '@salesforce/label/c.CC_SortBy';
import eligibilityRequirements from '@salesforce/label/c.CC_EligibilityRequirements';
import eligibilityDescriptionWarning from '@salesforce/label/c.CC_EligibilityDescriptionWarning';
import qualified from '@salesforce/label/c.CC_Qualified';
import potential from '@salesforce/label/c.CC_Potential';
import listedIncentives from '@salesforce/label/c.CC_ListedIncentives';
import subscription from '@salesforce/label/c.Subscription';
import labelEnroll from '@salesforce/label/c.CC_Enroll';
import enrollGlobalMessage from '@salesforce/label/c.CC_EnrollGlobalChallenge';
import close from '@salesforce/label/c.Close';
import agree from '@salesforce/label/c.Agree';
import cancel from '@salesforce/label/c.Cancel';*/


// Constants
const MANDATORY_FIELDS = [
  'FieloPLT__Status__c',
  'FieloPLT__Period__c',
  'FieloPLT__StartDate__c',
  'FieloPLT__EndDate__c',
  'FieloPLT__CurrentAgreement__c'
];

const CHALLENGE = 'Challenge';
const STATUS_ALL = 'All';
const STATUS_ACTIVE = 'Active';

const SORT_BY_OPTIONS = [{
  label: sortByNewestFirst,
  value: 'Newest First'
},
{
  label: sortByOldestFirst,
  value: 'Oldest First'
}, {
  label: myRecentActivity,
  value: 'My Recent Activity'
}, {
  label: myPastActivity,
  value: 'My Past Activity'
}
];

const INCENTIVES_GROUPS = {
  myIncentives: {
    label: qualified,
    value: 'My Incentives'
  },
  apply: {
    label: potential,
    value: 'Apply'
  },
  notApply: {
    label: potential,
    value: 'Not Apply'
  },
  allAvailable: {
    label: potential,
    value: 'All Available'
  }
};

/**
 * Registers a callback for an event
 * @param {string} eventName - Name of the event to listen for.
 * @param {function} callback - Function to invoke when said event is fired.
 * @param {object} thisArg - The value to be passed as the this parameter to the callback function is bound.
 */
 const registerListener = (eventName, callback, thisArg) => {
  // Checking that the listener has a pageRef property. We rely on that property for filtering purpose in fireEvent()
  if (!thisArg.pageRef) {
      throw new Error(
          'pubsub listeners need a "@wire(CurrentPageReference) pageRef" property'
      );
  }

  if (!events[eventName]) {
      events[eventName] = [];
  }
  const duplicate = events[eventName].find((listener) => {
      return listener.callback === callback && listener.thisArg === thisArg;
  });
  if (!duplicate) {
      events[eventName].push({ callback, thisArg });
  }
};

/**
 * Unregisters all event listeners bound to an object.
 * @param {object} thisArg - All the callbacks bound to this object will be removed.
 */
 const unregisterAllListeners = (thisArg) => {
  Object.keys(events).forEach((eventName) => {
      events[eventName] = events[eventName].filter(
          (listener) => listener.thisArg !== thisArg
      );
  });
};

/**
 * Fires an event to listeners.
 * @param {object} pageRef - Reference of the page that represents the event scope.
 * @param {string} eventName - Name of the event to fire.
 * @param {*} payload - Payload of the event to fire.
 */
 const fireEvent = (pageRef, eventName, payload) => {
  if (events[eventName]) {
      const listeners = events[eventName];
      listeners.forEach((listener) => {
          if (samePageRef(pageRef, listener.thisArg.pageRef)) {
              try {
                  listener.callback.call(listener.thisArg, payload);
              } catch (error) {
                  // fail silently
              }
          }
      });
  }
};

export default class CcIncentives extends LightningElement {
  // builder properties
  @api listType;
  @api componentTitle;
  @api listImageField;
  @api listTitleField;
  @api listDescriptionField;
  @api recordImageField;
  @api recordTitleField;
  @api recordDescriptionField;
  @api eligibilityMode;
  @api recordMoreFields;
  @api filterMoreFields;
  // end

  // list where the fields to be queried will be stored
  fields = [];
  @track sortByOptions = [];
  // param to be updated any time we need new results
  @track getIncentivesParams = {
    recordsPerPage: 9, // (8 + 1) added plus one to check if there is more results for the paginator
    offset: 0,
    orderBy: 'FieloPLT__ActivationDate__c DESC NULLS LAST, createddate DESC' // Newest First
  };

  // param to be updated any time we need new results
  @track getIncentiveDetailParams = {
    type: '',
    id: '',
    memberId: ''
  };

  // used to show a spinner while loading data
  @track loaded = false;

  // map of list data for markup
  @track recordsForList = [];

  // map of record datafor markup
  recordsForDetail = [];

  // map of metadata for the more fields
  metadata = {};

  incentivesGroups = [];

  // Flag to show the Enroll and Eligibility buttons in the markup
  showEnrollButton = false;
  showEligibilityButton = false;

  // defaultImage
  defaultImage = '';

  // record data to pass to the markup
  @track record = {};

  // flag to toggle visibility of more fields container
  @track showMoreFields = false;

  // member information loaded by the member selector
  @track member = {
    id: ''
  };

  @track leaderboardInfo = {};

  // Custom labels
  label = {
    /*noResultsFound,
    description,
    missions,
    rules,
    seeMore,
    seeLess,
    sortBy,
    sortByDisabled,
    eligibilityRequirements,
    eligibilityDescriptionWarning,
    listedIncentives,
    enroll: labelEnroll,
    enrollGlobalMessage,
    subscription,
    close,
    agree,
    cancel*/
  }

  // disabled conditions for markup
  disabledCondition = {
    previousButton: true,
    nextButton: true
  }

  @track objectName = '';
  @track objectFields = '';
  filterFields = "FieloPLT__Status__c,FieloPLT__StartDate__c,FieloPLT__EndDate__c";

  // Filter list for HMTL
  @track filterDataList = [];
  // Filter Object for JS
  filterDataObject = {};

  // filters select by user
  filters = {};
  listedIncentive = INCENTIVES_GROUPS.myIncentives.value;
  rawStatusPicklistentries = {}

  @track showAgreement = false;
  @track agreement = {};

  // used for events handling with member selector
  @wire(CurrentPageReference) pageRef;


  incentivesValue;
  incentivesValueDetails;

  /**
   * Gets the incentives and maps them
   * @param {*} param0
   */
  @wire(getIncentives, { params: '$getIncentivesParams' })
  incentives(value) {
    // Hold on to the provisioned value so we can refresh it later.
    this.incentivesValue = value; // track the provisioned value
    const { data, error } = value; // destructure the provisioned value
    if (error) {
      console.warn(JSON.stringify(error, '', 2));
    }
    if (data) {
      let items = [];
      // reset previousButton state
      if (this.getIncentivesParams.offset === 0) {
        this.disabledCondition.previousButton = true;
      } else {
        this.disabledCondition.previousButton = false;
      }

      if (data.length === this.getIncentivesParams.recordsPerPage) {
        this.disabledCondition.nextButton = false;
        // once paginator state is calculated we'll remove the last item wich we don't need
        items = data.slice(0, -1);
      } else {
        this.disabledCondition.nextButton = true;
        items = data;
      }

      // maps data
      this.recordsForDetail = [];
      this.recordsForList = [];
      let defaultImage = '';

      items.forEach(item => {
        // set eligibility data
        let eligibility = {};
        eligibility.eligible = item.eligible;
        eligibility.viewDashboard = false;
        eligibility.segment = item.FieloPLT__Segment__c || '';
        eligibility.cssClass =
          'fielo-incentives__list-item-button ' + (item.eligible ? 'slds-hidden' : '');
        eligibility.description = '';
        if (!item.FieloPLT__EligibilityViewMode__c) {
          eligibility.description = item.FieloPLT__EligibilityDescriptionView__c || this.label.eligibilityDescriptionWarning;
        }

        this.recordsForList.push({
          id: item.Id,
          type: item.type,
          eligibility,
          title: item[this.listTitleField],
          image: item[this.listImageField] || this.defaultImage,
          description: item[this.listDescriptionField],
          subscriptionMode: item.FieloPLT__Subscription__c,
          agreementId: item.FieloPLT__CurrentAgreement__c || null
        });

        let moreFieldsValues = {};

        this.recordMoreFields.split(',').forEach(itemMD => {
          moreFieldsValues[itemMD] = item[itemMD];
        });

        let teams = [];
        if (item.FieloPLT__TargetAudience__c && item.FieloPLT__TargetAudience__c === 'Team') {
          item.FieloPLT__ChallengesMembers__r.records.forEach(team => {
            teams.push({
              label: team.FieloPLT__Member__r.Name,
              value: team.FieloPLT__Member__r.Id
            });
          });
        }
        let statusItem = ((item.fieloplt__status__c_label == 'Edited') ? STATUS_ACTIVE : item.fieloplt__status__c_label);
        this.recordsForDetail.push(
          Object.assign(
            {
              id: item.Id,
              type: item.type,
              title: item[this.recordTitleField],
              image: item[this.recordImageField] || this.defaultImage,
              description: item[this.recordDescriptionField],
              status: statusItem,
              period: item.FieloPLT__Period__c,
              start: item.FieloPLT__StartDate__c,
              end: item.FieloPLT__EndDate__c,
              teams
            },
            moreFieldsValues
          )
        );
      });
    }
    this.loaded = true;
  };




  /**
   * Gets metadata from requested fields
   * @param {*} param0 - we pass the object name and the fields
   */

  @wire(getFieldData, { objectName: '$objectName', fieldNames: '$objectFields', enableDependentPicklist: false })
  fieldData({ error, data }) {
    if (error) {
      console.log(error);
    }
    if (data) {
      JSON.parse(data).fields.forEach(field => {
        if (field.picklistentries) {
          field.picklistentries.unshift(
            {
              label: STATUS_ALL,
              value: STATUS_ALL
            });
          this.metadata[field.attributes.name] = {
            type: field.attributes.type,
            label: field.attributes.label,
            picklistentries: field.picklistentries
          }
        } else {
          this.metadata[field.attributes.name] = {
            type: field.attributes.type,
            label: field.attributes.label
          }
        }
      });

      this.metadata.FieloPLT__Status__c.picklistentries.forEach(function (item, key) {
        if (item.value === 'Draft') {
          this.metadata.FieloPLT__Status__c.picklistentries.splice(key, 1);
        }
      }.bind(this));

      this.rawStatusPicklistentries = this.metadata["FieloPLT__Status__c"].picklistentries;

      this.filterFields.split(",").forEach(item => {
        let type = {
          string: false,
          date: false,
          startDate: false,
          endDate: false,
          number: false,
          picklist: false,
          boolean: false
        }
        let fieldType = this.metadata[item].type;
        let isRange = false;
        switch (fieldType) {
          case 'double': fieldType = 'number'; break;
          case 'auto number':
          case 'formula':
          case 'textarea': fieldType = 'string'; break;
          case 'datetime': fieldType = 'date'; break;
        }

        if (item === "FieloPLT__StartDate__c") {
          type.startDate = true;
        } else {
          if (item === "FieloPLT__EndDate__c") {
            type.endDate = true;
          } else {
            if (this.metadata[item]) {
              type[fieldType] = true;
              if (this.metadata[item].type === 'number' ||
                this.metadata[item].type === 'date' ||
                this.metadata[item].type === 'datetime') {
                isRange = true;
              }
            }
          }
        }

        if (this.metadata[item]) {
          this.filterDataObject[item] = {
            name: item,
            rangeStart: item + '_start',
            rangeEnd: item + '_end',
            label: this.metadata[item].label,
            type,
            fieldType,
            isRange,
            picklistentries: this.metadata[item].picklistentries
          }
          if (fieldType === 'picklist') {
            this.filterDataObject[item].value = STATUS_ALL;
          }
        } else {
          console.warn(item + ' does not exist or do not have permissons');
        }
      });

      this.filterDataList = Object.values(this.filterDataObject);
      this.setStatusOptions();
      this.setFieldsToQuery();
      this.setInitialIncentivesParams();

      this.filterDataObject.FieloPLT__Status__c.value = 'Active';

      this.filters.FieloPLT__Status__c = {
        field: 'FieloPLT__Status__c',
        value: 'Active',
        operator: 'equal',
        andOrOperator: '',
        openPars: '('
      }

      this.filters.FieloPLT__Status__c_Edited = {
        field: 'FieloPLT__Status__c',
        value: 'Edited',
        operator: 'equal',
        andOrOperator: 'OR',
        closePars: ')'
      }
      this.setFilter();

    }
  }

  /**
   * runs once inserted into the DOM but before rendering
   */
  connectedCallback() {
    this.setMetadataObjectConfig();
    this.setIncentivesListOptions();
    this.setSortByOptions();
    this.setTitle();

    // subscribe to memberChange event
    registerListener('memberChange', this.handleMemberChange, this);
    if (this.member.id === '') {
      // be sure to show the spinner
      this.loaded = false;
      fireEvent(this.pageRef, 'getMember', '');
    }
  }

  /**
   * runs when removed form DOM
   */
  disconnectedCallback() {
    // unsubscribe from memberChange event
    unregisterAllListeners(this);
  }

  /**
   * Handles the click of the list image
   * @param {*} event
   */
  handleClickListImage(event) {
    this.fillRecordObject(event.currentTarget.dataset.index)
  }
  /**
   * Handles the click of the list title
   * @param {*} event
   */
  handleClickListTitle(event) {
    this.fillRecordObject(event.currentTarget.dataset.index)
  }

  /**
   * Handles the click of the previous button (paginator)
   * @param {*} event
   */
  handleClickPrevious() {
    if (this.getIncentivesParams.offset > 0) {
      // -1 to balance for the added one for calculating the disable condition
      this.updateIncentivesParams({
        offset: this.getIncentivesParams.offset - this.getIncentivesParams.recordsPerPage + 1
      });
    }
  }

  /**
   * Handles the click of the next button (paginator)
   * @param {*} event
   */
  handleClickNext() {
    // -1 to balance for the added one for calculating the disable condition
    this.updateIncentivesParams({
      offset: this.getIncentivesParams.offset + this.getIncentivesParams.recordsPerPage - 1
    });
  }

  /**
   * Runs When a member is changed because of a member event
   * @param {*} payload
   */
  handleMemberChange(payload) {
    if (this.member.id !== payload.member.Id) {
      this.member = payload.member;
      this.member.id = this.member.Id;

      this.updateIncentivesParams({ memberId: this.member.id });
    }
  }
  /**
   * Updates the params in order to fire the wire again
   * @param {*} params
   */
  updateIncentivesParams(params) {
    this.loaded = false;
    this.recordsForList = [];
    this.getIncentivesParams = Object.assign({}, this.getIncentivesParams, params);
  }

  /**
   * Puts the corresponding record data into the record property
   * @param {*} position
   */
  fillRecordObject(position = null) {
    if (position) {
      this.record = this.recordsForDetail[position];

      // set team value if available
      if (this.record.teams.length) {
        this.record.selectedTeam = this.record.teams[0].value;
      }
      // More Fields
      var moreFields = [];

      if (this.recordMoreFields) {
        this.recordMoreFields.split(',').forEach(item => {
          if (this.metadata[item]) {
            let label = this.metadata[item].label;
            let value = this.record[item];
            if (this.metadata[item].type == 'datetime') {
              value = new Date(value).valueOf();
            }
            switch (this.metadata[item].type) {
              case "date":
              case "datetime":
              case "boolean":
                this.metadata[item].type = this.metadata[item].type; break;
              default:
                this.metadata[item].type = 'string'; break;
            }
            let type = {
              date: false,
              datetime: false,
              string: false,
              boolean: false
            }
            type[this.metadata[item].type] = true;
            moreFields.push({
              label,
              value,
              type,
              typeField: this.metadata[item].type
            })
          }
        });
      }
      this.record.moreFields = moreFields;
      // get missions, ranks, rules, etc
      try {
        this.getIncentiveDetailParams = {
          params: {
            type: this.record.type,
            id: this.record.id,
            memberId: this.member.id
          }
        }
      }

      catch (e) {
        console.error(e);
      }


      getIncentiveDetail(this.getIncentiveDetailParams)
        .then(data => {
          this.record.progress = data.progress;
          this.record.missions = [];
          this.record.missionsObject = {};
          this.record.rules = [];
          this.record.hasMission = false;
          this.record.hasRules = false;

          if (data.missions) {
            this.record.hasMission = true;
            data.missions.forEach(item => {
              var hasPeriod = false;
              if (item.FieloPLT__StartDate__c || item.FieloPLT__EndDate__c) {
                hasPeriod = true;
              }
              let progress = {};
              progress.porcentage = 0;
              progress.value = 0;
              if (this.record.progress.hasOwnProperty(this.record.selectedTeam) || this.record.progress.hasOwnProperty(this.member.id)) {
                progress = Object.assign(
                  {}, progress, this.record.progress[this.record.selectedTeam || this.member.id].missions[item.Id]
                );
              }
              if (progress.objectiveValue && progress.type === "With Objective") {
                progress.percentage =
                  progress.value * 100 /
                  progress.objectiveValue;
              }

              this.record.missionsObject[item.Id] = {
                id: item.Id,
                name: item.Name,
                description: item.FieloPLT__Description__c,
                hasPeriod: hasPeriod,
                start: item.FieloPLT__StartDate__c,
                end: item.FieloPLT__EndDate__c,
                isTypeWithObjective: item.FieloPLT__Type__c === 'With Objective' ? true : false,
                hasLeaderboard: item.FieloPLT__LeaderboardMode__c || false,
                descriptionSize: item.FieloPLT__LeaderboardMode__c ? '6' : '12',
                progress: progress
              };

              this.record.missions.push(this.record.missionsObject[item.Id]);

            })
          }
          if (data.rules) {
            this.record.hasRules = true;
            data.rules.forEach(item => {
              this.record.rules.push(
                {
                  id: item.Id,
                  name: item.Name,
                  description: item.FieloPLT__Description__c
                }
              );
            })
          }
        })
        .catch(error => {
          console.warn(JSON.stringify(error, '', 2));
        })
    } else {
      this.record = {};
    }
  }

  handleClickCloseModal() {
    this.record = {};
    this.showMoreFields = false;
    this.showAgreement = false;
  }

  handleClickSeeMore() {
    this.showMoreFields = !this.showMoreFields;
  }

  handleClickEligibilityButton(event) {
    this.recordsForList[event.currentTarget.dataset.index]
      .eligibility.viewDashboard =
      !this.recordsForList[event.currentTarget.dataset.index]
        .eligibility.viewDashboard;
  }

  handleClickEnroll(event) {
    let index = event.currentTarget.dataset.index;
    if (this.recordsForList[index].subscriptionMode === 'Global') {
      const toast = new ShowToastEvent({
        title: this.label.enrollGlobalMessage,
        variant: 'warning'
      });
      this.dispatchEvent(toast);
    } else {
      if (this.recordsForList[index].agreementId) {

        getRecords({
          fields: 'FieloPLT__Agreement__c,LastModifiedDate',
          objectName: 'FieloPLT__Agreement__c',
          dataFilters: JSON.stringify({ Id: this.recordsForList[index].agreementId })
        })
          .then(result => {
            this.agreement.title = this.recordsForList[index].title;
            this.agreement.date = result[0].LastModifiedDate;
            this.agreement.text = result[0].FieloPLT__Agreement__c;
            this.agreement.index = index;
            this.showAgreement = true;
          })
          .catch(error => {
            console.log(error);
            const toast = new ShowToastEvent({
              title: error,
              variant: 'error'
            });
            this.dispatchEvent(toast);
          });

      } else {
        this.doEnroll(index);
      }
    }

  }

  handleClickAgree(event) {
    let index = event.currentTarget.dataset.index;
    this.doEnroll(index);
    this.handleClickCloseModal();
  }

  doEnroll(index) {
    this.loaded = false;
    enroll({
      params: {
        memberId: this.member.id,
        incentiveId: this.recordsForList[index].id,
        agreementId: this.recordsForList[index].agreementId,
        type: this.recordsForList[index].type
      }
    })
      .then(result => {

        const toast = new ShowToastEvent({
          title: this.label.subscription + ' ' + this.recordsForList[index].title,
          variant: 'success'
        });
        this.dispatchEvent(toast);

        refreshApex(this.incentivesValue);
      })
      .catch(error => {
        console.log(error);
        const toast = new ShowToastEvent({
          title: error,
          variant: 'error'
        });
        this.dispatchEvent(toast);
      });
  }

  /**
   * Handles the change of the sortBy filter
   * @param {*} event
   */
  handleChangeSortBy(event) {
    let orderBy = null;
    let orderByMemberActivity = null;
    let offset = 0;
    switch (event.currentTarget.value) {
      case 'Newest First':
        orderBy = 'FieloPLT__ActivationDate__c DESC NULLS LAST, createddate DESC';
        orderByMemberActivity = null;
        break;
      case 'Oldest First':
        orderBy = 'FieloPLT__ActivationDate__c ASC NULLS LAST, createddate ASC';
        orderByMemberActivity = null;
        break;
      case 'My Recent Activity':
        orderBy = null;
        orderByMemberActivity = 'FieloPLT__LastActivity__c Desc NULLS LAST, createddate DESC';
        break;
      case 'My Past Activity':
        orderBy = null;
        orderByMemberActivity = 'FieloPLT__LastActivity__c ASC NULLS LAST, createddate ASC';
        break;
      default:
        break;
    }
    this.updateIncentivesParams({
      orderBy,
      orderByMemberActivity,
      offset
    });
  }


  /**
   * Handles dynamic change for filters
   * @param {Event} event
   */
  handleFilterChange(event) {
    // update object Value
    if (this.filterDataObject[event.currentTarget.dataset.fieldName].isRange) {
      if (event.currentTarget.dataset.range === 'start') {
        this.filterDataObject[event.currentTarget.dataset.fieldName].valueStart =
          event.currentTarget.value;
      } else {
        this.filterDataObject[event.currentTarget.dataset.fieldName].valueEnd =
          event.currentTarget.value;
      }
    } else {
      this.filterDataObject[event.currentTarget.dataset.fieldName].value =
        event.currentTarget.value;
    }

    switch (event.currentTarget.name) {
      case 'FieloPLT__Status__c':
        this.handleFilterStatus(event);
        break;
      case 'FieloPLT__StartDate__c':
        this.handleFilterStart(event);
        break;
      case 'FieloPLT__EndDate__c':
        this.handleFilterEnd(event);
        break;
      default:
        switch (this.filterDataObject[event.currentTarget.dataset.fieldName].fieldType) {
          case 'picklist':
            this.handleFilterTypePicklist(event);
            break;
          case 'date':
            this.handleFilterTypeRange(event);
            break;
          case 'number':
            this.handleFilterTypeRange(event);
            break;
          case 'boolean':
            this.handleFilterTypeBoolean(event);
            break;
          case 'string':
            this.handleFilterTypeString(event);
            break;
        }
        break;
    }
  }

  handleFilterStatus(event) {
    if (event.currentTarget.value == STATUS_ALL) {
      delete this.filters.FieloPLT__Status__c;
      delete this.filters.FieloPLT__Status__c_Edited;
    } else {
      this.filters.FieloPLT__Status__c = {
        field: 'FieloPLT__Status__c',
        value: event.currentTarget.value,
        operator: 'equal',
        andOrOperator: ''
      }
      if (event.currentTarget.value == 'Active') {
        this.filters.FieloPLT__Status__c.openPars = '(';

        this.filters.FieloPLT__Status__c_Edited = {
          field: 'FieloPLT__Status__c',
          value: 'Edited',
          operator: 'equal',
          andOrOperator: 'OR',
          closePars: ')'
        }
      }
    }
    this.setFilter();
  }
  handleFilterTypePicklist(event) {
    if (event.currentTarget.value == STATUS_ALL) {
      delete this.filters[event.currentTarget.name];
    } else {
      this.filters[event.currentTarget.name] = {
        field: event.currentTarget.name,
        value: event.currentTarget.value,
        operator: 'equal',
        andOrOperator: ''
      }
    }
    this.setFilter();
  }

  handleFilterStart(event) {
    if (event.currentTarget.value) {
      this.filters.FieloPLT__StartDate__c = {
        field: 'FieloPLT__StartDate__c',
        value: event.currentTarget.value,
        operator: 'greater or equal',
        andOrOperator: ''
      }
    } else {
      delete this.filters.FieloPLT__StartDate__c;
    }
    this.setFilter();
  }

  handleFilterEnd(event) {
    if (event.currentTarget.value) {
      this.filters.FieloPLT__EndDate__c = {
        field: 'FieloPLT__EndDate__c',
        value: event.currentTarget.value,
        operator: 'less or equal',
        andOrOperator: ''
      }
    } else {
      delete this.filters.FieloPLT__EndDate__c;
    }
    this.setFilter();
  }

  handleFilterTypeRange(event) {
    let operator = 'greater or equal';
    if (event.currentTarget.dataset.range === 'end') {
      operator = 'less or equal';
    }
    if (event.currentTarget.value) {
      this.filters[event.currentTarget.name] = {
        field: event.currentTarget.dataset.fieldName,
        value: event.currentTarget.value,
        operator,
        andOrOperator: ''
      }
    } else {
      delete this.filters[event.currentTarget.name];
    }
    this.setFilter();
  }

  handleFilterTypeString(event) {
    if (event.currentTarget.value) {
      this.filters[event.currentTarget.name] = {
        field: event.currentTarget.name,
        value: event.currentTarget.value,
        operator: 'equal',
        andOrOperator: ''
      }
    } else {
      delete this.filters[event.currentTarget.name];
    }
    this.setFilter();
  }

  handleFilterTypeBoolean(event) {
    this.filters[event.currentTarget.name] = {
      field: event.currentTarget.name,
      value: event.currentTarget.checked,
      operator: 'equal',
      andOrOperator: ''
    }
    this.setFilter();
  }

  setFilter() {
    let offset = 0;
    let filters = Object.values(this.filters);
    console.log(filters);
    this.updateIncentivesParams({ filters, offset });
  }

  handleChangeListedIncentives(event) {
    if (event.currentTarget.value) {
      let setName = this.listedIncentive = event.currentTarget.value;
      // show Enroll / Eligibility buttons
      if (setName === INCENTIVES_GROUPS.myIncentives.value) {
        this.showEligibilityButton = false;
        this.showEnrollButton = false;
      } else {
        this.showEligibilityButton = true;
        this.showEnrollButton = true;
      }

      this.setStatusOptions();
      this.setSortByOptions();
      this.updateIncentivesParams({
        offset: 0,
        setName,
        filters: Object.values(this.filters)
      });
    }
  }

  /**
   * Set the status according to the incentives being listed
   */
  setStatusOptions() {
    let validOptions = [];
    if (this.listType === CHALLENGE) {
      switch (this.listedIncentive) {
        case INCENTIVES_GROUPS.myIncentives.value:
          validOptions.push('Inactive');
          validOptions.push('Completed');

        case INCENTIVES_GROUPS.myIncentives.value:
        case INCENTIVES_GROUPS.apply.value:
        case INCENTIVES_GROUPS.allAvailable.value:
        case INCENTIVES_GROUPS.notApply.value:
          validOptions.push(STATUS_ALL);
          validOptions.push('Scheduled');
          validOptions.push('Active');
          break;
        default:
          break;
      }

    } else {
      validOptions.push(STATUS_ALL);
      validOptions.push('Scheduled');
      validOptions.push('Active');
    }

    // filter the compatible status depending on the incentives listed
    this.filterDataObject.FieloPLT__Status__c.picklistentries =
      this.rawStatusPicklistentries.filter(item => {
        return validOptions.includes(item.value)
      });

    if (!validOptions.includes(this.filterDataObject.FieloPLT__Status__c.value)) {
      this.filterDataObject.FieloPLT__Status__c.value = STATUS_ALL;
      delete this.filters.FieloPLT__Status__c;
    }
  }

  setSortByOptions() {
    if (
      this.listType === CHALLENGE &&
      this.listedIncentive === INCENTIVES_GROUPS.myIncentives.value
    ) {
      this.sortByOptions = SORT_BY_OPTIONS;
    } else {
      this.sortByOptions = SORT_BY_OPTIONS.slice(0, 2);
    }
  }

  setIncentivesListOptions() {
    // set Incentives list options (for filter)
    this.incentivesGroups.push(INCENTIVES_GROUPS.myIncentives);

    switch (this.eligibilityMode) {
      case 'All':
        this.incentivesGroups.push(INCENTIVES_GROUPS.allAvailable);
        break;
      case INCENTIVES_GROUPS.notApply.value:
        this.incentivesGroups.push(INCENTIVES_GROUPS.notApply);
        break;
      case INCENTIVES_GROUPS.apply.value:
        this.incentivesGroups.push(INCENTIVES_GROUPS.apply);
        break;
    }
  }

  setInitialIncentivesParams() {
    let setName = null;
    setName = this.listedIncentive = INCENTIVES_GROUPS.myIncentives.value;
    if (this.listType === CHALLENGE) {
      //this.defaultImage = DEFAULT_INCENTIVE_IMAGE + '/images/challenge.png';
      this.defaultImage = '../plt/main/default/staticresources/FieloPlt_Salesforce/images/challenge.png';
    } else {
      //this.defaultImage = DEFAULT_INCENTIVE_IMAGE + '/images/promotion.png';
      this.defaultImage = '../plt/main/default/staticresources/FieloPlt_Salesforce/images/promotion.png';
    }

    // set init params
    this.updateIncentivesParams({
      type: this.listType,
      fields: this.fields,
      setName
    });
  }

  /**
   * Sets the title of the component
   */
  setTitle() {
    // set the title of the component
    if (this.componentTitle.startsWith('Label.')) {
      getLabel({
        labelName: this.componentTitle.slice(6),
        language: LANGUAGE
      })
        .then(label => {
          this.componentTitle = label;
        })
        .catch(error => {
          console.log(error);
          this.componentTitle = '';
        });
    }
  }

  /**
   * Sets a unique lists of fields to query
   */
  setFieldsToQuery() {
    // set fields
    var tempMF = [];
    if (this.recordMoreFields) {
      tempMF = this.recordMoreFields.split(',');
    }
    let challengeFields = [];
    if (this.listType === CHALLENGE) {
      challengeFields.push('FieloPLT__TargetAudience__c');
    }
    this.fields = [
      ...new Set([
        ...MANDATORY_FIELDS,
        ...tempMF,
        ...challengeFields,
        this.listImageField,
        this.listTitleField,
        this.listDescriptionField,
        this.recordImageField,
        this.recordTitleField,
        this.recordDescriptionField
      ])
    ];
  }

  /**
   * Sets the object fields and name for getting the metadata
   */
  setMetadataObjectConfig() {
    this.fieldsetCalls = 0;
    this.fieldsetToBeCall = 0;
    let objectName = this.listType === CHALLENGE ? 'FieloPLT__Challenge__c' : 'FieloPLT__Promotion__c';

    // avoids calling getFieldData with an objectName defined and without more fields
    // if this isn't done this way, all the metadata will be fetch
    if (this.filterMoreFields) {
      this.fieldsetToBeCall++;
      getFieldSet({
        objectApiName: objectName,
        fieldSetName: this.filterMoreFields
      })
        .then(result => {
          this.filterMoreFields = result.join();
          this.filterFields += ',' + result.join();

          if (this.objectFields !== '') {
            this.objectFields += ',';
          }
          this.objectFields += this.filterFields;
          this.fieldsetCalls++;
          if (this.fieldsetCalls === this.fieldsetToBeCall) {
            this.objectName = objectName;
          }
        })
        .catch(error => {
          console.log(error);
        });
    } else {
      this.objectFields = this.filterFields;
    }
    if (this.recordMoreFields) {
      this.fieldsetToBeCall++;
      getFieldSet({
        objectApiName: objectName,
        fieldSetName: this.recordMoreFields
      })
        .then(result => {
          // Avoid render Name and CreatedDate inside the See More Fields option
          // The Name and CreatedDate is the default return from getFieldSet when fail
          if (result[0] === 'Name' && result[1] === 'CreatedDate') {
            return;
          }
          this.recordMoreFields = result.join();

          if (this.objectFields !== '') {
            this.objectFields += ',';
          }
          this.objectFields += this.recordMoreFields;
          this.fieldsetCalls++;
          if (this.fieldsetCalls === this.fieldsetToBeCall) {
            this.objectName = objectName;
          }
        })
        .catch(error => {
          console.log(error);
        });
    }
    this.objectName = objectName;
  }

  handleSectionToggle(event) {
    if (this.record.missionsObject[event.currentTarget.activeSectionName].hasLeaderboard) {
      this.leaderboardInfo = {
        isTypeWithObjective: this.record.missionsObject[event.currentTarget.activeSectionName].isTypeWithObjective,
        myPosition: {},
        missionId: event.currentTarget.activeSectionName,
        leaderboard: []
      }
      this.getLeaderboard();
    }
  }

  getLeaderboard() {
    this.leaderboardInfo.leaderboard = [];
    this.leaderboardInfo.myPosition = {};
    getMissionLeaderboard({
      params: {
        memberId: this.record.selectedTeam || this.member.id,
        missionId: this.leaderboardInfo.missionId
      }
    })
      .then(result => {
        if (result.length) {
          let value = this.leaderboardInfo.isTypeWithObjective ? result[0].FieloPLT__LeaderboardValue__c * 100 : result[0].FieloPLT__LeaderboardValue__c;
          this.leaderboardInfo.myPosition = {
            position: result[0].FieloPLT__LeaderboardPosition__c,
            name: result[0].FieloPLT__ChallengeMember__r.FieloPLT__Member__r.Name,
            img: result[0].FieloPLT__ChallengeMember__r.FieloPLT__Member__r.FieloPLT__ExternalURL__c || DEFAULT_INCENTIVE_IMAGE + '/images/member.png',
            value,
            className: 'fielo-incentives__mission-leaderboard-item fielo-incentives__mission-leaderboard-item--is-my-position'
          }
        }

        getMissionLeaderboard({
          params: {
            memberId: null,
            missionId: this.leaderboardInfo.missionId
          }
        })
          .then(result => {
            if (result.length) {
              let addMyPosition = true;
              let value = 0;
              result.forEach(position => {
                value = this.leaderboardInfo.isTypeWithObjective ? position.FieloPLT__LeaderboardValue__c * 100 : position.FieloPLT__LeaderboardValue__c;
                this.leaderboardInfo.leaderboard.push(
                  {
                    position: position.FieloPLT__LeaderboardPosition__c,
                    name: position.FieloPLT__ChallengeMember__r.FieloPLT__Member__r.Name,
                    img: position.FieloPLT__ChallengeMember__r.FieloPLT__Member__r.FieloPLT__ExternalURL__c || DEFAULT_INCENTIVE_IMAGE + '/images/member.png',
                    value,
                    className: position.FieloPLT__LeaderboardPosition__c == this.leaderboardInfo.myPosition.position ? 'fielo-incentives__mission-leaderboard-item fielo-incentives__mission-leaderboard-item--is-my-position' : 'fielo-incentives__mission-leaderboard-item'
                  }
                )
                if (position.FieloPLT__LeaderboardPosition__c == this.leaderboardInfo.myPosition.position && addMyPosition) {
                  addMyPosition = false;
                }
                if (!this.leaderboardInfo.myPosition.position) {
                  addMyPosition = false;
                }
              })
              if (addMyPosition) {
                this.leaderboardInfo.leaderboard.push(this.leaderboardInfo.myPosition);
              }
            }
          })
          .catch(error => {
            console.log(error);
          });

      })
      .catch(error => {
        console.log(error);
      });
  }

  handleChangeTeam(event) {
    this.record.selectedTeam = event.currentTarget.value;
    this.updateMissionProgress();
    this.getLeaderboard();
  }

  updateMissionProgress() {
    this.record.missions.forEach(mission => {
      let percentage = parseFloat(this.record.progress[this.record.selectedTeam].missions[mission.id].value) * 100 /
        parseFloat(this.record.progress[this.record.selectedTeam].missions[mission.id].objectiveValue);

      mission.progress = Object.assign({},
        this.record.progress[this.record.selectedTeam].missions[mission.id], { percentage }
      );

      this.record.missionsObject[mission.id] = mission;
    });
  }
}
