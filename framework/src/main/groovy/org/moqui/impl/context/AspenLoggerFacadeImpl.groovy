/* Copyright 2014-2019 Spokane Software Systems, Inc. All Rights Reserved. */

package org.moqui.impl.context

import org.moqui.context.AspenLoggerFacade
import org.slf4j.Logger
import org.slf4j.LoggerFactory
/*
import io.sentry.Sentry;
import io.sentry.context.Context;
import io.sentry.event.BreadcrumbBuilder;
import io.sentry.event.UserBuilder;
*/
class AspenLoggerFacadeImpl implements AspenLoggerFacade {
    protected final static Logger logger = LoggerFactory.getLogger(LoggerFacadeImpl.class)

    protected final ExecutionContextFactoryImpl ecfi

    // usage of this class:
    // replace
    //protected final static Logger logger = LoggerFactory.getLogger(AspenPayrollTests.class)
    // with
    //protected final static AspenLoggerFacade logger = LoggerFactory.getLogger(AspenPayrollTests.class)

    // TODO: wait to hear back from Sentry and see if I need this class or not.

    // Constructor:
    // TODO: why do I need ecfi?
    AspenLoggerFacadeImpl(ExecutionContextFactoryImpl ecfi) {
        this.ecfi = ecfi
       // Sentry.init("https://6ed01a0f72b647b6b6fbc05810cc317f@sentry.io/1783379?release=0.0.1&environment=dev&servername=kiraLocal")
    }

    void log(String levelStr, String message, Throwable thrown) {
        int level
        switch (levelStr) {
            case "trace": level = TRACE_INT; break
            case "debug": level = DEBUG_INT; break
            case "info": level = INFO_INT; break
            case "warn": level = WARN_INT; break
            case "error": level = ERROR_INT; break
            case "off": // do nothing
            default: return
        }
        log(level, message, thrown)
    }

    @Override
    void log(int level, String message, Throwable thrown) {
        switch (level) {
            case TRACE_INT: logger.trace(message, thrown); break
            case DEBUG_INT: logger.debug(message, thrown); break
            case INFO_INT: logger.info(message + "---*--*--", thrown); break
            case WARN_INT: logger.warn(message, thrown); break
            case ERROR_INT: logger.error(message, thrown); break
            case FATAL_INT: logger.error(message, thrown); break
            case ALL_INT: logger.warn(message, thrown); break
            case OFF_INT: break // do nothing
        }
    }

    void trace(String message) { log(TRACE_INT, message, null) }
    void debug(String message) { log(DEBUG_INT, message, null) }
    void info(String message) { log(INFO_INT, message, null) }
    void warn(String message) { log(WARN_INT, message, null) }
    void error(String message) { log(ERROR_INT, message, null) }

    void error(String message, Object e) { log(ERROR_INT, message+e.toString(), null) }
    void info(String message, Object e) { log(INFO_INT, message+e.toString(), null) }
    void warn(String message, Object e) { log(WARN_INT, message+e.toString(), null) }
    public boolean traceEnabled = true

    @Override
    boolean logEnabled(int level) {
        switch (level) {
            case TRACE_INT: return logger.isTraceEnabled()
            case DEBUG_INT: return logger.isDebugEnabled()
            case INFO_INT: return logger.isInfoEnabled()
            case WARN_INT: return logger.isWarnEnabled()
            case ERROR_INT:
            case FATAL_INT: return logger.isErrorEnabled()
            case ALL_INT: return logger.isWarnEnabled()
            case OFF_INT: return false
            default: return false
        }
    }
}
