import subprocess
import os
import shlex
#import pyodbc
#import base64
#from subprocess import Popen, PIPE


cmd_1="sudo python lambda_deployer.py"
cmd_2="terraform apply -var-file=variables.tfvars && terraform output -json > outputs.json"
cmd_3="sudo python sql_executor.py"

# os.system(cmd_1)
#subprocess.call(cmd_1,shell=True)

############################################################################
########################### ERROR HANDLING #################################
############################################################################

os.chdir("src/lambda")
child_1 = subprocess.Popen(shlex.split(cmd_1), stdout=subprocess.PIPE)
streamdata = child_1.communicate()[0]
rc_1 = child_1.returncode
print rc_1

if rc_1 != 0:
    print("Previous Command:",cmd_1,"failed! Please see the Error log for more details.")


############################################################################

os.chdir("../../terraform")

print(os.getcwd())
#child_2 = subprocess.Popen(shlex.split(cmd_2), stdout=subprocess.PIPE)
#streamdata = child_2.communicate()[0]
#rc_2 = child_2.returncode

#print rc_2

os.system(cmd_2)
#if rc_2 != 0:
#    print("Previous Command:",cmd_2,"failed! Please see the Error log for more details.")


############################################################################

os.chdir("../src/sql_executor")
child_3 = subprocess.Popen(shlex.split(cmd_3), stdout=subprocess.PIPE)
streamdata = child_3.communicate()[0]
rc_3 = child_3.returncode

print rc_3

if rc_3 != 0:
    print("Previous Command:",cmd_1,"failed! Please see the Error log for more details.")








