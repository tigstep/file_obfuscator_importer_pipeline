# file_obfuscator_importer_pipeline
<h2>
  Description
</h2>  
A sample file obfuscation/ingestion pipeline running on AWS with automated infrastructure deployment and execution
<h2>
  Process
</h2>  
<ul>
  <li>A file will be pushed to an S3 bucket from an EC2 instance</li>
  <li>S3 bucket will generate an alert which in turn will trigger the <b> State Machine Starter lambda</b> function</li>
  <li>The <b> State Machine Starter Lambda</b> function in turn will kick off AWS Step Functions' State Machine</li>
  <li>Inside the State Machine
  <ul>
    <li><b>File Obfuscator Lambda</b> looks up in the configuration table located in RDS and based on the file name obfuscates the columns specified and writes the result to separate S3 prefix</li>
    <li><b>Data Inserter Lambda</b> Inserts both original and obfuscated files' data into two separate RDS MySQL tables</li>
    <li><b>Notifier Lambda</b> sends out a Success/Failure SNS notification based on the outcome of the previous states of the State Machine</li>
  </ul>
</ul>
<h2>
  Execution
</h2>
<ul>
  <li>Looks into /src/lambda and creates AWS Lambda Deployment Packages</li>
  <li>Deploys AWS infrastructure using the Terraform script included and the deployment packages created in previous step</li>
</ul>
