trigger PropertyExtensionTrigger on Property_Extension__c (after insert, after update) {
  if(Trigger.isAfter) {
    if(Trigger.isInsert) {
      PropertyExtensionHelper.afterInsert(Trigger.newMap);
    }

    if(Trigger.isUpdate) {
      PropertyExtensionHelper.afterUpdate(Trigger.oldMap, Trigger.newMap);
    }
  }
}