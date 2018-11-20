# file_obfuscator_importer_pipeline
<h2>
  Description
</h2>  
A sample file obfuscation/ingestion pipeline that runs on AWS with automated infrastructure deployment and execution
<h2>
  Process
</h2>  
<ul>
  <li>A file is put to an S3 bucket from an EC2 instance</li>
  <li>The put event generates an alert that triggers the <b>sfn_triggerer</b> lambda, which, in turn, kicks off the state machine </li>
  <li>Inside the State Machine
  <ul>
    <li><b>File Obfuscator Lambda</b> queries the configuration table (created as part of the <b>terraform apply</b>), extracts the column names for the given file name that need to be obfuscated, obfuscates the columns in the source file and writes the result to a separate S3 prefix</li>
    <li>Next <b>rds_inserter</b> lambda inserts both original and obfuscated files into two separate RDS MySQL tables</li>
    <li>Next <b>notifier</b> lambda publishes a Success/Failure SNS notification to its topic, based on the outcome of the previous states of the State Machine</li>. The published notifications at this point is available for future consumption.
  </ul>
</ul>
<h2>
  Execution
</h2>
In order to execute run <B>wrapper.py</b> script
<h2>
  Execution process explained
</h2>
<ul>
  <li><b>wrapper.py</b> executes three scripts in sequence
  <ul>  
    <li><b>lambda_deployer.py</b>: Looks into /src/lambda and creates AWS Lambda Deployment Packages</li>
    <li><b>terraform apply</b>: Deploys AWS infrastructure using the Terraform script included and the deployment packages created during the previous step</li>
    <li><b>sql_executor.py</b>: Creates and populates the configuration table in the RDS instance, created during the terraform apply step</li>
  </ul>
</ul>
