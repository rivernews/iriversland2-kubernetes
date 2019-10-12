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
}]

def check_hash(docker_build_hash):
    pattern = re.compile(r'[a-z0-9]{40}')
    if not pattern.match(docker_build_hash):
        raise argparse.ArgumentTypeError('Build hash string is invalid: {}'.format(docker_build_hash))
    return docker_build_hash

def terraform_deploy():
    parser = argparse.ArgumentParser()

    for manifest in MANIFEST_IMAGE_TAGS:
    
        # action=store - just store the value of the arg as a string
        # there's other choices like store_true, store_false, store_const, so that when user specify the flag, an internal value is set
        # see python doc: https://docs.python.org/3/library/argparse.html#action
        parser.add_argument('-{}'.format(manifest['arg_name_short']), '--{}'.format(manifest['arg_name_full']), type=check_hash, action='store', help="set new {} docker image hash for deployment".format(manifest['project name']))
        
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
                release_history[-1][arg_name_full] if release_history else None,
                hash_value
            ))
    s = input("Please review the change above.")

    # run terraform here
    if changed_release:
        print('INFO: running terraform...')
        try:
            subprocess.run([
                'terraform', 'apply'] +
                ['-var={}={}'.format(env_name, hash_value) for env_name, hash_value in apply_release.items()]
                + ['-auto-approve'
            ], check=True)

            release_history.append(apply_release)
            with open('release.json', 'w') as f:
                json.dump(release_history, f)
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