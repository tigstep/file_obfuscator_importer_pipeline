import os
import shutil

def install_reqs(current_folder):
        site_package_dir = os.path.join(current_folder, "site_packages")
        print("site_packages_dir is : " + str(site_package_dir))
        req_file = open(os.path.join(current_folder,'requirements.txt'))
        for line in req_file:
            os.system("pip install " + line + " --target " + str(site_package_dir))

def create_zip(base_dir, func_dir, dir):
    output_dir = os.path.join(os.path.join(os.path.join(base_dir, '../../terraform'), 'deployment_packages'), dir)
    shutil.make_archive(output_dir, 'zip', os.path.join(func_dir, dir))

def remove_site_packages(dir):
    shutil.rmtree(dir)

def main():
    base_dir = os.getcwd()
    func_dir = os.path.join(base_dir, 'functions')
    for dir in next(os.walk(func_dir))[1]:
        print("current dir is : " + str(dir))
        install_reqs(os.path.join(func_dir,dir))
        create_zip(base_dir, func_dir, dir)
        remove_site_packages(os.path.join(os.path.join(func_dir, dir),'site_packages'))
main()
