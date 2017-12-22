##-----------the required tools ---------------------
registerTool "$TTRO_scriptDir/streamsutils.sh"

##-----------the script part -----------------------------------------------------
# The initialization section should contain all
# actions which are imediately executed during test collection initialization


streamsutilsInitialization
setVar 'TTPN_streamsInetToolkit' "$STREAMS_INSTALL/toolkits/com.ibm.streamsx.inet"
setVar 'TT_toolkitPath' "$TTPN_streamsInetToolkit" #consider more than one tk...
