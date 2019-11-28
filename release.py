# doc: https://docs.python.org/3/library/argparse.html
# example: http://zetcode.com/python/argparse/
import argparse 
import json
import re
import subprocess

MANIFEST_IMAGE_TAGS = [{
    'arg_name_full': 'app_container_image_tag',
    'arg_name_short': 'app',
    'project name': 'iriversland'
},{
    'arg_name_full': 'appl_tracky_api_image_tag',
    'arg_name_short': 'at',
    'project name': 'appl tracky'
},{
    'arg_name_full': 'postgres_cluster_image_tag',
    'arg_name_short': 'pg',
    'project name': 'postgres db'
},{
    'arg_name_full': 'redis_cluster_image_tag',
    'arg_name_short': 'rd',
    'project name': 'redis db'
},{
    'arg_name_full': 'kafka_connect_image_tag',
    'arg_name_short': 'kc',
    'project name': 'kafka connect cdc'
}]

def validate_tag(docker_build_hash):
    if docker_build_hash.lower().strip() == 'latest':
        return 'latest'
    
    # check by version number (X.X.X)-rX
    version_pattern = re.compile(r'[0-9]+\.[0-9]+.*')
    if version_pattern.match(docker_build_hash):
        return docker_build_hash

    # check by hash
    pattern = re.compile(r'[a-z0-9]{40}')
    if not pattern.match(docker_build_hash):
        raise argparse.ArgumentTypeError('Build hash string is invalid: {}'.format(docker_build_hash))
    return docker_build_hash

def terraform_deploy():
    parser = argparse.ArgumentParser()

    parser.add_argument('-f', '--force', action='store_true', help="force run terraform command even if no change in release. Useful when terraform script changed except microservice installation does not.")

    parser.add_argument('-p', '--plan', action='store_true', help="run a plan terraform command to do a dry run.")

    parser.add_argument('-d', '--delete', action='store_true', help="perform a terraform delete command instead of apply")
    parser.add_argument('-t', '--target', action='append', help="specify resource(s) to be deleted. You can specify multiple times.")

    parser.add_argument('-r', '--refresh', action='store_true', help="update local state file against real resources.")

    parser.add_argument('-rm', '--remove', action='store_true', help="remove items from the Terraform state: https://www.terraform.io/docs/commands/state/rm.html")
    parser.add_argument('-dry', '--dryrun', action='store_true', help="If set, prints out what would've been removed but doesn't actually remove anything.")

    for manifest in MANIFEST_IMAGE_TAGS:
    
        # action=store - just store the value of the arg as a string
        # there's other choices like store_true, store_false, store_const, so that when user specify the flag, an internal value is set
        # see python doc: https://docs.python.org/3/library/argparse.html#action
        parser.add_argument('-{}'.format(manifest['arg_name_short']), '--{}'.format(manifest['arg_name_full']), type=validate_tag, action='store', help="set new {} docker image hash for deployment".format(manifest['project name']))
        
    args_data = parser.parse_args()

    with open('release.json') as f:
        release_history = json.load(f)
    
    if not release_history:
        print('INFO: no history release available.')
        apply_release = []
    apply_release = dict(release_history[-1])

    changed_release = {}
    for manifest in MANIFEST_IMAGE_TAGS:
        hash_value = getattr(args_data, manifest['arg_name_full'])
        if hash_value:
            single_manifest = {
                manifest['arg_name_full']: hash_value
            }
            apply_release.update(single_manifest)
            changed_release.update(single_manifest)
    
    if not changed_release:
        print('no change given')
    else:
        for arg_name_full, hash_value in changed_release.items():
            print('\n{}: {} -> {}'.format(
                arg_name_full,
                release_history[-1][arg_name_full] if release_history and arg_name_full in release_history[-1] else None,
                hash_value
            ))
    
    if args_data.delete:
        terraform_base_command = ['terraform', 'destroy', '-auto-approve']
    elif args_data.plan:
        terraform_base_command = ['terraform', 'plan']
    elif args_data.refresh:
        terraform_base_command = ['terraform', 'refresh']
    elif args_data.remove:
        terraform_base_command = ['terraform', 'state', 'rm', '""']
        terraform_base_command += ['-dry-run'] if args_data.dryrun else []
    else:
        terraform_base_command = ['terraform', 'apply', '-auto-approve']
    
    if not args_data.remove:
        terraform_command = terraform_base_command + ['-var={}={}'.format(env_name, hash_value) for env_name, hash_value in apply_release.items()]
    else:
        terraform_command = terraform_base_command

    if args_data.target:
        # terraform_command += [' '.join([f'-target={target}' for target in args_data.target ])]
        terraform_command += [f'-target={target}' for target in args_data.target]
    
    s = input("\nTerraform command:\n{}\n\nPlease review the change above.\n".format(' '.join(terraform_command)))

    # run terraform here
    if args_data.delete or args_data.plan or args_data.refresh or args_data.remove:  
        subprocess.run(terraform_command, check=True)
    elif changed_release or args_data.force:
        print('INFO: running terraform...')
        try:
            subprocess.run(terraform_command, check=True)

            release_history.append(apply_release)
            with open('release.json', 'w') as f:
                json.dump(release_history, f, indent=4)
        except subprocess.CalledProcessError as e:
            raise
    else:
        print('INFO: terraform not run due to no change.')

    """
        Example:
        terraform apply -var="app_container_image_tag=d41b9b2a6a6b2c645ac36539d8492c9991113f0f" -var="appl_tracky_api_image_tag=49f5d6dbb12e2b23e9b737ccbf79033bc748929a" -auto-approve 
    """


if __name__ == "__main__":
    terraform_deploy()