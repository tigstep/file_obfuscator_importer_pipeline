# file_obfuscator_importer_pipeline
<h2>
  Diagram
</h2>

![alt text](https://github.com/tigstep/file_obfuscator_importer_pipeline/blob/master/diagrams/diagram.jpg)
<h2>
  Requirements
</h2>
This project requires Terraform, Python3 and an AWS account.
<h2>
  Tools/Services Used
</h2>
  <ul>
  <li>Python3</li>
  <li>Terraform</li>
  <li>AWS</li>
    <ul>
      <li>EC2</li>
      <li>S3</li>
      <li>Lambda</li>
      <li>RDS</li>
      <li>Step Functions</li>
      <li>SNS</li>
    </ul>
  </ul>
<h2>
  Short Description
</h2>  
A simple file obfuscation/ingestion pipeline that runs on AWS with automated infrastructure deployment and execution
<h2>
  Process Description
</h2>  
<ul>
  <li>A file is put to an S3 bucket from an EC2 instance</li>
  <li>The put event generates an alert that triggers the <b>sfn_triggerer</b> lambda, which, in turn, kicks off the state machine </li>
  <li>Inside the State Machine
  <ul>
    <li><b>File Obfuscator Lambda</b> queries the configuration table (created as part of the <b>terraform apply</b>), extracts the column names for the given file name that need to be obfuscated, obfuscates the columns in the source file and writes the result to a separate S3 prefix</li>
    <li>Next <b>rds_inserter</b> lambda inserts both original and obfuscated files into two separate RDS MySQL tables</li>
    <li>Next <b>notifier</b> lambda publishes a Success/Failure SNS notification to its topic, based on the outcome of the previous states of the State Machine. The published notifications at this point is available for future consumption.</li>
  </ul>
</ul>
<h2>
  Execution
</h2>
In order to execute run <B>wrapper.py</b> script
<h2>
  Execution Process Description
</h2>
<ul>
  <li><b>wrapper.py</b> executes three scripts in sequence
  <ul>  
    <li><b>lambda_deployer.py</b> - Looks into <b>/src/lambda</b> and creates AWS Lambda Deployment Packages</li>
    <li><b>terraform apply</b> - Deploys AWS infrastructure using the Terraform script included and the deployment packages created during the previous step</li>
    <li><b>sql_executor.py</b> - Creates and populates the configuration table in the RDS instance, created during the terraform apply step</li>
  </ul>
</ul>
<h2>
  To Do
</h2>
<ul>
  <li>Implement better logging</li>
  <li>Use Redis for configuration lookup instead of MySQL</li>
  <li>Improve the security by making NACLs and SGs stricter</li>
</ul>
<h2>
  Warnings
</h2>
<ul>
  <li>Current configuration of this project will be using AWS services that are beyond the Free Tier!</li>
</ul>
