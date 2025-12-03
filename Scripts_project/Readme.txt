Seq reader analyzer with processing pipeline using FastP software

1º
Create a project folder with Folder_maker.sh

Project/
 ├── Raw_data/              # Copied FASTQ files
 ├── Processed_data/        # Processed FASTQ files (versioned)
 ├── Results/               # FastQC + MultiQC outputs
 └── Logs/   


NOTE:
    Before continuing:
    It is necessary to active the proper conda enviroment, that has Fastqc, multiqc and fastp software
    Using a GNU screen is also optimal, allows the user to maitain control of the terminal whilst the software is running

2º 
Then use the Copy_Analyzer.sh script to copy the necessary files (note it will only copy fastq.gz .fastq files).
Capable of local copy and remote through ssh protocol
This script will run an initial analysis with fastqc and multiqc.

3º
Run the processor_analyser.sh
This software will normalize the files that are in the raw folder, 
allowing for uncomomn naming schemes to be utilized.
This software creates a version for each run of the software, allowing an iterative approach to each run.
This software allows the user to select a few standard 
processing options availabe within fastp,
while also allowing other options for advanced users to use.
!!!!!!ATTENTION USING INCORRECT OPTIONS WILL BREAK THE PROGRAM, USE WITH CARE!!!!

???? Profit?

Enjoy your results in the Results folder
Trimmed files will be in the processed_files folder.
