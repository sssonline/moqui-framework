/*
 * This software is in the public domain under CC0 1.0 Universal plus a
 * Grant of Patent License.
 * 
 * To the extent possible under law, the author(s) have dedicated all
 * copyright and related and neighboring rights to this software to the
 * public domain worldwide. This software is distributed without any
 * warranty.
 * 
 * You should have received a copy of the CC0 Public Domain Dedication
 * along with this software (see the LICENSE.md file). If not, see
 * <http://creativecommons.org/publicdomain/zero/1.0/>.
 */

/*
    JavaMail API Documentation at: https://java.net/projects/javamail/pages/Home
    For JavaMail JavaDocs see: https://javamail.java.net/nonav/docs/api/index.html
 */

import javax.mail.FetchProfile
import javax.mail.Flags
import javax.mail.Folder
import javax.mail.Message
import javax.mail.Session
import javax.mail.Store
import javax.mail.internet.MimeMessage
import javax.mail.search.FlagTerm
import javax.mail.search.SearchTerm

import org.apache.http.client.ClientProtocolException
import org.apache.http.impl.client.CloseableHttpClient
import org.apache.http.client.methods.HttpPost
import org.apache.http.client.methods.CloseableHttpResponse
import com.fasterxml.jackson.databind.ObjectMapper
import com.fasterxml.jackson.databind.JavaType
import org.apache.http.message.BasicHeader
import org.apache.http.impl.client.HttpClients
import org.apache.http.entity.StringEntity
import org.apache.http.entity.ContentType

import org.slf4j.Logger
import org.slf4j.LoggerFactory

import org.moqui.entity.EntityValue
import org.moqui.impl.context.ExecutionContextImpl

Logger logger = LoggerFactory.getLogger("org.moqui.impl.pollEmailServer")

// This is provided for backwards compatibility with Java 1.8
public static byte[] readAllBytes(InputStream inputStream) throws IOException {
    final int bufLen = 1024
    byte[] buf = new byte[bufLen]
    int readLen
    IOException exception = null

    try {
        ByteArrayOutputStream outputStream = new ByteArrayOutputStream()

        while ((readLen = inputStream.read(buf, 0, bufLen)) != -1)
            outputStream.write(buf, 0, readLen)

        return outputStream.toByteArray()
    } catch (IOException e) {
        exception = e
        throw e
    } finally {
        // TODO: This closes the inputStream; should it?
        if (exception == null) inputStream.close()
        else try {
            inputStream.close()
        } catch (IOException e) {
            exception.addSuppressed(e)
        }
    }
}

// TODO: This may be Office365 specific despite being parameterized
public String getAuthToken(String authTenantId,
                           String authAppClientId,
                           String authClientSecretValue,
                           String authLoginUrl,
                           String authLoginUrlSuffix,
                           String authScopesUrl) throws ClientProtocolException, IOException {
    CloseableHttpClient client = HttpClients.createDefault()
    // HttpPost loginPost = new HttpPost("https://login.microsoftonline.com/" + authTenantId + "/oauth2/v2.0/token")
    HttpPost loginPost = new HttpPost(authLoginUrl + authTenantId + authLoginUrlSuffix)
    // String scopes = "https://outlook.office365.com/.default"
    String scopes = authScopesUrl
    String encodedBody = "client_id=" + authAppClientId + "&scope=" + scopes + "&client_secret=" + authClientSecretValue + "&grant_type=client_credentials"
    loginPost.setEntity(new StringEntity(encodedBody, ContentType.APPLICATION_FORM_URLENCODED))
    loginPost.addHeader(new BasicHeader("cache-control", "no-cache"))
    CloseableHttpResponse loginResponse = client.execute(loginPost)
    InputStream inputStream = loginResponse.getEntity().getContent()
    byte[] response = readAllBytes(inputStream) // Call Java 1.8 compatible readAllBytes
    ObjectMapper objectMapper = new ObjectMapper()
    JavaType type = objectMapper.constructType(
            objectMapper.getTypeFactory().constructParametricType(Map.class, String.class, String.class))
    Map<String, String> parsed = new ObjectMapper().readValue(response, type)
    return parsed.get("access_token")
}

ExecutionContextImpl ec = context.ec

EntityValue emailServer = ec.entity.find("moqui.basic.email.EmailServer").condition("emailServerId", emailServerId).one()
if (!emailServer) { ec.message.addError(ec.resource.expand('No EmailServer found for ID [${emailServerId}]','')); return }
if (!emailServer.storeHost) { ec.message.addError(ec.resource.expand('EmailServer [${emailServerId}] has no storeHost','')) }
if (!emailServer.mailUsername) { ec.message.addError(ec.resource.expand('EmailServer [${emailServerId}] has no mailUsername','')) }
if (!emailServer.mailPassword && !emailServer.authMechanisms) { ec.message.addError(ec.resource.expand('EmailServer [${emailServerId}] has no mailPassword and no authMechanisms','')) }
if (ec.message.hasError()) return

String host = emailServer.storeHost
String user = emailServer.mailUsername
String password = emailServer.mailPassword
String protocol = emailServer.storeProtocol ?: "imaps"
int port = (emailServer.storePort ?: "993") as int
String storeFolder = emailServer.storeFolder ?: "INBOX"

// def urlName = new URLName(protocol, host, port as int, "", user, password)
Session session
Store store
if (emailServer.authMechanisms) {
    String authMechanisms = emailServer.authMechanisms
    String authLoginUrl = emailServer.authLoginUrl
    String authLoginUrlSuffix = emailServer.authLoginUrlSuffix
    String authScopesUrl = emailServer.authScopesUrl
    String authAppClientId = emailServer.authAppClientId
// String authObjectId = emailServer.authObjectId
    String authTenantId = emailServer.authTenantId
// String authClientSecretId = emailServer.authClientSecretId
    String authClientSecretValue = emailServer.authClientSecretValue
// String authEnterpriseSubObjectId = emailServer.authEnterpriseSubObjectId

    Properties props = new Properties()

    // TODO: This is IMAP specific
    props.put("mail.store.protocol", protocol) // Some documentation suggests this should be imap, not imaps
    props.put("mail.imap.host", host)
    props.put("mail.imap.port", port)
    // props.put("mail.imap.ssl.enable", "true")
    props.put("mail.imap.ssl.enable", emailServer.smtpSsl == 'N' ? "false": "true")
    // props.put("mail.imap.starttls.enable", "true")
    props.put("mail.imap.starttls.enable", emailServer.smtpStartTls == 'N' ? "false": "true")
    props.put("mail.imap.auth", "true")
    props.put("mail.imap.auth.mechanisms", authMechanisms)
    props.put("mail.imap.user", user)
//    props.put("mail.debug", "true")
//    props.put("mail.debug.auth", "true")

    String token = getAuthToken(authTenantId,
            authAppClientId,
            authClientSecretValue,
            authLoginUrl,
            authLoginUrlSuffix,
            authScopesUrl)
    // logger.warn('token: ' + token.toString())
    session = Session.getInstance(props)
//    session.setDebug(true)
    store = session.getStore("imap")
    store.connect("outlook.office365.com", user, token)
}
else {
    session = Session.getInstance(System.getProperties())
    store = session.getStore(protocol)
    if (!store.isConnected()) store.connect(host, port, user, password)
}

logger.info("Polling Email from ${user}@${host}:${port}/${storeFolder}, properties ${session.getProperties()}")

// open the folder
Folder folder = store.getFolder(storeFolder)
if (folder == null || !folder.exists()) { ec.message.addError(ec.resource.expand('No ${storeFolder} folder found','')); return }

// get message count
folder.open(Folder.READ_WRITE)
int totalMessages = folder.getMessageCount()
// close and return if no messages
if (totalMessages == 0) { folder.close(false); return }

// get messages not deleted (and optionally not seen)
Flags searchFlags = new Flags(Flags.Flag.DELETED)
if (emailServer.storeSkipSeen == "Y") searchFlags.add(Flags.Flag.SEEN)
SearchTerm searchTerm = new FlagTerm(searchFlags, false)
Message[] messages = folder.search(searchTerm)
FetchProfile profile = new FetchProfile()
profile.add(FetchProfile.Item.ENVELOPE)
profile.add(FetchProfile.Item.FLAGS)
profile.add("X-Mailer")
folder.fetch(messages, profile)

logger.info("Found ${totalMessages} messages (${messages.size()} filtered) at ${user}@${host}:${port}/${storeFolder}")

for (Message message in messages) {
    if (emailServer.storeSkipSeen == "Y" && message.isSet(Flags.Flag.SEEN)) continue

    // NOTE: should we check size? long messageSize = message.getSize()
    if (message instanceof MimeMessage) {
        // use copy constructor to have it download the full message, may fix BODYSTRUCTURE issue from some email servers (see details in issue #97)
        MimeMessage fullMessage = new MimeMessage(message)
        ec.service.runEmecaRules(fullMessage, emailServerId)
        // mark seen if setup to do so
        if (emailServer.storeMarkSeen == "Y") message.setFlag(Flags.Flag.SEEN, true)
        // delete the message if setup to do so
        if (emailServer.storeDelete == "Y") message.setFlag(Flags.Flag.DELETED, true)
    } else {
        logger.warn("Doing nothing with non-MimeMessage message: ${message}")
    }
}

// expunge and close the folder
folder.close(true)
