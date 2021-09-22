/**
 * ContiHttpCalloutMock: Mock class to simulate Http callouts
 * Created By: Accelerize360
 * Date: 16 Sep 2021
 */
public class ContiHttpCalloutMock implements HttpCalloutMock {
    
    public HttpResponse respond(HttpRequest req) {

        HttpResponse res = new HttpResponse();

        if (req.getEndpoint().endsWith('Verifications')) { 

            res.setStatusCode(200);

        } else if (req.getEndpoint().endsWith('VerificationCheck')) {
            
            String body = '{"status" : "Verified" }';
            res.setStatusCode(200);
            res.setBody(body);
        }

        return res;
    }
}