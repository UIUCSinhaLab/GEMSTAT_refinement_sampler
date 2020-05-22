### Installation
After cloning the git repository, it is necessary to run the following commands:

`git submodule init`
`git submodule update`
`git submodule foreach git pull origin master`


This loads parts of this project that come from other git repositories.
The last of the commands ensures that you have the newest versions of the submodules.


### Python Installation
It is recommended to use Miniconda3 to create your python environment.

See the file `requirements.txt` for required python packages.
