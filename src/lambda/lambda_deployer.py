#import imp
import shutil
import os
#import pdb
#import pip
#import sys
import virtualenv
from pip._internal import main as pipmain
#import subprocess
##################################################################
#               create a virtual environment
##################################################################

def create_activate_venv(current_folder):
        site_package_dir = os.path.join(current_folder, "site_packages")
        pipmain(["install", "--target", site_package_dir, "mysql-connector"])

##################################################################
#       move the site_packages out of venv(move_site_packages())
##################################################################

##################################################################
#       deactivate venv and remove the folder(deactivate())
##################################################################

##################################################################
#       remove the venv directory(remove_venv_dir())
##################################################################

##################################################################
#       create a .zip with site packages(create_zip())
##################################################################
def create_zip(base_dir, func_dir, dir):
    output_dir = os.path.join(os.path.join(base_dir, 'deployment_packages'), dir)
    shutil.make_archive(output_dir, 'zip', os.path.join(func_dir, dir))

##################################################################
#       boto3 deploy the deployment packages(deploy_package())
##################################################################

##################################################################
#       remove the .zip(remove_zip())
##################################################################
def remove_zip(base_dir):
    deployment_packages_dir = os.path.join(base_dir, 'deployment_packages')
    shutil.rmtree(deployment_packages_dir)

##################################################################
#       main method to execute the above
##################################################################

######### create_activate_venv(current_folder)
######### move_site_packages()
######### deactivate()
######### remove_venv_dir()
######### create_zip()
######### deploy_package()
######### remove_zip()

def main():
    base_dir = os.getcwd()
    func_dir = os.path.join(base_dir, 'functions')
    #for dir in next(os.walk(func_dir))[1]:
    create_activate_venv(os.path.join(func_dir,'data_obfuscator'))
        #create_zip(base_dir, func_dir, dir)
        #remove_zip(base_dir)
main()
