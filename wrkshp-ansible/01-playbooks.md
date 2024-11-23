# Ansible playbooks

Ansible playbooks are the files you will used to define the tasks you want to execute on ansible clients. An ansible playbook is a YAML file than can include all the tasks you want to execute. You can see an example in[generate-linux-pass-hash.yaml](generate-linux-pass-hash.yaml). However, you will use ansible roles which will allow you to reuse you code.

In [generate-linux-pass-hash.yaml](generate-linux-pass-hash.yaml):

+ How to use an ansible variable to store the output for a command.
+ How one user can provide information using the keyboard.
+ How to run tasks in the ansible controller without having to use SSH.

```console
[ansible@archimedes wrkshp-ansible]$ ansible-playbook -i hosts generate-linux-pass-hash.yaml 
Write you password to get the password hash: : 

PLAY [localhost] *************************************************************************************************************************************************************************************

TASK [random value to be used as salt to create the password] ****************************************************************************************************************************************
changed: [localhost -> 127.0.0.1]

TASK [hash creation (sha512)] ************************************************************************************************************************************************************************
changed: [localhost -> 127.0.0.1]

TASK [debug] *****************************************************************************************************************************************************************************************
ok: [localhost -> 127.0.0.1] => {
    "msg": "Password hash is $6$vCe5cnAZ8h7Pv9UY$p5UwZugjyyTu6jLoLoM0s1gTwWrD0uZXH1/OXpS82MaQ1P7aE5FJcvj9QAnxxo11YwNZ08xnrzIhtAWf9OpSU1"
}

PLAY RECAP *******************************************************************************************************************************************************************************************
localhost                  : ok=3    changed=2    unreachable=0    failed=0    skipped=0    rescued=0    ignored=0   

[ansible@archimedes wrkshp-ansible]$
```