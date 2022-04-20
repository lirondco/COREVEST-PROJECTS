trigger Foreclosure_Trigger on Foreclosure__c (after update) {
  if(Trigger.isAfter && Trigger.isUpdate) {
    ForeclosureHelper.afterUpdate(Trigger.oldMap, Trigger.newMap);
  }
}