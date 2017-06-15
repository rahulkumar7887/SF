@isTest(SeeAllData = false)
public class AccountCleanBatchTest {
    //Test Data
    public static void testData(){
        
        List<Account> lstAccount = TestDataFactory.createAccounts(1, true);
        System.assertEquals(1, [Select count() From Account]);
    }
    
    public static testMethod void AccountCleanBatch_Test(){
        AccountCleanBatch bc =  new AccountCleanBatch();
        Test.startTest();
        Database.executebatch(bc);
        Test.stopTest();
        System.assertEquals(0, [Select count() From Account]);
    }
}