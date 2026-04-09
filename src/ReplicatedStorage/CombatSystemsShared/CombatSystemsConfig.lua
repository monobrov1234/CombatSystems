export type LogLevel = "OFF" | "INFO" | "DEBUG" | "TRACE"

return {
    LogLevel = "TRACE" :: LogLevel -- logger depth level, will spam the console if set to debug/trace
}