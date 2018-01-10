# Folders:

source controlled
- bin      - contains all the scrips necessary to run the framework
- samples  - contains sample test collections
- test     - contains test collections for the test of the framwork
- tools    - contains tools for the creation of the release package

not source controlled
- releases - release packages goes here
- runTTWorkdir - work directory with test results and test artifacts


- doc      - md documentation. Folder is ignored in master branch but controlled in gh-pages branch

# Create a release package:
- Update version info in bin/version.sh
- create a release tag vx.y.z
- clean up your workspace and commit all changes
- execute the script buildReleasePackage.sh in the workspace directory

# Installation:
- The release package is a self extracting script. Execute it and follow the instructions.
