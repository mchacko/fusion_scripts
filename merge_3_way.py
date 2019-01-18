import os

print 'Script invoked...'

ADEAUTOFSCHANGEME = os.environ["ADEAUTOFSCHANGEME"]
AVRSYSTEMJAZNCHAGEME = os.environ["AVRSYSTEMJAZNCHAGEME"]
JPSCNFIGCHANGEME = os.environ["JPSCNFIGCHANGEME"]
AVRJAZNDELTACHANGEME = os.environ["AVRJAZNDELTACHANGEME"]
ADEAUTOFSCHANGEME = ADEAUTOFSCHANGEME + "/fusionapps/fscm/deploy/system-jazn-data.xml"

print 'ADEAUTOFSCHANGEME: ' + ADEAUTOFSCHANGEME
print 'AVRSYSTEMJAZNCHAGEME: ' + AVRSYSTEMJAZNCHAGEME
print 'JPSCNFIGCHANGEME: ' + JPSCNFIGCHANGEME
print 'AVRJAZNDELTACHANGEME: ' + AVRJAZNDELTACHANGEME

patchPolicyStore(phase="analyze",baselineFile=ADEAUTOFSCHANGEME, patchFile=AVRSYSTEMJAZNCHAGEME,productionJpsConfig=JPSCNFIGCHANGEME,patchDeltaFolder=AVRJAZNDELTACHANGEME, baselineAppStripe="fscm", productionAppStripe="fscm",patchAppStripe="fscm",ignoreEnterpriseMembersOfAppRole ="false")



exit()
