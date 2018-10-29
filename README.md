# file_obfuscator_importer_pipeline
<h2>
  Description
</h2>  
A sample file obfuscation/ingestion pipeline that runs on AWS with automated infrastructure deployment and execution
<h2>
  Process
</h2>  
<ul>
  <li>A file is pushed to an S3 bucket from an EC2 instance</li>
  <li>S3 bucket generates an alert, which in turn triggers the <b> State Machine Starter Lambda</b></li>
  <li>The <b> State Machine Starter Lambda</b> in turn kicks off the AWS Step Functions' State Machine</li>
  <li>Inside the State Machine
  <ul>
    <li><b>File Obfuscator Lambda</b> queries the configuration table (created as part of the <b>terraform apply</b>), extracts the column names for the given file that need to be obfuscated, obfuscates the columns in the source file and writes the result to a separate S3 prefix</li>
    <li><b>Data Inserter Lambda</b> Inserts both original and obfuscated files' data into two separate RDS MySQL tables</li>
    <li><b>Notifier Lambda</b> publishes a Success/Failure SNS notification to its topic based on the outcome of the previous states of the State Machine for further consumption</li>
  </ul>
</ul>
<h2>
  Execution
</h2>
<ul>
  <li>Looks into /src/lambda and creates AWS Lambda Deployment Packages</li>
  <li>Deploys AWS infrastructure using the Terraform script included and the deployment packages created in previous step</li>
</ul>
