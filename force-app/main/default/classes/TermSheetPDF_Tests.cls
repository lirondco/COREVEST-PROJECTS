@isTest
private class TermSheetPDF_Tests {

    static TestMethod void TermSheetPDF_UnitTest(){
        Account acc = test_Helper.createAccount();
		Contact cont = test_Helper.createContact( acc );
        Opportunity opp = test_Helper.createOpportunity( acc, cont );
        opp.Include_Assumption__c = true;
        opp.Include_Prop_Sub_Text__c = true;
        opp.Term_Sheet_Expiration_Date__c = system.today()+10;
        update opp;
        List<Property__c> props = test_Helper.createProperties( opp );

        Test.startTest();
            PageReference testpage = Page.TermSheetPDF;
            testPage.getParameters().put('month',''+system.today().month());
            testPage.getParameters().put('day',''+system.today().day());
            testPage.getParameters().put('year',''+system.today().year());
            testPage.getParameters().put('todaymonth',''+system.today().month());
            testPage.getParameters().put('todayday',''+system.today().day());
            testPage.getParameters().put('todayyear',''+system.today().year());
            testPage.getParameters().put('version','1');
            Test.setCurrentPage(testPage);

            TermSheetPDF_Controller con = new TermSheetPDF_Controller(
                new ApexPages.standardController(opp)
            );
            con.getMonth();
        	con.getDay();
        	con.getYear();
        	con.todayMonth();
        	con.todayDay();
        	con.todayYear();
        	con.convertText(11111.0);
            TermSheetPDF_Controller.formatCurrencyString(11111.0);
            con.save();

        Test.stopTest();
    }

}