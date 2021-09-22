/**
 * ContiSiteLoginController: Apex Class that controls contiSiteLogin LWC
 * Created By: Accelerize360
 * Date: 10 Sep 2021
 */
public class ContiSiteLoginController {

    /**
     * Retrieves Twilio credentials and returns the custom setting record
     * In the custom setting (ApiCreds__c), the username stores the Twilio Account SID, the password stores the Auth Token
     * @param none
     */
    public static ApiCreds__c fetchTwilioCreds() {

        return ApiCreds__c.getInstance('Twilio');
    }

    /**
     * Retrieves community login user details and returns the user record
     * @param uname String of Username
     */
    public static User getSiteLoginUserDetails(String uname) {

        return [SELECT Id, MobilePhone, Email FROM User WHERE username=: uname LIMIT 1];
    }
    
    /**
     * Verifies the username and password entered by the community user
     * @param username String of Username
     * @param password String of Password
     */
    @AuraEnabled
    public static String doLogin(String username, String password) {
    
        try {
            ApexPages.PageReference lgn = Site.login(username, password, '');
            if(lgn != null) return lgn.getUrl();

            throw new CalloutException();
        }
        catch (Exception ex) {
            return ex.getMessage();
        }
    }

    /**
     * Executes forgot password functionality
     * @param username String for username
     */
    @AuraEnabled
    public static String forgotPassword(String uname) {
        String procesMsg = '';
        
        if (Site.isValidUsername(uname)) {

            Site.forgotPassword(uname);
            procesMsg = 'Login reset success';
        }
        else {
            procesMsg = 'Username provided doesn\'t exist';
        }
        
        return procesMsg;
    }
    
    /**
     * Creates a verification service and returns the SID from the API response
     * Ref: https://www.twilio.com/docs/verify/api/service
     * @param none
     */
    // @AuraEnabled
    // public static String createVerifServiceViaTwilioSMS() {

    //     String VERSION  = '3.2.0';
    //     HttpRequest req = new HttpRequest();
    //     req.setEndpoint(fetchTwilioCreds().Endpoint__c+'/v2/Services');
    //     req.setMethod('POST');
    //     req.setHeader('Authorization','Basic '+EncodingUtil.base64Encode(Blob.valueOf(fetchTwilioCreds().Username__c+':' +fetchTwilioCreds().Password__c)));
    //     req.setHeader('X-Twilio-Client', 'salesforce-' + VERSION);
    //     req.setHeader('User-Agent', 'twilio-salesforce/' + VERSION);
    //     req.setHeader('Accept', 'application/json');
    //     req.setHeader('Accept-Charset', 'utf-8');
    //     req.setBody('FriendlyName='+EncodingUtil.urlEncode('Conti Site','UTF-8'));
        
    //     Http http = new Http();
    //     HTTPResponse res = http.send(req);

    //     String verifySid = '';

    //     if(res.getStatusCode() == 201){
    //         Object obj = (Object)JSON.deserializeUntyped(res.getBody());
    //         Map<string,object> r0 = (Map<string,object>) obj;
    //         verifySid = String.valueOf(r0.get('sid'));
    //     }
    //     System.debug('verifySid'+verifySid);

    //     return verifySid;
    // }
    
    /**
     * Sends verification code to community login user via SMS and returns the API response status code
     * Ref: https://www.twilio.com/docs/verify/api/verification
     * @param uname String of Username
     */
    @AuraEnabled
    public static Integer sendVerifCodeViaTwilioSMS(String uname) {
        
        String toPhNumber = getSiteLoginUserDetails(uname).MobilePhone;
        String VERSION  = '3.2.0';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(fetchTwilioCreds().Endpoint__c+'/v2/Services/'+fetchTwilioCreds().ServiceId__c+'/Verifications');
        req.setMethod('POST');
        req.setHeader('X-Twilio-Client', 'salesforce-' + VERSION);
        req.setHeader('User-Agent', 'twilio-salesforce/' + VERSION);
        req.setHeader('Accept', 'application/json');
        req.setHeader('Accept-Charset', 'utf-8');
        req.setHeader('Authorization','Basic '+EncodingUtil.base64Encode(Blob.valueOf(fetchTwilioCreds().Username__c+':' +fetchTwilioCreds().Password__c)));
        req.setBody('To='+EncodingUtil.urlEncode(toPhNumber,'UTF-8')+'&Channel='+EncodingUtil.urlEncode('sms','UTF-8'));
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug('2nd api response: '+res.getBody());

        return res.getStatusCode();
    }
    
    /**
     * Verifies if code entered by community user is correct and returns the verification status
     * Ref: https://www.twilio.com/docs/verify/api/verification-check
     * @param uname String of Username
     * @param userCode Integer of verification code entered by login user
     */
    @AuraEnabled
    public static String verifyVerifCodeViaTwilioSMS(String uname, Integer userCode) {

        String toPhNumber = getSiteLoginUserDetails(uname).MobilePhone;
        String VERSION  = '3.2.0';

        HttpRequest req = new HttpRequest();
        req.setEndpoint(fetchTwilioCreds().Endpoint__c+'/v2/Services/'+fetchTwilioCreds().ServiceId__c+'/VerificationCheck');
        req.setMethod('POST');
        req.setHeader('X-Twilio-Client', 'salesforce-' + VERSION);
        req.setHeader('User-Agent', 'twilio-salesforce/' + VERSION);
        req.setHeader('Accept', 'application/json');
        req.setHeader('Accept-Charset', 'utf-8');
        req.setHeader('Authorization','Basic '+EncodingUtil.base64Encode(Blob.valueOf(fetchTwilioCreds().Username__c+':' +fetchTwilioCreds().Password__c)));
        req.setBody('To='+EncodingUtil.urlEncode(toPhNumber,'UTF-8')+'&Code='+EncodingUtil.urlEncode(String.valueOf(userCode),'UTF-8'));
        
        Http http = new Http();
        HTTPResponse res = http.send(req);
        System.debug('2nd api response: '+res.getBody());
        System.debug('res.getStatusCode(): '+res.getStatusCode());

        String verificationStatus = '';
        if(res.getStatusCode() == 200){
            Object obj = (Object)JSON.deserializeUntyped(res.getBody());
            System.debug('obj'+obj);
            Map<string,object> r0 = (Map<string,object>) obj;
            System.debug('r0'+r0);
            verificationStatus = String.valueOf(r0.get('status'));
        }
        System.debug('verificationStatus: '+verificationStatus);
        return verificationStatus;
    }

    /**
     * Sends verification code to community login user via Email
     * @param uname String of Username
     */
    @AuraEnabled
    public static Integer sendVerifCodeViaEmail(String uname) {

        User siteUser = getSiteLoginUserDetails(uname);
        String toEmail = siteUser.Email;
        list<String> emailList = new list<String>();
        emailList.add(toEmail);
        System.debug('emaillist: '+emailList);
        Integer emailVerifCode = Math.round((Math.random() * (900000) + 100000));

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(emailList);
        mail.setSaveAsActivity(false);
        mail.setOrgWideEmailAddressId(System.label.OrgWideEmail);
        mail.setTargetObjectId(siteUser.Id);
        mail.setWhatId(siteUser.Id);
        mail.setSubject('Conti Site Verification Code');
        mail.setPlainTextBody('Your Conti site login verification code is '+emailVerifCode);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});

        return emailVerifCode;
    }

    // /**
    //  * Verifies if code entered by community user is correct and returns the verification status
    //  * @param uname String of Username
    //  * @param userCode Integer of verification code entered by login user
    //  */
    // @AuraEnabled
    // public static String verifyEmailVerifCode(Integer emailVerifCode, Integer userCode) {
        
    //     if(email)
    //     return '';
    // }



    // @AuraEnabled
    // public static String initVerification() {

    //     String id = UserManagement.initRegisterVerificationMethod(Auth.VerificationMethod.SALESFORCE_AUTHENTICATOR);
    //     System.debug('*****id: '+id);

    //     String res = System.UserManagement.verifyRegisterVerificationMethod('123456', Auth.VerificationMethod.SALESFORCE_AUTHENTICATOR);
        
    //     System.debug('*****res: '+res);

    //     return res;
    // }

    // @AuraEnabled
    // public static Auth.VerificationResult verifyVerification(String identifier, String code) {
    //     // requiring identifier from the initVerification
    //     // the code will need to be entered in this method
    //     return UserManagement.verifyVerificationMethod(identifier, code , Auth.VerificationMethod.SALESFORCE_AUTHENTICATOR);
    // }

    // @AuraEnabled
    // public static Auth.VerificationResult initVerification() {

    //     String id = UserManagement.initSelfRegistration(Auth.VerificationMethod.SMS, u);
    //     System.debug('*****id: '+id);

    //     Auth.VerificationResult res = System.UserManagement.verifySelfRegistration(Auth.VerificationMethod.SMS, id, '123456', null);
        
    //     System.debug('*****res: '+res);
    //     System.debug('*****res.success: '+res.success);
    //     if(res.success == true){
    //             //redirect
    //     }

    //     return res;
    // }

    // @AuraEnabled
    // public static Auth.VerificationResult initVerification() {
    @AuraEnabled
    public static String initVerification() {

        PageReference p =  System.UserManagement.registerVerificationMethod(Auth.VerificationMethod.SALESFORCE_AUTHENTICATOR, 'https://uat-conti.cs200.force.com/InvestorPortal/s/');

        String id = UserManagement.initVerificationMethod(Auth.VerificationMethod.SALESFORCE_AUTHENTICATOR);
        System.debug('*****id: '+id);

        return id;

        // Auth.VerificationResult res = System.UserManagement.verifyVerificationMethod(id, '', Auth.VerificationMethod.SALESFORCE_AUTHENTICATOR);
        
        // System.debug('*****res: '+res);
        // System.debug('*****res.success: '+res.success);
        // if(res.success == true){
        //         //redirect
        // }

        // return res;
    }

    @AuraEnabled
    public static Boolean addMfaPermisionSet(String uname){
        
        Id userId = getSiteLoginUserDetails(uname).Id;
        Id permSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Enable_Multi_Factor_Authenication' LIMIT 1].Id;
        Boolean psAssigned = false;

        if(permSetId != null){
            List<PermissionSetAssignment> permSetCheck = [
                SELECT Id FROM PermissionSetAssignment WHERE PermissionSetId =: permSetId AND AssigneeId =: userId];

            if(permSetCheck.size() == 0){
                PermissionSetAssignment psa = new PermissionSetAssignment(PermissionSetId = permSetId, AssigneeId = userId);
                insert psa;
                psAssigned = true;
            }
        }

        return psAssigned;
    }

    @AuraEnabled
    public static Boolean removeMfaPermisionSet(String uname){
        
        Id userId = getSiteLoginUserDetails(uname).Id;
        Id permSetId = [SELECT Id FROM PermissionSet WHERE Name = 'Enable_Multi_Factor_Authenication' LIMIT 1].Id;
        Boolean psRemoved = false;

        if(permSetId != null){
            delete [SELECT Id FROM PermissionSetAssignment WHERE PermissionSetId =: permSetId AND AssigneeId =: userId];
            psRemoved = true;
        }

        return psRemoved;
    }

}