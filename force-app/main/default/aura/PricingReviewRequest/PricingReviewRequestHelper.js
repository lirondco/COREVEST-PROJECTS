({
	toggleHide : function(component, name){
		$A.util.toggleClass(component.find(name), 'slds-hide');
	},

	parseData : function(returnVal, cb){
		var error = '';
		if (returnVal.wrongUser){
			error += 'You must be the originator in order to submit the pricing review. ';
		}
		if (returnVal.wrongStage){
			error += 'Inavlid Stage for Pricing Review Request. ';
		}
		if (Array.isArray(returnVal.nullFields) ){
			let list = returnVal.nullFields;
			let listStr = list.join(', ') + '.';
			error += 'These fields must be completed before initiating the pricing review: ';
			error += listStr;
		}
		cb(error);
	},
	
	doQueryPricingCount : function(component, helper) {
		let recId = component.get("v.recordId");
    let qpcAction = component.get("c.queryPricingCount");
		qpcAction.setParams({ recId });
		qpcAction.setCallback(this, function(res) {
			let state = res.getState();
			if(state === "SUCCESS") {
				 let value = res.getReturnValue();
				 component.set("v.requireComments", value > 0);
			} else {
				let errors = res.getError();
				if(errors) {
					let errMessages = component.get("v.errorMessage");
					if(errors[0] && errors[0].message) {
						errMessages.push(errors[0].message);
						console.error(errors[0].message);
					}
				} else {
					errMessages.push('An unknown exception has occured.');
				}
				component.set("v.errorMessage", errMessages);
			}
		});

		$A.enqueueAction(qpcAction);
	}
})