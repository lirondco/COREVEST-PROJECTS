trigger DealXFundingVehicleTrigger on Deal_x_Funding_Vehicle__c (after update) {
  if(Trigger.isAfter && Trigger.isUpdate) {
    DealXFundingVehicleHelper.afterUpdate(Trigger.oldMap, Trigger.new);
  }
}