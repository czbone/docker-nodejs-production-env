#!/bin/bash

ANSIBLE_PLAYBOOK="playbooks/main.yml"
ANSIBLE_REQUIREMENTS="playbooks/requirements.yml"

if [ ! -f /vagrant/$ANSIBLE_PLAYBOOK ]; then
  echo "Cannot find Ansible playbook"
  exit 1
fi

echo "Running Ansible"
if [ -n "${ANSIBLE_REQUIREMENTS}" ]; then
  ansible-galaxy install --role-file=/vagrant/${ANSIBLE_REQUIREMENTS} --roles-path=/etc/ansible/roles --force
fi

# Run ansible playbook
export ANSIBLE_HOST_KEY_CHECKING=False
ansible-playbook /vagrant/${ANSIBLE_PLAYBOOK} -i /vagrant/hostlist
exit 0
