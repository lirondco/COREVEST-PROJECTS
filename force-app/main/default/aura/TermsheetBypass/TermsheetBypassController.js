({
	init : function(component, event, helper) {
		let recordId = component.get('v.recordId');

		let action = component.get('c.returnDeal');
		action.setParams({recordId: recordId});
		action.setCallback(this, function(response){
			var state = response.getState();
			if (state === 'SUCCESS'){
				var returnVal = JSON.parse(response.getReturnValue());
                let errorMessages = [];

				if (returnVal.Error && returnVal.Error.length > 0){
					errorMessages.push('You can only submit a term sheet for approval after a pricing review has been approved and a term sheet has been generated.');
				}
                if (returnVal.TermSheetError && returnVal.TermSheetError.length > 0){
					errorMessages.push('You can only bypass termsheet approval after a term sheet has been generated.');
				}
                
                if (returnVal.ValidationError && returnVal.ValidationError.length > 0){
					errorMessages = errorMessages.concat(returnVal.ValidationError);
				}

                if(errorMessages.length > 0) {
                    helper.toggleHide(component, 'validationError');
                    component.set("v.validationErrorMessages", errorMessages);
                } else {
                    helper.toggleHide(component, 'allowed');
				}
			} else {
				console.log(response.getError());
			}
		});
		$A.enqueueAction(action);

    },
    
    bypass : function(component, event, helper){
        // console.log('bypass deal');
        component.set('v.submitting', true);
        let action = component.get('c.bypassDeal');
        action.setParams({recordId: component.get('v.recordId')});

        action.setCallback(this, response =>{
            let state = response.getState();

            if(state === 'SUCCESS'){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Success!",
                    "type": 'success',
                    "message": "Termsheet Approval successfully bypassed"
                });
                toastEvent.fire();
                $A.get("e.force:closeQuickAction").fire();
                $A.get('e.force:refreshView').fire();

            }else if(state === 'ERROR'){
                var toastEvent = $A.get("e.force:showToast");
                toastEvent.setParams({
                    "title": "Error!",
                    "type": 'error',
                    "message": response.getError()[0].message
                });
                toastEvent.fire();
                
                component.set('v.submitting', true);
            }

        });

        $A.enqueueAction(action);


    },

    closeWindow : function(component, event, helper){
        $A.get("e.force:closeQuickAction").fire();
    }

})