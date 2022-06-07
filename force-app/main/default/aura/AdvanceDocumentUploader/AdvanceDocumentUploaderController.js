({
    handleRecordUpdated : function(component, event, helper) {
        var eventParams = event.getParams();
        if(eventParams.changeType === "LOADED") {
            let recordType = component.get("v.advRecord.Deal__r.RecordType.DeveloperName");
            const recTypesToChange = ["Acquired_Bridge_Loan_Active", "Acquired_Bridge_Loan", "Table_Funded_CRE_Loan", "Table_Funded_CRE_Loan_Active"];
            if (recTypesToChange.includes(recordType)) {
              recordType = "LOC_Loan";
            }
            component.set("v.recordType", recordType);
        } else if(eventParams.changeType === "CHANGED") {
            // record is changed
        } else if(eventParams.changeType === "REMOVED") {
            // record is deleted
        } else if(eventParams.changeType === "ERROR") {
            // there’s an error while loading, saving, or deleting the record
        }

    }
})