##-----------the required tools ---------------------
import "$TTRO_scriptDir/streamsutils.sh"

setVar 'TTPR_timeout' 240

#Make sure instance and domain is running
PREPS='cleanUpInstAndDomainAtStart mkDomain startDomain mkInst startInst'
FINS='cleanUpInstAndDomainAtStop'
