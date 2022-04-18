public with sharing class SABAdvanceMemoExtension {
    public Advance__c record {get; set;}
    public string ExceptionRequested{get; set;}
    public string CompensatingFactors{get; set;}
    public string Comments{get; set;}
    public string Funding{get; set;}
    public Property_Advance__c propAdv{get; set;}
    public Opportunity deal{get; set;}
    public deal_contact__c sponsor{get;set;}
    public List<Deal_Contact__c> guarantors {get; set;}
    public Decimal TotalOriginationFee {get;set;}
    public Decimal borrowerEquityPercent {get;set;}
    public Decimal AdjustedFundingAmount {get;set;}
    public Decimal NetWireAmount {get;set;}
    public WrapperData unsavedObj{get; set;}
    public boolean printReady {get; set;}
    public String filtersJSON{get; set;}
    public decimal liquidcashreserves{get; set;}
    public decimal otheradjustments{get; set;}
    public guarantorsWrapper wrap1 {get; set;}
    
    public void  getData(){
        printReady=false;
        
        if(filtersJSON.substring(0,1) != '$'){
            if(String.isNotBlank(filtersJSON))
            {
                try{
                    System.debug('filtersJSON---> '+filtersJSON);
                    unsavedObj = (WrapperData)JSON.deserialize(filtersJSON, WrapperData.class);
                     if(unsavedObj.otheradjustments!= null)
                    {
                        otheradjustments=unsavedObj.otheradjustments;
                        liquidcashreserves=unsavedObj.liquidcashreserves;
                         
                    }
                    String recordId=unsavedObj.recordId;
                         
                    List<Advance__c> advances=[Select Id,deal__c,Loan_Number__c,LOC_Commitment__c,Max_LTC__c,Origination_Fee_Total__c,BPO_Appraisal_Fee_Total__c from Advance__c where Id=:recordId];
                    if(!advances.isEmpty()){
                        record=advances[0];
                    }
                    
                    //Add property advance fields here
					propAdv=new Property_Advance__c();
					TotalOriginationFee=0;
					List<Property_Advance__c> propAdvances=[Select Id, Name, Property__c,Property__r.City__c,Property__r.State__c,Property__r.ZipCode__c,Property__r.Name,Property__r.BPO_Appraisal_Value__c,Property__r.Approved_Renovation_Holdback__c,
															Property__r.Initial_Disbursement__c,Property__r.After_Repair_Value__c,Property__r.Borrower_Equity__c,Net_Funding__c,Property__r.Acquisition_Price__c,Property__r.Broker_Adv_Fee_Amnt__c,
															Property__r.Property_Type__c,Property__r.Requested_Funding_Date__c,Property__r.Override_Initial_Disbursement__c,Property__r.Rehab_Budget__c,Property__r.Funding_Status__c,Property__r.Lender_Comments__c,Property__r.Appraised_Value_Amount__c
															from Property_Advance__c where Advance__c=:recordId limit 1];
					if(!propAdvances.isEmpty()){
						propAdv=propAdvances[0];
						if(propAdv.Property__c!=null && propAdv.Property__r.Acquisition_Price__c!=null && propAdv.Property__r.Override_Initial_Disbursement__c!=null
						   && propAdv.Property__r.Rehab_Budget__c!=null){
							   borrowerEquityPercent=((propAdv.Property__r.Acquisition_Price__c-propAdv.Property__r.Override_Initial_Disbursement__c)/(propAdv.Property__r.Acquisition_Price__c+propAdv.Property__r.Rehab_Budget__c)*100).setScale(2);
						   }
					}
					
					//Add deal fields here
					deal=new Opportunity();
					List<Opportunity> deals=[Select Id, Name,Account.Name,Rate__c,Broker_Fees__c,CAF_Upfront_Fee__c,LTV__c,LTC__c,Approved_by_Underwriter_Date__c,
											 Anticipated_Closing_Date__c,Underwriter__r.Name,Borrower_Entity__r.Name,Owner_Name__c,Document_Date__c,Deposit_Amount__c,Calculated_Origination_Fee__c,
											 Pricing_Approval_Date__c,Exceptions_Comments_Explanations__c,Origination_Value__c,Notes__c
											 from Opportunity where Id=:record.deal__c limit 1];
					if(!deals.isEmpty()){
						deal=deals[0];
						TotalOriginationFee=(deals[0].Broker_Fees__c!=null ? deals[0].Broker_Fees__c : 0)+(deals[0].CAF_Upfront_Fee__c!=null ? deals[0].CAF_Upfront_Fee__c : 0).setScale(2);
						
						//add sponsor field here as required
						String dealId=deals[0].Id;
						String sponsorQuery = 'SELECT Id, Contact__c, Name, Contact__r.Middle_Credit_Score__c, Contact__r.Name FROM Deal_Contact__c WHERE Deal__c = : dealId  AND entity_type__c = \'Sponsor\' ORDER BY Percentage_Owned__c Desc, Middle_Credit_Score__c Desc';
                        List<Deal_Contact__c> sponsors = (List<Deal_Contact__c>)database.query(sponsorQuery);
                        if(sponsors.size() > 0){
                            sponsor = sponsors[0];
                        }
                        //add guarantors 
                   //     String dealId=deals[0].Id;
                        String guarantorsQuery = 'SELECT Id, Contact__c, Name, Contact__r.Middle_Credit_Score__c, Contact__r.Name FROM Deal_Contact__c WHERE Deal__c = : dealId  AND entity_type__c = \'Guarantor\' ORDER BY Percentage_Owned__c Desc, Middle_Credit_Score__c Desc';
                        guarantors = (List<Deal_Contact__c>)database.query(guarantorsQuery);
                        wrap1=new guarantorsWrapper(guarantors);
                        }
                        
					
					if(propAdv!=null && propAdv.Property__c!=null && propAdv.Property__r.Initial_Disbursement__c!=null && deal.Calculated_Origination_Fee__c!=null){
						AdjustedFundingAmount=(propAdv.Property__r.Initial_Disbursement__c-deal.Calculated_Origination_Fee__c-1250).setScale(2);
					}
                    if(AdjustedFundingAmount!=null && otheradjustments!=null && record.BPO_Appraisal_Fee_Total__c!=null){
						NetWireAmount=(AdjustedFundingAmount-record.BPO_Appraisal_Fee_Total__c-otheradjustments-150+(deals[0].Deposit_Amount__c!=null ? deals[0].Deposit_Amount__c : 0)).setScale(2);
					}
                     
                }
                catch(Exception ex){
                    unsavedObj=new WrapperData();
                    System.debug('Invalid JSON string passed. Unable to deserialize.');
                }
                
            }
            printReady=true;
        }
        
    }
	
    @AuraEnabled
    public static String getUrlAndInstance() {
        
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm();
        return baseUrl + '/apex/sabicmemo';
    }
     public class WrapperData {
        public string recordId{get;set;}
        public Decimal liquidcashreserves{get;set;}
        public string corevestapprovalmanager{get;set;}
        public Decimal otheradjustments{get;set;}
         public string otheradjustmentstext{get;set;}
        public string priorcvloans{get;set;}
        public string everdeliquent{get;set;}
        public string loantype{get;set;}
        
        
    }
    public class guarantorsWrapper{
        public List<Deal_Contact__c> guarantors {get; set;}
        public guarantorsWrapper(List<Deal_Contact__c> guarantors){
            this.guarantors=guarantors;
           
            }
        }  
    
	
}