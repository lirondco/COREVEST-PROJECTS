trigger Foreclosure_Trigger on Foreclosure__c (after insert, after update) {
  if(Trigger.isAfter && Trigger.isUpdate) {
    ForeclosureHelper.afterUpdate(Trigger.oldMap, Trigger.newMap);
  }

  if(Trigger.isAfter && Trigger.isInsert) {
    ForeclosureHelper.afterInsert(Trigger.New);
  }
}