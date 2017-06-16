### Installation
After cloning the git repository, it is necessary to run the following commands:

`git submodule init`
`git submodule update`
`git submodule foreach git pull origin master`


This loads parts of this project that come from other git repositories.
The last of the commands ensures that you have the newest versions of the submodules.
