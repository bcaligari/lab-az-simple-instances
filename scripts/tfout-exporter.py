import argparse
import json
import yaml
import jinja2
import os


def tfstate_output(tfstate_json):
    """
    Convert the Terraform output from state file json to a dict suitable for compile_artefact
    """
    tfstate = json.loads(tfstate_json)
    tfout_cooked = {
        "user": tfstate['outputs']['admin']['value']['username'],
        "ssh_private_key": tfstate['outputs']['admin']['value']['ssh_private_key'],
        "hosts": []
    }
    for host in zip(tfstate['outputs']['hosts']['value']['hostname'],
                    tfstate['outputs']['hosts']['value']['private_ip'],
                    tfstate['outputs']['hosts']['value']['public_ip']):
        tfout_cooked['hosts'].append({'hostname': host[0], 'private_ip': host[1], 'public_ip': host[2]})
    return tfout_cooked


def compile_artefact(stencil, values, filename, mode):
    """
    Populate a Jinja2 template and write to a file.
    """
    template = jinja2.Template(stencil)
    print(f"Writing {filename}")
    with open(filename, "w") as f:
        f.write(template.render(values))
    os.chmod(filename, mode)


def main():
    """
    To docsplain later
    """
    prog = 'python tfout-exporter.py'
    description = ('Generate artefacts from Terraform output variables.')
    parser = argparse.ArgumentParser(prog=prog, description=description)
    parser.add_argument("artefacts", nargs='?',
                        type=argparse.FileType('r', encoding="utf-8"),
                        help="artefact list of j2 templates and filenames in yaml (artefacts.yaml)",
                        default="artefacts.yaml")
    parser.add_argument("tfstate", nargs='?',
                        type=argparse.FileType('r', encoding="utf-8"),
                        help="the 'terraform output --json' data (terraform.tfstate)",
                        default="terraform.tfstate")
    args = parser.parse_args()
    tfstate = args.tfstate
    artefacts_file = args.artefacts
    with tfstate, artefacts_file:
        artefacts = yaml.safe_load(artefacts_file)
        infra_data = tfstate_output(tfstate.read())
        for artefact in artefacts:
            compile_artefact(artefact['stencil'],
                                        infra_data,
                                        artefact['filename'],
                                        int(artefact['mode'], base=8))


if __name__ == "__main__":
    main()
