
### Experiments
	An experiment is defined by a numerically named .bash file in `REFINEMENT_SETTINGS`, for example `REFINEMENT_SETTINGS/1.bash`

### Refinement Methods
	A refinement method is defined by an executable file in the `METHODS` subdirectory.

	See `METHODS/EXAMPLE` for a bash script that parses the command-line parameters that are expected from a refinement method, you can put anything in `METHODS` and as long as it uses the correct command-line parameters and environment variables, producing the right output files, it should work.

	The intention is that you will wrap calls to GEMSTAT with a bash script here.

### Scoring Methods
	A scoring method is defined by an executable in `SCORING` whose STDOUT will be just one floating-point score with no newline.

	See `SCORING/SSE` for an example, there are several command-line parameters that a scoring method should be sensitive to.
	I should explain them

	- --data [DIRECTORY]
		A data directory containing the training data as it was input when the method was trained
	- --parfile [FILENAME]
		The parfile *whence refinement began* (to be symmetric to the refinement method command-line parameters)
	- --parout [FILENAME]
		The parfile after refinement. (Could be used if you want to score something about the properties of the par files, such as distance from known true parameters...)
	- --out [FILENAME]
		The output from cross-validation. Currently that output might contain the ground-truth, but ideally, you should get the ground-truth from the --data option, since in the future we might give no data at cross-validation time, to prevent methods from somehow cheating.

### Datasets
	TODO: Mention the subdirectory structure for storing a dataset

A dataset directory must contain the following:
	- template.par (optional, but used if you want to randomly generate starting points on-the-fly.)
	- base/ (required by the system)
		- seqs.fa (assumed by gemstat)
		- 
	- ORTHO/
		- whatever_your_training_ortholog_name_was
			- whatever files you want to have overwrite the base dataset
		- another_ortholog
			- whatever files are specific to _this_ ortholog


### Defining Ensembles

Ensembles of starting-points are stored in the `ENSEMBLES` directory.

An ensemble definition make take one of three forms:
	- A randomly generated ensemble from a `template.par` file in the dataset. This will be expected if your REFINEMMENT\_SETTING file does not specify an "ENSEMBLE\_NAME" environment variable.
	- A fixed ensemble from an ASCII format table of values, substituted into a `template.par` file.
		If the file `ENSEMBLES/${ENSEMBLE_NAME}` is a regular file, that file is assumed to be a table of values which will be used this way.
	- A directory of .par files.
		If the file `ENSEMBLES/${ENSEMBLE_NAME}` is a directory, it is assumed to contain files named 1.par 2.par ... etc.
