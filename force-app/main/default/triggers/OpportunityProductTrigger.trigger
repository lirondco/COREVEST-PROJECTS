trigger OpportunityProductTrigger on OpportunityLineItem (after update, after insert) {
  if(Trigger.isUpdate && Trigger.isAfter) {
    OpportunityProductHelper.afterUpdate(Trigger.oldMap, Trigger.new);
  }
  if(Trigger.isInsert && Trigger.isAfter) {
    OpportunityProductHelper.afterInsert(Trigger.new);
  }
}