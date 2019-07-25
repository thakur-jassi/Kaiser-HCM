@isTest
public class Noti5_NotificationUtilityTest {
    
    static testMethod void SendNotification() {
        Profile userProfile = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

        UserRole role = new UserRole(DeveloperName = 'MyCustomRole', Name = 'My Role');
        insert role;
        
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
            LocaleSidKey = 'en_US',
            UserRoleId = role.Id
        );
        insert usr;

        User usr2 = new User(
            ProfileId = userProfile.Id,
            LastName = 'Granger',
            Email = 'granger@hogwarts.com',
            Username = 'granger@hogwarts.com.test',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'gran',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            UserRoleId = role.Id
        );
        insert usr2;

        System.runAs(usr){
            
            PermissionSet ps = [SELECT Id, Name FROM PermissionSet where Label ='Account Rating' LIMIT 1];
            insert new PermissionSetAssignment(AssigneeId = usr.id, PermissionSetId = ps.Id);

            Group grp = new Group(Name='Service Agents');
            insert grp;
            insert new GroupMember(GroupId = grp.Id, UserOrGroupId = usr.Id);

            List<Notification__c> listOfNotifications = new List<Notification__c>();
            listOfNotifications.add(new Notification__c(Message__c = 'This is a test Notification', Status__c = 'Notification Sent'));
            listOfNotifications.add(new Notification__c(Message__c = 'This is a 2nd test Notification', Status__c = 'Notification Sent'));
            listOfNotifications.add(new Notification__c(Message__c = 'This is a 3rd test Notification', Status__c = 'Notification Sent'));
            listOfNotifications.add(new Notification__c(Message__c = 'This is a 4th test Notification', Status__c = 'Notification Sent'));
            listOfNotifications.add(new Notification__c(Message__c = 'This is a 5th test Notification', Status__c = 'Notification Sent'));
            insert listOfNotifications;

            List<Audience__c> listOfAudienceRecord = new List<Audience__c>();
            listOfAudienceRecord.add(new Audience__c(Notification__c = listOfNotifications[0].Id, Group_Id__c = userProfile.Id, Type__c = 'Profile'));
            listOfAudienceRecord.add(new Audience__c(Notification__c = listOfNotifications[1].Id, Group_Id__c = role.Id, Type__c = 'Role'));
            listOfAudienceRecord.add(new Audience__c(Notification__c = listOfNotifications[2].Id, Group_Id__c = grp.Id, Type__c = 'Public Group'));
            listOfAudienceRecord.add(new Audience__c(Notification__c = listOfNotifications[3].Id, Group_Id__c = ps.Id, Type__c = 'Permission Set'));
            listOfAudienceRecord.add(new Audience__c(Notification__c = listOfNotifications[4].Id, Group_Id__c = role.Id, Type__c = 'Role'));
            listOfAudienceRecord.add(new Audience__c(Notification__c = listOfNotifications[4].Id, Group_Id__c = userProfile.Id, Type__c = 'Profile'));
            insert listOfAudienceRecord;

            Test.startTest();
           
            //Get all New Notification(Unread) pending for user
            Noti5_NotificationUtility.getNewMessages();

            if(Noti5_NotificationUtility.checkEligibility(listOfNotifications[0].Id)){
                Noti5_NotificationUtility.insertResponse(listOfNotifications[0].Id);
            }
            if(Noti5_NotificationUtility.checkEligibility(listOfNotifications[1].Id)){
                Noti5_NotificationUtility.insertResponse(listOfNotifications[1].Id);
            }

            //Get Wall of Shame Users
            Noti5_NotificationUtility.getWallOfShameUsers();
            Noti5_NotificationUtility.getchartMetrics(listOfNotifications[0].Id);
            Noti5_NotificationUtility.getchartMetrics(listOfNotifications[1].Id);
            if(Noti5_NotificationUtility.checkEligibility(listOfNotifications[2].Id)){
                Noti5_NotificationUtility.insertResponse(listOfNotifications[2].Id);
            }
            if(Noti5_NotificationUtility.checkEligibility(listOfNotifications[3].Id)){
                Noti5_NotificationUtility.insertResponse(listOfNotifications[3].Id);
            }
            Noti5_NotificationUtility.getAckMessages();
            Noti5_NotificationUtility.getchartMetrics(listOfNotifications[2].Id);
            Noti5_NotificationUtility.getchartMetrics(listOfNotifications[3].Id);

            Noti5_NotificationUtility.getAudienceResponse(listOfNotifications[3].Id);

            Noti5_NotificationUtility.getCount(listOfNotifications[0].Id, '', '', '',1);
            Noti5_NotificationUtility.getCount(listOfNotifications[1].Id, 'Potter', '', '',1);
            Noti5_NotificationUtility.getCount(listOfNotifications[2].Id, '', 'yes', '',1);
            Noti5_NotificationUtility.getCount(listOfNotifications[3].Id, '', '', 'yes',1);
            Noti5_NotificationUtility.getCount(listOfNotifications[4].Id, '', '', '',1);
            Test.stopTest();
        }
    }

}