# bash_md5check

The bash script compares to directories and deletes duplicate files and moves new and different files to an import folder. Differences depend on a different MD5 hash checksum--not filenames. Two files with the same name and checksums that differ from each are consider different files. It will run on any OS that has a Bash Shell, e.g. Linux, OSX, and Windows with the Linux Subsystem.

The assumption is that you have a SOURCE folder which contains files that you want to merge with another folder. The TARGET folder contains your files that you want to keep. Files will never be delete from the TARGET folder. 

**Example** Let's assume you have your regular Documents folder. You have spend a lot of time to organize the files in there. On an external hard drive you have another folder that contains a lot of document files that you want to merge with your regular Document's folder. The script will look at both folders and detect duplicates and delete them and move files that are not present in your regular Document's folder to an import folder. After that the script will delete all empty folders effectively removing your folder on the external hard drive. That way you will not be confused which folder is which or if it contains any files that might not have been processed. The code that you have to type into your terminal:

```
./main.sh /mnt/external ~/Documents
``` 

## USAGE: 

```
./main.sh [OPTIONS] "SOURCE" "TARGET" 
```
  - SOURCE: This is the directory that contains possible duplicates 
  - TARGET: Contains the files that you want to keep and that you want to import the SOURCE to 
  Please note that the quotation marks are required to accept paths with spaces in the name 

 ## OPTIONS

The following options are available to change the default behavior of the script:
 
  -r) Retain duplicate files in SOURCE folder. Default: delete them. 
  -d) Delete empty folders and metadata files from TARGET. On default only SOURCE will be cleaned of those files and folders 
  -k) Keep unmatched files in SOURCE and don't move them to the import folder in TARGET 
  -m) The default MD5 Checksum file will created in /tmp, i.e. will not be saved. Activate this option if you want to save the MD5 Checksum file for referencing it later. It will be saved to ~/.checksums 
  -v) Verbose - Show additional information during the run of the script 
  -y) Assume 'yes' to all. Great for running it as a cron job etc.

  --help) Show this help message 

## Dependencies
- bash
- realpath