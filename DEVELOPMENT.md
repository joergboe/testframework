# Folders:

source controlled
- bin      - contains all the scrips necessary to run the framework
- samples  - contains sample test collections
- test     - contains test collections for the test of the framwork
- tools    - contains tools for the creation of the release package

not source controlled
- releases - releaase packages goes here
- runTTWorkdir - work directory with test results and test artifacts

# Create a release package:
- create a release tag vx.y.z
- execute the script buildReleasePackage.sh in the workspace directory

# Installation:
- The release package is a self extracting script. Execute it and follow the instructions.
