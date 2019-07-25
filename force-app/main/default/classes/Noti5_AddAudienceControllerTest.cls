@isTest
public class Noti5_AddAudienceControllerTest {
    static testMethod void create_audience() {

        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];
        User usr = new User(
            ProfileId = userProfile.Id,
            LastName = 'Potter',
            Email = 'potter@hogwarts.com',
            Username = 'potter@hogwarts.com.test',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        insert usr;
        System.runAs(usr){
            Notification__c NotificationRecord = new Notification__c(Message__c = 'This is a test Notification');
            insert NotificationRecord;
            String AudienceWrap = '[{"Type":"Profile","GroupId":"'+userProfile.Id+'","title":"System Administrator"}]';
            Test.startTest();
            String AudieceRecordId = Noti5_addAudienceController.createAudienceRecords(NotificationRecord.Id, AudienceWrap);
            Test.stopTest();
            System.assertNotEquals(null, AudieceRecordId);
        }
        
    }
}