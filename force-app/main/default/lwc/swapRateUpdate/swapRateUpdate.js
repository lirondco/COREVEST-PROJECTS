import { LightningElement,api } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import UpdateRate from '@salesforce/apex/update_Swap_Rate.UpdateRate';


export default class SwapRateUpdate extends LightningElement {
    
    @api recordId;
    isExecuting = false;    
    @api async invoke() {
        if (this.isExecuting) {
            return;
        }  
        console.log('SwapRateUpdate Execution Start Record id is : ' , this.recordId);
        this.isExecuting = true;
       // await this.sleep(500);
        this.isExecuting = false;
        UpdateRate({opportunityId : this.recordId})
        .then((result) => {
            console.log('result :', result);
            if (result == 'Success')
            {
            const event = new ShowToastEvent({
                title: 'Success!',
                message: 'Swap Rate Sucessfully Updated!',
                Varient: 'Success'
            });
            this.dispatchEvent(event);
            }
            else
            if (result == 'No Updates')
            {
            const event = new ShowToastEvent({
                title: 'Warning!',
                message: 'Failed to update the Swap Rate. The deal must be Term, not rate locked, not in Withdrawn or Rejected Stage, and Term Loan Type not blank.',
                Varient: 'warning'
            });
            this.dispatchEvent(event);
            } 
        })
        .catch((error) => {
          console.log("Swap Rate Update error");
          console.log(error);
        });
        console.log('SwapRateUpdate Execution Stop');
    } 
    // sleep(ms) {
    //    return new Promise((resolve) => setTimeout(resolve, ms));
    //}
}