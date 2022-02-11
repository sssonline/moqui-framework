/* Copyright 2014-2017 Spokane Software Systems, Inc. All Rights Reserved. */
package org.moqui.impl.webapp

import groovy.transform.CompileStatic
import org.apache.poi.hssf.util.HSSFColor
import org.moqui.context.ArtifactAuthorizationException
import org.moqui.context.ArtifactTarpitException
import org.moqui.impl.context.ExecutionContextFactoryImpl
import org.moqui.impl.context.ExecutionContextImpl
import org.moqui.screen.ScreenRender
import org.moqui.util.StringUtilities
import org.slf4j.Logger
import org.slf4j.LoggerFactory

import javax.servlet.ServletException
import javax.servlet.http.HttpServlet
import javax.servlet.http.HttpServletRequest
import javax.servlet.http.HttpServletResponse
import javax.xml.transform.stream.StreamSource

import java.net.ServerSocket

import java.io.FileOutputStream
import java.io.IOException

@CompileStatic
class MoquiLineServlet extends HttpServlet {
    protected final static Logger logger = LoggerFactory.getLogger(MoquiLineServlet.class)

    MoquiLineServlet() {
        super()
    }

    @Override
    void doPost(HttpServletRequest request, HttpServletResponse response) { doScreenRequest(request, response) }

    @Override
    void doGet(HttpServletRequest request, HttpServletResponse response) { doScreenRequest(request, response) }

    void doScreenRequest(HttpServletRequest request, HttpServletResponse response) throws ServletException, IOException {
        ExecutionContextFactoryImpl ecfi =
                (ExecutionContextFactoryImpl) getServletContext().getAttribute("executionContextFactory")
        String moquiWebappName = getServletContext().getInitParameter("moqui-name")

        if (ecfi == null || moquiWebappName == null) {
            response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, "System is initializing, try again soon.")
            return
        }

        long startTime = System.currentTimeMillis()

        if (logger.traceEnabled) logger.trace("Start request to [${request.getPathInfo()}] at time [${startTime}] in session [${request.session.id}] thread [${Thread.currentThread().id}:${Thread.currentThread().name}]")

        ExecutionContextImpl activeEc = ecfi.activeContext.get()
        if (activeEc != null) {
            logger.warn("In MoquiServlet.service there is already an ExecutionContext for user ${activeEc.user.username} (from ${activeEc.forThreadId}:${activeEc.forThreadName}) in this thread (${Thread.currentThread().id}:${Thread.currentThread().name}), destroying")
            activeEc.destroy()
        }
        ExecutionContextImpl ec = ecfi.getEci()

        String screenText = null
        try {
            ec.initWebFacade(moquiWebappName, request, response)
            ec.web.requestAttributes.put("moquiRequestStartTime", startTime)
            ArrayList<String> pathInfoList = ec.web.getPathInfoList()

            ScreenRender sr = ec.screen.makeRender().webappName(moquiWebappName).renderMode("line")
                    .rootScreenFromHost(request.getServerName()).screenPath(pathInfoList)
            screenText = sr.render()

            String printerIPAndPort = (ec.web.parameters.get("printerIP") as String)

            String[] printerIPParts = printerIPAndPort.split(':')

            String printerIP = printerIPParts[0]
            String printerPort = printerIPParts[1]

            String[] lines = screenText.split('\r?\n')

            def s = new Socket(printerIP, printerPort.toInteger())

            s.withStreams { inStream, outStream ->
                // This causes leading blank lines to be skipped. Printing does not begin until a non-blank
                // line is encountered, at which point every line (including blanks) is printed.
                Boolean printing = false

                // If, for whatever reason, it becomes desirable to not include a trailing \r\n
                // (which is probably needed for line printers, but we're not sure)
                // then simply change the .each statement to:
                // lines.eachWithIndex { line, i ->
                // and then the \r\n can be made conditional like so:
                // outStream << line + (i == lines.size-1 ? "" : "\r\n")
                lines.each { line ->
                    if( printing || line != "" ) {
                        printing = true
                        outStream << line + "\r\n"
                    }
                }
            }

            s.close()

            if (logger.infoEnabled) logger.info("Finished LINE request to ${pathInfoList}, content type ${response.getContentType()} in ${System.currentTimeMillis()-startTime}ms; session ${request.session.id} thread ${Thread.currentThread().id}:${Thread.currentThread().name}")
        } catch (ArtifactAuthorizationException e) {
            // SC_UNAUTHORIZED 401 used when authc/login fails, use SC_FORBIDDEN 403 for authz failures
            // See ScreenRenderImpl.checkWebappSettings for authc and SC_UNAUTHORIZED handling
            logger.warn((String) "Web Access Forbidden (no authz): " + e.message)
            response.sendError(HttpServletResponse.SC_FORBIDDEN, e.message)
        } catch (ArtifactTarpitException e) {
            logger.warn((String) "Web Too Many Requests (tarpit): " + e.message)
            if (e.getRetryAfterSeconds()) response.addIntHeader("Retry-After", e.getRetryAfterSeconds())
            // NOTE: there is no constant on HttpServletResponse for 429; see RFC 6585 for details
            response.sendError(429, e.message)
        } catch (ScreenResourceNotFoundException e) {
            logger.warn((String) "Web Resource Not Found: " + e.message)
            response.sendError(HttpServletResponse.SC_NOT_FOUND, e.message)
        } catch (Throwable t) {
            logger.error("Error transforming POI content:\n${screenText}", t)
            if (ec.message.hasError()) {
                String errorsString = ec.message.errorsString
                logger.error(errorsString, t)
                response.sendError(HttpServletResponse.SC_INTERNAL_SERVER_ERROR, errorsString)
            } else {
                throw t
            }
        } finally {
            // make sure everything is cleaned up
            ec.destroy()
        }
    }
}
