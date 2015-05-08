## Overview
This provides validation for data dictionaries and data files, and is currently implemented within the Phenotype KnowledgeBase (https://phekb.org/).  The application allows you to run it as a standalone app, invoke functionality from an API, or via command line.

## Installation
* Ensure Ruby 2.1 (or higher) is installed on your machine and configured properly.
* Clone the repository
* From the command line, in the project directory
  * `bundle install`
  * `bundle exec rake db:setup`

## Running
### Command Line
To run the application from the command line, you can invoke two different rake tasks, which will return JSON summarizing the results of the validation.  It's recommended that you start with the data ditionary validation first, since errors in the data dictionary will cause issues validating a data file.

The application comes with sample data dictionaries that you can use.
* Data dictionary only: `bundle exec rake validate:data_dictionary['data-dictionary.csv']`
  * Ex: `bundle exec rake validate:data_dictionary['doc/sample-data-dictionary.csv']`
* Data file: `bundle exec rake validate:data_file['data-dictionary.csv','data-file.csv']`
  * Ex: `bundle exec rake validate:data_file['doc/sample-data-dictionary-corrected.csv','doc/sample-data-file.csv']`

### Website
* Start the web server locally
  * `bundle exec rails server`
* Open a browser and navigate to:  http://localhost:3000
* You can select a data dictionary to validate, or both a data dictionary and data file

## Acknowledgements
This work was completed as part of the electronic Medical Records and Genomics (eMERGE) Network.  The eMERGE Network receives funding NHGRI through the following grants: U01HG006828 (Cincinnati Children’s Hospital Medical Center/Boston Children’s Hospital); U01HG006830 (Children’s Hospital of Philadelphia); U01HG006389 (Essentia Institute of Rural Health, Marshfield Clinic Research Foundation and Pennsylvania State University); U01HG006382 (Geisinger Clinic);  U01HG006375 (Group Health Cooperative/University of Washington); U01HG006379 (Mayo Clinic); U01HG006380 (Icahn School of Medicine at Mount Sinai); U01HG006388 (Northwestern University); U01HG006378 (Vanderbilt University Medical Center); and U01HG006385 (Vanderbilt University Medical Center serving as the Coordinating Center).

In addition, the primary author of this software was supported, in part, by the Northwestern University Clinical and Translational Science Institute, Grant Number UL1TR000150 from the National Center for Advancing Translational Sciences, Clinical and Translational Sciences Award (CTSA). The content is solely the responsibility of the authors and does not necessarily represent the official views of the NIH. The CTSA is a registered trademark of the U.S. Department of Health and Human Services (DHHS).

Licensed under the Apache License, Version 2.0 (read LICENSE for more information)