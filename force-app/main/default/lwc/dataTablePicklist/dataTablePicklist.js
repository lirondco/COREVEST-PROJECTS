import { LightningElement, api } from 'lwc';

export default class DatatablePicklist extends LightningElement {
    @api label;
    @api placeholder;
    @api options;
    @api value;
    @api context;
    @api apiName;
    @api errorMessage;
    @api disabled = false;
    hasErrorLocal = false;
    isOpen = false;

    get fieldValue() {
        return this.disabled ? '' : this.value;
    }
    
    get showError() {
        return this.hasErrorLocal;
    }

    @api
    set showError(value) {
        this.hasErrorLocal = value;
    }

    get divClass() {
        return `picklist-container slds-form-element ${this.showError ? 'slds-has-error' : ''}`;
    }

    handleClick() {
        this.isOpen = true;
    }

    handleMouseOut() {
        this.isOpen = false;
    }

    handleChange(event) {
        //show the selected value on UI
        this.isOpen = false;
        this.value = event.detail.value;

        //fire event to send context and selected value to the data table
        this.dispatchEvent(new CustomEvent('picklistchanged', {
            composed: true,
            bubbles: true,
            cancelable: true,
            detail: {
                data: { context: this.context, value: this.value, apiName: this.apiName }
            }
        }));
    }

}