import { LightningElement, track } from 'lwc';
import doLogin from '@salesforce/apex/ContiSiteLoginController.doLogin';
import initVerification from '@salesforce/apex/ContiSiteLoginController.initVerification';
import forgotPassword from '@salesforce/apex/ContiSiteLoginController.forgotPassword';
import sendVerifCodeViaTwilioSMS from '@salesforce/apex/ContiSiteLoginController.sendVerifCodeViaTwilioSMS';
import verifyVerifCodeViaTwilioSMS from '@salesforce/apex/ContiSiteLoginController.verifyVerifCodeViaTwilioSMS';
import sendVerifCodeViaEmail from '@salesforce/apex/ContiSiteLoginController.sendVerifCodeViaEmail';
import addMfaPermisionSet from '@salesforce/apex/ContiSiteLoginController.addMfaPermisionSet';
import removeMfaPermisionSet from '@salesforce/apex/ContiSiteLoginController.removeMfaPermisionSet';

export default class ContiSiteLogin extends LightningElement {
    username;
    password;
    @track errorCheck;
    @track errorMessage;
    @track correctCred = true;
    @track wrongCredMsg = '';
    @track authAppRedirectUrl = '';
    @track verifySid;
    @track verifCode;
    @track userVerifCode;
    @track verifStatus;

    /**
     * controlling track variables to toggle between the 3 screens 
     * screen 1: entering username & password (for 1st step of authentication)
     * screen 2: choosing verification method (Authenticator App, Email, SMS)
     * screen 3: entering verification code (for 2nd step of authentication) */
    @track displayLoginScreen = true;
    @track displayVerifMethodScreen = false;
    @track displayVerifCodeScreen = false;

    /**
     * controller track variables to toggle between the 2 buttons
     * button 1: verify code sent via SMS
     * button 2: verify code sent via Email
     */
    @track displaySmsVerifButton = false;
    @track displayEmailVerifButton = false;

    connectedCallback(){
        var meta = document.createElement("meta");
        meta.setAttribute("name", "viewport");
        meta.setAttribute("content", "width=device-width, initial-scale=1.0");
        document.getElementsByTagName('head')[0].appendChild(meta);
    }

    handleUserNameChange(event){
        this.username = event.target.value;
        console.log('username: '+this.username);
    }

    handlePasswordChange(event){        
        this.password = event.target.value;
        console.log('password: '+this.password);
    }

    handleVerifCodeChange(event){
        this.userVerifCode = event.target.value;
        console.log('userVerifCode: '+this.this.userVerifCode);
    }

    //verifies community login credentials entered by the user (1st step of verification process)
    verifyCreds(){
        if(this.username && this.password){

            doLogin({ username: this.username, password: this.password })
            .then((result) => {
                console.log('result: '+result);

                //display error message if wrong credentials are entered
                if(result.includes('failed')){
                    this.correctCred = false;
                    this.wrongCredMsg = result;
                }
                //display verification method selection screen if correct credentials are entered
                else{
                    this.authAppRedirectUrl = result;
                    this.displayLoginScreen = false;
                    this.displayVerifMethodScreen = true;
                    this.displayVerifCodeScreen = false;
                }
            })
            .catch((error) => {
                this.error = error;      
                this.errorCheck = true;
                this.errorMessage = error.body.message;
                console.log('error: '+JSON.stringify(this.error));
            });

        }
    }

    //sends password reset email to user
    forgotPassword(){
        console.log('forgotPassword username: '+this.username);

        forgotPassword({uname: this.username})
        .then((result) => {
            console.log('forgotPassword result: '+JSON.stringify(result));
        })
        .catch((error) => {
            this.error = error;      
            this.errorCheck = true;
            this.errorMessage = error.body.message;
            console.log('forgotPassword error: '+JSON.stringify(this.error));
        });
    }

    //redirects to auth app verification if user chooses to verify via the SF Authenticator App
    verifyAuthApp(){
        console.log('authAppRedirectUrl: '+this.authAppRedirectUrl);
        window.location.href = 'https://uat-conti.cs200.force.com/InvestorPortal/_ui/identity/verification/method/ToopherVerificationFinishUi/e';

        // addMfaPermisionSet({uname: this.username})
        // .then((result) => {
        //     console.log('result verifyAuthApp addMfaPermisionSet: '+result);
        //     if(result == true){

        //         setInterval(function() {
        //             window.location.href = this.authAppRedirectUrl;
        //         }.bind(this), 5000);

        //         setInterval(function() {
        //             removeMfaPermisionSet({uname: this.username})
        //             .then((result) => {

        //                 console.log('result verifyAuthApp removeMfaPermisionSet: '+result);
        //             })
        //             .catch((error) => {
        //                 this.error = error;      
        //                 this.errorCheck = true;
        //                 this.errorMessage = error.body.message;
        //                 console.log('verifyAuthApp error: '+JSON.stringify(this.error));
        //             });
        //         }.bind(this), 10000);
        //     }
        // })
        // .catch((error) => {
        //     this.error = error;      
        //     this.errorCheck = true;
        //     this.errorMessage = error.body.message;
        //     console.log('verifyAuthApp error: '+JSON.stringify(this.error));
        // });

        // initVerification()
        // .then((result) => {
        //     this.verifCode = result;
        //     console.log('this.verifCode: '+JSON.stringify(this.verifCode));
        //     this.displayLoginScreen = false;
        //     this.displayVerifMethodScreen = false;
        //     this.displayVerifCodeScreen = true;

        // })
        // .catch((error) => {
        //     this.error = error;      
        //     this.errorCheck = true;
        //     this.errorMessage = error.body.message;
        //     console.log('sendVerifCodeViaTwilioSMS error: '+JSON.stringify(this.error));
        // });
    }

    //Sends verification code to user via Twilio SMS (for 2nd step of authentication)
    verifySMS(){
        console.log('uname: '+this.username);

        sendVerifCodeViaTwilioSMS({uname: this.username})
        .then((result) => {
            this.verifCode = result;
            console.log('this.verifCode: '+JSON.stringify(this.verifCode));
            this.displayLoginScreen = false;
            this.displayVerifMethodScreen = false;
            this.displayVerifCodeScreen = true;
            this.displaySmsVerifButton = true;
            this.displayEmailVerifButton = false;
        })
        .catch((error) => {
            this.error = error;      
            this.errorCheck = true;
            this.errorMessage = error.body.message;
            console.log('sendVerifCodeViaTwilioSMS error: '+JSON.stringify(this.error));
        });
    }

    //verifies code entered by the user (for 2nd step of authentication via SMS)
    verifySmsCode(){
        console.log('userVerifCode: '+this.userVerifCode);

        verifyVerifCodeViaTwilioSMS({uname: this.username, userCode: this.userVerifCode})
        .then((result) => {
            console.log('result: '+JSON.stringify(result));
            this.verifStatus = result;
            console.log('this.verifStatus: '+JSON.stringify(this.verifStatus));
            //site redirect logic
            window.location.href = this.authAppRedirectUrl;
            //'https://uat-conti.cs200.force.com/InvestorPortal/s/';
        })
        .catch((error) => {
            this.error = error;      
            this.errorCheck = true;
            this.errorMessage = error.body.message;
            console.log('verifyVerifCodeViaTwilioSMS error: '+JSON.stringify(this.error));
        });
    }

    //initiates email verification process (for 2nd step of authentication via Email) 
    verifyEmail(){

        sendVerifCodeViaEmail({uname: this.username})
        .then((result) => {
            this.verifCode = result;
            console.log('this.verifCode: '+JSON.stringify(this.verifCode));
            this.displayLoginScreen = false;
            this.displayVerifMethodScreen = false;
            this.displayVerifCodeScreen = true;
            this.displaySmsVerifButton = false;
            this.displayEmailVerifButton = true;
        })
        .catch((error) => {
            this.error = error;      
            this.errorCheck = true;
            this.errorMessage = error.body.message;
            console.log('sendVerifCodeViaTwilioSMS error: '+JSON.stringify(this.error));
        });
    }

    //verifies code entered by the user (for 2nd step of authentication via Email)
    verifyEmailCode(){

        if(this.verifCode == this.userVerifCode){
            console.log('email verification success');
            //site redirect logic
            console.log('document cookie: '+document.cookie);
            console.log('decoded cookie: '+decodeURIComponent(document.cookie));
            window.location.href = this.authAppRedirectUrl;
            //'https://uat-conti.cs200.force.com/InvestorPortal/s/';
        }
        else{
            console.log('email verification failure');
        }
    }
    
    // setRedirectUrlCookie() {
    //     var baseURL = this.getBaseUrl(window.location.href);
    //     var newPathName = window.location.pathname.substr(1) + window.location.search;
    //     // newPathName = newPathName.replace("s/", "");
    //     console.log('newPathName: '+newPathName);
    //     document.cookie = "redirecturlfromlogin=" + encodeURIComponent(newPathName) + ";path=/";
    // }

    // getBaseUrl(url) {
    //     var urlString = url;
    //     var baseURL = urlString.substring(0, urlString.indexOf("/s"));
    //     baseURL = baseURL.replace("https://", ".");
    //     baseURL = baseURL.replace("/ria", "");
    //     return baseURL;
    // }
}