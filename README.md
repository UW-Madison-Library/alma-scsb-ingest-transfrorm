# BTAA Alma-to-SCSB Data Tranform

This project provides a simple transformation of Alma publishing profile XML data to the XML formatting required by the SCSB ingest process.

This codebase is being developed for the BTAA ReCAP/SCSB pilot project. It is used so the BTAA can kick the proverbial tires on the SCSB software and evaluate its effectiveness as a commitments registry for the BTAA's Big Collection initiative.

## Dependencies

* Ruby 3
* Nokogiri gem
* RubyMarc gem

This code base has been tested using Ruby 3. The gem dependencies will be installed by the setup process.

## Setup

### Step 1: Create Data Directories

Create a location on your file system for the input and output data directories. Note that the root directory path can be any location, but the sub-directories `alma-published-data` and `scsb-ingest-xml` must be present since the codebase expects these directories to exist.

```bash
$ mkdir -p ~/Documents/programming/data/scsb
$ mkdir ~/Documents/programming/data/scsb/alma-published-data
$ mkdir ~/Documents/programming/data/scsb/scsb-ingest-xml
```

### Step 2: Download Alma Published Data

Download the Alma publishing profile data and place the files in the input data directory, `alma-published-data`. Uncompress and extract the XML files from the tarballs:

```bash
$ cd ~/Documents/programming/data/scsb/alma-published-data
$ for file in *.gz; do tar xfz $file; done
```

### Step 3: Clone and Configure the Code Base

1. Clone this repository
1. Install the dependencies
1. Update the configuration file
   * Set the root data_directory from setup step 1
   * Set your institution_code
   * Review the MARC enrichment fields and subfields if your publishing profile did not use the same values

```bash
$ cd ~/Documents/programming/ruby
$ git clone <repo-url>
$ cd alma-scsb-ingest-transform
$ bundle install
$ cp transform.yml.example transform.yml
$ nano transform.yml
```

## Running the Script

```bash
$ ruby main.rb
```

This will generate SCSB ingest XML files in the output data directory created in the setup section. It will generate an output file for each input file. Output files will have a file name based on the input file with `-scsb-ingest` appended in order to make debugging easier.
